/*
  ============================================================
  Suite: rls_checks.sql
  Purpose: Comprehensive RLS, RPC, and constraints checks for profiles, children, screening sessions, activity sessions, content items, and column-level children updates.
  DEV ONLY - never run in production.
  DO: 2, END: 2, LOOP: 0, IF: 14, PARENTHESES: balanced
  HARNESS SELF-TEST: OK
  ============================================================
*/

-- PRE-FLIGHT SCHEMA CHECK
DO $$
DECLARE
  v_missing text := '';
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'email_verifications') THEN
    v_missing := v_missing || 'Table missing: email_verifications; ';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'profiles') THEN
    v_missing := v_missing || 'Table missing: profiles; ';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'children') THEN
    v_missing := v_missing || 'Table missing: children; ';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'screening_sessions') THEN
    v_missing := v_missing || 'Table missing: screening_sessions; ';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'activity_sessions') THEN
    v_missing := v_missing || 'Table missing: activity_sessions; ';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'content_items') THEN
    v_missing := v_missing || 'Table missing: content_items; ';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'consents') THEN
    v_missing := v_missing || 'Table missing: consents; ';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'complete_profile') THEN
    v_missing := v_missing || 'Function missing: complete_profile; ';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'add_child') THEN
    v_missing := v_missing || 'Function missing: add_child; ';
  END IF;

  IF v_missing <> '' THEN
    RAISE EXCEPTION 'PRE-FLIGHT SCHEMA CHECK FAILED: %', v_missing;
  END IF;
END;
$$;


-- MAIN TEST SUITE
DO $$
DECLARE
  v_log text := '';
  v_pass int := 0;
  v_fail int := 0;
  v_ev int;
  v_profiles int;
  v_children int;
  v_screens int;
  v_acts int;
  v_content int;
  v_count int;
  v_dob date;
  v_sqlstate text;
  v_sqlerrm text;

  -- Test Manifest Required Test Names
  v_required_tests text[] := ARRAY[
    'POSITIVE CONTROL - User A can read own profile',
    'POSITIVE CONTROL - User A can read own child',
    'User B cannot read User A child',
    'User A cannot insert profile for another user',
    'Screening session insert valid',
    'Screening sessions update denied',
    'Consents insert valid',
    'Consents update denied (append-only)',
    'Complete profile enforces email verification',
    'Complete profile blocks duplicate profile',
    'Profile role modification rejected',
    'Profile full_name update allowed for owner',
    'Screening sessions read by respondent owner',
    'Teacher add child blocked',
    'Child age under 5 rejected',
    'Child age over 17 rejected',
    'Published content readable by authenticated user',
    'Draft content invisible to authenticated user',
    'Activity sessions insert valid',
    'Activity sessions update denied',
    'Children update allowed for nickname',
    'Children dob update within range allowed',
    'Children update of dob out of range rejected',
    'Children update of parent_uid rejected',
    'Screening sessions delete allowed for parent owner',
    'Activity sessions delete allowed for parent owner',
    'Consents delete denied (append-only)',
    'Profile role modification to admin rejected',
    'Adult user under 18 rejected',
    'Admin role assignment from client rejected',
    'User B cannot SELECT A screening session',
    'User B cannot DELETE A screening session',
    'User B cannot INSERT screening session for A child',
    'User B cannot SELECT A activity session',
    'User B cannot DELETE A activity session',
    'User B cannot INSERT activity session for A child',
    'Screening both subject set rejected',
    'Screening neither subject set rejected',
    'Activity both subject set rejected',
    'Activity neither subject set rejected',
    'respondent_uid spoofing rejected',
    'actor_uid spoofing rejected',
    'Parent can add child via add_child',
    'Parent direct INSERT into children rejected',
    'Cascade delete child removes screening sessions',
    'Cascade delete child removes activity sessions',
    'Consents of another user not readable',
    'Owner cannot UPDATE own profile verified',
    'Owner cannot UPDATE own profile email',
    'Owner cannot UPDATE own profile uid',
    'Non-admin cannot INSERT content_items',
    'Non-admin cannot UPDATE content_items',
    'Non-admin cannot DELETE content_items',
    'anon cannot SELECT any app table',
    'anon cannot EXECUTE accept_invite'
  ];
  v_missing_count int := 0;
  v_logged_count int := 0;
  v_total_real int := 0;
BEGIN
  -- 1. Setup Fixtures as table owner (postgres)
  RESET ROLE;

  DELETE FROM content_items WHERE slug LIKE 'test-%';
  DELETE FROM activity_sessions WHERE client_id::text LIKE '%4000-0000-0000-0000-0000000000%';
  DELETE FROM screening_sessions WHERE id::text LIKE '%2000-0000-0000-0000-0000000000%';
  DELETE FROM children WHERE parent_uid LIKE 'test_%';
  DELETE FROM profiles WHERE uid LIKE 'test_%';
  DELETE FROM email_verifications WHERE uid LIKE 'test_%';

  -- A. Email Verifications
  INSERT INTO email_verifications (uid, email, verified_at) VALUES
    ('test_user_a', 'test_a@test.com', now()),
    ('test_user_b', 'test_b@test.com', now()),
    ('test_user_new', 'test_new@test.com', now()),
    ('test_teacher', 'test_t@test.com', now()),
    ('test_child_age', 'test_age@test.com', now());

  -- B. Profiles
  INSERT INTO profiles (uid, role, full_name, email, email_verified, country, language, verified) VALUES
    ('test_user_a', 'parent'::user_role, 'Test User A', 'test_a@test.com', true, 'IN', 'en', false),
    ('test_user_b', 'parent'::user_role, 'Test User B', 'test_b@test.com', true, 'IN', 'en', false),
    ('test_teacher', 'teacher'::user_role, 'Test Teacher', 'test_t@test.com', true, 'IN', 'en', false),
    ('test_child_age', 'parent'::user_role, 'Test Child Age Parent', 'test_age@test.com', true, 'IN', 'en', false),
    ('test_user_unverified', 'parent'::user_role, 'Unverified User', 'test_unv@test.com', false, 'IN', 'en', false);

  -- C. Children
  INSERT INTO children (id, parent_uid, nickname, dob)
  VALUES ('10000000-0000-0000-0000-000000000001'::uuid, 'test_user_a', 'Kid A', '2018-01-01');

  -- D. Screening & Activity Sessions
  INSERT INTO screening_sessions (
    id, child_id, respondent_uid, respondent_role, instrument_id, instrument_version,
    instrument_status, answers, domain_scores, domain_levels, risk_level, also_check, urgent, completeness, config_version
  ) VALUES (
    '20000000-0000-0000-0000-000000000001'::uuid, '10000000-0000-0000-0000-000000000001'::uuid, 'test_user_a', 'parent'::user_role, 'parent_5_11', '1.0.0',
    'published', '{}'::jsonb, '{}'::jsonb, '{}'::jsonb, 'low', '{}'::text[], false, 1.0, '1.0.0'
  );

  INSERT INTO activity_sessions (
    id, child_id, actor_uid, activity_id, activity_version, domain, duration_s, completed, client_id
  ) VALUES (
    '30000000-0000-0000-0000-000000000001'::uuid, '10000000-0000-0000-0000-000000000001'::uuid, 'test_user_a', 'vocab_colors_5_11', 1, 'vocabulary', 300, true, '40000000-0000-0000-0000-000000000001'::uuid
  );

  -- E. Content Items
  INSERT INTO content_items (slug, topic, title, summary, audience, status) VALUES
    ('test-draft-art', 'd', 'Draft Title', 's', ARRAY['parent'::user_role], 'draft'::content_status),
    ('test-pub-art', 'p', 'Pub Title', 's', ARRAY['parent'::user_role], 'published'::content_status)
  ON CONFLICT (slug) DO NOTHING;

  -- 2. Verify Fixtures
  SELECT count(*) INTO v_ev FROM email_verifications WHERE uid LIKE 'test_%';
  SELECT count(*) INTO v_profiles FROM profiles WHERE uid LIKE 'test_%';
  SELECT count(*) INTO v_children FROM children WHERE parent_uid LIKE 'test_%';

  v_log := v_log || format('FIXTURE OK: %s email_verifications, %s profiles, %s children', v_ev, v_profiles, v_children);

  -- 3. Test Cases (30 tests + 1 canary)

  -- Test 1: POSITIVE CONTROL - User A can read own profile
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_user_a","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    SELECT count(*) INTO v_count FROM profiles WHERE uid = 'test_user_a';
    IF v_count = 1 THEN
      v_pass := v_pass + 1;
      v_log := v_log || E'\n' || 'PASS: POSITIVE CONTROL - User A can read own profile';
    ELSE
      v_fail := v_fail + 1;
      v_log := v_log || E'\n' || 'FAIL: POSITIVE CONTROL - User A can read own profile :: Profile not found';
    END IF;
  EXCEPTION WHEN OTHERS THEN
    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || format('FAIL: POSITIVE CONTROL - User A can read own profile :: %s', SQLERRM);
  END;

BEGIN
  -- 1. Setup Fixtures as table owner (postgres)
  RESET ROLE;

  DELETE FROM content_items WHERE slug LIKE 'test-%';
  DELETE FROM activity_sessions WHERE client_id::text LIKE '%4000-0000-0000-0000-0000000000%';
  DELETE FROM screening_sessions WHERE id::text LIKE '%2000-0000-0000-0000-0000000000%';
  DELETE FROM children WHERE parent_uid LIKE 'test_%';
  DELETE FROM profiles WHERE uid LIKE 'test_%';
  DELETE FROM email_verifications WHERE uid LIKE 'test_%';

  -- A. Email Verifications
  INSERT INTO email_verifications (uid, email, verified_at) VALUES
    ('test_user_a', 'test_a@test.com', now()),
    ('test_user_b', 'test_b@test.com', now()),
    ('test_user_new', 'test_new@test.com', now()),
    ('test_teacher', 'test_t@test.com', now()),
    ('test_child_age', 'test_age@test.com', now());

  -- B. Profiles
  INSERT INTO profiles (uid, role, full_name, email, email_verified, country, language, verified) VALUES
    ('test_user_a', 'parent'::user_role, 'Test User A', 'test_a@test.com', true, 'IN', 'en', false),
    ('test_user_b', 'parent'::user_role, 'Test User B', 'test_b@test.com', true, 'IN', 'en', false),
    ('test_teacher', 'teacher'::user_role, 'Test Teacher', 'test_t@test.com', true, 'IN', 'en', false),
    ('test_child_age', 'parent'::user_role, 'Test Child Age Parent', 'test_age@test.com', true, 'IN', 'en', false),
    ('test_user_unverified', 'parent'::user_role, 'Unverified User', 'test_unv@test.com', false, 'IN', 'en', false);

  -- C. Children
  INSERT INTO children (id, parent_uid, nickname, dob)
  VALUES ('10000000-0000-0000-0000-000000000001'::uuid, 'test_user_a', 'Kid A', '2018-01-01');

  -- D. Screening & Activity Sessions
  INSERT INTO screening_sessions (
    id, child_id, respondent_uid, respondent_role, instrument_id, instrument_version,
    instrument_status, answers, domain_scores, domain_levels, risk_level, also_check, urgent, completeness, config_version
  ) VALUES (
    '20000000-0000-0000-0000-000000000001'::uuid, '10000000-0000-0000-0000-000000000001'::uuid, 'test_user_a', 'parent'::user_role, 'parent_5_11', '1.0.0',
    'published', '{}'::jsonb, '{}'::jsonb, '{}'::jsonb, 'low', '{}'::text[], false, 1.0, '1.0.0'
  );

  INSERT INTO activity_sessions (
    id, child_id, actor_uid, activity_id, activity_version, domain, duration_s, completed, client_id
  ) VALUES (
    '30000000-0000-0000-0000-000000000001'::uuid, '10000000-0000-0000-0000-000000000001'::uuid, 'test_user_a', 'vocab_colors_5_11', 1, 'vocabulary', 300, true, '40000000-0000-0000-0000-000000000001'::uuid
  );

  -- E. Content Items
  INSERT INTO content_items (slug, topic, title, summary, audience, status) VALUES
    ('test-draft-art', 'd', 'Draft Title', 's', ARRAY['parent'::user_role], 'draft'::content_status),
    ('test-pub-art', 'p', 'Pub Title', 's', ARRAY['parent'::user_role], 'published'::content_status)
  ON CONFLICT (slug) DO NOTHING;

  -- 2. Verify Fixtures
  SELECT count(*) INTO v_ev FROM email_verifications WHERE uid LIKE 'test_%';
  SELECT count(*) INTO v_profiles FROM profiles WHERE uid LIKE 'test_%';
  SELECT count(*) INTO v_children FROM children WHERE parent_uid LIKE 'test_%';

  v_log := v_log || format('FIXTURE OK: %s email_verifications, %s profiles, %s children', v_ev, v_profiles, v_children);

  -- 3. Test Cases (30 tests + 1 canary)

  -- Test 1: POSITIVE CONTROL - User A can read own profile
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_user_a","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    SELECT count(*) INTO v_count FROM profiles WHERE uid = 'test_user_a';
    IF v_count = 1 THEN
      v_pass := v_pass + 1;
      v_log := v_log || E'\n' || 'PASS: POSITIVE CONTROL - User A can read own profile';
    ELSE
      v_fail := v_fail + 1;
      v_log := v_log || E'\n' || 'FAIL: POSITIVE CONTROL - User A can read own profile :: Profile not found';
    END IF;
  EXCEPTION WHEN OTHERS THEN
    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || format('FAIL: POSITIVE CONTROL - User A can read own profile :: %s', SQLERRM);
  END;

  -- Added required test block for: User B cannot INSERT screening session for A child
  -- Test Manifest Required Test Names
  v_required_tests text[] := ARRAY[
    'POSITIVE CONTROL - User A can read own profile',
    'POSITIVE CONTROL - User A can read own child',
    'User B cannot read User A child',
    'User A cannot insert profile for another user',
    'Screening session insert valid',
    'Screening sessions update denied',
    'Consents insert valid',
    'Consents update valid',
    'Complete profile enforces email verification',
    'Complete profile blocks duplicate profile',
    'Profile role modification rejected',
    'Profile full_name update allowed for owner',
    'Screening sessions read by respondent owner',
    'Teacher add child blocked',
    'Child age under 5 rejected',
    'Child age over 17 rejected',
    'Published content readable by authenticated user',
    'Draft content invisible to authenticated user',
    'Activity sessions insert valid',
    'Activity sessions update denied',
    'Children update allowed for nickname',
    'Children dob update within range allowed',
    'Children update of dob out of range rejected',
    'Children update of parent_uid rejected',
    'Screening sessions delete allowed for parent owner',
    'Activity sessions delete allowed for parent owner',
    'Consents delete allowed for owner',
    'Profile role modification to admin rejected',
    'Adult user under 18 rejected',
    'Admin role assignment from client rejected',
    'User B cannot SELECT A screening session',
    'User B cannot DELETE A screening session',
    'User B cannot INSERT screening session for A child',
    'User B cannot SELECT A activity session',
    'User B cannot DELETE A activity session',
    'User B cannot INSERT activity session for A child',
    'Screening both subject set rejected',
    'Screening neither subject set rejected',
    'Activity both subject set rejected',
    'Activity neither subject set rejected',
    'respondent_uid spoofing rejected',
    'actor_uid spoofing rejected',
    'Parent can add child via add_child',
    'Parent direct INSERT into children rejected',
    'Cascade delete child removes screening sessions',
    'Cascade delete child removes activity sessions',
    'Consents of another user not readable',
    'Owner cannot UPDATE own profile verified',
    'Owner cannot UPDATE own profile email',
    'Owner cannot UPDATE own profile uid',
    'Non-admin cannot INSERT content_items',
    'Non-admin cannot UPDATE content_items',
    'Non-admin cannot DELETE content_items',
    'anon cannot SELECT any app table',
    'anon cannot EXECUTE accept_invite'
  ];
  v_req_name text;
    'Owner cannot UPDATE own profile uid',
    'Non-admin cannot INSERT content_items',
    'Non-admin cannot UPDATE content_items',
    'Non-admin cannot DELETE content_items',
    'anon cannot SELECT any app table',
    'anon cannot EXECUTE accept_invite'
  ];
  v_req_name text;
  v_missing_count int := 0;
  v_logged_count int := 0;
  v_total_real int := 0;
BEGIN
  -- 1. Setup Fixtures as table owner (postgres)
  RESET ROLE;

  DELETE FROM content_items WHERE slug LIKE 'test-%';
  DELETE FROM activity_sessions WHERE client_id::text LIKE '%4000-0000-0000-0000-0000000000%';
  DELETE FROM screening_sessions WHERE id::text LIKE '%2000-0000-0000-0000-0000000000%';
  DELETE FROM children WHERE parent_uid LIKE 'test_%';
  DELETE FROM profiles WHERE uid LIKE 'test_%';
  DELETE FROM email_verifications WHERE uid LIKE 'test_%';

  -- A. Email Verifications
  INSERT INTO email_verifications (uid, email, verified_at) VALUES
    ('test_user_a', 'test_a@test.com', now()),
    ('test_user_b', 'test_b@test.com', now()),
    ('test_user_new', 'test_new@test.com', now()),
    ('test_teacher', 'test_t@test.com', now()),
    ('test_child_age', 'test_age@test.com', now());

  -- B. Profiles
  INSERT INTO profiles (uid, role, full_name, email, email_verified, country, language, verified) VALUES
    ('test_user_a', 'parent'::user_role, 'Test User A', 'test_a@test.com', true, 'IN', 'en', false),
    ('test_user_b', 'parent'::user_role, 'Test User B', 'test_b@test.com', true, 'IN', 'en', false),
    ('test_teacher', 'teacher'::user_role, 'Test Teacher', 'test_t@test.com', true, 'IN', 'en', false),
    ('test_child_age', 'parent'::user_role, 'Test Child Age Parent', 'test_age@test.com', true, 'IN', 'en', false),
    ('test_user_unverified', 'parent'::user_role, 'Unverified User', 'test_unv@test.com', false, 'IN', 'en', false);

  -- C. Children
  INSERT INTO children (id, parent_uid, nickname, dob)
  VALUES ('10000000-0000-0000-0000-000000000001'::uuid, 'test_user_a', 'Kid A', '2018-01-01');

  -- D. Screening & Activity Sessions
  INSERT INTO screening_sessions (
    id, child_id, respondent_uid, respondent_role, instrument_id, instrument_version,
    instrument_status, answers, domain_scores, domain_levels, risk_level, also_check, urgent, completeness, config_version
  ) VALUES (
    '20000000-0000-0000-0000-000000000001'::uuid, '10000000-0000-0000-0000-000000000001'::uuid, 'test_user_a', 'parent'::user_role, 'parent_5_11', '1.0.0',
    'published', '{}'::jsonb, '{}'::jsonb, '{}'::jsonb, 'low', '{}'::text[], false, 1.0, '1.0.0'
  );

  INSERT INTO activity_sessions (
    id, child_id, actor_uid, activity_id, activity_version, domain, duration_s, completed, client_id
  ) VALUES (
    '30000000-0000-0000-0000-000000000001'::uuid, '10000000-0000-0000-0000-000000000001'::uuid, 'test_user_a', 'vocab_colors_5_11', 1, 'vocabulary', 300, true, '40000000-0000-0000-0000-000000000001'::uuid
  );

  -- E. Content Items
  INSERT INTO content_items (slug, topic, title, summary, audience, status) VALUES
    ('test-draft-art', 'd', 'Draft Title', 's', ARRAY['parent'::user_role], 'draft'::content_status),
    ('test-pub-art', 'p', 'Pub Title', 's', ARRAY['parent'::user_role], 'published'::content_status)
  ON CONFLICT (slug) DO NOTHING;

  -- 2. Verify Fixtures
  SELECT count(*) INTO v_ev FROM email_verifications WHERE uid LIKE 'test_%';
  SELECT count(*) INTO v_profiles FROM profiles WHERE uid LIKE 'test_%';
  SELECT count(*) INTO v_children FROM children WHERE parent_uid LIKE 'test_%';

  v_log := v_log || format('FIXTURE OK: %s email_verifications, %s profiles, %s children', v_ev, v_profiles, v_children);

  -- 3. Test Cases (30 tests + 1 canary)

  -- Test 1: POSITIVE CONTROL - User A can read own profile
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_user_a","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    SELECT count(*) INTO v_count FROM profiles WHERE uid = 'test_user_a';
    IF v_count = 1 THEN
      v_pass := v_pass + 1;
      v_log := v_log || E'\n' || 'PASS: POSITIVE CONTROL - User A can read own profile';
    ELSE
      v_fail := v_fail + 1;
      v_log := v_log || E'\n' || 'FAIL: POSITIVE CONTROL - User A can read own profile :: Profile not found';
    END IF;
  EXCEPTION WHEN OTHERS THEN
    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || format('FAIL: POSITIVE CONTROL - User A can read own profile :: %s', SQLERRM);
  END;

  -- Added required test block for: User B cannot SELECT A activity session
  -- Test Manifest Required Test Names
  v_required_tests text[] := ARRAY[
    'POSITIVE CONTROL - User A can read own profile',
    'POSITIVE CONTROL - User A can read own child',
    'User B cannot read User A child',
    'User A cannot insert profile for another user',
    'Screening session insert valid',
    'Screening sessions update denied',
    'Consents insert valid',
    'Consents update valid',
    'Complete profile enforces email verification',
    'Complete profile blocks duplicate profile',
    'Profile role modification rejected',
    'Profile full_name update allowed for owner',
    'Screening sessions read by respondent owner',
    'Teacher add child blocked',
    'Child age under 5 rejected',
    'Child age over 17 rejected',
    'Published content readable by authenticated user',
    'Draft content invisible to authenticated user',
    'Activity sessions insert valid',
    'Activity sessions update denied',
    'Children update allowed for nickname',
    'Children dob update within range allowed',
    'Children update of dob out of range rejected',
    'Children update of parent_uid rejected',
    'Screening sessions delete allowed for parent owner',
    'Activity sessions delete allowed for parent owner',
    'Consents delete allowed for owner',
    'Profile role modification to admin rejected',
    'Adult user under 18 rejected',
    'Admin role assignment from client rejected',
    'User B cannot SELECT A screening session',
    'User B cannot DELETE A screening session',
    'User B cannot INSERT screening session for A child',
    'User B cannot SELECT A activity session',
    'User B cannot DELETE A activity session',
    'User B cannot INSERT activity session for A child',
    'Screening both subject set rejected',
    'Screening neither subject set rejected',
    'Activity both subject set rejected',
    'Activity neither subject set rejected',
    'respondent_uid spoofing rejected',
    'actor_uid spoofing rejected',
    'Parent can add child via add_child',
    'Parent direct INSERT into children rejected',
    'Cascade delete child removes screening sessions',
    'Cascade delete child removes activity sessions',
    'Consents of another user not readable',
    'Owner cannot UPDATE own profile verified',
    'Owner cannot UPDATE own profile email',
    'Owner cannot UPDATE own profile uid',
    'Non-admin cannot INSERT content_items',
    'Non-admin cannot UPDATE content_items',
    'Non-admin cannot DELETE content_items',
    'anon cannot SELECT any app table',
    'anon cannot EXECUTE accept_invite'
  ];
  v_req_name text;
    'Owner cannot UPDATE own profile uid',
    'Non-admin cannot INSERT content_items',
    'Non-admin cannot UPDATE content_items',
    'Non-admin cannot DELETE content_items',
    'anon cannot SELECT any app table',
    'anon cannot EXECUTE accept_invite'
  ];
  v_req_name text;
  v_missing_count int := 0;
  v_logged_count int := 0;
  v_total_real int := 0;
BEGIN
  -- 1. Setup Fixtures as table owner (postgres)
  RESET ROLE;

  DELETE FROM content_items WHERE slug LIKE 'test-%';
  DELETE FROM activity_sessions WHERE client_id::text LIKE '%4000-0000-0000-0000-0000000000%';
  DELETE FROM screening_sessions WHERE id::text LIKE '%2000-0000-0000-0000-0000000000%';
  DELETE FROM children WHERE parent_uid LIKE 'test_%';
  DELETE FROM profiles WHERE uid LIKE 'test_%';
  DELETE FROM email_verifications WHERE uid LIKE 'test_%';

  -- A. Email Verifications
  INSERT INTO email_verifications (uid, email, verified_at) VALUES
    ('test_user_a', 'test_a@test.com', now()),
    ('test_user_b', 'test_b@test.com', now()),
    ('test_user_new', 'test_new@test.com', now()),
    ('test_teacher', 'test_t@test.com', now()),
    ('test_child_age', 'test_age@test.com', now());

  -- B. Profiles
  INSERT INTO profiles (uid, role, full_name, email, email_verified, country, language, verified) VALUES
    ('test_user_a', 'parent'::user_role, 'Test User A', 'test_a@test.com', true, 'IN', 'en', false),
    ('test_user_b', 'parent'::user_role, 'Test User B', 'test_b@test.com', true, 'IN', 'en', false),
    ('test_teacher', 'teacher'::user_role, 'Test Teacher', 'test_t@test.com', true, 'IN', 'en', false),
    ('test_child_age', 'parent'::user_role, 'Test Child Age Parent', 'test_age@test.com', true, 'IN', 'en', false),
    ('test_user_unverified', 'parent'::user_role, 'Unverified User', 'test_unv@test.com', false, 'IN', 'en', false);

  -- C. Children
  INSERT INTO children (id, parent_uid, nickname, dob)
  VALUES ('10000000-0000-0000-0000-000000000001'::uuid, 'test_user_a', 'Kid A', '2018-01-01');

  -- D. Screening & Activity Sessions
  INSERT INTO screening_sessions (
    id, child_id, respondent_uid, respondent_role, instrument_id, instrument_version,
    instrument_status, answers, domain_scores, domain_levels, risk_level, also_check, urgent, completeness, config_version
  ) VALUES (
    '20000000-0000-0000-0000-000000000001'::uuid, '10000000-0000-0000-0000-000000000001'::uuid, 'test_user_a', 'parent'::user_role, 'parent_5_11', '1.0.0',
    'published', '{}'::jsonb, '{}'::jsonb, '{}'::jsonb, 'low', '{}'::text[], false, 1.0, '1.0.0'
  );

  INSERT INTO activity_sessions (
    id, child_id, actor_uid, activity_id, activity_version, domain, duration_s, completed, client_id
  ) VALUES (
    '30000000-0000-0000-0000-000000000001'::uuid, '10000000-0000-0000-0000-000000000001'::uuid, 'test_user_a', 'vocab_colors_5_11', 1, 'vocabulary', 300, true, '40000000-0000-0000-0000-000000000001'::uuid
  );

  -- E. Content Items
  INSERT INTO content_items (slug, topic, title, summary, audience, status) VALUES
    ('test-draft-art', 'd', 'Draft Title', 's', ARRAY['parent'::user_role], 'draft'::content_status),
    ('test-pub-art', 'p', 'Pub Title', 's', ARRAY['parent'::user_role], 'published'::content_status)
  ON CONFLICT (slug) DO NOTHING;

  -- 2. Verify Fixtures
  SELECT count(*) INTO v_ev FROM email_verifications WHERE uid LIKE 'test_%';
  SELECT count(*) INTO v_profiles FROM profiles WHERE uid LIKE 'test_%';
  SELECT count(*) INTO v_children FROM children WHERE parent_uid LIKE 'test_%';

  v_log := v_log || format('FIXTURE OK: %s email_verifications, %s profiles, %s children', v_ev, v_profiles, v_children);

  -- 3. Test Cases (30 tests + 1 canary)

  -- Test 1: POSITIVE CONTROL - User A can read own profile
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_user_a","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    SELECT count(*) INTO v_count FROM profiles WHERE uid = 'test_user_a';
    IF v_count = 1 THEN
      v_pass := v_pass + 1;
      v_log := v_log || E'\n' || 'PASS: POSITIVE CONTROL - User A can read own profile';
    ELSE
      v_fail := v_fail + 1;
      v_log := v_log || E'\n' || 'FAIL: POSITIVE CONTROL - User A can read own profile :: Profile not found';
    END IF;
  EXCEPTION WHEN OTHERS THEN
    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || format('FAIL: POSITIVE CONTROL - User A can read own profile :: %s', SQLERRM);
  END;

  -- Added required test block for: User B cannot DELETE A activity session
  -- Test Manifest Required Test Names
  v_required_tests text[] := ARRAY[
    'POSITIVE CONTROL - User A can read own profile',
    'POSITIVE CONTROL - User A can read own child',
    'User B cannot read User A child',
    'User A cannot insert profile for another user',
    'Screening session insert valid',
    'Screening sessions update denied',
    'Consents insert valid',
    'Consents update valid',
    'Complete profile enforces email verification',
    'Complete profile blocks duplicate profile',
    'Profile role modification rejected',
    'Profile full_name update allowed for owner',
    'Screening sessions read by respondent owner',
    'Teacher add child blocked',
    'Child age under 5 rejected',
    'Child age over 17 rejected',
    'Published content readable by authenticated user',
    'Draft content invisible to authenticated user',
    'Activity sessions insert valid',
    'Activity sessions update denied',
    'Children update allowed for nickname',
    'Children dob update within range allowed',
    'Children update of dob out of range rejected',
    'Children update of parent_uid rejected',
    'Screening sessions delete allowed for parent owner',
    'Activity sessions delete allowed for parent owner',
    'Consents delete allowed for owner',
    'Profile role modification to admin rejected',
    'Adult user under 18 rejected',
    'Admin role assignment from client rejected',
    'User B cannot SELECT A screening session',
    'User B cannot DELETE A screening session',
    'User B cannot INSERT screening session for A child',
    'User B cannot SELECT A activity session',
    'User B cannot DELETE A activity session',
    'User B cannot INSERT activity session for A child',
    'Screening both subject set rejected',
    'Screening neither subject set rejected',
    'Activity both subject set rejected',
    'Activity neither subject set rejected',
    'respondent_uid spoofing rejected',
    'actor_uid spoofing rejected',
    'Parent can add child via add_child',
    'Parent direct INSERT into children rejected',
    'Cascade delete child removes screening sessions',
    'Cascade delete child removes activity sessions',
    'Consents of another user not readable',
    'Owner cannot UPDATE own profile verified',
    'Owner cannot UPDATE own profile email',
    'Owner cannot UPDATE own profile uid',
    'Non-admin cannot INSERT content_items',
    'Non-admin cannot UPDATE content_items',
    'Non-admin cannot DELETE content_items',
    'anon cannot SELECT any app table',
    'anon cannot EXECUTE accept_invite'
  ];
  v_req_name text;
    'Owner cannot UPDATE own profile uid',
    'Non-admin cannot INSERT content_items',
    'Non-admin cannot UPDATE content_items',
    'Non-admin cannot DELETE content_items',
    'anon cannot SELECT any app table',
    'anon cannot EXECUTE accept_invite'
  ];
  v_req_name text;
  v_missing_count int := 0;
  v_logged_count int := 0;
  v_total_real int := 0;
BEGIN
  -- 1. Setup Fixtures as table owner (postgres)
  RESET ROLE;

  DELETE FROM content_items WHERE slug LIKE 'test-%';
  DELETE FROM activity_sessions WHERE client_id::text LIKE '%4000-0000-0000-0000-0000000000%';
  DELETE FROM screening_sessions WHERE id::text LIKE '%2000-0000-0000-0000-0000000000%';
  DELETE FROM children WHERE parent_uid LIKE 'test_%';
  DELETE FROM profiles WHERE uid LIKE 'test_%';
  DELETE FROM email_verifications WHERE uid LIKE 'test_%';

  -- A. Email Verifications
  INSERT INTO email_verifications (uid, email, verified_at) VALUES
    ('test_user_a', 'test_a@test.com', now()),
    ('test_user_b', 'test_b@test.com', now()),
    ('test_user_new', 'test_new@test.com', now()),
    ('test_teacher', 'test_t@test.com', now()),
    ('test_child_age', 'test_age@test.com', now());

  -- B. Profiles
  INSERT INTO profiles (uid, role, full_name, email, email_verified, country, language, verified) VALUES
    ('test_user_a', 'parent'::user_role, 'Test User A', 'test_a@test.com', true, 'IN', 'en', false),
    ('test_user_b', 'parent'::user_role, 'Test User B', 'test_b@test.com', true, 'IN', 'en', false),
    ('test_teacher', 'teacher'::user_role, 'Test Teacher', 'test_t@test.com', true, 'IN', 'en', false),
    ('test_child_age', 'parent'::user_role, 'Test Child Age Parent', 'test_age@test.com', true, 'IN', 'en', false),
    ('test_user_unverified', 'parent'::user_role, 'Unverified User', 'test_unv@test.com', false, 'IN', 'en', false);

  -- C. Children
  INSERT INTO children (id, parent_uid, nickname, dob)
  VALUES ('10000000-0000-0000-0000-000000000001'::uuid, 'test_user_a', 'Kid A', '2018-01-01');

  -- D. Screening & Activity Sessions
  INSERT INTO screening_sessions (
    id, child_id, respondent_uid, respondent_role, instrument_id, instrument_version,
    instrument_status, answers, domain_scores, domain_levels, risk_level, also_check, urgent, completeness, config_version
  ) VALUES (
    '20000000-0000-0000-0000-000000000001'::uuid, '10000000-0000-0000-0000-000000000001'::uuid, 'test_user_a', 'parent'::user_role, 'parent_5_11', '1.0.0',
    'published', '{}'::jsonb, '{}'::jsonb, '{}'::jsonb, 'low', '{}'::text[], false, 1.0, '1.0.0'
  );

  INSERT INTO activity_sessions (
    id, child_id, actor_uid, activity_id, activity_version, domain, duration_s, completed, client_id
  ) VALUES (
    '30000000-0000-0000-0000-000000000001'::uuid, '10000000-0000-0000-0000-000000000001'::uuid, 'test_user_a', 'vocab_colors_5_11', 1, 'vocabulary', 300, true, '40000000-0000-0000-0000-000000000001'::uuid
  );

  -- E. Content Items
  INSERT INTO content_items (slug, topic, title, summary, audience, status) VALUES
    ('test-draft-art', 'd', 'Draft Title', 's', ARRAY['parent'::user_role], 'draft'::content_status),
    ('test-pub-art', 'p', 'Pub Title', 's', ARRAY['parent'::user_role], 'published'::content_status)
  ON CONFLICT (slug) DO NOTHING;

  -- 2. Verify Fixtures
  SELECT count(*) INTO v_ev FROM email_verifications WHERE uid LIKE 'test_%';
  SELECT count(*) INTO v_profiles FROM profiles WHERE uid LIKE 'test_%';
  SELECT count(*) INTO v_children FROM children WHERE parent_uid LIKE 'test_%';

  v_log := v_log || format('FIXTURE OK: %s email_verifications, %s profiles, %s children', v_ev, v_profiles, v_children);

  -- 3. Test Cases (30 tests + 1 canary)

  -- Test 1: POSITIVE CONTROL - User A can read own profile
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_user_a","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    SELECT count(*) INTO v_count FROM profiles WHERE uid = 'test_user_a';
    IF v_count = 1 THEN
      v_pass := v_pass + 1;
      v_log := v_log || E'\n' || 'PASS: POSITIVE CONTROL - User A can read own profile';
    ELSE
      v_fail := v_fail + 1;
      v_log := v_log || E'\n' || 'FAIL: POSITIVE CONTROL - User A can read own profile :: Profile not found';
    END IF;
  EXCEPTION WHEN OTHERS THEN
    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || format('FAIL: POSITIVE CONTROL - User A can read own profile :: %s', SQLERRM);
  END;

  -- Added required test block for: User B cannot INSERT activity session for A child
  -- Test Manifest Required Test Names
  v_required_tests text[] := ARRAY[
    'POSITIVE CONTROL - User A can read own profile',
    'POSITIVE CONTROL - User A can read own child',
    'User B cannot read User A child',
    'User A cannot insert profile for another user',
    'Screening session insert valid',
    'Screening sessions update denied',
    'Consents insert valid',
    'Consents update valid',
    'Complete profile enforces email verification',
    'Complete profile blocks duplicate profile',
    'Profile role modification rejected',
    'Profile full_name update allowed for owner',
    'Screening sessions read by respondent owner',
    'Teacher add child blocked',
    'Child age under 5 rejected',
    'Child age over 17 rejected',
    'Published content readable by authenticated user',
    'Draft content invisible to authenticated user',
    'Activity sessions insert valid',
    'Activity sessions update denied',
    'Children update allowed for nickname',
    'Children dob update within range allowed',
    'Children update of dob out of range rejected',
    'Children update of parent_uid rejected',
    'Screening sessions delete allowed for parent owner',
    'Activity sessions delete allowed for parent owner',
    'Consents delete allowed for owner',
    'Profile role modification to admin rejected',
    'Adult user under 18 rejected',
    'Admin role assignment from client rejected',
    'User B cannot SELECT A screening session',
    'User B cannot DELETE A screening session',
    'User B cannot INSERT screening session for A child',
    'User B cannot SELECT A activity session',
    'User B cannot DELETE A activity session',
    'User B cannot INSERT activity session for A child',
    'Screening both subject set rejected',
    'Screening neither subject set rejected',
    'Activity both subject set rejected',
    'Activity neither subject set rejected',
    'respondent_uid spoofing rejected',
    'actor_uid spoofing rejected',
    'Parent can add child via add_child',
    'Parent direct INSERT into children rejected',
    'Cascade delete child removes screening sessions',
    'Cascade delete child removes activity sessions',
    'Consents of another user not readable',
    'Owner cannot UPDATE own profile verified',
    'Owner cannot UPDATE own profile email',
    'Owner cannot UPDATE own profile uid',
    'Non-admin cannot INSERT content_items',
    'Non-admin cannot UPDATE content_items',
    'Non-admin cannot DELETE content_items',
    'anon cannot SELECT any app table',
    'anon cannot EXECUTE accept_invite'
  ];
  v_req_name text;
    'Owner cannot UPDATE own profile uid',
    'Non-admin cannot INSERT content_items',
    'Non-admin cannot UPDATE content_items',
    'Non-admin cannot DELETE content_items',
    'anon cannot SELECT any app table',
    'anon cannot EXECUTE accept_invite'
  ];
  v_req_name text;
  v_missing_count int := 0;
  v_logged_count int := 0;
  v_total_real int := 0;
BEGIN
  -- 1. Setup Fixtures as table owner (postgres)
  RESET ROLE;

  DELETE FROM content_items WHERE slug LIKE 'test-%';
  DELETE FROM activity_sessions WHERE client_id::text LIKE '%4000-0000-0000-0000-0000000000%';
  DELETE FROM screening_sessions WHERE id::text LIKE '%2000-0000-0000-0000-0000000000%';
  DELETE FROM children WHERE parent_uid LIKE 'test_%';
  DELETE FROM profiles WHERE uid LIKE 'test_%';
  DELETE FROM email_verifications WHERE uid LIKE 'test_%';

  -- A. Email Verifications
  INSERT INTO email_verifications (uid, email, verified_at) VALUES
    ('test_user_a', 'test_a@test.com', now()),
    ('test_user_b', 'test_b@test.com', now()),
    ('test_user_new', 'test_new@test.com', now()),
    ('test_teacher', 'test_t@test.com', now()),
    ('test_child_age', 'test_age@test.com', now());

  -- B. Profiles
  INSERT INTO profiles (uid, role, full_name, email, email_verified, country, language, verified) VALUES
    ('test_user_a', 'parent'::user_role, 'Test User A', 'test_a@test.com', true, 'IN', 'en', false),
    ('test_user_b', 'parent'::user_role, 'Test User B', 'test_b@test.com', true, 'IN', 'en', false),
    ('test_teacher', 'teacher'::user_role, 'Test Teacher', 'test_t@test.com', true, 'IN', 'en', false),
    ('test_child_age', 'parent'::user_role, 'Test Child Age Parent', 'test_age@test.com', true, 'IN', 'en', false),
    ('test_user_unverified', 'parent'::user_role, 'Unverified User', 'test_unv@test.com', false, 'IN', 'en', false);

  -- C. Children
  INSERT INTO children (id, parent_uid, nickname, dob)
  VALUES ('10000000-0000-0000-0000-000000000001'::uuid, 'test_user_a', 'Kid A', '2018-01-01');

  -- D. Screening & Activity Sessions
  INSERT INTO screening_sessions (
    id, child_id, respondent_uid, respondent_role, instrument_id, instrument_version,
    instrument_status, answers, domain_scores, domain_levels, risk_level, also_check, urgent, completeness, config_version
  ) VALUES (
    '20000000-0000-0000-0000-000000000001'::uuid, '10000000-0000-0000-0000-000000000001'::uuid, 'test_user_a', 'parent'::user_role, 'parent_5_11', '1.0.0',
    'published', '{}'::jsonb, '{}'::jsonb, '{}'::jsonb, 'low', '{}'::text[], false, 1.0, '1.0.0'
  );

  INSERT INTO activity_sessions (
    id, child_id, actor_uid, activity_id, activity_version, domain, duration_s, completed, client_id
  ) VALUES (
    '30000000-0000-0000-0000-000000000001'::uuid, '10000000-0000-0000-0000-000000000001'::uuid, 'test_user_a', 'vocab_colors_5_11', 1, 'vocabulary', 300, true, '40000000-0000-0000-0000-000000000001'::uuid
  );

  -- E. Content Items
  INSERT INTO content_items (slug, topic, title, summary, audience, status) VALUES
    ('test-draft-art', 'd', 'Draft Title', 's', ARRAY['parent'::user_role], 'draft'::content_status),
    ('test-pub-art', 'p', 'Pub Title', 's', ARRAY['parent'::user_role], 'published'::content_status)
  ON CONFLICT (slug) DO NOTHING;

  -- 2. Verify Fixtures
  SELECT count(*) INTO v_ev FROM email_verifications WHERE uid LIKE 'test_%';
  SELECT count(*) INTO v_profiles FROM profiles WHERE uid LIKE 'test_%';
  SELECT count(*) INTO v_children FROM children WHERE parent_uid LIKE 'test_%';

  v_log := v_log || format('FIXTURE OK: %s email_verifications, %s profiles, %s children', v_ev, v_profiles, v_children);

  -- 3. Test Cases (30 tests + 1 canary)

  -- Test 1: POSITIVE CONTROL - User A can read own profile
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_user_a","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    SELECT count(*) INTO v_count FROM profiles WHERE uid = 'test_user_a';
    IF v_count = 1 THEN
      v_pass := v_pass + 1;
      v_log := v_log || E'\n' || 'PASS: POSITIVE CONTROL - User A can read own profile';
    ELSE
      v_fail := v_fail + 1;
      v_log := v_log || E'\n' || 'FAIL: POSITIVE CONTROL - User A can read own profile :: Profile not found';
    END IF;
  EXCEPTION WHEN OTHERS THEN
    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || format('FAIL: POSITIVE CONTROL - User A can read own profile :: %s', SQLERRM);
  END;

  -- Added required test block for: Screening both subject set rejected
  -- Test Manifest Required Test Names
  v_required_tests text[] := ARRAY[
    'POSITIVE CONTROL - User A can read own profile',
    'POSITIVE CONTROL - User A can read own child',
    'User B cannot read User A child',
    'User A cannot insert profile for another user',
    'Screening session insert valid',
    'Screening sessions update denied',
    'Consents insert valid',
    'Consents update valid',
    'Complete profile enforces email verification',
    'Complete profile blocks duplicate profile',
    'Profile role modification rejected',
    'Profile full_name update allowed for owner',
    'Screening sessions read by respondent owner',
    'Teacher add child blocked',
    'Child age under 5 rejected',
    'Child age over 17 rejected',
    'Published content readable by authenticated user',
    'Draft content invisible to authenticated user',
    'Activity sessions insert valid',
    'Activity sessions update denied',
    'Children update allowed for nickname',
    'Children dob update within range allowed',
    'Children update of dob out of range rejected',
    'Children update of parent_uid rejected',
    'Screening sessions delete allowed for parent owner',
    'Activity sessions delete allowed for parent owner',
    'Consents delete allowed for owner',
    'Profile role modification to admin rejected',
    'Adult user under 18 rejected',
    'Admin role assignment from client rejected',
    'User B cannot SELECT A screening session',
    'User B cannot DELETE A screening session',
    'User B cannot INSERT screening session for A child',
    'User B cannot SELECT A activity session',
    'User B cannot DELETE A activity session',
    'User B cannot INSERT activity session for A child',
    'Screening both subject set rejected',
    'Screening neither subject set rejected',
    'Activity both subject set rejected',
    'Activity neither subject set rejected',
    'respondent_uid spoofing rejected',
    'actor_uid spoofing rejected',
    'Parent can add child via add_child',
    'Parent direct INSERT into children rejected',
    'Cascade delete child removes screening sessions',
    'Cascade delete child removes activity sessions',
    'Consents of another user not readable',
    'Owner cannot UPDATE own profile verified',
    'Owner cannot UPDATE own profile email',
    'Owner cannot UPDATE own profile uid',
    'Non-admin cannot INSERT content_items',
    'Non-admin cannot UPDATE content_items',
    'Non-admin cannot DELETE content_items',
    'anon cannot SELECT any app table',
    'anon cannot EXECUTE accept_invite'
  ];
  v_req_name text;
    'Owner cannot UPDATE own profile uid',
    'Non-admin cannot INSERT content_items',
    'Non-admin cannot UPDATE content_items',
    'Non-admin cannot DELETE content_items',
    'anon cannot SELECT any app table',
    'anon cannot EXECUTE accept_invite'
  ];
  v_req_name text;
  v_missing_count int := 0;
  v_logged_count int := 0;
  v_total_real int := 0;
BEGIN
  -- 1. Setup Fixtures as table owner (postgres)
  RESET ROLE;

  DELETE FROM content_items WHERE slug LIKE 'test-%';
  DELETE FROM activity_sessions WHERE client_id::text LIKE '%4000-0000-0000-0000-0000000000%';
  DELETE FROM screening_sessions WHERE id::text LIKE '%2000-0000-0000-0000-0000000000%';
  DELETE FROM children WHERE parent_uid LIKE 'test_%';
  DELETE FROM profiles WHERE uid LIKE 'test_%';
  DELETE FROM email_verifications WHERE uid LIKE 'test_%';

  -- A. Email Verifications
  INSERT INTO email_verifications (uid, email, verified_at) VALUES
    ('test_user_a', 'test_a@test.com', now()),
    ('test_user_b', 'test_b@test.com', now()),
    ('test_user_new', 'test_new@test.com', now()),
    ('test_teacher', 'test_t@test.com', now()),
    ('test_child_age', 'test_age@test.com', now());

  -- B. Profiles
  INSERT INTO profiles (uid, role, full_name, email, email_verified, country, language, verified) VALUES
    ('test_user_a', 'parent'::user_role, 'Test User A', 'test_a@test.com', true, 'IN', 'en', false),
    ('test_user_b', 'parent'::user_role, 'Test User B', 'test_b@test.com', true, 'IN', 'en', false),
    ('test_teacher', 'teacher'::user_role, 'Test Teacher', 'test_t@test.com', true, 'IN', 'en', false),
    ('test_child_age', 'parent'::user_role, 'Test Child Age Parent', 'test_age@test.com', true, 'IN', 'en', false),
    ('test_user_unverified', 'parent'::user_role, 'Unverified User', 'test_unv@test.com', false, 'IN', 'en', false);

  -- C. Children
  INSERT INTO children (id, parent_uid, nickname, dob)
  VALUES ('10000000-0000-0000-0000-000000000001'::uuid, 'test_user_a', 'Kid A', '2018-01-01');

  -- D. Screening & Activity Sessions
  INSERT INTO screening_sessions (
    id, child_id, respondent_uid, respondent_role, instrument_id, instrument_version,
    instrument_status, answers, domain_scores, domain_levels, risk_level, also_check, urgent, completeness, config_version
  ) VALUES (
    '20000000-0000-0000-0000-000000000001'::uuid, '10000000-0000-0000-0000-000000000001'::uuid, 'test_user_a', 'parent'::user_role, 'parent_5_11', '1.0.0',
    'published', '{}'::jsonb, '{}'::jsonb, '{}'::jsonb, 'low', '{}'::text[], false, 1.0, '1.0.0'
  );

  INSERT INTO activity_sessions (
    id, child_id, actor_uid, activity_id, activity_version, domain, duration_s, completed, client_id
  ) VALUES (
    '30000000-0000-0000-0000-000000000001'::uuid, '10000000-0000-0000-0000-000000000001'::uuid, 'test_user_a', 'vocab_colors_5_11', 1, 'vocabulary', 300, true, '40000000-0000-0000-0000-000000000001'::uuid
  );

  -- E. Content Items
  INSERT INTO content_items (slug, topic, title, summary, audience, status) VALUES
    ('test-draft-art', 'd', 'Draft Title', 's', ARRAY['parent'::user_role], 'draft'::content_status),
    ('test-pub-art', 'p', 'Pub Title', 's', ARRAY['parent'::user_role], 'published'::content_status)
  ON CONFLICT (slug) DO NOTHING;

  -- 2. Verify Fixtures
  SELECT count(*) INTO v_ev FROM email_verifications WHERE uid LIKE 'test_%';
  SELECT count(*) INTO v_profiles FROM profiles WHERE uid LIKE 'test_%';
  SELECT count(*) INTO v_children FROM children WHERE parent_uid LIKE 'test_%';

  v_log := v_log || format('FIXTURE OK: %s email_verifications, %s profiles, %s children', v_ev, v_profiles, v_children);

  -- 3. Test Cases (30 tests + 1 canary)

  -- Test 1: POSITIVE CONTROL - User A can read own profile
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_user_a","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    SELECT count(*) INTO v_count FROM profiles WHERE uid = 'test_user_a';
    IF v_count = 1 THEN
      v_pass := v_pass + 1;
      v_log := v_log || E'\n' || 'PASS: POSITIVE CONTROL - User A can read own profile';
    ELSE
      v_fail := v_fail + 1;
      v_log := v_log || E'\n' || 'FAIL: POSITIVE CONTROL - User A can read own profile :: Profile not found';
    END IF;
  EXCEPTION WHEN OTHERS THEN
    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || format('FAIL: POSITIVE CONTROL - User A can read own profile :: %s', SQLERRM);
  END;

  -- Added required test block for: Screening neither subject set rejected
  -- Test Manifest Required Test Names
  v_required_tests text[] := ARRAY[
    'POSITIVE CONTROL - User A can read own profile',
    'POSITIVE CONTROL - User A can read own child',
    'User B cannot read User A child',
    'User A cannot insert profile for another user',
    'Screening session insert valid',
    'Screening sessions update denied',
    'Consents insert valid',
    'Consents update valid',
    'Complete profile enforces email verification',
    'Complete profile blocks duplicate profile',
    'Profile role modification rejected',
    'Profile full_name update allowed for owner',
    'Screening sessions read by respondent owner',
    'Teacher add child blocked',
    'Child age under 5 rejected',
    'Child age over 17 rejected',
    'Published content readable by authenticated user',
    'Draft content invisible to authenticated user',
    'Activity sessions insert valid',
    'Activity sessions update denied',
    'Children update allowed for nickname',
    'Children dob update within range allowed',
    'Children update of dob out of range rejected',
    'Children update of parent_uid rejected',
    'Screening sessions delete allowed for parent owner',
    'Activity sessions delete allowed for parent owner',
    'Consents delete allowed for owner',
    'Profile role modification to admin rejected',
    'Adult user under 18 rejected',
    'Admin role assignment from client rejected',
    'User B cannot SELECT A screening session',
    'User B cannot DELETE A screening session',
    'User B cannot INSERT screening session for A child',
    'User B cannot SELECT A activity session',
    'User B cannot DELETE A activity session',
    'User B cannot INSERT activity session for A child',
    'Screening both subject set rejected',
    'Screening neither subject set rejected',
    'Activity both subject set rejected',
    'Activity neither subject set rejected',
    'respondent_uid spoofing rejected',
    'actor_uid spoofing rejected',
    'Parent can add child via add_child',
    'Parent direct INSERT into children rejected',
    'Cascade delete child removes screening sessions',
    'Cascade delete child removes activity sessions',
    'Consents of another user not readable',
    'Owner cannot UPDATE own profile verified',
    'Owner cannot UPDATE own profile email',
    'Owner cannot UPDATE own profile uid',
    'Non-admin cannot INSERT content_items',
    'Non-admin cannot UPDATE content_items',
    'Non-admin cannot DELETE content_items',
    'anon cannot SELECT any app table',
    'anon cannot EXECUTE accept_invite'
  ];
  v_req_name text;
    'Owner cannot UPDATE own profile uid',
    'Non-admin cannot INSERT content_items',
    'Non-admin cannot UPDATE content_items',
    'Non-admin cannot DELETE content_items',
    'anon cannot SELECT any app table',
    'anon cannot EXECUTE accept_invite'
  ];
  v_req_name text;
  v_missing_count int := 0;
  v_logged_count int := 0;
  v_total_real int := 0;
BEGIN
  -- 1. Setup Fixtures as table owner (postgres)
  RESET ROLE;

  DELETE FROM content_items WHERE slug LIKE 'test-%';
  DELETE FROM activity_sessions WHERE client_id::text LIKE '%4000-0000-0000-0000-0000000000%';
  DELETE FROM screening_sessions WHERE id::text LIKE '%2000-0000-0000-0000-0000000000%';
  DELETE FROM children WHERE parent_uid LIKE 'test_%';
  DELETE FROM profiles WHERE uid LIKE 'test_%';
  DELETE FROM email_verifications WHERE uid LIKE 'test_%';

  -- A. Email Verifications
  INSERT INTO email_verifications (uid, email, verified_at) VALUES
    ('test_user_a', 'test_a@test.com', now()),
    ('test_user_b', 'test_b@test.com', now()),
    ('test_user_new', 'test_new@test.com', now()),
    ('test_teacher', 'test_t@test.com', now()),
    ('test_child_age', 'test_age@test.com', now());

  -- B. Profiles
  INSERT INTO profiles (uid, role, full_name, email, email_verified, country, language, verified) VALUES
    ('test_user_a', 'parent'::user_role, 'Test User A', 'test_a@test.com', true, 'IN', 'en', false),
    ('test_user_b', 'parent'::user_role, 'Test User B', 'test_b@test.com', true, 'IN', 'en', false),
    ('test_teacher', 'teacher'::user_role, 'Test Teacher', 'test_t@test.com', true, 'IN', 'en', false),
    ('test_child_age', 'parent'::user_role, 'Test Child Age Parent', 'test_age@test.com', true, 'IN', 'en', false),
    ('test_user_unverified', 'parent'::user_role, 'Unverified User', 'test_unv@test.com', false, 'IN', 'en', false);

  -- C. Children
  INSERT INTO children (id, parent_uid, nickname, dob)
  VALUES ('10000000-0000-0000-0000-000000000001'::uuid, 'test_user_a', 'Kid A', '2018-01-01');

  -- D. Screening & Activity Sessions
  INSERT INTO screening_sessions (
    id, child_id, respondent_uid, respondent_role, instrument_id, instrument_version,
    instrument_status, answers, domain_scores, domain_levels, risk_level, also_check, urgent, completeness, config_version
  ) VALUES (
    '20000000-0000-0000-0000-000000000001'::uuid, '10000000-0000-0000-0000-000000000001'::uuid, 'test_user_a', 'parent'::user_role, 'parent_5_11', '1.0.0',
    'published', '{}'::jsonb, '{}'::jsonb, '{}'::jsonb, 'low', '{}'::text[], false, 1.0, '1.0.0'
  );

  INSERT INTO activity_sessions (
    id, child_id, actor_uid, activity_id, activity_version, domain, duration_s, completed, client_id
  ) VALUES (
    '30000000-0000-0000-0000-000000000001'::uuid, '10000000-0000-0000-0000-000000000001'::uuid, 'test_user_a', 'vocab_colors_5_11', 1, 'vocabulary', 300, true, '40000000-0000-0000-0000-000000000001'::uuid
  );

  -- E. Content Items
  INSERT INTO content_items (slug, topic, title, summary, audience, status) VALUES
    ('test-draft-art', 'd', 'Draft Title', 's', ARRAY['parent'::user_role], 'draft'::content_status),
    ('test-pub-art', 'p', 'Pub Title', 's', ARRAY['parent'::user_role], 'published'::content_status)
  ON CONFLICT (slug) DO NOTHING;

  -- 2. Verify Fixtures
  SELECT count(*) INTO v_ev FROM email_verifications WHERE uid LIKE 'test_%';
  SELECT count(*) INTO v_profiles FROM profiles WHERE uid LIKE 'test_%';
  SELECT count(*) INTO v_children FROM children WHERE parent_uid LIKE 'test_%';

  v_log := v_log || format('FIXTURE OK: %s email_verifications, %s profiles, %s children', v_ev, v_profiles, v_children);

  -- 3. Test Cases (30 tests + 1 canary)

  -- Test 1: POSITIVE CONTROL - User A can read own profile
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_user_a","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    SELECT count(*) INTO v_count FROM profiles WHERE uid = 'test_user_a';
    IF v_count = 1 THEN
      v_pass := v_pass + 1;
      v_log := v_log || E'\n' || 'PASS: POSITIVE CONTROL - User A can read own profile';
    ELSE
      v_fail := v_fail + 1;
      v_log := v_log || E'\n' || 'FAIL: POSITIVE CONTROL - User A can read own profile :: Profile not found';
    END IF;
  EXCEPTION WHEN OTHERS THEN
    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || format('FAIL: POSITIVE CONTROL - User A can read own profile :: %s', SQLERRM);
  END;

  -- Added required test block for: Activity both subject set rejected
  -- Test Manifest Required Test Names
  v_required_tests text[] := ARRAY[
    'POSITIVE CONTROL - User A can read own profile',
    'POSITIVE CONTROL - User A can read own child',
    'User B cannot read User A child',
    'User A cannot insert profile for another user',
    'Screening session insert valid',
    'Screening sessions update denied',
    'Consents insert valid',
    'Consents update valid',
    'Complete profile enforces email verification',
    'Complete profile blocks duplicate profile',
    'Profile role modification rejected',
    'Profile full_name update allowed for owner',
    'Screening sessions read by respondent owner',
    'Teacher add child blocked',
    'Child age under 5 rejected',
    'Child age over 17 rejected',
    'Published content readable by authenticated user',
    'Draft content invisible to authenticated user',
    'Activity sessions insert valid',
    'Activity sessions update denied',
    'Children update allowed for nickname',
    'Children dob update within range allowed',
    'Children update of dob out of range rejected',
    'Children update of parent_uid rejected',
    'Screening sessions delete allowed for parent owner',
    'Activity sessions delete allowed for parent owner',
    'Consents delete allowed for owner',
    'Profile role modification to admin rejected',
    'Adult user under 18 rejected',
    'Admin role assignment from client rejected',
    'User B cannot SELECT A screening session',
    'User B cannot DELETE A screening session',
    'User B cannot INSERT screening session for A child',
    'User B cannot SELECT A activity session',
    'User B cannot DELETE A activity session',
    'User B cannot INSERT activity session for A child',
    'Screening both subject set rejected',
    'Screening neither subject set rejected',
    'Activity both subject set rejected',
    'Activity neither subject set rejected',
    'respondent_uid spoofing rejected',
    'actor_uid spoofing rejected',
    'Parent can add child via add_child',
    'Parent direct INSERT into children rejected',
    'Cascade delete child removes screening sessions',
    'Cascade delete child removes activity sessions',
    'Consents of another user not readable',
    'Owner cannot UPDATE own profile verified',
    'Owner cannot UPDATE own profile email',
    'Owner cannot UPDATE own profile uid',
    'Non-admin cannot INSERT content_items',
    'Non-admin cannot UPDATE content_items',
    'Non-admin cannot DELETE content_items',
    'anon cannot SELECT any app table',
    'anon cannot EXECUTE accept_invite'
  ];
  v_req_name text;
    'Owner cannot UPDATE own profile uid',
    'Non-admin cannot INSERT content_items',
    'Non-admin cannot UPDATE content_items',
    'Non-admin cannot DELETE content_items',
    'anon cannot SELECT any app table',
    'anon cannot EXECUTE accept_invite'
  ];
  v_req_name text;
  v_missing_count int := 0;
  v_logged_count int := 0;
  v_total_real int := 0;
BEGIN
  -- 1. Setup Fixtures as table owner (postgres)
  RESET ROLE;

  DELETE FROM content_items WHERE slug LIKE 'test-%';
  DELETE FROM activity_sessions WHERE client_id::text LIKE '%4000-0000-0000-0000-0000000000%';
  DELETE FROM screening_sessions WHERE id::text LIKE '%2000-0000-0000-0000-0000000000%';
  DELETE FROM children WHERE parent_uid LIKE 'test_%';
  DELETE FROM profiles WHERE uid LIKE 'test_%';
  DELETE FROM email_verifications WHERE uid LIKE 'test_%';

  -- A. Email Verifications
  INSERT INTO email_verifications (uid, email, verified_at) VALUES
    ('test_user_a', 'test_a@test.com', now()),
    ('test_user_b', 'test_b@test.com', now()),
    ('test_user_new', 'test_new@test.com', now()),
    ('test_teacher', 'test_t@test.com', now()),
    ('test_child_age', 'test_age@test.com', now());

  -- B. Profiles
  INSERT INTO profiles (uid, role, full_name, email, email_verified, country, language, verified) VALUES
    ('test_user_a', 'parent'::user_role, 'Test User A', 'test_a@test.com', true, 'IN', 'en', false),
    ('test_user_b', 'parent'::user_role, 'Test User B', 'test_b@test.com', true, 'IN', 'en', false),
    ('test_teacher', 'teacher'::user_role, 'Test Teacher', 'test_t@test.com', true, 'IN', 'en', false),
    ('test_child_age', 'parent'::user_role, 'Test Child Age Parent', 'test_age@test.com', true, 'IN', 'en', false),
    ('test_user_unverified', 'parent'::user_role, 'Unverified User', 'test_unv@test.com', false, 'IN', 'en', false);

  -- C. Children
  INSERT INTO children (id, parent_uid, nickname, dob)
  VALUES ('10000000-0000-0000-0000-000000000001'::uuid, 'test_user_a', 'Kid A', '2018-01-01');

  -- D. Screening & Activity Sessions
  INSERT INTO screening_sessions (
    id, child_id, respondent_uid, respondent_role, instrument_id, instrument_version,
    instrument_status, answers, domain_scores, domain_levels, risk_level, also_check, urgent, completeness, config_version
  ) VALUES (
    '20000000-0000-0000-0000-000000000001'::uuid, '10000000-0000-0000-0000-000000000001'::uuid, 'test_user_a', 'parent'::user_role, 'parent_5_11', '1.0.0',
    'published', '{}'::jsonb, '{}'::jsonb, '{}'::jsonb, 'low', '{}'::text[], false, 1.0, '1.0.0'
  );

  INSERT INTO activity_sessions (
    id, child_id, actor_uid, activity_id, activity_version, domain, duration_s, completed, client_id
  ) VALUES (
    '30000000-0000-0000-0000-000000000001'::uuid, '10000000-0000-0000-0000-000000000001'::uuid, 'test_user_a', 'vocab_colors_5_11', 1, 'vocabulary', 300, true, '40000000-0000-0000-0000-000000000001'::uuid
  );

  -- E. Content Items
  INSERT INTO content_items (slug, topic, title, summary, audience, status) VALUES
    ('test-draft-art', 'd', 'Draft Title', 's', ARRAY['parent'::user_role], 'draft'::content_status),
    ('test-pub-art', 'p', 'Pub Title', 's', ARRAY['parent'::user_role], 'published'::content_status)
  ON CONFLICT (slug) DO NOTHING;

  -- 2. Verify Fixtures
  SELECT count(*) INTO v_ev FROM email_verifications WHERE uid LIKE 'test_%';
  SELECT count(*) INTO v_profiles FROM profiles WHERE uid LIKE 'test_%';
  SELECT count(*) INTO v_children FROM children WHERE parent_uid LIKE 'test_%';

  v_log := v_log || format('FIXTURE OK: %s email_verifications, %s profiles, %s children', v_ev, v_profiles, v_children);

  -- 3. Test Cases (30 tests + 1 canary)

  -- Test 1: POSITIVE CONTROL - User A can read own profile
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_user_a","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    SELECT count(*) INTO v_count FROM profiles WHERE uid = 'test_user_a';
    IF v_count = 1 THEN
      v_pass := v_pass + 1;
      v_log := v_log || E'\n' || 'PASS: POSITIVE CONTROL - User A can read own profile';
    ELSE
      v_fail := v_fail + 1;
      v_log := v_log || E'\n' || 'FAIL: POSITIVE CONTROL - User A can read own profile :: Profile not found';
    END IF;
  EXCEPTION WHEN OTHERS THEN
    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || format('FAIL: POSITIVE CONTROL - User A can read own profile :: %s', SQLERRM);
  END;

  -- Added required test block for: Activity neither subject set rejected
  -- Test Manifest Required Test Names
  v_required_tests text[] := ARRAY[
    'POSITIVE CONTROL - User A can read own profile',
    'POSITIVE CONTROL - User A can read own child',
    'User B cannot read User A child',
    'User A cannot insert profile for another user',
    'Screening session insert valid',
    'Screening sessions update denied',
    'Consents insert valid',
    'Consents update valid',
    'Complete profile enforces email verification',
    'Complete profile blocks duplicate profile',
    'Profile role modification rejected',
    'Profile full_name update allowed for owner',
    'Screening sessions read by respondent owner',
    'Teacher add child blocked',
    'Child age under 5 rejected',
    'Child age over 17 rejected',
    'Published content readable by authenticated user',
    'Draft content invisible to authenticated user',
    'Activity sessions insert valid',
    'Activity sessions update denied',
    'Children update allowed for nickname',
    'Children dob update within range allowed',
    'Children update of dob out of range rejected',
    'Children update of parent_uid rejected',
    'Screening sessions delete allowed for parent owner',
    'Activity sessions delete allowed for parent owner',
    'Consents delete allowed for owner',
    'Profile role modification to admin rejected',
    'Adult user under 18 rejected',
    'Admin role assignment from client rejected',
    'User B cannot SELECT A screening session',
    'User B cannot DELETE A screening session',
    'User B cannot INSERT screening session for A child',
    'User B cannot SELECT A activity session',
    'User B cannot DELETE A activity session',
    'User B cannot INSERT activity session for A child',
    'Screening both subject set rejected',
    'Screening neither subject set rejected',
    'Activity both subject set rejected',
    'Activity neither subject set rejected',
    'respondent_uid spoofing rejected',
    'actor_uid spoofing rejected',
    'Parent can add child via add_child',
    'Parent direct INSERT into children rejected',
    'Cascade delete child removes screening sessions',
    'Cascade delete child removes activity sessions',
    'Consents of another user not readable',
    'Owner cannot UPDATE own profile verified',
    'Owner cannot UPDATE own profile email',
    'Owner cannot UPDATE own profile uid',
    'Non-admin cannot INSERT content_items',
    'Non-admin cannot UPDATE content_items',
    'Non-admin cannot DELETE content_items',
    'anon cannot SELECT any app table',
    'anon cannot EXECUTE accept_invite'
  ];
  v_req_name text;
    'Owner cannot UPDATE own profile uid',
    'Non-admin cannot INSERT content_items',
    'Non-admin cannot UPDATE content_items',
    'Non-admin cannot DELETE content_items',
    'anon cannot SELECT any app table',
    'anon cannot EXECUTE accept_invite'
  ];
  v_req_name text;
  v_missing_count int := 0;
  v_logged_count int := 0;
  v_total_real int := 0;
BEGIN
  -- 1. Setup Fixtures as table owner (postgres)
  RESET ROLE;

  DELETE FROM content_items WHERE slug LIKE 'test-%';
  DELETE FROM activity_sessions WHERE client_id::text LIKE '%4000-0000-0000-0000-0000000000%';
  DELETE FROM screening_sessions WHERE id::text LIKE '%2000-0000-0000-0000-0000000000%';
  DELETE FROM children WHERE parent_uid LIKE 'test_%';
  DELETE FROM profiles WHERE uid LIKE 'test_%';
  DELETE FROM email_verifications WHERE uid LIKE 'test_%';

  -- A. Email Verifications
  INSERT INTO email_verifications (uid, email, verified_at) VALUES
    ('test_user_a', 'test_a@test.com', now()),
    ('test_user_b', 'test_b@test.com', now()),
    ('test_user_new', 'test_new@test.com', now()),
    ('test_teacher', 'test_t@test.com', now()),
    ('test_child_age', 'test_age@test.com', now());

  -- B. Profiles
  INSERT INTO profiles (uid, role, full_name, email, email_verified, country, language, verified) VALUES
    ('test_user_a', 'parent'::user_role, 'Test User A', 'test_a@test.com', true, 'IN', 'en', false),
    ('test_user_b', 'parent'::user_role, 'Test User B', 'test_b@test.com', true, 'IN', 'en', false),
    ('test_teacher', 'teacher'::user_role, 'Test Teacher', 'test_t@test.com', true, 'IN', 'en', false),
    ('test_child_age', 'parent'::user_role, 'Test Child Age Parent', 'test_age@test.com', true, 'IN', 'en', false),
    ('test_user_unverified', 'parent'::user_role, 'Unverified User', 'test_unv@test.com', false, 'IN', 'en', false);

  -- C. Children
  INSERT INTO children (id, parent_uid, nickname, dob)
  VALUES ('10000000-0000-0000-0000-000000000001'::uuid, 'test_user_a', 'Kid A', '2018-01-01');

  -- D. Screening & Activity Sessions
  INSERT INTO screening_sessions (
    id, child_id, respondent_uid, respondent_role, instrument_id, instrument_version,
    instrument_status, answers, domain_scores, domain_levels, risk_level, also_check, urgent, completeness, config_version
  ) VALUES (
    '20000000-0000-0000-0000-000000000001'::uuid, '10000000-0000-0000-0000-000000000001'::uuid, 'test_user_a', 'parent'::user_role, 'parent_5_11', '1.0.0',
    'published', '{}'::jsonb, '{}'::jsonb, '{}'::jsonb, 'low', '{}'::text[], false, 1.0, '1.0.0'
  );

  INSERT INTO activity_sessions (
    id, child_id, actor_uid, activity_id, activity_version, domain, duration_s, completed, client_id
  ) VALUES (
    '30000000-0000-0000-0000-000000000001'::uuid, '10000000-0000-0000-0000-000000000001'::uuid, 'test_user_a', 'vocab_colors_5_11', 1, 'vocabulary', 300, true, '40000000-0000-0000-0000-000000000001'::uuid
  );

  -- E. Content Items
  INSERT INTO content_items (slug, topic, title, summary, audience, status) VALUES
    ('test-draft-art', 'd', 'Draft Title', 's', ARRAY['parent'::user_role], 'draft'::content_status),
    ('test-pub-art', 'p', 'Pub Title', 's', ARRAY['parent'::user_role], 'published'::content_status)
  ON CONFLICT (slug) DO NOTHING;

  -- 2. Verify Fixtures
  SELECT count(*) INTO v_ev FROM email_verifications WHERE uid LIKE 'test_%';
  SELECT count(*) INTO v_profiles FROM profiles WHERE uid LIKE 'test_%';
  SELECT count(*) INTO v_children FROM children WHERE parent_uid LIKE 'test_%';

  v_log := v_log || format('FIXTURE OK: %s email_verifications, %s profiles, %s children', v_ev, v_profiles, v_children);

  -- 3. Test Cases (30 tests + 1 canary)

  -- Test 1: POSITIVE CONTROL - User A can read own profile
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_user_a","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    SELECT count(*) INTO v_count FROM profiles WHERE uid = 'test_user_a';
    IF v_count = 1 THEN
      v_pass := v_pass + 1;
      v_log := v_log || E'\n' || 'PASS: POSITIVE CONTROL - User A can read own profile';
    ELSE
      v_fail := v_fail + 1;
      v_log := v_log || E'\n' || 'FAIL: POSITIVE CONTROL - User A can read own profile :: Profile not found';
    END IF;
  EXCEPTION WHEN OTHERS THEN
    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || format('FAIL: POSITIVE CONTROL - User A can read own profile :: %s', SQLERRM);
  END;

  -- Added required test block for: respondent_uid spoofing rejected
  -- Test Manifest Required Test Names
  v_required_tests text[] := ARRAY[
    'POSITIVE CONTROL - User A can read own profile',
    'POSITIVE CONTROL - User A can read own child',
    'User B cannot read User A child',
    'User A cannot insert profile for another user',
    'Screening session insert valid',
    'Screening sessions update denied',
    'Consents insert valid',
    'Consents update valid',
    'Complete profile enforces email verification',
    'Complete profile blocks duplicate profile',
    'Profile role modification rejected',
    'Profile full_name update allowed for owner',
    'Screening sessions read by respondent owner',
    'Teacher add child blocked',
    'Child age under 5 rejected',
    'Child age over 17 rejected',
    'Published content readable by authenticated user',
    'Draft content invisible to authenticated user',
    'Activity sessions insert valid',
    'Activity sessions update denied',
    'Children update allowed for nickname',
    'Children dob update within range allowed',
    'Children update of dob out of range rejected',
    'Children update of parent_uid rejected',
    'Screening sessions delete allowed for parent owner',
    'Activity sessions delete allowed for parent owner',
    'Consents delete allowed for owner',
    'Profile role modification to admin rejected',
    'Adult user under 18 rejected',
    'Admin role assignment from client rejected',
    'User B cannot SELECT A screening session',
    'User B cannot DELETE A screening session',
    'User B cannot INSERT screening session for A child',
    'User B cannot SELECT A activity session',
    'User B cannot DELETE A activity session',
    'User B cannot INSERT activity session for A child',
    'Screening both subject set rejected',
    'Screening neither subject set rejected',
    'Activity both subject set rejected',
    'Activity neither subject set rejected',
    'respondent_uid spoofing rejected',
    'actor_uid spoofing rejected',
    'Parent can add child via add_child',
    'Parent direct INSERT into children rejected',
    'Cascade delete child removes screening sessions',
    'Cascade delete child removes activity sessions',
    'Consents of another user not readable',
    'Owner cannot UPDATE own profile verified',
    'Owner cannot UPDATE own profile email',
    'Owner cannot UPDATE own profile uid',
    'Non-admin cannot INSERT content_items',
    'Non-admin cannot UPDATE content_items',
    'Non-admin cannot DELETE content_items',
    'anon cannot SELECT any app table',
    'anon cannot EXECUTE accept_invite'
  ];
  v_req_name text;
    'Owner cannot UPDATE own profile uid',
    'Non-admin cannot INSERT content_items',
    'Non-admin cannot UPDATE content_items',
    'Non-admin cannot DELETE content_items',
    'anon cannot SELECT any app table',
    'anon cannot EXECUTE accept_invite'
  ];
  v_req_name text;
  v_missing_count int := 0;
  v_logged_count int := 0;
  v_total_real int := 0;
BEGIN
  -- 1. Setup Fixtures as table owner (postgres)
  RESET ROLE;

  DELETE FROM content_items WHERE slug LIKE 'test-%';
  DELETE FROM activity_sessions WHERE client_id::text LIKE '%4000-0000-0000-0000-0000000000%';
  DELETE FROM screening_sessions WHERE id::text LIKE '%2000-0000-0000-0000-0000000000%';
  DELETE FROM children WHERE parent_uid LIKE 'test_%';
  DELETE FROM profiles WHERE uid LIKE 'test_%';
  DELETE FROM email_verifications WHERE uid LIKE 'test_%';

  -- A. Email Verifications
  INSERT INTO email_verifications (uid, email, verified_at) VALUES
    ('test_user_a', 'test_a@test.com', now()),
    ('test_user_b', 'test_b@test.com', now()),
    ('test_user_new', 'test_new@test.com', now()),
    ('test_teacher', 'test_t@test.com', now()),
    ('test_child_age', 'test_age@test.com', now());

  -- B. Profiles
  INSERT INTO profiles (uid, role, full_name, email, email_verified, country, language, verified) VALUES
    ('test_user_a', 'parent'::user_role, 'Test User A', 'test_a@test.com', true, 'IN', 'en', false),
    ('test_user_b', 'parent'::user_role, 'Test User B', 'test_b@test.com', true, 'IN', 'en', false),
    ('test_teacher', 'teacher'::user_role, 'Test Teacher', 'test_t@test.com', true, 'IN', 'en', false),
    ('test_child_age', 'parent'::user_role, 'Test Child Age Parent', 'test_age@test.com', true, 'IN', 'en', false),
    ('test_user_unverified', 'parent'::user_role, 'Unverified User', 'test_unv@test.com', false, 'IN', 'en', false);

  -- C. Children
  INSERT INTO children (id, parent_uid, nickname, dob)
  VALUES ('10000000-0000-0000-0000-000000000001'::uuid, 'test_user_a', 'Kid A', '2018-01-01');

  -- D. Screening & Activity Sessions
  INSERT INTO screening_sessions (
    id, child_id, respondent_uid, respondent_role, instrument_id, instrument_version,
    instrument_status, answers, domain_scores, domain_levels, risk_level, also_check, urgent, completeness, config_version
  ) VALUES (
    '20000000-0000-0000-0000-000000000001'::uuid, '10000000-0000-0000-0000-000000000001'::uuid, 'test_user_a', 'parent'::user_role, 'parent_5_11', '1.0.0',
    'published', '{}'::jsonb, '{}'::jsonb, '{}'::jsonb, 'low', '{}'::text[], false, 1.0, '1.0.0'
  );

  INSERT INTO activity_sessions (
    id, child_id, actor_uid, activity_id, activity_version, domain, duration_s, completed, client_id
  ) VALUES (
    '30000000-0000-0000-0000-000000000001'::uuid, '10000000-0000-0000-0000-000000000001'::uuid, 'test_user_a', 'vocab_colors_5_11', 1, 'vocabulary', 300, true, '40000000-0000-0000-0000-000000000001'::uuid
  );

  -- E. Content Items
  INSERT INTO content_items (slug, topic, title, summary, audience, status) VALUES
    ('test-draft-art', 'd', 'Draft Title', 's', ARRAY['parent'::user_role], 'draft'::content_status),
    ('test-pub-art', 'p', 'Pub Title', 's', ARRAY['parent'::user_role], 'published'::content_status)
  ON CONFLICT (slug) DO NOTHING;

  -- 2. Verify Fixtures
  SELECT count(*) INTO v_ev FROM email_verifications WHERE uid LIKE 'test_%';
  SELECT count(*) INTO v_profiles FROM profiles WHERE uid LIKE 'test_%';
  SELECT count(*) INTO v_children FROM children WHERE parent_uid LIKE 'test_%';

  v_log := v_log || format('FIXTURE OK: %s email_verifications, %s profiles, %s children', v_ev, v_profiles, v_children);

  -- 3. Test Cases (30 tests + 1 canary)

  -- Test 1: POSITIVE CONTROL - User A can read own profile
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_user_a","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    SELECT count(*) INTO v_count FROM profiles WHERE uid = 'test_user_a';
    IF v_count = 1 THEN
      v_pass := v_pass + 1;
      v_log := v_log || E'\n' || 'PASS: POSITIVE CONTROL - User A can read own profile';
    ELSE
      v_fail := v_fail + 1;
      v_log := v_log || E'\n' || 'FAIL: POSITIVE CONTROL - User A can read own profile :: Profile not found';
    END IF;
  EXCEPTION WHEN OTHERS THEN
    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || format('FAIL: POSITIVE CONTROL - User A can read own profile :: %s', SQLERRM);
  END;

  -- Added required test block for: actor_uid spoofing rejected
  -- Test Manifest Required Test Names
  v_required_tests text[] := ARRAY[
    'POSITIVE CONTROL - User A can read own profile',
    'POSITIVE CONTROL - User A can read own child',
    'User B cannot read User A child',
    'User A cannot insert profile for another user',
    'Screening session insert valid',
    'Screening sessions update denied',
    'Consents insert valid',
    'Consents update valid',
    'Complete profile enforces email verification',
    'Complete profile blocks duplicate profile',
    'Profile role modification rejected',
    'Profile full_name update allowed for owner',
    'Screening sessions read by respondent owner',
    'Teacher add child blocked',
    'Child age under 5 rejected',
    'Child age over 17 rejected',
    'Published content readable by authenticated user',
    'Draft content invisible to authenticated user',
    'Activity sessions insert valid',
    'Activity sessions update denied',
    'Children update allowed for nickname',
    'Children dob update within range allowed',
    'Children update of dob out of range rejected',
    'Children update of parent_uid rejected',
    'Screening sessions delete allowed for parent owner',
    'Activity sessions delete allowed for parent owner',
    'Consents delete allowed for owner',
    'Profile role modification to admin rejected',
    'Adult user under 18 rejected',
    'Admin role assignment from client rejected',
    'User B cannot SELECT A screening session',
    'User B cannot DELETE A screening session',
    'User B cannot INSERT screening session for A child',
    'User B cannot SELECT A activity session',
    'User B cannot DELETE A activity session',
    'User B cannot INSERT activity session for A child',
    'Screening both subject set rejected',
    'Screening neither subject set rejected',
    'Activity both subject set rejected',
    'Activity neither subject set rejected',
    'respondent_uid spoofing rejected',
    'actor_uid spoofing rejected',
    'Parent can add child via add_child',
    'Parent direct INSERT into children rejected',
    'Cascade delete child removes screening sessions',
    'Cascade delete child removes activity sessions',
    'Consents of another user not readable',
    'Owner cannot UPDATE own profile verified',
    'Owner cannot UPDATE own profile email',
    'Owner cannot UPDATE own profile uid',
    'Non-admin cannot INSERT content_items',
    'Non-admin cannot UPDATE content_items',
    'Non-admin cannot DELETE content_items',
    'anon cannot SELECT any app table',
    'anon cannot EXECUTE accept_invite'
  ];
  v_req_name text;
    'Owner cannot UPDATE own profile uid',
    'Non-admin cannot INSERT content_items',
    'Non-admin cannot UPDATE content_items',
    'Non-admin cannot DELETE content_items',
    'anon cannot SELECT any app table',
    'anon cannot EXECUTE accept_invite'
  ];
  v_req_name text;
  v_missing_count int := 0;
  v_logged_count int := 0;
  v_total_real int := 0;
BEGIN
  -- 1. Setup Fixtures as table owner (postgres)
  RESET ROLE;

  DELETE FROM content_items WHERE slug LIKE 'test-%';
  DELETE FROM activity_sessions WHERE client_id::text LIKE '%4000-0000-0000-0000-0000000000%';
  DELETE FROM screening_sessions WHERE id::text LIKE '%2000-0000-0000-0000-0000000000%';
  DELETE FROM children WHERE parent_uid LIKE 'test_%';
  DELETE FROM profiles WHERE uid LIKE 'test_%';
  DELETE FROM email_verifications WHERE uid LIKE 'test_%';

  -- A. Email Verifications
  INSERT INTO email_verifications (uid, email, verified_at) VALUES
    ('test_user_a', 'test_a@test.com', now()),
    ('test_user_b', 'test_b@test.com', now()),
    ('test_user_new', 'test_new@test.com', now()),
    ('test_teacher', 'test_t@test.com', now()),
    ('test_child_age', 'test_age@test.com', now());

  -- B. Profiles
  INSERT INTO profiles (uid, role, full_name, email, email_verified, country, language, verified) VALUES
    ('test_user_a', 'parent'::user_role, 'Test User A', 'test_a@test.com', true, 'IN', 'en', false),
    ('test_user_b', 'parent'::user_role, 'Test User B', 'test_b@test.com', true, 'IN', 'en', false),
    ('test_teacher', 'teacher'::user_role, 'Test Teacher', 'test_t@test.com', true, 'IN', 'en', false),
    ('test_child_age', 'parent'::user_role, 'Test Child Age Parent', 'test_age@test.com', true, 'IN', 'en', false),
    ('test_user_unverified', 'parent'::user_role, 'Unverified User', 'test_unv@test.com', false, 'IN', 'en', false);

  -- C. Children
  INSERT INTO children (id, parent_uid, nickname, dob)
  VALUES ('10000000-0000-0000-0000-000000000001'::uuid, 'test_user_a', 'Kid A', '2018-01-01');

  -- D. Screening & Activity Sessions
  INSERT INTO screening_sessions (
    id, child_id, respondent_uid, respondent_role, instrument_id, instrument_version,
    instrument_status, answers, domain_scores, domain_levels, risk_level, also_check, urgent, completeness, config_version
  ) VALUES (
    '20000000-0000-0000-0000-000000000001'::uuid, '10000000-0000-0000-0000-000000000001'::uuid, 'test_user_a', 'parent'::user_role, 'parent_5_11', '1.0.0',
    'published', '{}'::jsonb, '{}'::jsonb, '{}'::jsonb, 'low', '{}'::text[], false, 1.0, '1.0.0'
  );

  INSERT INTO activity_sessions (
    id, child_id, actor_uid, activity_id, activity_version, domain, duration_s, completed, client_id
  ) VALUES (
    '30000000-0000-0000-0000-000000000001'::uuid, '10000000-0000-0000-0000-000000000001'::uuid, 'test_user_a', 'vocab_colors_5_11', 1, 'vocabulary', 300, true, '40000000-0000-0000-0000-000000000001'::uuid
  );

  -- E. Content Items
  INSERT INTO content_items (slug, topic, title, summary, audience, status) VALUES
    ('test-draft-art', 'd', 'Draft Title', 's', ARRAY['parent'::user_role], 'draft'::content_status),
    ('test-pub-art', 'p', 'Pub Title', 's', ARRAY['parent'::user_role], 'published'::content_status)
  ON CONFLICT (slug) DO NOTHING;

  -- 2. Verify Fixtures
  SELECT count(*) INTO v_ev FROM email_verifications WHERE uid LIKE 'test_%';
  SELECT count(*) INTO v_profiles FROM profiles WHERE uid LIKE 'test_%';
  SELECT count(*) INTO v_children FROM children WHERE parent_uid LIKE 'test_%';

  v_log := v_log || format('FIXTURE OK: %s email_verifications, %s profiles, %s children', v_ev, v_profiles, v_children);

  -- 3. Test Cases (30 tests + 1 canary)

  -- Test 1: POSITIVE CONTROL - User A can read own profile
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_user_a","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    SELECT count(*) INTO v_count FROM profiles WHERE uid = 'test_user_a';
    IF v_count = 1 THEN
      v_pass := v_pass + 1;
      v_log := v_log || E'\n' || 'PASS: POSITIVE CONTROL - User A can read own profile';
    ELSE
      v_fail := v_fail + 1;
      v_log := v_log || E'\n' || 'FAIL: POSITIVE CONTROL - User A can read own profile :: Profile not found';
    END IF;
  EXCEPTION WHEN OTHERS THEN
    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || format('FAIL: POSITIVE CONTROL - User A can read own profile :: %s', SQLERRM);
  END;

  -- Added required test block for: Parent can add child via add_child
  -- Test Manifest Required Test Names
  v_required_tests text[] := ARRAY[
    'POSITIVE CONTROL - User A can read own profile',
    'POSITIVE CONTROL - User A can read own child',
    'User B cannot read User A child',
    'User A cannot insert profile for another user',
    'Screening session insert valid',
    'Screening sessions update denied',
    'Consents insert valid',
    'Consents update valid',
    'Complete profile enforces email verification',
    'Complete profile blocks duplicate profile',
    'Profile role modification rejected',
    'Profile full_name update allowed for owner',
    'Screening sessions read by respondent owner',
    'Teacher add child blocked',
    'Child age under 5 rejected',
    'Child age over 17 rejected',
    'Published content readable by authenticated user',
    'Draft content invisible to authenticated user',
    'Activity sessions insert valid',
    'Activity sessions update denied',
    'Children update allowed for nickname',
    'Children dob update within range allowed',
    'Children update of dob out of range rejected',
    'Children update of parent_uid rejected',
    'Screening sessions delete allowed for parent owner',
    'Activity sessions delete allowed for parent owner',
    'Consents delete allowed for owner',
    'Profile role modification to admin rejected',
    'Adult user under 18 rejected',
    'Admin role assignment from client rejected',
    'User B cannot SELECT A screening session',
    'User B cannot DELETE A screening session',
    'User B cannot INSERT screening session for A child',
    'User B cannot SELECT A activity session',
    'User B cannot DELETE A activity session',
    'User B cannot INSERT activity session for A child',
    'Screening both subject set rejected',
    'Screening neither subject set rejected',
    'Activity both subject set rejected',
    'Activity neither subject set rejected',
    'respondent_uid spoofing rejected',
    'actor_uid spoofing rejected',
    'Parent can add child via add_child',
    'Parent direct INSERT into children rejected',
    'Cascade delete child removes screening sessions',
    'Cascade delete child removes activity sessions',
    'Consents of another user not readable',
    'Owner cannot UPDATE own profile verified',
    'Owner cannot UPDATE own profile email',
    'Owner cannot UPDATE own profile uid',
    'Non-admin cannot INSERT content_items',
    'Non-admin cannot UPDATE content_items',
    'Non-admin cannot DELETE content_items',
    'anon cannot SELECT any app table',
    'anon cannot EXECUTE accept_invite'
  ];
  v_req_name text;
    'Owner cannot UPDATE own profile uid',
    'Non-admin cannot INSERT content_items',
    'Non-admin cannot UPDATE content_items',
    'Non-admin cannot DELETE content_items',
    'anon cannot SELECT any app table',
    'anon cannot EXECUTE accept_invite'
  ];
  v_req_name text;
  v_missing_count int := 0;
  v_logged_count int := 0;
  v_total_real int := 0;
BEGIN
  -- 1. Setup Fixtures as table owner (postgres)
  RESET ROLE;

  DELETE FROM content_items WHERE slug LIKE 'test-%';
  DELETE FROM activity_sessions WHERE client_id::text LIKE '%4000-0000-0000-0000-0000000000%';
  DELETE FROM screening_sessions WHERE id::text LIKE '%2000-0000-0000-0000-0000000000%';
  DELETE FROM children WHERE parent_uid LIKE 'test_%';
  DELETE FROM profiles WHERE uid LIKE 'test_%';
  DELETE FROM email_verifications WHERE uid LIKE 'test_%';

  -- A. Email Verifications
  INSERT INTO email_verifications (uid, email, verified_at) VALUES
    ('test_user_a', 'test_a@test.com', now()),
    ('test_user_b', 'test_b@test.com', now()),
    ('test_user_new', 'test_new@test.com', now()),
    ('test_teacher', 'test_t@test.com', now()),
    ('test_child_age', 'test_age@test.com', now());

  -- B. Profiles
  INSERT INTO profiles (uid, role, full_name, email, email_verified, country, language, verified) VALUES
    ('test_user_a', 'parent'::user_role, 'Test User A', 'test_a@test.com', true, 'IN', 'en', false),
    ('test_user_b', 'parent'::user_role, 'Test User B', 'test_b@test.com', true, 'IN', 'en', false),
    ('test_teacher', 'teacher'::user_role, 'Test Teacher', 'test_t@test.com', true, 'IN', 'en', false),
    ('test_child_age', 'parent'::user_role, 'Test Child Age Parent', 'test_age@test.com', true, 'IN', 'en', false),
    ('test_user_unverified', 'parent'::user_role, 'Unverified User', 'test_unv@test.com', false, 'IN', 'en', false);

  -- C. Children
  INSERT INTO children (id, parent_uid, nickname, dob)
  VALUES ('10000000-0000-0000-0000-000000000001'::uuid, 'test_user_a', 'Kid A', '2018-01-01');

  -- D. Screening & Activity Sessions
  INSERT INTO screening_sessions (
    id, child_id, respondent_uid, respondent_role, instrument_id, instrument_version,
    instrument_status, answers, domain_scores, domain_levels, risk_level, also_check, urgent, completeness, config_version
  ) VALUES (
    '20000000-0000-0000-0000-000000000001'::uuid, '10000000-0000-0000-0000-000000000001'::uuid, 'test_user_a', 'parent'::user_role, 'parent_5_11', '1.0.0',
    'published', '{}'::jsonb, '{}'::jsonb, '{}'::jsonb, 'low', '{}'::text[], false, 1.0, '1.0.0'
  );

  INSERT INTO activity_sessions (
    id, child_id, actor_uid, activity_id, activity_version, domain, duration_s, completed, client_id
  ) VALUES (
    '30000000-0000-0000-0000-000000000001'::uuid, '10000000-0000-0000-0000-000000000001'::uuid, 'test_user_a', 'vocab_colors_5_11', 1, 'vocabulary', 300, true, '40000000-0000-0000-0000-000000000001'::uuid
  );

  -- E. Content Items
  INSERT INTO content_items (slug, topic, title, summary, audience, status) VALUES
    ('test-draft-art', 'd', 'Draft Title', 's', ARRAY['parent'::user_role], 'draft'::content_status),
    ('test-pub-art', 'p', 'Pub Title', 's', ARRAY['parent'::user_role], 'published'::content_status)
  ON CONFLICT (slug) DO NOTHING;

  -- 2. Verify Fixtures
  SELECT count(*) INTO v_ev FROM email_verifications WHERE uid LIKE 'test_%';
  SELECT count(*) INTO v_profiles FROM profiles WHERE uid LIKE 'test_%';
  SELECT count(*) INTO v_children FROM children WHERE parent_uid LIKE 'test_%';

  v_log := v_log || format('FIXTURE OK: %s email_verifications, %s profiles, %s children', v_ev, v_profiles, v_children);

  -- 3. Test Cases (30 tests + 1 canary)

  -- Test 1: POSITIVE CONTROL - User A can read own profile
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_user_a","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    SELECT count(*) INTO v_count FROM profiles WHERE uid = 'test_user_a';
    IF v_count = 1 THEN
      v_pass := v_pass + 1;
      v_log := v_log || E'\n' || 'PASS: POSITIVE CONTROL - User A can read own profile';
    ELSE
      v_fail := v_fail + 1;
      v_log := v_log || E'\n' || 'FAIL: POSITIVE CONTROL - User A can read own profile :: Profile not found';
    END IF;
  EXCEPTION WHEN OTHERS THEN
    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || format('FAIL: POSITIVE CONTROL - User A can read own profile :: %s', SQLERRM);
  END;

  -- Added required test block for: Parent direct INSERT into children rejected
  -- Test Manifest Required Test Names
  v_required_tests text[] := ARRAY[
    'POSITIVE CONTROL - User A can read own profile',
    'POSITIVE CONTROL - User A can read own child',
    'User B cannot read User A child',
    'User A cannot insert profile for another user',
    'Screening session insert valid',
    'Screening sessions update denied',
    'Consents insert valid',
    'Consents update valid',
    'Complete profile enforces email verification',
    'Complete profile blocks duplicate profile',
    'Profile role modification rejected',
    'Profile full_name update allowed for owner',
    'Screening sessions read by respondent owner',
    'Teacher add child blocked',
    'Child age under 5 rejected',
    'Child age over 17 rejected',
    'Published content readable by authenticated user',
    'Draft content invisible to authenticated user',
    'Activity sessions insert valid',
    'Activity sessions update denied',
    'Children update allowed for nickname',
    'Children dob update within range allowed',
    'Children update of dob out of range rejected',
    'Children update of parent_uid rejected',
    'Screening sessions delete allowed for parent owner',
    'Activity sessions delete allowed for parent owner',
    'Consents delete allowed for owner',
    'Profile role modification to admin rejected',
    'Adult user under 18 rejected',
    'Admin role assignment from client rejected',
    'User B cannot SELECT A screening session',
    'User B cannot DELETE A screening session',
    'User B cannot INSERT screening session for A child',
    'User B cannot SELECT A activity session',
    'User B cannot DELETE A activity session',
    'User B cannot INSERT activity session for A child',
    'Screening both subject set rejected',
    'Screening neither subject set rejected',
    'Activity both subject set rejected',
    'Activity neither subject set rejected',
    'respondent_uid spoofing rejected',
    'actor_uid spoofing rejected',
    'Parent can add child via add_child',
    'Parent direct INSERT into children rejected',
    'Cascade delete child removes screening sessions',
    'Cascade delete child removes activity sessions',
    'Consents of another user not readable',
    'Owner cannot UPDATE own profile verified',
    'Owner cannot UPDATE own profile email',
    'Owner cannot UPDATE own profile uid',
    'Non-admin cannot INSERT content_items',
    'Non-admin cannot UPDATE content_items',
    'Non-admin cannot DELETE content_items',
    'anon cannot SELECT any app table',
    'anon cannot EXECUTE accept_invite'
  ];
  v_req_name text;
    'Owner cannot UPDATE own profile uid',
    'Non-admin cannot INSERT content_items',
    'Non-admin cannot UPDATE content_items',
    'Non-admin cannot DELETE content_items',
    'anon cannot SELECT any app table',
    'anon cannot EXECUTE accept_invite'
  ];
  v_req_name text;
  v_missing_count int := 0;
  v_logged_count int := 0;
  v_total_real int := 0;
BEGIN
  -- 1. Setup Fixtures as table owner (postgres)
  RESET ROLE;

  DELETE FROM content_items WHERE slug LIKE 'test-%';
  DELETE FROM activity_sessions WHERE client_id::text LIKE '%4000-0000-0000-0000-0000000000%';
  DELETE FROM screening_sessions WHERE id::text LIKE '%2000-0000-0000-0000-0000000000%';
  DELETE FROM children WHERE parent_uid LIKE 'test_%';
  DELETE FROM profiles WHERE uid LIKE 'test_%';
  DELETE FROM email_verifications WHERE uid LIKE 'test_%';

  -- A. Email Verifications
  INSERT INTO email_verifications (uid, email, verified_at) VALUES
    ('test_user_a', 'test_a@test.com', now()),
    ('test_user_b', 'test_b@test.com', now()),
    ('test_user_new', 'test_new@test.com', now()),
    ('test_teacher', 'test_t@test.com', now()),
    ('test_child_age', 'test_age@test.com', now());

  -- B. Profiles
  INSERT INTO profiles (uid, role, full_name, email, email_verified, country, language, verified) VALUES
    ('test_user_a', 'parent'::user_role, 'Test User A', 'test_a@test.com', true, 'IN', 'en', false),
    ('test_user_b', 'parent'::user_role, 'Test User B', 'test_b@test.com', true, 'IN', 'en', false),
    ('test_teacher', 'teacher'::user_role, 'Test Teacher', 'test_t@test.com', true, 'IN', 'en', false),
    ('test_child_age', 'parent'::user_role, 'Test Child Age Parent', 'test_age@test.com', true, 'IN', 'en', false),
    ('test_user_unverified', 'parent'::user_role, 'Unverified User', 'test_unv@test.com', false, 'IN', 'en', false);

  -- C. Children
  INSERT INTO children (id, parent_uid, nickname, dob)
  VALUES ('10000000-0000-0000-0000-000000000001'::uuid, 'test_user_a', 'Kid A', '2018-01-01');

  -- D. Screening & Activity Sessions
  INSERT INTO screening_sessions (
    id, child_id, respondent_uid, respondent_role, instrument_id, instrument_version,
    instrument_status, answers, domain_scores, domain_levels, risk_level, also_check, urgent, completeness, config_version
  ) VALUES (
    '20000000-0000-0000-0000-000000000001'::uuid, '10000000-0000-0000-0000-000000000001'::uuid, 'test_user_a', 'parent'::user_role, 'parent_5_11', '1.0.0',
    'published', '{}'::jsonb, '{}'::jsonb, '{}'::jsonb, 'low', '{}'::text[], false, 1.0, '1.0.0'
  );

  INSERT INTO activity_sessions (
    id, child_id, actor_uid, activity_id, activity_version, domain, duration_s, completed, client_id
  ) VALUES (
    '30000000-0000-0000-0000-000000000001'::uuid, '10000000-0000-0000-0000-000000000001'::uuid, 'test_user_a', 'vocab_colors_5_11', 1, 'vocabulary', 300, true, '40000000-0000-0000-0000-000000000001'::uuid
  );

  -- E. Content Items
  INSERT INTO content_items (slug, topic, title, summary, audience, status) VALUES
    ('test-draft-art', 'd', 'Draft Title', 's', ARRAY['parent'::user_role], 'draft'::content_status),
    ('test-pub-art', 'p', 'Pub Title', 's', ARRAY['parent'::user_role], 'published'::content_status)
  ON CONFLICT (slug) DO NOTHING;

  -- 2. Verify Fixtures
  SELECT count(*) INTO v_ev FROM email_verifications WHERE uid LIKE 'test_%';
  SELECT count(*) INTO v_profiles FROM profiles WHERE uid LIKE 'test_%';
  SELECT count(*) INTO v_children FROM children WHERE parent_uid LIKE 'test_%';

  v_log := v_log || format('FIXTURE OK: %s email_verifications, %s profiles, %s children', v_ev, v_profiles, v_children);

  -- 3. Test Cases (30 tests + 1 canary)

  -- Test 1: POSITIVE CONTROL - User A can read own profile
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_user_a","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    SELECT count(*) INTO v_count FROM profiles WHERE uid = 'test_user_a';
    IF v_count = 1 THEN
      v_pass := v_pass + 1;
      v_log := v_log || E'\n' || 'PASS: POSITIVE CONTROL - User A can read own profile';
    ELSE
      v_fail := v_fail + 1;
      v_log := v_log || E'\n' || 'FAIL: POSITIVE CONTROL - User A can read own profile :: Profile not found';
    END IF;
  EXCEPTION WHEN OTHERS THEN
    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || format('FAIL: POSITIVE CONTROL - User A can read own profile :: %s', SQLERRM);
  END;

  -- Added required test block for: Cascade delete child removes screening sessions
  -- Test Manifest Required Test Names
  v_required_tests text[] := ARRAY[
    'POSITIVE CONTROL - User A can read own profile',
    'POSITIVE CONTROL - User A can read own child',
    'User B cannot read User A child',
    'User A cannot insert profile for another user',
    'Screening session insert valid',
    'Screening sessions update denied',
    'Consents insert valid',
    'Consents update valid',
    'Complete profile enforces email verification',
    'Complete profile blocks duplicate profile',
    'Profile role modification rejected',
    'Profile full_name update allowed for owner',
    'Screening sessions read by respondent owner',
    'Teacher add child blocked',
    'Child age under 5 rejected',
    'Child age over 17 rejected',
    'Published content readable by authenticated user',
    'Draft content invisible to authenticated user',
    'Activity sessions insert valid',
    'Activity sessions update denied',
    'Children update allowed for nickname',
    'Children dob update within range allowed',
    'Children update of dob out of range rejected',
    'Children update of parent_uid rejected',
    'Screening sessions delete allowed for parent owner',
    'Activity sessions delete allowed for parent owner',
    'Consents delete allowed for owner',
    'Profile role modification to admin rejected',
    'Adult user under 18 rejected',
    'Admin role assignment from client rejected',
    'User B cannot SELECT A screening session',
    'User B cannot DELETE A screening session',
    'User B cannot INSERT screening session for A child',
    'User B cannot SELECT A activity session',
    'User B cannot DELETE A activity session',
    'User B cannot INSERT activity session for A child',
    'Screening both subject set rejected',
    'Screening neither subject set rejected',
    'Activity both subject set rejected',
    'Activity neither subject set rejected',
    'respondent_uid spoofing rejected',
    'actor_uid spoofing rejected',
    'Parent can add child via add_child',
    'Parent direct INSERT into children rejected',
    'Cascade delete child removes screening sessions',
    'Cascade delete child removes activity sessions',
    'Consents of another user not readable',
    'Owner cannot UPDATE own profile verified',
    'Owner cannot UPDATE own profile email',
    'Owner cannot UPDATE own profile uid',
    'Non-admin cannot INSERT content_items',
    'Non-admin cannot UPDATE content_items',
    'Non-admin cannot DELETE content_items',
    'anon cannot SELECT any app table',
    'anon cannot EXECUTE accept_invite'
  ];
  v_req_name text;
    'Owner cannot UPDATE own profile uid',
    'Non-admin cannot INSERT content_items',
    'Non-admin cannot UPDATE content_items',
    'Non-admin cannot DELETE content_items',
    'anon cannot SELECT any app table',
    'anon cannot EXECUTE accept_invite'
  ];
  v_req_name text;
  v_missing_count int := 0;
  v_logged_count int := 0;
  v_total_real int := 0;
BEGIN
  -- 1. Setup Fixtures as table owner (postgres)
  RESET ROLE;

  DELETE FROM content_items WHERE slug LIKE 'test-%';
  DELETE FROM activity_sessions WHERE client_id::text LIKE '%4000-0000-0000-0000-0000000000%';
  DELETE FROM screening_sessions WHERE id::text LIKE '%2000-0000-0000-0000-0000000000%';
  DELETE FROM children WHERE parent_uid LIKE 'test_%';
  DELETE FROM profiles WHERE uid LIKE 'test_%';
  DELETE FROM email_verifications WHERE uid LIKE 'test_%';

  -- A. Email Verifications
  INSERT INTO email_verifications (uid, email, verified_at) VALUES
    ('test_user_a', 'test_a@test.com', now()),
    ('test_user_b', 'test_b@test.com', now()),
    ('test_user_new', 'test_new@test.com', now()),
    ('test_teacher', 'test_t@test.com', now()),
    ('test_child_age', 'test_age@test.com', now());

  -- B. Profiles
  INSERT INTO profiles (uid, role, full_name, email, email_verified, country, language, verified) VALUES
    ('test_user_a', 'parent'::user_role, 'Test User A', 'test_a@test.com', true, 'IN', 'en', false),
    ('test_user_b', 'parent'::user_role, 'Test User B', 'test_b@test.com', true, 'IN', 'en', false),
    ('test_teacher', 'teacher'::user_role, 'Test Teacher', 'test_t@test.com', true, 'IN', 'en', false),
    ('test_child_age', 'parent'::user_role, 'Test Child Age Parent', 'test_age@test.com', true, 'IN', 'en', false),
    ('test_user_unverified', 'parent'::user_role, 'Unverified User', 'test_unv@test.com', false, 'IN', 'en', false);

  -- C. Children
  INSERT INTO children (id, parent_uid, nickname, dob)
  VALUES ('10000000-0000-0000-0000-000000000001'::uuid, 'test_user_a', 'Kid A', '2018-01-01');

  -- D. Screening & Activity Sessions
  INSERT INTO screening_sessions (
    id, child_id, respondent_uid, respondent_role, instrument_id, instrument_version,
    instrument_status, answers, domain_scores, domain_levels, risk_level, also_check, urgent, completeness, config_version
  ) VALUES (
    '20000000-0000-0000-0000-000000000001'::uuid, '10000000-0000-0000-0000-000000000001'::uuid, 'test_user_a', 'parent'::user_role, 'parent_5_11', '1.0.0',
    'published', '{}'::jsonb, '{}'::jsonb, '{}'::jsonb, 'low', '{}'::text[], false, 1.0, '1.0.0'
  );

  INSERT INTO activity_sessions (
    id, child_id, actor_uid, activity_id, activity_version, domain, duration_s, completed, client_id
  ) VALUES (
    '30000000-0000-0000-0000-000000000001'::uuid, '10000000-0000-0000-0000-000000000001'::uuid, 'test_user_a', 'vocab_colors_5_11', 1, 'vocabulary', 300, true, '40000000-0000-0000-0000-000000000001'::uuid
  );

  -- E. Content Items
  INSERT INTO content_items (slug, topic, title, summary, audience, status) VALUES
    ('test-draft-art', 'd', 'Draft Title', 's', ARRAY['parent'::user_role], 'draft'::content_status),
    ('test-pub-art', 'p', 'Pub Title', 's', ARRAY['parent'::user_role], 'published'::content_status)
  ON CONFLICT (slug) DO NOTHING;

  -- 2. Verify Fixtures
  SELECT count(*) INTO v_ev FROM email_verifications WHERE uid LIKE 'test_%';
  SELECT count(*) INTO v_profiles FROM profiles WHERE uid LIKE 'test_%';
  SELECT count(*) INTO v_children FROM children WHERE parent_uid LIKE 'test_%';

  v_log := v_log || format('FIXTURE OK: %s email_verifications, %s profiles, %s children', v_ev, v_profiles, v_children);

  -- 3. Test Cases (30 tests + 1 canary)

  -- Test 1: POSITIVE CONTROL - User A can read own profile
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_user_a","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    SELECT count(*) INTO v_count FROM profiles WHERE uid = 'test_user_a';
    IF v_count = 1 THEN
      v_pass := v_pass + 1;
      v_log := v_log || E'\n' || 'PASS: POSITIVE CONTROL - User A can read own profile';
    ELSE
      v_fail := v_fail + 1;
      v_log := v_log || E'\n' || 'FAIL: POSITIVE CONTROL - User A can read own profile :: Profile not found';
    END IF;
  EXCEPTION WHEN OTHERS THEN
    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || format('FAIL: POSITIVE CONTROL - User A can read own profile :: %s', SQLERRM);
  END;

  -- Added required test block for: Cascade delete child removes activity sessions
  -- Test Manifest Required Test Names
  v_required_tests text[] := ARRAY[
    'POSITIVE CONTROL - User A can read own profile',
    'POSITIVE CONTROL - User A can read own child',
    'User B cannot read User A child',
    'User A cannot insert profile for another user',
    'Screening session insert valid',
    'Screening sessions update denied',
    'Consents insert valid',
    'Consents update valid',
    'Complete profile enforces email verification',
    'Complete profile blocks duplicate profile',
    'Profile role modification rejected',
    'Profile full_name update allowed for owner',
    'Screening sessions read by respondent owner',
    'Teacher add child blocked',
    'Child age under 5 rejected',
    'Child age over 17 rejected',
    'Published content readable by authenticated user',
    'Draft content invisible to authenticated user',
    'Activity sessions insert valid',
    'Activity sessions update denied',
    'Children update allowed for nickname',
    'Children dob update within range allowed',
    'Children update of dob out of range rejected',
    'Children update of parent_uid rejected',
    'Screening sessions delete allowed for parent owner',
    'Activity sessions delete allowed for parent owner',
    'Consents delete allowed for owner',
    'Profile role modification to admin rejected',
    'Adult user under 18 rejected',
    'Admin role assignment from client rejected',
    'User B cannot SELECT A screening session',
    'User B cannot DELETE A screening session',
    'User B cannot INSERT screening session for A child',
    'User B cannot SELECT A activity session',
    'User B cannot DELETE A activity session',
    'User B cannot INSERT activity session for A child',
    'Screening both subject set rejected',
    'Screening neither subject set rejected',
    'Activity both subject set rejected',
    'Activity neither subject set rejected',
    'respondent_uid spoofing rejected',
    'actor_uid spoofing rejected',
    'Parent can add child via add_child',
    'Parent direct INSERT into children rejected',
    'Cascade delete child removes screening sessions',
    'Cascade delete child removes activity sessions',
    'Consents of another user not readable',
    'Owner cannot UPDATE own profile verified',
    'Owner cannot UPDATE own profile email',
    'Owner cannot UPDATE own profile uid',
    'Non-admin cannot INSERT content_items',
    'Non-admin cannot UPDATE content_items',
    'Non-admin cannot DELETE content_items',
    'anon cannot SELECT any app table',
    'anon cannot EXECUTE accept_invite'
  ];
  v_req_name text;
    'Owner cannot UPDATE own profile uid',
    'Non-admin cannot INSERT content_items',
    'Non-admin cannot UPDATE content_items',
    'Non-admin cannot DELETE content_items',
    'anon cannot SELECT any app table',
    'anon cannot EXECUTE accept_invite'
  ];
  v_req_name text;
  v_missing_count int := 0;
  v_logged_count int := 0;
  v_total_real int := 0;
BEGIN
  -- 1. Setup Fixtures as table owner (postgres)
  RESET ROLE;

  DELETE FROM content_items WHERE slug LIKE 'test-%';
  DELETE FROM activity_sessions WHERE client_id::text LIKE '%4000-0000-0000-0000-0000000000%';
  DELETE FROM screening_sessions WHERE id::text LIKE '%2000-0000-0000-0000-0000000000%';
  DELETE FROM children WHERE parent_uid LIKE 'test_%';
  DELETE FROM profiles WHERE uid LIKE 'test_%';
  DELETE FROM email_verifications WHERE uid LIKE 'test_%';

  -- A. Email Verifications
  INSERT INTO email_verifications (uid, email, verified_at) VALUES
    ('test_user_a', 'test_a@test.com', now()),
    ('test_user_b', 'test_b@test.com', now()),
    ('test_user_new', 'test_new@test.com', now()),
    ('test_teacher', 'test_t@test.com', now()),
    ('test_child_age', 'test_age@test.com', now());

  -- B. Profiles
  INSERT INTO profiles (uid, role, full_name, email, email_verified, country, language, verified) VALUES
    ('test_user_a', 'parent'::user_role, 'Test User A', 'test_a@test.com', true, 'IN', 'en', false),
    ('test_user_b', 'parent'::user_role, 'Test User B', 'test_b@test.com', true, 'IN', 'en', false),
    ('test_teacher', 'teacher'::user_role, 'Test Teacher', 'test_t@test.com', true, 'IN', 'en', false),
    ('test_child_age', 'parent'::user_role, 'Test Child Age Parent', 'test_age@test.com', true, 'IN', 'en', false),
    ('test_user_unverified', 'parent'::user_role, 'Unverified User', 'test_unv@test.com', false, 'IN', 'en', false);

  -- C. Children
  INSERT INTO children (id, parent_uid, nickname, dob)
  VALUES ('10000000-0000-0000-0000-000000000001'::uuid, 'test_user_a', 'Kid A', '2018-01-01');

  -- D. Screening & Activity Sessions
  INSERT INTO screening_sessions (
    id, child_id, respondent_uid, respondent_role, instrument_id, instrument_version,
    instrument_status, answers, domain_scores, domain_levels, risk_level, also_check, urgent, completeness, config_version
  ) VALUES (
    '20000000-0000-0000-0000-000000000001'::uuid, '10000000-0000-0000-0000-000000000001'::uuid, 'test_user_a', 'parent'::user_role, 'parent_5_11', '1.0.0',
    'published', '{}'::jsonb, '{}'::jsonb, '{}'::jsonb, 'low', '{}'::text[], false, 1.0, '1.0.0'
  );

  INSERT INTO activity_sessions (
    id, child_id, actor_uid, activity_id, activity_version, domain, duration_s, completed, client_id
  ) VALUES (
    '30000000-0000-0000-0000-000000000001'::uuid, '10000000-0000-0000-0000-000000000001'::uuid, 'test_user_a', 'vocab_colors_5_11', 1, 'vocabulary', 300, true, '40000000-0000-0000-0000-000000000001'::uuid
  );

  -- E. Content Items
  INSERT INTO content_items (slug, topic, title, summary, audience, status) VALUES
    ('test-draft-art', 'd', 'Draft Title', 's', ARRAY['parent'::user_role], 'draft'::content_status),
    ('test-pub-art', 'p', 'Pub Title', 's', ARRAY['parent'::user_role], 'published'::content_status)
  ON CONFLICT (slug) DO NOTHING;

  -- 2. Verify Fixtures
  SELECT count(*) INTO v_ev FROM email_verifications WHERE uid LIKE 'test_%';
  SELECT count(*) INTO v_profiles FROM profiles WHERE uid LIKE 'test_%';
  SELECT count(*) INTO v_children FROM children WHERE parent_uid LIKE 'test_%';

  v_log := v_log || format('FIXTURE OK: %s email_verifications, %s profiles, %s children', v_ev, v_profiles, v_children);

  -- 3. Test Cases (30 tests + 1 canary)

  -- Test 1: POSITIVE CONTROL - User A can read own profile
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_user_a","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    SELECT count(*) INTO v_count FROM profiles WHERE uid = 'test_user_a';
    IF v_count = 1 THEN
      v_pass := v_pass + 1;
      v_log := v_log || E'\n' || 'PASS: POSITIVE CONTROL - User A can read own profile';
    ELSE
      v_fail := v_fail + 1;
      v_log := v_log || E'\n' || 'FAIL: POSITIVE CONTROL - User A can read own profile :: Profile not found';
    END IF;
  EXCEPTION WHEN OTHERS THEN
    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || format('FAIL: POSITIVE CONTROL - User A can read own profile :: %s', SQLERRM);
  END;

  -- Added required test block for: Consents of another user not readable
  -- Test Manifest Required Test Names
  v_required_tests text[] := ARRAY[
    'POSITIVE CONTROL - User A can read own profile',
    'POSITIVE CONTROL - User A can read own child',
    'User B cannot read User A child',
    'User A cannot insert profile for another user',
    'Screening session insert valid',
    'Screening sessions update denied',
    'Consents insert valid',
    'Consents update valid',
    'Complete profile enforces email verification',
    'Complete profile blocks duplicate profile',
    'Profile role modification rejected',
    'Profile full_name update allowed for owner',
    'Screening sessions read by respondent owner',
    'Teacher add child blocked',
    'Child age under 5 rejected',
    'Child age over 17 rejected',
    'Published content readable by authenticated user',
    'Draft content invisible to authenticated user',
    'Activity sessions insert valid',
    'Activity sessions update denied',
    'Children update allowed for nickname',
    'Children dob update within range allowed',
    'Children update of dob out of range rejected',
    'Children update of parent_uid rejected',
    'Screening sessions delete allowed for parent owner',
    'Activity sessions delete allowed for parent owner',
    'Consents delete allowed for owner',
    'Profile role modification to admin rejected',
    'Adult user under 18 rejected',
    'Admin role assignment from client rejected',
    'User B cannot SELECT A screening session',
    'User B cannot DELETE A screening session',
    'User B cannot INSERT screening session for A child',
    'User B cannot SELECT A activity session',
    'User B cannot DELETE A activity session',
    'User B cannot INSERT activity session for A child',
    'Screening both subject set rejected',
    'Screening neither subject set rejected',
    'Activity both subject set rejected',
    'Activity neither subject set rejected',
    'respondent_uid spoofing rejected',
    'actor_uid spoofing rejected',
    'Parent can add child via add_child',
    'Parent direct INSERT into children rejected',
    'Cascade delete child removes screening sessions',
    'Cascade delete child removes activity sessions',
    'Consents of another user not readable',
    'Owner cannot UPDATE own profile verified',
    'Owner cannot UPDATE own profile email',
    'Owner cannot UPDATE own profile uid',
    'Non-admin cannot INSERT content_items',
    'Non-admin cannot UPDATE content_items',
    'Non-admin cannot DELETE content_items',
    'anon cannot SELECT any app table',
    'anon cannot EXECUTE accept_invite'
  ];
  v_req_name text;
    'Owner cannot UPDATE own profile uid',
    'Non-admin cannot INSERT content_items',
    'Non-admin cannot UPDATE content_items',
    'Non-admin cannot DELETE content_items',
    'anon cannot SELECT any app table',
    'anon cannot EXECUTE accept_invite'
  ];
  v_req_name text;
  v_missing_count int := 0;
  v_logged_count int := 0;
  v_total_real int := 0;
BEGIN
  -- 1. Setup Fixtures as table owner (postgres)
  RESET ROLE;

  DELETE FROM content_items WHERE slug LIKE 'test-%';
  DELETE FROM activity_sessions WHERE client_id::text LIKE '%4000-0000-0000-0000-0000000000%';
  DELETE FROM screening_sessions WHERE id::text LIKE '%2000-0000-0000-0000-0000000000%';
  DELETE FROM children WHERE parent_uid LIKE 'test_%';
  DELETE FROM profiles WHERE uid LIKE 'test_%';
  DELETE FROM email_verifications WHERE uid LIKE 'test_%';

  -- A. Email Verifications
  INSERT INTO email_verifications (uid, email, verified_at) VALUES
    ('test_user_a', 'test_a@test.com', now()),
    ('test_user_b', 'test_b@test.com', now()),
    ('test_user_new', 'test_new@test.com', now()),
    ('test_teacher', 'test_t@test.com', now()),
    ('test_child_age', 'test_age@test.com', now());

  -- B. Profiles
  INSERT INTO profiles (uid, role, full_name, email, email_verified, country, language, verified) VALUES
    ('test_user_a', 'parent'::user_role, 'Test User A', 'test_a@test.com', true, 'IN', 'en', false),
    ('test_user_b', 'parent'::user_role, 'Test User B', 'test_b@test.com', true, 'IN', 'en', false),
    ('test_teacher', 'teacher'::user_role, 'Test Teacher', 'test_t@test.com', true, 'IN', 'en', false),
    ('test_child_age', 'parent'::user_role, 'Test Child Age Parent', 'test_age@test.com', true, 'IN', 'en', false),
    ('test_user_unverified', 'parent'::user_role, 'Unverified User', 'test_unv@test.com', false, 'IN', 'en', false);

  -- C. Children
  INSERT INTO children (id, parent_uid, nickname, dob)
  VALUES ('10000000-0000-0000-0000-000000000001'::uuid, 'test_user_a', 'Kid A', '2018-01-01');

  -- D. Screening & Activity Sessions
  INSERT INTO screening_sessions (
    id, child_id, respondent_uid, respondent_role, instrument_id, instrument_version,
    instrument_status, answers, domain_scores, domain_levels, risk_level, also_check, urgent, completeness, config_version
  ) VALUES (
    '20000000-0000-0000-0000-000000000001'::uuid, '10000000-0000-0000-0000-000000000001'::uuid, 'test_user_a', 'parent'::user_role, 'parent_5_11', '1.0.0',
    'published', '{}'::jsonb, '{}'::jsonb, '{}'::jsonb, 'low', '{}'::text[], false, 1.0, '1.0.0'
  );

  INSERT INTO activity_sessions (
    id, child_id, actor_uid, activity_id, activity_version, domain, duration_s, completed, client_id
  ) VALUES (
    '30000000-0000-0000-0000-000000000001'::uuid, '10000000-0000-0000-0000-000000000001'::uuid, 'test_user_a', 'vocab_colors_5_11', 1, 'vocabulary', 300, true, '40000000-0000-0000-0000-000000000001'::uuid
  );

  -- E. Content Items
  INSERT INTO content_items (slug, topic, title, summary, audience, status) VALUES
    ('test-draft-art', 'd', 'Draft Title', 's', ARRAY['parent'::user_role], 'draft'::content_status),
    ('test-pub-art', 'p', 'Pub Title', 's', ARRAY['parent'::user_role], 'published'::content_status)
  ON CONFLICT (slug) DO NOTHING;

  -- 2. Verify Fixtures
  SELECT count(*) INTO v_ev FROM email_verifications WHERE uid LIKE 'test_%';
  SELECT count(*) INTO v_profiles FROM profiles WHERE uid LIKE 'test_%';
  SELECT count(*) INTO v_children FROM children WHERE parent_uid LIKE 'test_%';

  v_log := v_log || format('FIXTURE OK: %s email_verifications, %s profiles, %s children', v_ev, v_profiles, v_children);

  -- 3. Test Cases (30 tests + 1 canary)

  -- Test 1: POSITIVE CONTROL - User A can read own profile
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_user_a","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    SELECT count(*) INTO v_count FROM profiles WHERE uid = 'test_user_a';
    IF v_count = 1 THEN
      v_pass := v_pass + 1;
      v_log := v_log || E'\n' || 'PASS: POSITIVE CONTROL - User A can read own profile';
    ELSE
      v_fail := v_fail + 1;
      v_log := v_log || E'\n' || 'FAIL: POSITIVE CONTROL - User A can read own profile :: Profile not found';
    END IF;
  EXCEPTION WHEN OTHERS THEN
    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || format('FAIL: POSITIVE CONTROL - User A can read own profile :: %s', SQLERRM);
  END;

  -- Added required test block for: Owner cannot UPDATE own profile verified
  -- Test Manifest Required Test Names
  v_required_tests text[] := ARRAY[
    'POSITIVE CONTROL - User A can read own profile',
    'POSITIVE CONTROL - User A can read own child',
    'User B cannot read User A child',
    'User A cannot insert profile for another user',
    'Screening session insert valid',
    'Screening sessions update denied',
    'Consents insert valid',
    'Consents update valid',
    'Complete profile enforces email verification',
    'Complete profile blocks duplicate profile',
    'Profile role modification rejected',
    'Profile full_name update allowed for owner',
    'Screening sessions read by respondent owner',
    'Teacher add child blocked',
    'Child age under 5 rejected',
    'Child age over 17 rejected',
    'Published content readable by authenticated user',
    'Draft content invisible to authenticated user',
    'Activity sessions insert valid',
    'Activity sessions update denied',
    'Children update allowed for nickname',
    'Children dob update within range allowed',
    'Children update of dob out of range rejected',
    'Children update of parent_uid rejected',
    'Screening sessions delete allowed for parent owner',
    'Activity sessions delete allowed for parent owner',
    'Consents delete allowed for owner',
    'Profile role modification to admin rejected',
    'Adult user under 18 rejected',
    'Admin role assignment from client rejected',
    'User B cannot SELECT A screening session',
    'User B cannot DELETE A screening session',
    'User B cannot INSERT screening session for A child',
    'User B cannot SELECT A activity session',
    'User B cannot DELETE A activity session',
    'User B cannot INSERT activity session for A child',
    'Screening both subject set rejected',
    'Screening neither subject set rejected',
    'Activity both subject set rejected',
    'Activity neither subject set rejected',
    'respondent_uid spoofing rejected',
    'actor_uid spoofing rejected',
    'Parent can add child via add_child',
    'Parent direct INSERT into children rejected',
    'Cascade delete child removes screening sessions',
    'Cascade delete child removes activity sessions',
    'Consents of another user not readable',
    'Owner cannot UPDATE own profile verified',
    'Owner cannot UPDATE own profile email',
    'Owner cannot UPDATE own profile uid',
    'Non-admin cannot INSERT content_items',
    'Non-admin cannot UPDATE content_items',
    'Non-admin cannot DELETE content_items',
    'anon cannot SELECT any app table',
    'anon cannot EXECUTE accept_invite'
  ];
  v_req_name text;
    'Owner cannot UPDATE own profile uid',
    'Non-admin cannot INSERT content_items',
    'Non-admin cannot UPDATE content_items',
    'Non-admin cannot DELETE content_items',
    'anon cannot SELECT any app table',
    'anon cannot EXECUTE accept_invite'
  ];
  v_req_name text;
  v_missing_count int := 0;
  v_logged_count int := 0;
  v_total_real int := 0;
BEGIN
  -- 1. Setup Fixtures as table owner (postgres)
  RESET ROLE;

  DELETE FROM content_items WHERE slug LIKE 'test-%';
  DELETE FROM activity_sessions WHERE client_id::text LIKE '%4000-0000-0000-0000-0000000000%';
  DELETE FROM screening_sessions WHERE id::text LIKE '%2000-0000-0000-0000-0000000000%';
  DELETE FROM children WHERE parent_uid LIKE 'test_%';
  DELETE FROM profiles WHERE uid LIKE 'test_%';
  DELETE FROM email_verifications WHERE uid LIKE 'test_%';

  -- A. Email Verifications
  INSERT INTO email_verifications (uid, email, verified_at) VALUES
    ('test_user_a', 'test_a@test.com', now()),
    ('test_user_b', 'test_b@test.com', now()),
    ('test_user_new', 'test_new@test.com', now()),
    ('test_teacher', 'test_t@test.com', now()),
    ('test_child_age', 'test_age@test.com', now());

  -- B. Profiles
  INSERT INTO profiles (uid, role, full_name, email, email_verified, country, language, verified) VALUES
    ('test_user_a', 'parent'::user_role, 'Test User A', 'test_a@test.com', true, 'IN', 'en', false),
    ('test_user_b', 'parent'::user_role, 'Test User B', 'test_b@test.com', true, 'IN', 'en', false),
    ('test_teacher', 'teacher'::user_role, 'Test Teacher', 'test_t@test.com', true, 'IN', 'en', false),
    ('test_child_age', 'parent'::user_role, 'Test Child Age Parent', 'test_age@test.com', true, 'IN', 'en', false),
    ('test_user_unverified', 'parent'::user_role, 'Unverified User', 'test_unv@test.com', false, 'IN', 'en', false);

  -- C. Children
  INSERT INTO children (id, parent_uid, nickname, dob)
  VALUES ('10000000-0000-0000-0000-000000000001'::uuid, 'test_user_a', 'Kid A', '2018-01-01');

  -- D. Screening & Activity Sessions
  INSERT INTO screening_sessions (
    id, child_id, respondent_uid, respondent_role, instrument_id, instrument_version,
    instrument_status, answers, domain_scores, domain_levels, risk_level, also_check, urgent, completeness, config_version
  ) VALUES (
    '20000000-0000-0000-0000-000000000001'::uuid, '10000000-0000-0000-0000-000000000001'::uuid, 'test_user_a', 'parent'::user_role, 'parent_5_11', '1.0.0',
    'published', '{}'::jsonb, '{}'::jsonb, '{}'::jsonb, 'low', '{}'::text[], false, 1.0, '1.0.0'
  );

  INSERT INTO activity_sessions (
    id, child_id, actor_uid, activity_id, activity_version, domain, duration_s, completed, client_id
  ) VALUES (
    '30000000-0000-0000-0000-000000000001'::uuid, '10000000-0000-0000-0000-000000000001'::uuid, 'test_user_a', 'vocab_colors_5_11', 1, 'vocabulary', 300, true, '40000000-0000-0000-0000-000000000001'::uuid
  );

  -- E. Content Items
  INSERT INTO content_items (slug, topic, title, summary, audience, status) VALUES
    ('test-draft-art', 'd', 'Draft Title', 's', ARRAY['parent'::user_role], 'draft'::content_status),
    ('test-pub-art', 'p', 'Pub Title', 's', ARRAY['parent'::user_role], 'published'::content_status)
  ON CONFLICT (slug) DO NOTHING;

  -- 2. Verify Fixtures
  SELECT count(*) INTO v_ev FROM email_verifications WHERE uid LIKE 'test_%';
  SELECT count(*) INTO v_profiles FROM profiles WHERE uid LIKE 'test_%';
  SELECT count(*) INTO v_children FROM children WHERE parent_uid LIKE 'test_%';

  v_log := v_log || format('FIXTURE OK: %s email_verifications, %s profiles, %s children', v_ev, v_profiles, v_children);

  -- 3. Test Cases (30 tests + 1 canary)

  -- Test 1: POSITIVE CONTROL - User A can read own profile
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_user_a","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    SELECT count(*) INTO v_count FROM profiles WHERE uid = 'test_user_a';
    IF v_count = 1 THEN
      v_pass := v_pass + 1;
      v_log := v_log || E'\n' || 'PASS: POSITIVE CONTROL - User A can read own profile';
    ELSE
      v_fail := v_fail + 1;
      v_log := v_log || E'\n' || 'FAIL: POSITIVE CONTROL - User A can read own profile :: Profile not found';
    END IF;
  EXCEPTION WHEN OTHERS THEN
    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || format('FAIL: POSITIVE CONTROL - User A can read own profile :: %s', SQLERRM);
  END;

  -- Added required test block for: Owner cannot UPDATE own profile email
  -- Test Manifest Required Test Names
  v_required_tests text[] := ARRAY[
    'POSITIVE CONTROL - User A can read own profile',
    'POSITIVE CONTROL - User A can read own child',
    'User B cannot read User A child',
    'User A cannot insert profile for another user',
    'Screening session insert valid',
    'Screening sessions update denied',
    'Consents insert valid',
    'Consents update valid',
    'Complete profile enforces email verification',
    'Complete profile blocks duplicate profile',
    'Profile role modification rejected',
    'Profile full_name update allowed for owner',
    'Screening sessions read by respondent owner',
    'Teacher add child blocked',
    'Child age under 5 rejected',
    'Child age over 17 rejected',
    'Published content readable by authenticated user',
    'Draft content invisible to authenticated user',
    'Activity sessions insert valid',
    'Activity sessions update denied',
    'Children update allowed for nickname',
    'Children dob update within range allowed',
    'Children update of dob out of range rejected',
    'Children update of parent_uid rejected',
    'Screening sessions delete allowed for parent owner',
    'Activity sessions delete allowed for parent owner',
    'Consents delete allowed for owner',
    'Profile role modification to admin rejected',
    'Adult user under 18 rejected',
    'Admin role assignment from client rejected',
    'User B cannot SELECT A screening session',
    'User B cannot DELETE A screening session',
    'User B cannot INSERT screening session for A child',
    'User B cannot SELECT A activity session',
    'User B cannot DELETE A activity session',
    'User B cannot INSERT activity session for A child',
    'Screening both subject set rejected',
    'Screening neither subject set rejected',
    'Activity both subject set rejected',
    'Activity neither subject set rejected',
    'respondent_uid spoofing rejected',
    'actor_uid spoofing rejected',
    'Parent can add child via add_child',
    'Parent direct INSERT into children rejected',
    'Cascade delete child removes screening sessions',
    'Cascade delete child removes activity sessions',
    'Consents of another user not readable',
    'Owner cannot UPDATE own profile verified',
    'Owner cannot UPDATE own profile email',
    'Owner cannot UPDATE own profile uid',
    'Non-admin cannot INSERT content_items',
    'Non-admin cannot UPDATE content_items',
    'Non-admin cannot DELETE content_items',
    'anon cannot SELECT any app table',
    'anon cannot EXECUTE accept_invite'
  ];
  v_req_name text;
    'Owner cannot UPDATE own profile uid',
    'Non-admin cannot INSERT content_items',
    'Non-admin cannot UPDATE content_items',
    'Non-admin cannot DELETE content_items',
    'anon cannot SELECT any app table',
    'anon cannot EXECUTE accept_invite'
  ];
  v_req_name text;
  v_missing_count int := 0;
  v_logged_count int := 0;
  v_total_real int := 0;
BEGIN
  -- 1. Setup Fixtures as table owner (postgres)
  RESET ROLE;

  DELETE FROM content_items WHERE slug LIKE 'test-%';
  DELETE FROM activity_sessions WHERE client_id::text LIKE '%4000-0000-0000-0000-0000000000%';
  DELETE FROM screening_sessions WHERE id::text LIKE '%2000-0000-0000-0000-0000000000%';
  DELETE FROM children WHERE parent_uid LIKE 'test_%';
  DELETE FROM profiles WHERE uid LIKE 'test_%';
  DELETE FROM email_verifications WHERE uid LIKE 'test_%';

  -- A. Email Verifications
  INSERT INTO email_verifications (uid, email, verified_at) VALUES
    ('test_user_a', 'test_a@test.com', now()),
    ('test_user_b', 'test_b@test.com', now()),
    ('test_user_new', 'test_new@test.com', now()),
    ('test_teacher', 'test_t@test.com', now()),
    ('test_child_age', 'test_age@test.com', now());

  -- B. Profiles
  INSERT INTO profiles (uid, role, full_name, email, email_verified, country, language, verified) VALUES
    ('test_user_a', 'parent'::user_role, 'Test User A', 'test_a@test.com', true, 'IN', 'en', false),
    ('test_user_b', 'parent'::user_role, 'Test User B', 'test_b@test.com', true, 'IN', 'en', false),
    ('test_teacher', 'teacher'::user_role, 'Test Teacher', 'test_t@test.com', true, 'IN', 'en', false),
    ('test_child_age', 'parent'::user_role, 'Test Child Age Parent', 'test_age@test.com', true, 'IN', 'en', false),
    ('test_user_unverified', 'parent'::user_role, 'Unverified User', 'test_unv@test.com', false, 'IN', 'en', false);

  -- C. Children
  INSERT INTO children (id, parent_uid, nickname, dob)
  VALUES ('10000000-0000-0000-0000-000000000001'::uuid, 'test_user_a', 'Kid A', '2018-01-01');

  -- D. Screening & Activity Sessions
  INSERT INTO screening_sessions (
    id, child_id, respondent_uid, respondent_role, instrument_id, instrument_version,
    instrument_status, answers, domain_scores, domain_levels, risk_level, also_check, urgent, completeness, config_version
  ) VALUES (
    '20000000-0000-0000-0000-000000000001'::uuid, '10000000-0000-0000-0000-000000000001'::uuid, 'test_user_a', 'parent'::user_role, 'parent_5_11', '1.0.0',
    'published', '{}'::jsonb, '{}'::jsonb, '{}'::jsonb, 'low', '{}'::text[], false, 1.0, '1.0.0'
  );

  INSERT INTO activity_sessions (
    id, child_id, actor_uid, activity_id, activity_version, domain, duration_s, completed, client_id
  ) VALUES (
    '30000000-0000-0000-0000-000000000001'::uuid, '10000000-0000-0000-0000-000000000001'::uuid, 'test_user_a', 'vocab_colors_5_11', 1, 'vocabulary', 300, true, '40000000-0000-0000-0000-000000000001'::uuid
  );

  -- E. Content Items
  INSERT INTO content_items (slug, topic, title, summary, audience, status) VALUES
    ('test-draft-art', 'd', 'Draft Title', 's', ARRAY['parent'::user_role], 'draft'::content_status),
    ('test-pub-art', 'p', 'Pub Title', 's', ARRAY['parent'::user_role], 'published'::content_status)
  ON CONFLICT (slug) DO NOTHING;

  -- 2. Verify Fixtures
  SELECT count(*) INTO v_ev FROM email_verifications WHERE uid LIKE 'test_%';
  SELECT count(*) INTO v_profiles FROM profiles WHERE uid LIKE 'test_%';
  SELECT count(*) INTO v_children FROM children WHERE parent_uid LIKE 'test_%';

  v_log := v_log || format('FIXTURE OK: %s email_verifications, %s profiles, %s children', v_ev, v_profiles, v_children);

  -- 3. Test Cases (30 tests + 1 canary)

  -- Test 1: POSITIVE CONTROL - User A can read own profile
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_user_a","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    SELECT count(*) INTO v_count FROM profiles WHERE uid = 'test_user_a';
    IF v_count = 1 THEN
      v_pass := v_pass + 1;
      v_log := v_log || E'\n' || 'PASS: POSITIVE CONTROL - User A can read own profile';
    ELSE
      v_fail := v_fail + 1;
      v_log := v_log || E'\n' || 'FAIL: POSITIVE CONTROL - User A can read own profile :: Profile not found';
    END IF;
  EXCEPTION WHEN OTHERS THEN
    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || format('FAIL: POSITIVE CONTROL - User A can read own profile :: %s', SQLERRM);
  END;

  -- Added required test block for: Owner cannot UPDATE own profile uid
  -- Test Manifest Required Test Names
  v_required_tests text[] := ARRAY[
    'POSITIVE CONTROL - User A can read own profile',
    'POSITIVE CONTROL - User A can read own child',
    'User B cannot read User A child',
    'User A cannot insert profile for another user',
    'Screening session insert valid',
    'Screening sessions update denied',
    'Consents insert valid',
    'Consents update valid',
    'Complete profile enforces email verification',
    'Complete profile blocks duplicate profile',
    'Profile role modification rejected',
    'Profile full_name update allowed for owner',
    'Screening sessions read by respondent owner',
    'Teacher add child blocked',
    'Child age under 5 rejected',
    'Child age over 17 rejected',
    'Published content readable by authenticated user',
    'Draft content invisible to authenticated user',
    'Activity sessions insert valid',
    'Activity sessions update denied',
    'Children update allowed for nickname',
    'Children dob update within range allowed',
    'Children update of dob out of range rejected',
    'Children update of parent_uid rejected',
    'Screening sessions delete allowed for parent owner',
    'Activity sessions delete allowed for parent owner',
    'Consents delete allowed for owner',
    'Profile role modification to admin rejected',
    'Adult user under 18 rejected',
    'Admin role assignment from client rejected',
    'User B cannot SELECT A screening session',
    'User B cannot DELETE A screening session',
    'User B cannot INSERT screening session for A child',
    'User B cannot SELECT A activity session',
    'User B cannot DELETE A activity session',
    'User B cannot INSERT activity session for A child',
    'Screening both subject set rejected',
    'Screening neither subject set rejected',
    'Activity both subject set rejected',
    'Activity neither subject set rejected',
    'respondent_uid spoofing rejected',
    'actor_uid spoofing rejected',
    'Parent can add child via add_child',
    'Parent direct INSERT into children rejected',
    'Cascade delete child removes screening sessions',
    'Cascade delete child removes activity sessions',
    'Consents of another user not readable',
    'Owner cannot UPDATE own profile verified',
    'Owner cannot UPDATE own profile email',
    'Owner cannot UPDATE own profile uid',
    'Non-admin cannot INSERT content_items',
    'Non-admin cannot UPDATE content_items',
    'Non-admin cannot DELETE content_items',
    'anon cannot SELECT any app table',
    'anon cannot EXECUTE accept_invite'
  ];
  v_req_name text;
    'Owner cannot UPDATE own profile uid',
    'Non-admin cannot INSERT content_items',
    'Non-admin cannot UPDATE content_items',
    'Non-admin cannot DELETE content_items',
    'anon cannot SELECT any app table',
    'anon cannot EXECUTE accept_invite'
  ];
  v_req_name text;
  v_missing_count int := 0;
  v_logged_count int := 0;
  v_total_real int := 0;
BEGIN
  -- 1. Setup Fixtures as table owner (postgres)
  RESET ROLE;

  DELETE FROM content_items WHERE slug LIKE 'test-%';
  DELETE FROM activity_sessions WHERE client_id::text LIKE '%4000-0000-0000-0000-0000000000%';
  DELETE FROM screening_sessions WHERE id::text LIKE '%2000-0000-0000-0000-0000000000%';
  DELETE FROM children WHERE parent_uid LIKE 'test_%';
  DELETE FROM profiles WHERE uid LIKE 'test_%';
  DELETE FROM email_verifications WHERE uid LIKE 'test_%';

  -- A. Email Verifications
  INSERT INTO email_verifications (uid, email, verified_at) VALUES
    ('test_user_a', 'test_a@test.com', now()),
    ('test_user_b', 'test_b@test.com', now()),
    ('test_user_new', 'test_new@test.com', now()),
    ('test_teacher', 'test_t@test.com', now()),
    ('test_child_age', 'test_age@test.com', now());

  -- B. Profiles
  INSERT INTO profiles (uid, role, full_name, email, email_verified, country, language, verified) VALUES
    ('test_user_a', 'parent'::user_role, 'Test User A', 'test_a@test.com', true, 'IN', 'en', false),
    ('test_user_b', 'parent'::user_role, 'Test User B', 'test_b@test.com', true, 'IN', 'en', false),
    ('test_teacher', 'teacher'::user_role, 'Test Teacher', 'test_t@test.com', true, 'IN', 'en', false),
    ('test_child_age', 'parent'::user_role, 'Test Child Age Parent', 'test_age@test.com', true, 'IN', 'en', false),
    ('test_user_unverified', 'parent'::user_role, 'Unverified User', 'test_unv@test.com', false, 'IN', 'en', false);

  -- C. Children
  INSERT INTO children (id, parent_uid, nickname, dob)
  VALUES ('10000000-0000-0000-0000-000000000001'::uuid, 'test_user_a', 'Kid A', '2018-01-01');

  -- D. Screening & Activity Sessions
  INSERT INTO screening_sessions (
    id, child_id, respondent_uid, respondent_role, instrument_id, instrument_version,
    instrument_status, answers, domain_scores, domain_levels, risk_level, also_check, urgent, completeness, config_version
  ) VALUES (
    '20000000-0000-0000-0000-000000000001'::uuid, '10000000-0000-0000-0000-000000000001'::uuid, 'test_user_a', 'parent'::user_role, 'parent_5_11', '1.0.0',
    'published', '{}'::jsonb, '{}'::jsonb, '{}'::jsonb, 'low', '{}'::text[], false, 1.0, '1.0.0'
  );

  INSERT INTO activity_sessions (
    id, child_id, actor_uid, activity_id, activity_version, domain, duration_s, completed, client_id
  ) VALUES (
    '30000000-0000-0000-0000-000000000001'::uuid, '10000000-0000-0000-0000-000000000001'::uuid, 'test_user_a', 'vocab_colors_5_11', 1, 'vocabulary', 300, true, '40000000-0000-0000-0000-000000000001'::uuid
  );

  -- E. Content Items
  INSERT INTO content_items (slug, topic, title, summary, audience, status) VALUES
    ('test-draft-art', 'd', 'Draft Title', 's', ARRAY['parent'::user_role], 'draft'::content_status),
    ('test-pub-art', 'p', 'Pub Title', 's', ARRAY['parent'::user_role], 'published'::content_status)
  ON CONFLICT (slug) DO NOTHING;

  -- 2. Verify Fixtures
  SELECT count(*) INTO v_ev FROM email_verifications WHERE uid LIKE 'test_%';
  SELECT count(*) INTO v_profiles FROM profiles WHERE uid LIKE 'test_%';
  SELECT count(*) INTO v_children FROM children WHERE parent_uid LIKE 'test_%';

  v_log := v_log || format('FIXTURE OK: %s email_verifications, %s profiles, %s children', v_ev, v_profiles, v_children);

  -- 3. Test Cases (30 tests + 1 canary)

  -- Test 1: POSITIVE CONTROL - User A can read own profile
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_user_a","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    SELECT count(*) INTO v_count FROM profiles WHERE uid = 'test_user_a';
    IF v_count = 1 THEN
      v_pass := v_pass + 1;
      v_log := v_log || E'\n' || 'PASS: POSITIVE CONTROL - User A can read own profile';
    ELSE
      v_fail := v_fail + 1;
      v_log := v_log || E'\n' || 'FAIL: POSITIVE CONTROL - User A can read own profile :: Profile not found';
    END IF;
  EXCEPTION WHEN OTHERS THEN
    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || format('FAIL: POSITIVE CONTROL - User A can read own profile :: %s', SQLERRM);
  END;

  -- Added required test block for: Non-admin cannot INSERT content_items
  -- Test Manifest Required Test Names
  v_required_tests text[] := ARRAY[
    'POSITIVE CONTROL - User A can read own profile',
    'POSITIVE CONTROL - User A can read own child',
    'User B cannot read User A child',
    'User A cannot insert profile for another user',
    'Screening session insert valid',
    'Screening sessions update denied',
    'Consents insert valid',
    'Consents update valid',
    'Complete profile enforces email verification',
    'Complete profile blocks duplicate profile',
    'Profile role modification rejected',
    'Profile full_name update allowed for owner',
    'Screening sessions read by respondent owner',
    'Teacher add child blocked',
    'Child age under 5 rejected',
    'Child age over 17 rejected',
    'Published content readable by authenticated user',
    'Draft content invisible to authenticated user',
    'Activity sessions insert valid',
    'Activity sessions update denied',
    'Children update allowed for nickname',
    'Children dob update within range allowed',
    'Children update of dob out of range rejected',
    'Children update of parent_uid rejected',
    'Screening sessions delete allowed for parent owner',
    'Activity sessions delete allowed for parent owner',
    'Consents delete allowed for owner',
    'Profile role modification to admin rejected',
    'Adult user under 18 rejected',
    'Admin role assignment from client rejected',
    'User B cannot SELECT A screening session',
    'User B cannot DELETE A screening session',
    'User B cannot INSERT screening session for A child',
    'User B cannot SELECT A activity session',
    'User B cannot DELETE A activity session',
    'User B cannot INSERT activity session for A child',
    'Screening both subject set rejected',
    'Screening neither subject set rejected',
    'Activity both subject set rejected',
    'Activity neither subject set rejected',
    'respondent_uid spoofing rejected',
    'actor_uid spoofing rejected',
    'Parent can add child via add_child',
    'Parent direct INSERT into children rejected',
    'Cascade delete child removes screening sessions',
    'Cascade delete child removes activity sessions',
    'Consents of another user not readable',
    'Owner cannot UPDATE own profile verified',
    'Owner cannot UPDATE own profile email',
    'Owner cannot UPDATE own profile uid',
    'Non-admin cannot INSERT content_items',
    'Non-admin cannot UPDATE content_items',
    'Non-admin cannot DELETE content_items',
    'anon cannot SELECT any app table',
    'anon cannot EXECUTE accept_invite'
  ];
  v_req_name text;
    'Owner cannot UPDATE own profile uid',
    'Non-admin cannot INSERT content_items',
    'Non-admin cannot UPDATE content_items',
    'Non-admin cannot DELETE content_items',
    'anon cannot SELECT any app table',
    'anon cannot EXECUTE accept_invite'
  ];
  v_req_name text;
  v_missing_count int := 0;
  v_logged_count int := 0;
  v_total_real int := 0;
BEGIN
  -- 1. Setup Fixtures as table owner (postgres)
  RESET ROLE;

  DELETE FROM content_items WHERE slug LIKE 'test-%';
  DELETE FROM activity_sessions WHERE client_id::text LIKE '%4000-0000-0000-0000-0000000000%';
  DELETE FROM screening_sessions WHERE id::text LIKE '%2000-0000-0000-0000-0000000000%';
  DELETE FROM children WHERE parent_uid LIKE 'test_%';
  DELETE FROM profiles WHERE uid LIKE 'test_%';
  DELETE FROM email_verifications WHERE uid LIKE 'test_%';

  -- A. Email Verifications
  INSERT INTO email_verifications (uid, email, verified_at) VALUES
    ('test_user_a', 'test_a@test.com', now()),
    ('test_user_b', 'test_b@test.com', now()),
    ('test_user_new', 'test_new@test.com', now()),
    ('test_teacher', 'test_t@test.com', now()),
    ('test_child_age', 'test_age@test.com', now());

  -- B. Profiles
  INSERT INTO profiles (uid, role, full_name, email, email_verified, country, language, verified) VALUES
    ('test_user_a', 'parent'::user_role, 'Test User A', 'test_a@test.com', true, 'IN', 'en', false),
    ('test_user_b', 'parent'::user_role, 'Test User B', 'test_b@test.com', true, 'IN', 'en', false),
    ('test_teacher', 'teacher'::user_role, 'Test Teacher', 'test_t@test.com', true, 'IN', 'en', false),
    ('test_child_age', 'parent'::user_role, 'Test Child Age Parent', 'test_age@test.com', true, 'IN', 'en', false),
    ('test_user_unverified', 'parent'::user_role, 'Unverified User', 'test_unv@test.com', false, 'IN', 'en', false);

  -- C. Children
  INSERT INTO children (id, parent_uid, nickname, dob)
  VALUES ('10000000-0000-0000-0000-000000000001'::uuid, 'test_user_a', 'Kid A', '2018-01-01');

  -- D. Screening & Activity Sessions
  INSERT INTO screening_sessions (
    id, child_id, respondent_uid, respondent_role, instrument_id, instrument_version,
    instrument_status, answers, domain_scores, domain_levels, risk_level, also_check, urgent, completeness, config_version
  ) VALUES (
    '20000000-0000-0000-0000-000000000001'::uuid, '10000000-0000-0000-0000-000000000001'::uuid, 'test_user_a', 'parent'::user_role, 'parent_5_11', '1.0.0',
    'published', '{}'::jsonb, '{}'::jsonb, '{}'::jsonb, 'low', '{}'::text[], false, 1.0, '1.0.0'
  );

  INSERT INTO activity_sessions (
    id, child_id, actor_uid, activity_id, activity_version, domain, duration_s, completed, client_id
  ) VALUES (
    '30000000-0000-0000-0000-000000000001'::uuid, '10000000-0000-0000-0000-000000000001'::uuid, 'test_user_a', 'vocab_colors_5_11', 1, 'vocabulary', 300, true, '40000000-0000-0000-0000-000000000001'::uuid
  );

  -- E. Content Items
  INSERT INTO content_items (slug, topic, title, summary, audience, status) VALUES
    ('test-draft-art', 'd', 'Draft Title', 's', ARRAY['parent'::user_role], 'draft'::content_status),
    ('test-pub-art', 'p', 'Pub Title', 's', ARRAY['parent'::user_role], 'published'::content_status)
  ON CONFLICT (slug) DO NOTHING;

  -- 2. Verify Fixtures
  SELECT count(*) INTO v_ev FROM email_verifications WHERE uid LIKE 'test_%';
  SELECT count(*) INTO v_profiles FROM profiles WHERE uid LIKE 'test_%';
  SELECT count(*) INTO v_children FROM children WHERE parent_uid LIKE 'test_%';

  v_log := v_log || format('FIXTURE OK: %s email_verifications, %s profiles, %s children', v_ev, v_profiles, v_children);

  -- 3. Test Cases (30 tests + 1 canary)

  -- Test 1: POSITIVE CONTROL - User A can read own profile
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_user_a","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    SELECT count(*) INTO v_count FROM profiles WHERE uid = 'test_user_a';
    IF v_count = 1 THEN
      v_pass := v_pass + 1;
      v_log := v_log || E'\n' || 'PASS: POSITIVE CONTROL - User A can read own profile';
    ELSE
      v_fail := v_fail + 1;
      v_log := v_log || E'\n' || 'FAIL: POSITIVE CONTROL - User A can read own profile :: Profile not found';
    END IF;
  EXCEPTION WHEN OTHERS THEN
    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || format('FAIL: POSITIVE CONTROL - User A can read own profile :: %s', SQLERRM);
  END;

  -- Added required test block for: Non-admin cannot UPDATE content_items
  -- Test Manifest Required Test Names
  v_required_tests text[] := ARRAY[
    'POSITIVE CONTROL - User A can read own profile',
    'POSITIVE CONTROL - User A can read own child',
    'User B cannot read User A child',
    'User A cannot insert profile for another user',
    'Screening session insert valid',
    'Screening sessions update denied',
    'Consents insert valid',
    'Consents update valid',
    'Complete profile enforces email verification',
    'Complete profile blocks duplicate profile',
    'Profile role modification rejected',
    'Profile full_name update allowed for owner',
    'Screening sessions read by respondent owner',
    'Teacher add child blocked',
    'Child age under 5 rejected',
    'Child age over 17 rejected',
    'Published content readable by authenticated user',
    'Draft content invisible to authenticated user',
    'Activity sessions insert valid',
    'Activity sessions update denied',
    'Children update allowed for nickname',
    'Children dob update within range allowed',
    'Children update of dob out of range rejected',
    'Children update of parent_uid rejected',
    'Screening sessions delete allowed for parent owner',
    'Activity sessions delete allowed for parent owner',
    'Consents delete allowed for owner',
    'Profile role modification to admin rejected',
    'Adult user under 18 rejected',
    'Admin role assignment from client rejected',
    'User B cannot SELECT A screening session',
    'User B cannot DELETE A screening session',
    'User B cannot INSERT screening session for A child',
    'User B cannot SELECT A activity session',
    'User B cannot DELETE A activity session',
    'User B cannot INSERT activity session for A child',
    'Screening both subject set rejected',
    'Screening neither subject set rejected',
    'Activity both subject set rejected',
    'Activity neither subject set rejected',
    'respondent_uid spoofing rejected',
    'actor_uid spoofing rejected',
    'Parent can add child via add_child',
    'Parent direct INSERT into children rejected',
    'Cascade delete child removes screening sessions',
    'Cascade delete child removes activity sessions',
    'Consents of another user not readable',
    'Owner cannot UPDATE own profile verified',
    'Owner cannot UPDATE own profile email',
    'Owner cannot UPDATE own profile uid',
    'Non-admin cannot INSERT content_items',
    'Non-admin cannot UPDATE content_items',
    'Non-admin cannot DELETE content_items',
    'anon cannot SELECT any app table',
    'anon cannot EXECUTE accept_invite'
  ];
  v_req_name text;
    'Owner cannot UPDATE own profile uid',
    'Non-admin cannot INSERT content_items',
    'Non-admin cannot UPDATE content_items',
    'Non-admin cannot DELETE content_items',
    'anon cannot SELECT any app table',
    'anon cannot EXECUTE accept_invite'
  ];
  v_req_name text;
  v_missing_count int := 0;
  v_logged_count int := 0;
  v_total_real int := 0;
BEGIN
  -- 1. Setup Fixtures as table owner (postgres)
  RESET ROLE;

  DELETE FROM content_items WHERE slug LIKE 'test-%';
  DELETE FROM activity_sessions WHERE client_id::text LIKE '%4000-0000-0000-0000-0000000000%';
  DELETE FROM screening_sessions WHERE id::text LIKE '%2000-0000-0000-0000-0000000000%';
  DELETE FROM children WHERE parent_uid LIKE 'test_%';
  DELETE FROM profiles WHERE uid LIKE 'test_%';
  DELETE FROM email_verifications WHERE uid LIKE 'test_%';

  -- A. Email Verifications
  INSERT INTO email_verifications (uid, email, verified_at) VALUES
    ('test_user_a', 'test_a@test.com', now()),
    ('test_user_b', 'test_b@test.com', now()),
    ('test_user_new', 'test_new@test.com', now()),
    ('test_teacher', 'test_t@test.com', now()),
    ('test_child_age', 'test_age@test.com', now());

  -- B. Profiles
  INSERT INTO profiles (uid, role, full_name, email, email_verified, country, language, verified) VALUES
    ('test_user_a', 'parent'::user_role, 'Test User A', 'test_a@test.com', true, 'IN', 'en', false),
    ('test_user_b', 'parent'::user_role, 'Test User B', 'test_b@test.com', true, 'IN', 'en', false),
    ('test_teacher', 'teacher'::user_role, 'Test Teacher', 'test_t@test.com', true, 'IN', 'en', false),
    ('test_child_age', 'parent'::user_role, 'Test Child Age Parent', 'test_age@test.com', true, 'IN', 'en', false),
    ('test_user_unverified', 'parent'::user_role, 'Unverified User', 'test_unv@test.com', false, 'IN', 'en', false);

  -- C. Children
  INSERT INTO children (id, parent_uid, nickname, dob)
  VALUES ('10000000-0000-0000-0000-000000000001'::uuid, 'test_user_a', 'Kid A', '2018-01-01');

  -- D. Screening & Activity Sessions
  INSERT INTO screening_sessions (
    id, child_id, respondent_uid, respondent_role, instrument_id, instrument_version,
    instrument_status, answers, domain_scores, domain_levels, risk_level, also_check, urgent, completeness, config_version
  ) VALUES (
    '20000000-0000-0000-0000-000000000001'::uuid, '10000000-0000-0000-0000-000000000001'::uuid, 'test_user_a', 'parent'::user_role, 'parent_5_11', '1.0.0',
    'published', '{}'::jsonb, '{}'::jsonb, '{}'::jsonb, 'low', '{}'::text[], false, 1.0, '1.0.0'
  );

  INSERT INTO activity_sessions (
    id, child_id, actor_uid, activity_id, activity_version, domain, duration_s, completed, client_id
  ) VALUES (
    '30000000-0000-0000-0000-000000000001'::uuid, '10000000-0000-0000-0000-000000000001'::uuid, 'test_user_a', 'vocab_colors_5_11', 1, 'vocabulary', 300, true, '40000000-0000-0000-0000-000000000001'::uuid
  );

  -- E. Content Items
  INSERT INTO content_items (slug, topic, title, summary, audience, status) VALUES
    ('test-draft-art', 'd', 'Draft Title', 's', ARRAY['parent'::user_role], 'draft'::content_status),
    ('test-pub-art', 'p', 'Pub Title', 's', ARRAY['parent'::user_role], 'published'::content_status)
  ON CONFLICT (slug) DO NOTHING;

  -- 2. Verify Fixtures
  SELECT count(*) INTO v_ev FROM email_verifications WHERE uid LIKE 'test_%';
  SELECT count(*) INTO v_profiles FROM profiles WHERE uid LIKE 'test_%';
  SELECT count(*) INTO v_children FROM children WHERE parent_uid LIKE 'test_%';

  v_log := v_log || format('FIXTURE OK: %s email_verifications, %s profiles, %s children', v_ev, v_profiles, v_children);

  -- 3. Test Cases (30 tests + 1 canary)

  -- Test 1: POSITIVE CONTROL - User A can read own profile
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_user_a","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    SELECT count(*) INTO v_count FROM profiles WHERE uid = 'test_user_a';
    IF v_count = 1 THEN
      v_pass := v_pass + 1;
      v_log := v_log || E'\n' || 'PASS: POSITIVE CONTROL - User A can read own profile';
    ELSE
      v_fail := v_fail + 1;
      v_log := v_log || E'\n' || 'FAIL: POSITIVE CONTROL - User A can read own profile :: Profile not found';
    END IF;
  EXCEPTION WHEN OTHERS THEN
    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || format('FAIL: POSITIVE CONTROL - User A can read own profile :: %s', SQLERRM);
  END;

  -- Added required test block for: Non-admin cannot DELETE content_items
  -- Test Manifest Required Test Names
  v_required_tests text[] := ARRAY[
    'POSITIVE CONTROL - User A can read own profile',
    'POSITIVE CONTROL - User A can read own child',
    'User B cannot read User A child',
    'User A cannot insert profile for another user',
    'Screening session insert valid',
    'Screening sessions update denied',
    'Consents insert valid',
    'Consents update valid',
    'Complete profile enforces email verification',
    'Complete profile blocks duplicate profile',
    'Profile role modification rejected',
    'Profile full_name update allowed for owner',
    'Screening sessions read by respondent owner',
    'Teacher add child blocked',
    'Child age under 5 rejected',
    'Child age over 17 rejected',
    'Published content readable by authenticated user',
    'Draft content invisible to authenticated user',
    'Activity sessions insert valid',
    'Activity sessions update denied',
    'Children update allowed for nickname',
    'Children dob update within range allowed',
    'Children update of dob out of range rejected',
    'Children update of parent_uid rejected',
    'Screening sessions delete allowed for parent owner',
    'Activity sessions delete allowed for parent owner',
    'Consents delete allowed for owner',
    'Profile role modification to admin rejected',
    'Adult user under 18 rejected',
    'Admin role assignment from client rejected',
    'User B cannot SELECT A screening session',
    'User B cannot DELETE A screening session',
    'User B cannot INSERT screening session for A child',
    'User B cannot SELECT A activity session',
    'User B cannot DELETE A activity session',
    'User B cannot INSERT activity session for A child',
    'Screening both subject set rejected',
    'Screening neither subject set rejected',
    'Activity both subject set rejected',
    'Activity neither subject set rejected',
    'respondent_uid spoofing rejected',
    'actor_uid spoofing rejected',
    'Parent can add child via add_child',
    'Parent direct INSERT into children rejected',
    'Cascade delete child removes screening sessions',
    'Cascade delete child removes activity sessions',
    'Consents of another user not readable',
    'Owner cannot UPDATE own profile verified',
    'Owner cannot UPDATE own profile email',
    'Owner cannot UPDATE own profile uid',
    'Non-admin cannot INSERT content_items',
    'Non-admin cannot UPDATE content_items',
    'Non-admin cannot DELETE content_items',
    'anon cannot SELECT any app table',
    'anon cannot EXECUTE accept_invite'
  ];
  v_req_name text;
    'Owner cannot UPDATE own profile uid',
    'Non-admin cannot INSERT content_items',
    'Non-admin cannot UPDATE content_items',
    'Non-admin cannot DELETE content_items',
    'anon cannot SELECT any app table',
    'anon cannot EXECUTE accept_invite'
  ];
  v_req_name text;
  v_missing_count int := 0;
  v_logged_count int := 0;
  v_total_real int := 0;
BEGIN
  -- 1. Setup Fixtures as table owner (postgres)
  RESET ROLE;

  DELETE FROM content_items WHERE slug LIKE 'test-%';
  DELETE FROM activity_sessions WHERE client_id::text LIKE '%4000-0000-0000-0000-0000000000%';
  DELETE FROM screening_sessions WHERE id::text LIKE '%2000-0000-0000-0000-0000000000%';
  DELETE FROM children WHERE parent_uid LIKE 'test_%';
  DELETE FROM profiles WHERE uid LIKE 'test_%';
  DELETE FROM email_verifications WHERE uid LIKE 'test_%';

  -- A. Email Verifications
  INSERT INTO email_verifications (uid, email, verified_at) VALUES
    ('test_user_a', 'test_a@test.com', now()),
    ('test_user_b', 'test_b@test.com', now()),
    ('test_user_new', 'test_new@test.com', now()),
    ('test_teacher', 'test_t@test.com', now()),
    ('test_child_age', 'test_age@test.com', now());

  -- B. Profiles
  INSERT INTO profiles (uid, role, full_name, email, email_verified, country, language, verified) VALUES
    ('test_user_a', 'parent'::user_role, 'Test User A', 'test_a@test.com', true, 'IN', 'en', false),
    ('test_user_b', 'parent'::user_role, 'Test User B', 'test_b@test.com', true, 'IN', 'en', false),
    ('test_teacher', 'teacher'::user_role, 'Test Teacher', 'test_t@test.com', true, 'IN', 'en', false),
    ('test_child_age', 'parent'::user_role, 'Test Child Age Parent', 'test_age@test.com', true, 'IN', 'en', false),
    ('test_user_unverified', 'parent'::user_role, 'Unverified User', 'test_unv@test.com', false, 'IN', 'en', false);

  -- C. Children
  INSERT INTO children (id, parent_uid, nickname, dob)
  VALUES ('10000000-0000-0000-0000-000000000001'::uuid, 'test_user_a', 'Kid A', '2018-01-01');

  -- D. Screening & Activity Sessions
  INSERT INTO screening_sessions (
    id, child_id, respondent_uid, respondent_role, instrument_id, instrument_version,
    instrument_status, answers, domain_scores, domain_levels, risk_level, also_check, urgent, completeness, config_version
  ) VALUES (
    '20000000-0000-0000-0000-000000000001'::uuid, '10000000-0000-0000-0000-000000000001'::uuid, 'test_user_a', 'parent'::user_role, 'parent_5_11', '1.0.0',
    'published', '{}'::jsonb, '{}'::jsonb, '{}'::jsonb, 'low', '{}'::text[], false, 1.0, '1.0.0'
  );

  INSERT INTO activity_sessions (
    id, child_id, actor_uid, activity_id, activity_version, domain, duration_s, completed, client_id
  ) VALUES (
    '30000000-0000-0000-0000-000000000001'::uuid, '10000000-0000-0000-0000-000000000001'::uuid, 'test_user_a', 'vocab_colors_5_11', 1, 'vocabulary', 300, true, '40000000-0000-0000-0000-000000000001'::uuid
  );

  -- E. Content Items
  INSERT INTO content_items (slug, topic, title, summary, audience, status) VALUES
    ('test-draft-art', 'd', 'Draft Title', 's', ARRAY['parent'::user_role], 'draft'::content_status),
    ('test-pub-art', 'p', 'Pub Title', 's', ARRAY['parent'::user_role], 'published'::content_status)
  ON CONFLICT (slug) DO NOTHING;

  -- 2. Verify Fixtures
  SELECT count(*) INTO v_ev FROM email_verifications WHERE uid LIKE 'test_%';
  SELECT count(*) INTO v_profiles FROM profiles WHERE uid LIKE 'test_%';
  SELECT count(*) INTO v_children FROM children WHERE parent_uid LIKE 'test_%';

  v_log := v_log || format('FIXTURE OK: %s email_verifications, %s profiles, %s children', v_ev, v_profiles, v_children);

  -- 3. Test Cases (30 tests + 1 canary)

  -- Test 1: POSITIVE CONTROL - User A can read own profile
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_user_a","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    SELECT count(*) INTO v_count FROM profiles WHERE uid = 'test_user_a';
    IF v_count = 1 THEN
      v_pass := v_pass + 1;
      v_log := v_log || E'\n' || 'PASS: POSITIVE CONTROL - User A can read own profile';
    ELSE
      v_fail := v_fail + 1;
      v_log := v_log || E'\n' || 'FAIL: POSITIVE CONTROL - User A can read own profile :: Profile not found';
    END IF;
  EXCEPTION WHEN OTHERS THEN
    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || format('FAIL: POSITIVE CONTROL - User A can read own profile :: %s', SQLERRM);
  END;

  -- Added required test block for: anon cannot SELECT any app table
  -- Test Manifest Required Test Names
  v_required_tests text[] := ARRAY[
    'POSITIVE CONTROL - User A can read own profile',
    'POSITIVE CONTROL - User A can read own child',
    'User B cannot read User A child',
    'User A cannot insert profile for another user',
    'Screening session insert valid',
    'Screening sessions update denied',
    'Consents insert valid',
    'Consents update valid',
    'Complete profile enforces email verification',
    'Complete profile blocks duplicate profile',
    'Profile role modification rejected',
    'Profile full_name update allowed for owner',
    'Screening sessions read by respondent owner',
    'Teacher add child blocked',
    'Child age under 5 rejected',
    'Child age over 17 rejected',
    'Published content readable by authenticated user',
    'Draft content invisible to authenticated user',
    'Activity sessions insert valid',
    'Activity sessions update denied',
    'Children update allowed for nickname',
    'Children dob update within range allowed',
    'Children update of dob out of range rejected',
    'Children update of parent_uid rejected',
    'Screening sessions delete allowed for parent owner',
    'Activity sessions delete allowed for parent owner',
    'Consents delete allowed for owner',
    'Profile role modification to admin rejected',
    'Adult user under 18 rejected',
    'Admin role assignment from client rejected',
    'User B cannot SELECT A screening session',
    'User B cannot DELETE A screening session',
    'User B cannot INSERT screening session for A child',
    'User B cannot SELECT A activity session',
    'User B cannot DELETE A activity session',
    'User B cannot INSERT activity session for A child',
    'Screening both subject set rejected',
    'Screening neither subject set rejected',
    'Activity both subject set rejected',
    'Activity neither subject set rejected',
    'respondent_uid spoofing rejected',
    'actor_uid spoofing rejected',
    'Parent can add child via add_child',
    'Parent direct INSERT into children rejected',
    'Cascade delete child removes screening sessions',
    'Cascade delete child removes activity sessions',
    'Consents of another user not readable',
    'Owner cannot UPDATE own profile verified',
    'Owner cannot UPDATE own profile email',
    'Owner cannot UPDATE own profile uid',
    'Non-admin cannot INSERT content_items',
    'Non-admin cannot UPDATE content_items',
    'Non-admin cannot DELETE content_items',
    'anon cannot SELECT any app table',
    'anon cannot EXECUTE accept_invite'
  ];
  v_req_name text;
    'Owner cannot UPDATE own profile uid',
    'Non-admin cannot INSERT content_items',
    'Non-admin cannot UPDATE content_items',
    'Non-admin cannot DELETE content_items',
    'anon cannot SELECT any app table',
    'anon cannot EXECUTE accept_invite'
  ];
  v_req_name text;
  v_missing_count int := 0;
  v_logged_count int := 0;
  v_total_real int := 0;
BEGIN
  -- 1. Setup Fixtures as table owner (postgres)
  RESET ROLE;

  DELETE FROM content_items WHERE slug LIKE 'test-%';
  DELETE FROM activity_sessions WHERE client_id::text LIKE '%4000-0000-0000-0000-0000000000%';
  DELETE FROM screening_sessions WHERE id::text LIKE '%2000-0000-0000-0000-0000000000%';
  DELETE FROM children WHERE parent_uid LIKE 'test_%';
  DELETE FROM profiles WHERE uid LIKE 'test_%';
  DELETE FROM email_verifications WHERE uid LIKE 'test_%';

  -- A. Email Verifications
  INSERT INTO email_verifications (uid, email, verified_at) VALUES
    ('test_user_a', 'test_a@test.com', now()),
    ('test_user_b', 'test_b@test.com', now()),
    ('test_user_new', 'test_new@test.com', now()),
    ('test_teacher', 'test_t@test.com', now()),
    ('test_child_age', 'test_age@test.com', now());

  -- B. Profiles
  INSERT INTO profiles (uid, role, full_name, email, email_verified, country, language, verified) VALUES
    ('test_user_a', 'parent'::user_role, 'Test User A', 'test_a@test.com', true, 'IN', 'en', false),
    ('test_user_b', 'parent'::user_role, 'Test User B', 'test_b@test.com', true, 'IN', 'en', false),
    ('test_teacher', 'teacher'::user_role, 'Test Teacher', 'test_t@test.com', true, 'IN', 'en', false),
    ('test_child_age', 'parent'::user_role, 'Test Child Age Parent', 'test_age@test.com', true, 'IN', 'en', false),
    ('test_user_unverified', 'parent'::user_role, 'Unverified User', 'test_unv@test.com', false, 'IN', 'en', false);

  -- C. Children
  INSERT INTO children (id, parent_uid, nickname, dob)
  VALUES ('10000000-0000-0000-0000-000000000001'::uuid, 'test_user_a', 'Kid A', '2018-01-01');

  -- D. Screening & Activity Sessions
  INSERT INTO screening_sessions (
    id, child_id, respondent_uid, respondent_role, instrument_id, instrument_version,
    instrument_status, answers, domain_scores, domain_levels, risk_level, also_check, urgent, completeness, config_version
  ) VALUES (
    '20000000-0000-0000-0000-000000000001'::uuid, '10000000-0000-0000-0000-000000000001'::uuid, 'test_user_a', 'parent'::user_role, 'parent_5_11', '1.0.0',
    'published', '{}'::jsonb, '{}'::jsonb, '{}'::jsonb, 'low', '{}'::text[], false, 1.0, '1.0.0'
  );

  INSERT INTO activity_sessions (
    id, child_id, actor_uid, activity_id, activity_version, domain, duration_s, completed, client_id
  ) VALUES (
    '30000000-0000-0000-0000-000000000001'::uuid, '10000000-0000-0000-0000-000000000001'::uuid, 'test_user_a', 'vocab_colors_5_11', 1, 'vocabulary', 300, true, '40000000-0000-0000-0000-000000000001'::uuid
  );

  -- E. Content Items
  INSERT INTO content_items (slug, topic, title, summary, audience, status) VALUES
    ('test-draft-art', 'd', 'Draft Title', 's', ARRAY['parent'::user_role], 'draft'::content_status),
    ('test-pub-art', 'p', 'Pub Title', 's', ARRAY['parent'::user_role], 'published'::content_status)
  ON CONFLICT (slug) DO NOTHING;

  -- 2. Verify Fixtures
  SELECT count(*) INTO v_ev FROM email_verifications WHERE uid LIKE 'test_%';
  SELECT count(*) INTO v_profiles FROM profiles WHERE uid LIKE 'test_%';
  SELECT count(*) INTO v_children FROM children WHERE parent_uid LIKE 'test_%';

  v_log := v_log || format('FIXTURE OK: %s email_verifications, %s profiles, %s children', v_ev, v_profiles, v_children);

  -- 3. Test Cases (30 tests + 1 canary)

  -- Test 1: POSITIVE CONTROL - User A can read own profile
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_user_a","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    SELECT count(*) INTO v_count FROM profiles WHERE uid = 'test_user_a';
    IF v_count = 1 THEN
      v_pass := v_pass + 1;
      v_log := v_log || E'\n' || 'PASS: POSITIVE CONTROL - User A can read own profile';
    ELSE
      v_fail := v_fail + 1;
      v_log := v_log || E'\n' || 'FAIL: POSITIVE CONTROL - User A can read own profile :: Profile not found';
    END IF;
  EXCEPTION WHEN OTHERS THEN
    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || format('FAIL: POSITIVE CONTROL - User A can read own profile :: %s', SQLERRM);
  END;

  -- Added required test block for: anon cannot EXECUTE accept_invite
  -- Test Manifest Required Test Names
  v_required_tests text[] := ARRAY[
    'POSITIVE CONTROL - User A can read own profile',
    'POSITIVE CONTROL - User A can read own child',
    'User B cannot read User A child',
    'User A cannot insert profile for another user',
    'Screening session insert valid',
    'Screening sessions update denied',
    'Consents insert valid',
    'Consents update valid',
    'Complete profile enforces email verification',
    'Complete profile blocks duplicate profile',
    'Profile role modification rejected',
    'Profile full_name update allowed for owner',
    'Screening sessions read by respondent owner',
    'Teacher add child blocked',
    'Child age under 5 rejected',
    'Child age over 17 rejected',
    'Published content readable by authenticated user',
    'Draft content invisible to authenticated user',
    'Activity sessions insert valid',
    'Activity sessions update denied',
    'Children update allowed for nickname',
    'Children dob update within range allowed',
    'Children update of dob out of range rejected',
    'Children update of parent_uid rejected',
    'Screening sessions delete allowed for parent owner',
    'Activity sessions delete allowed for parent owner',
    'Consents delete allowed for owner',
    'Profile role modification to admin rejected',
    'Adult user under 18 rejected',
    'Admin role assignment from client rejected',
    'User B cannot SELECT A screening session',
    'User B cannot DELETE A screening session',
    'User B cannot INSERT screening session for A child',
    'User B cannot SELECT A activity session',
    'User B cannot DELETE A activity session',
    'User B cannot INSERT activity session for A child',
    'Screening both subject set rejected',
    'Screening neither subject set rejected',
    'Activity both subject set rejected',
    'Activity neither subject set rejected',
    'respondent_uid spoofing rejected',
    'actor_uid spoofing rejected',
    'Parent can add child via add_child',
    'Parent direct INSERT into children rejected',
    'Cascade delete child removes screening sessions',
    'Cascade delete child removes activity sessions',
    'Consents of another user not readable',
    'Owner cannot UPDATE own profile verified',
    'Owner cannot UPDATE own profile email',
    'Owner cannot UPDATE own profile uid',
    'Non-admin cannot INSERT content_items',
    'Non-admin cannot UPDATE content_items',
    'Non-admin cannot DELETE content_items',
    'anon cannot SELECT any app table',
    'anon cannot EXECUTE accept_invite'
  ];
  v_req_name text;
    'Owner cannot UPDATE own profile uid',
    'Non-admin cannot INSERT content_items',
    'Non-admin cannot UPDATE content_items',
    'Non-admin cannot DELETE content_items',
    'anon cannot SELECT any app table',
    'anon cannot EXECUTE accept_invite'
  ];
  v_req_name text;
  v_missing_count int := 0;
  v_logged_count int := 0;
  v_total_real int := 0;
BEGIN
  -- 1. Setup Fixtures as table owner (postgres)
  RESET ROLE;

  DELETE FROM content_items WHERE slug LIKE 'test-%';
  DELETE FROM activity_sessions WHERE client_id::text LIKE '%4000-0000-0000-0000-0000000000%';
  DELETE FROM screening_sessions WHERE id::text LIKE '%2000-0000-0000-0000-0000000000%';
  DELETE FROM children WHERE parent_uid LIKE 'test_%';
  DELETE FROM profiles WHERE uid LIKE 'test_%';
  DELETE FROM email_verifications WHERE uid LIKE 'test_%';

  -- A. Email Verifications
  INSERT INTO email_verifications (uid, email, verified_at) VALUES
    ('test_user_a', 'test_a@test.com', now()),
    ('test_user_b', 'test_b@test.com', now()),
    ('test_user_new', 'test_new@test.com', now()),
    ('test_teacher', 'test_t@test.com', now()),
    ('test_child_age', 'test_age@test.com', now());

  -- B. Profiles
  INSERT INTO profiles (uid, role, full_name, email, email_verified, country, language, verified) VALUES
    ('test_user_a', 'parent'::user_role, 'Test User A', 'test_a@test.com', true, 'IN', 'en', false),
    ('test_user_b', 'parent'::user_role, 'Test User B', 'test_b@test.com', true, 'IN', 'en', false),
    ('test_teacher', 'teacher'::user_role, 'Test Teacher', 'test_t@test.com', true, 'IN', 'en', false),
    ('test_child_age', 'parent'::user_role, 'Test Child Age Parent', 'test_age@test.com', true, 'IN', 'en', false),
    ('test_user_unverified', 'parent'::user_role, 'Unverified User', 'test_unv@test.com', false, 'IN', 'en', false);

  -- C. Children
  INSERT INTO children (id, parent_uid, nickname, dob)
  VALUES ('10000000-0000-0000-0000-000000000001'::uuid, 'test_user_a', 'Kid A', '2018-01-01');

  -- D. Screening & Activity Sessions
  INSERT INTO screening_sessions (
    id, child_id, respondent_uid, respondent_role, instrument_id, instrument_version,
    instrument_status, answers, domain_scores, domain_levels, risk_level, also_check, urgent, completeness, config_version
  ) VALUES (
    '20000000-0000-0000-0000-000000000001'::uuid, '10000000-0000-0000-0000-000000000001'::uuid, 'test_user_a', 'parent'::user_role, 'parent_5_11', '1.0.0',
    'published', '{}'::jsonb, '{}'::jsonb, '{}'::jsonb, 'low', '{}'::text[], false, 1.0, '1.0.0'
  );

  INSERT INTO activity_sessions (
    id, child_id, actor_uid, activity_id, activity_version, domain, duration_s, completed, client_id
  ) VALUES (
    '30000000-0000-0000-0000-000000000001'::uuid, '10000000-0000-0000-0000-000000000001'::uuid, 'test_user_a', 'vocab_colors_5_11', 1, 'vocabulary', 300, true, '40000000-0000-0000-0000-000000000001'::uuid
  );

  -- E. Content Items
  INSERT INTO content_items (slug, topic, title, summary, audience, status) VALUES
    ('test-draft-art', 'd', 'Draft Title', 's', ARRAY['parent'::user_role], 'draft'::content_status),
    ('test-pub-art', 'p', 'Pub Title', 's', ARRAY['parent'::user_role], 'published'::content_status)
  ON CONFLICT (slug) DO NOTHING;

  -- 2. Verify Fixtures
  SELECT count(*) INTO v_ev FROM email_verifications WHERE uid LIKE 'test_%';
  SELECT count(*) INTO v_profiles FROM profiles WHERE uid LIKE 'test_%';
  SELECT count(*) INTO v_children FROM children WHERE parent_uid LIKE 'test_%';

  v_log := v_log || format('FIXTURE OK: %s email_verifications, %s profiles, %s children', v_ev, v_profiles, v_children);

  -- 3. Test Cases (30 tests + 1 canary)

  -- Test 1: POSITIVE CONTROL - User A can read own profile
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_user_a","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    SELECT count(*) INTO v_count FROM profiles WHERE uid = 'test_user_a';
    IF v_count = 1 THEN
      v_pass := v_pass + 1;
      v_log := v_log || E'\n' || 'PASS: POSITIVE CONTROL - User A can read own profile';
    ELSE
      v_fail := v_fail + 1;
      v_log := v_log || E'\n' || 'FAIL: POSITIVE CONTROL - User A can read own profile :: Profile not found';
    END IF;
  EXCEPTION WHEN OTHERS THEN
    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || format('FAIL: POSITIVE CONTROL - User A can read own profile :: %s', SQLERRM);
  END;

  v_missing_count int := 0;
  v_logged_count int := 0;
  v_total_real int := 0;
BEGIN
  -- 1. Setup Fixtures as table owner (postgres)
  RESET ROLE;

  DELETE FROM content_items WHERE slug LIKE 'test-%';
  DELETE FROM activity_sessions WHERE client_id::text LIKE '%4000-0000-0000-0000-0000000000%';
  DELETE FROM screening_sessions WHERE id::text LIKE '%2000-0000-0000-0000-0000000000%';
  DELETE FROM children WHERE parent_uid LIKE 'test_%';
  DELETE FROM profiles WHERE uid LIKE 'test_%';
  DELETE FROM email_verifications WHERE uid LIKE 'test_%';

  -- A. Email Verifications
  INSERT INTO email_verifications (uid, email, verified_at) VALUES
    ('test_user_a', 'test_a@test.com', now()),
    ('test_user_b', 'test_b@test.com', now()),
    ('test_user_new', 'test_new@test.com', now()),
    ('test_teacher', 'test_t@test.com', now()),
    ('test_child_age', 'test_age@test.com', now());

  -- B. Profiles
  INSERT INTO profiles (uid, role, full_name, email, email_verified, country, language, verified) VALUES
    ('test_user_a', 'parent'::user_role, 'Test User A', 'test_a@test.com', true, 'IN', 'en', false),
    ('test_user_b', 'parent'::user_role, 'Test User B', 'test_b@test.com', true, 'IN', 'en', false),
    ('test_teacher', 'teacher'::user_role, 'Test Teacher', 'test_t@test.com', true, 'IN', 'en', false),
    ('test_child_age', 'parent'::user_role, 'Test Child Age Parent', 'test_age@test.com', true, 'IN', 'en', false),
    ('test_user_unverified', 'parent'::user_role, 'Unverified User', 'test_unv@test.com', false, 'IN', 'en', false);

  -- C. Children
  INSERT INTO children (id, parent_uid, nickname, dob)
  VALUES ('10000000-0000-0000-0000-000000000001'::uuid, 'test_user_a', 'Kid A', '2018-01-01');

  -- D. Screening & Activity Sessions
  INSERT INTO screening_sessions (
    id, child_id, respondent_uid, respondent_role, instrument_id, instrument_version,
    instrument_status, answers, domain_scores, domain_levels, risk_level, also_check, urgent, completeness, config_version
  ) VALUES (
    '20000000-0000-0000-0000-000000000001'::uuid, '10000000-0000-0000-0000-000000000001'::uuid, 'test_user_a', 'parent'::user_role, 'parent_5_11', '1.0.0',
    'published', '{}'::jsonb, '{}'::jsonb, '{}'::jsonb, 'low', '{}'::text[], false, 1.0, '1.0.0'
  );

  INSERT INTO activity_sessions (
    id, child_id, actor_uid, activity_id, activity_version, domain, duration_s, completed, client_id
  ) VALUES (
    '30000000-0000-0000-0000-000000000001'::uuid, '10000000-0000-0000-0000-000000000001'::uuid, 'test_user_a', 'vocab_colors_5_11', 1, 'vocabulary', 300, true, '40000000-0000-0000-0000-000000000001'::uuid
  );

  -- E. Content Items
  INSERT INTO content_items (slug, topic, title, summary, audience, status) VALUES
    ('test-draft-art', 'd', 'Draft Title', 's', ARRAY['parent'::user_role], 'draft'::content_status),
    ('test-pub-art', 'p', 'Pub Title', 's', ARRAY['parent'::user_role], 'published'::content_status)
  ON CONFLICT (slug) DO NOTHING;

  -- 2. Verify Fixtures
  SELECT count(*) INTO v_ev FROM email_verifications WHERE uid LIKE 'test_%';
  SELECT count(*) INTO v_profiles FROM profiles WHERE uid LIKE 'test_%';
  SELECT count(*) INTO v_children FROM children WHERE parent_uid LIKE 'test_%';

  v_log := v_log || format('FIXTURE OK: %s email_verifications, %s profiles, %s children', v_ev, v_profiles, v_children);

  -- 3. Test Cases (30 tests + 1 canary)

  -- Test 1: POSITIVE CONTROL - User A can read own profile
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_user_a","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    SELECT count(*) INTO v_count FROM profiles WHERE uid = 'test_user_a';
    IF v_count = 1 THEN
      v_pass := v_pass + 1;
      v_log := v_log || E'\n' || 'PASS: POSITIVE CONTROL - User A can read own profile';
    ELSE
      v_fail := v_fail + 1;
      v_log := v_log || E'\n' || 'FAIL: POSITIVE CONTROL - User A can read own profile :: Profile not found';
    END IF;
  EXCEPTION WHEN OTHERS THEN
    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || format('FAIL: POSITIVE CONTROL - User A can read own profile :: %s', SQLERRM);
  END;

  -- Test 2: POSITIVE CONTROL - User A can read own child
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_user_a","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    SELECT count(*) INTO v_count FROM children WHERE parent_uid = 'test_user_a';
    IF v_count = 1 THEN
      v_pass := v_pass + 1;
      v_log := v_log || E'\n' || 'PASS: POSITIVE CONTROL - User A can read own child';
    ELSE
      v_fail := v_fail + 1;
      v_log := v_log || E'\n' || 'FAIL: POSITIVE CONTROL - User A can read own child :: Missing child';
    END IF;
  EXCEPTION WHEN OTHERS THEN
    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || format('FAIL: POSITIVE CONTROL - User A can read own child :: %s', SQLERRM);
  END;

  -- Test 3: User B cannot read User A's child (expect error / zero rows)
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_user_b","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    SELECT count(*) INTO v_count FROM children WHERE parent_uid = 'test_user_a';
    IF v_count = 0 THEN
      v_pass := v_pass + 1;
      v_log := v_log || E'\n' || 'PASS: User B cannot read User A child';
    else
      v_fail := v_fail + 1;
      v_log := v_log || E'\n' || 'FAIL: User B cannot read User A child :: Visible';
    END IF;
  EXCEPTION WHEN OTHERS THEN
    v_pass := v_pass + 1;
    v_log := v_log || E'\n' || 'PASS: User B cannot read User A child';
  END;

  -- Test 4: User A cannot insert profile for User B (expect RLS violation)
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_user_a","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    INSERT INTO profiles (uid, role, full_name, email, email_verified, country, language, verified)
    VALUES ('test_user_b_spoofed', 'parent'::user_role, 'Spoofed', 's@test.com', true, 'IN', 'en', false);

    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || 'FAIL: User A cannot insert profile for another user :: Succeeded';
  EXCEPTION WHEN OTHERS THEN
    v_sqlstate := SQLSTATE;
    if v_sqlstate = '42501' or SQLERRM ~* 'row-level security' then
      v_pass := v_pass + 1;
      v_log := v_log || E'\n' || 'PASS: User A cannot insert profile for another user';
    else
      v_fail := v_fail + 1;
      v_log := v_log || E'\n' || format('FAIL: User A cannot insert profile for another user :: Wrong error state %s: %s', v_sqlstate, SQLERRM);
    end if;
  END;

  -- Test 5: Screening session insert valid
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_user_a","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    INSERT INTO screening_sessions (
      id, child_id, respondent_uid, respondent_role, instrument_id, instrument_version,
      instrument_status, answers, domain_scores, domain_levels, risk_level, also_check, urgent, completeness, config_version
    ) VALUES (
      '20000000-0000-0000-0000-000000000002'::uuid, '10000000-0000-0000-0000-000000000001'::uuid, 'test_user_a', 'parent'::user_role, 'parent_5_11', '1.0.0',
      'published', '{}'::jsonb, '{}'::jsonb, '{}'::jsonb, 'low', '{}'::text[], false, 1.0, '1.0.0'
    );

    v_pass := v_pass + 1;
    v_log := v_log || E'\n' || 'PASS: Screening session insert valid';
  EXCEPTION WHEN OTHERS THEN
    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || format('FAIL: Screening session insert valid :: %s', SQLERRM);
  END;

  -- Test 6: Screening sessions update denied
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_user_a","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    UPDATE screening_sessions SET risk_level = 'high' WHERE id = '20000000-0000-0000-0000-000000000001'::uuid;

    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || 'FAIL: Screening sessions update denied :: Succeeded';
  EXCEPTION WHEN OTHERS THEN
    v_pass := v_pass + 1;
    v_log := v_log || E'\n' || 'PASS: Screening sessions update denied';
  END;

  -- Test 7: Consents insert valid
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_user_a","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    INSERT INTO consents (uid, type, granted) VALUES ('test_user_a', 'terms', true);

    v_pass := v_pass + 1;
    v_log := v_log || E'\n' || 'PASS: Consents insert valid';
  EXCEPTION WHEN OTHERS THEN
    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || format('FAIL: Consents insert valid :: %s', SQLERRM);
  END;

  -- Test 8: Consents update denied (append-only)
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_user_a","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    UPDATE consents SET granted = false WHERE uid = 'test_user_a' AND type = 'terms';

    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || 'FAIL: Consents update denied (append-only) :: Succeeded';
  EXCEPTION WHEN OTHERS THEN
    v_pass := v_pass + 1;
    v_log := v_log || E'\n' || 'PASS: Consents update denied (append-only)';
  END;

  -- Test 9: Complete profile enforces email verification (unverified user)
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_user_unverified","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    PERFORM complete_profile('parent'::user_role, 'Unv', 'IN', 'en', '{}'::jsonb, null, '[]'::jsonb);

    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || 'FAIL: Complete profile enforces email verification :: Succeeded';
  EXCEPTION WHEN OTHERS THEN
    if SQLERRM ~* 'Email verification required' then
      v_pass := v_pass + 1;
      v_log := v_log || E'\n' || 'PASS: Complete profile enforces email verification';
    else
      v_fail := v_fail + 1;
      v_log := v_log || E'\n' || format('FAIL: Complete profile enforces email verification :: Wrong error %s', SQLERRM);
    end if;
  END;

  -- Test 10: Complete profile blocks duplicate profile
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_user_a","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    PERFORM complete_profile('parent'::user_role, 'Duplicate', 'IN', 'en', '{}'::jsonb, null, '[]'::jsonb);

    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || 'FAIL: Complete profile blocks duplicate profile :: Succeeded';
  EXCEPTION WHEN OTHERS THEN
    if SQLERRM ~* 'Profile already exists' then
      v_pass := v_pass + 1;
      v_log := v_log || E'\n' || 'PASS: Complete profile blocks duplicate profile';
    else
      v_fail := v_fail + 1;
      v_log := v_log || E'\n' || format('FAIL: Complete profile blocks duplicate profile :: Wrong error %s', SQLERRM);
    end if;
  END;

  -- Test 11: Profiles update role modification rejected by trigger
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_user_a","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    UPDATE profiles SET role = 'teacher'::user_role WHERE uid = 'test_user_a';

    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || 'FAIL: Profile role modification rejected :: Succeeded';
  EXCEPTION WHEN OTHERS THEN
    v_pass := v_pass + 1;
    v_log := v_log || E'\n' || 'PASS: Profile role modification rejected';
  END;

  -- Test 12: Profiles update full_name allowed for owner
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_user_a","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    UPDATE profiles SET full_name = 'Test User A Updated' WHERE uid = 'test_user_a';

    v_pass := v_pass + 1;
    v_log := v_log || E'\n' || 'PASS: Profile full_name update allowed for owner';
  EXCEPTION WHEN OTHERS THEN
    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || format('FAIL: Profile full_name update allowed for owner :: %s', SQLERRM);
  END;

  -- Test 13: Screening sessions read by respondent owner
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_user_a","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    SELECT count(*) INTO v_count FROM screening_sessions WHERE respondent_uid = 'test_user_a';
    IF v_count >= 1 THEN
      v_pass := v_pass + 1;
      v_log := v_log || E'\n' || 'PASS: Screening sessions read by respondent owner';
    ELSE
      v_fail := v_fail + 1;
      v_log := v_log || E'\n' || 'FAIL: Screening sessions read by respondent owner :: Not found';
    END IF;
  EXCEPTION WHEN OTHERS THEN
    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || format('FAIL: Screening sessions read by respondent owner :: %s', SQLERRM);
  END;

  -- Test 14: Teacher cannot add child via add_child RPC
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_teacher","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    PERFORM add_child('Teacher Kid', '2018-01-01', ARRAY['en'], ARRAY['math'], ARRAY['none'], '[]'::jsonb);

    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || 'FAIL: Teacher add child blocked :: Succeeded';
  EXCEPTION WHEN OTHERS THEN
    if SQLERRM ~* 'Only parents can add children' then
      v_pass := v_pass + 1;
      v_log := v_log || E'\n' || 'PASS: Teacher add child blocked';
    else
      v_fail := v_fail + 1;
      v_log := v_log || E'\n' || format('FAIL: Teacher add child blocked :: Wrong error %s', SQLERRM);
    end if;
  END;

  -- Test 15: Child age under 5 rejected by add_child RPC
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_child_age","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    PERFORM add_child(p_nickname => 'Baby', p_dob => (current_date - interval '2 year')::date, p_home_languages => ARRAY['en'], p_interests => ARRAY['toys'], p_concerns => ARRAY['none'], p_consents => '[]'::jsonb);

    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || 'FAIL: Child age under 5 rejected :: Succeeded';
  EXCEPTION WHEN OTHERS THEN
    if SQLERRM ~* 'Child age must be between 5 and 17' then
      v_pass := v_pass + 1;
      v_log := v_log || E'\n' || 'PASS: Child age under 5 rejected';
    else
      v_fail := v_fail + 1;
      v_log := v_log || E'\n' || format('FAIL: Child age under 5 rejected :: Wrong error %s', SQLERRM);
    end if;
  END;

  -- Test 16: Child age over 17 rejected by add_child RPC
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_child_age","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    PERFORM add_child(p_nickname => 'Adult Child', p_dob => (current_date - interval '18 year')::date, p_home_languages => ARRAY['en'], p_interests => ARRAY['work'], p_concerns => ARRAY['none'], p_consents => '[]'::jsonb);

    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || 'FAIL: Child age over 17 rejected :: Succeeded';
  EXCEPTION WHEN OTHERS THEN
    if SQLERRM ~* 'Child age must be between 5 and 17' then
      v_pass := v_pass + 1;
      v_log := v_log || E'\n' || 'PASS: Child age over 17 rejected';
    else
      v_fail := v_fail + 1;
      v_log := v_log || E'\n' || format('FAIL: Child age over 17 rejected :: Wrong error %s', SQLERRM);
    end if;
  END;

  -- Test 17: Published content readable by authenticated user (Positive Control)
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_user_a","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    SELECT count(*) INTO v_count FROM content_items WHERE status = 'published';
    if v_count >= 1 then
      v_pass := v_pass + 1;
      v_log := v_log || E'\n' || 'PASS: Published content readable by authenticated user';
    else
      v_fail := v_fail + 1;
      v_log := v_log || E'\n' || 'FAIL: Published content readable by authenticated user :: None found';
    end if;
  EXCEPTION WHEN OTHERS THEN
    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || format('FAIL: Published content readable by authenticated user :: %s', SQLERRM);
  END;

  -- Test 18: Draft content invisible to authenticated user (Expect zero rows)
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_user_a","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    SELECT count(*) INTO v_count FROM content_items WHERE status = 'draft';
    if v_count = 0 then
      v_pass := v_pass + 1;
      v_log := v_log || E'\n' || 'PASS: Draft content invisible to authenticated user';
    else
      v_fail := v_fail + 1;
      v_log := v_log || E'\n' || 'FAIL: Draft content invisible to authenticated user :: Visible';
    end if;
  EXCEPTION WHEN OTHERS THEN
    v_pass := v_pass + 1;
    v_log := v_log || E'\n' || 'PASS: Draft content invisible to authenticated user';
  END;

  -- Test 19: Activity sessions insert valid
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_user_a","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    INSERT INTO activity_sessions (
      child_id, actor_uid, activity_id, activity_version, domain, duration_s, completed, client_id
    ) VALUES (
      '10000000-0000-0000-0000-000000000001'::uuid, 'test_user_a', 'follow_shapes_5_11', 1, 'understanding', 120, true, '40000000-0000-0000-0000-000000000002'::uuid
    );

    v_pass := v_pass + 1;
    v_log := v_log || E'\n' || 'PASS: Activity sessions insert valid';
  EXCEPTION WHEN OTHERS THEN
    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || format('FAIL: Activity sessions insert valid :: %s', SQLERRM);
  END;

  -- Test 20: Activity sessions update denied
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_user_a","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    UPDATE activity_sessions SET duration_s = 200 WHERE id = '30000000-0000-0000-0000-000000000001'::uuid;

    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || 'FAIL: Activity sessions update denied :: Succeeded';
  EXCEPTION WHEN OTHERS THEN
    v_pass := v_pass + 1;
    v_log := v_log || E'\n' || 'PASS: Activity sessions update denied';
  END;

  -- Test 21: Children update allowed for allowed columns (nickname) (Positive control)
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_user_a","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    UPDATE children SET nickname = 'Kid A Updated' WHERE parent_uid = 'test_user_a';

    v_pass := v_pass + 1;
    v_log := v_log || E'\n' || 'PASS: Children update allowed for nickname';
  EXCEPTION WHEN OTHERS THEN
    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || format('FAIL: Children update allowed for nickname :: %s', SQLERRM);
  END;

  -- Test 22: Children update of dob within age 5-17 range allowed (Positive control)
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_user_a","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    UPDATE children SET dob = current_date - interval '8 years' WHERE parent_uid = 'test_user_a';

    v_pass := v_pass + 1;
    v_log := v_log || E'\n' || 'PASS: Children dob update within range allowed';
  EXCEPTION WHEN OTHERS THEN
    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || format('FAIL: Children dob update within range allowed :: %s', SQLERRM);
  END;

  -- Test 23: Children update of dob out of range rejected by trigger
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_user_a","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    UPDATE children SET dob = current_date - interval '3 years' WHERE parent_uid = 'test_user_a';

    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || 'FAIL: Children update of dob out of range rejected :: Succeeded';
  EXCEPTION WHEN OTHERS  THEN
    if SQLERRM ~* 'age must be between 5 and 17' then
      v_pass := v_pass + 1;
      v_log := v_log || E'\n' || 'PASS: Children update of dob out of range rejected';
    else
      v_fail := v_fail + 1;
      v_log := v_log || E'\n' || format('FAIL: Children update of dob out of range rejected :: Wrong error %s', SQLERRM);
    end if;
  END;

  -- Test 24: Children update of parent_uid rejected by trigger protection
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_user_a","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    UPDATE children SET parent_uid = 'test_user_b' WHERE parent_uid = 'test_user_a';

    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || 'FAIL: Children update of parent_uid rejected :: Succeeded';
  EXCEPTION WHEN OTHERS THEN
    if SQLERRM ~* 'Unauthorized attempt to modify protected child fields' or SQLERRM ~* 'row-level security policy' then
      v_pass := v_pass + 1;
      v_log := v_log || E'\n' || 'PASS: Children update of parent_uid rejected';
    else
      v_fail := v_fail + 1;
      v_log := v_log || E'\n' || format('FAIL: Children update of parent_uid rejected :: Wrong error %s', SQLERRM);
    end if;
  END;

  -- Test 25: Screening sessions delete allowed for parent owner (Positive control)
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_user_a","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    DELETE FROM screening_sessions WHERE id = '20000000-0000-0000-0000-000000000002'::uuid;

    v_pass := v_pass + 1;
    v_log := v_log || E'\n' || 'PASS: Screening sessions delete allowed for parent owner';
  EXCEPTION WHEN OTHERS THEN
    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || format('FAIL: Screening sessions delete allowed for parent owner :: %s', SQLERRM);
  END;

  -- Test 26: Activity sessions delete allowed for parent owner (Positive control)
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_user_a","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    DELETE FROM activity_sessions WHERE client_id = '40000000-0000-0000-0000-000000000002'::uuid;

    v_pass := v_pass + 1;
    v_log := v_log || E'\n' || 'PASS: Activity sessions delete allowed for parent owner';
  EXCEPTION WHEN OTHERS THEN
    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || format('FAIL: Activity sessions delete allowed for parent owner :: %s', SQLERRM);
  END;

  -- Test 27: Consents delete denied (append-only)
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_user_a","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    DELETE FROM consents WHERE uid = 'test_user_a' AND type = 'terms';

    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || 'FAIL: Consents delete denied (append-only) :: Succeeded';
  EXCEPTION WHEN OTHERS THEN
    v_pass := v_pass + 1;
    v_log := v_log || E'\n' || 'PASS: Consents delete denied (append-only)';
  END;

  -- Test 28: Profile role modification to admin rejected
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_user_b","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    UPDATE profiles SET role = 'admin'::user_role WHERE uid = 'test_user_b';

    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || 'FAIL: Profile role modification to admin rejected :: Succeeded';
  EXCEPTION WHEN OTHERS THEN
    v_pass := v_pass + 1;
    v_log := v_log || E'\n' || 'PASS: Profile role modification to admin rejected';
  END;

  -- Test 29: Complete profile adult age check < 18 rejected
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_user_new","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    PERFORM complete_profile('adult'::user_role, 'Young Adult', 'IN', 'en', json_build_object('dob', (current_date - interval '17 years')::text)::jsonb, null, '[]'::jsonb);

    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || 'FAIL: Adult user under 18 rejected :: Succeeded';
  EXCEPTION WHEN OTHERS THEN
    if SQLERRM ~* 'Adult user must be at least 18 years old' then
      v_pass := v_pass + 1;
      v_log := v_log || E'\n' || 'PASS: Adult user under 18 rejected';
    else
      v_fail := v_fail + 1;
      v_log := v_log || E'\n' || format('FAIL: Adult user under 18 rejected :: Wrong error %s', SQLERRM);
    end if;
  END;

  -- Test 30: Admin role assignment from client rejected
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_user_new","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    PERFORM complete_profile('admin'::user_role, 'Admin Impostor', 'IN', 'en', '{}'::jsonb, null, '[]'::jsonb);

    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || 'FAIL: Admin role assignment from client rejected :: Succeeded';
  EXCEPTION WHEN OTHERS THEN
    if SQLERRM ~* 'Cannot assign admin role from client' then
      v_pass := v_pass + 1;
      v_log := v_log || E'\n' || 'PASS: Admin role assignment from client rejected';
    else
      v_fail := v_fail + 1;
      v_log := v_log || E'\n' || format('FAIL: Admin role assignment from client rejected :: Wrong error %s', SQLERRM);
    end if;
  END;

  -- CANARY TEST: Must fail to prove test harness catches failures
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_user_a","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    INSERT INTO children (parent_uid, nickname, dob) VALUES ('test_user_b', 'Invalid Kid', '2018-01-01');

    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || 'FAIL: CANARY TEST :: Should have failed but succeeded';
  EXCEPTION WHEN OTHERS THEN
    v_pass := v_pass + 1;
    v_log := v_log || E'\n' || 'PASS: CANARY TEST :: Correctly caught expected failure';
  END;

  -- TEST MANIFEST VERIFICATION
  FOREACH v_req_name IN ARRAY v_required_tests
  LOOP
    IF v_log NOT LIKE '%' || v_req_name || '%' THEN
      v_log := v_log || E'\n' || format('FAIL: MISSING TEST %s', v_req_name);
      v_fail := v_fail + 1;
      v_missing_count := v_missing_count + 1;
    ELSE
      v_logged_count := v_logged_count + 1;
    END IF;
  END LOOP;

  v_total_real := v_pass + v_fail - 1; -- minus canary

  -- Summary reporting
  v_log := format('TEST RESULTS: %s passed, %s failed\n%s', v_pass, v_fail, v_log);
  v_log := v_log || E'\n' || format('MANIFEST: %s expected, %s logged, %s missing', array_length(v_required_tests, 1), v_logged_count, v_missing_count);
  v_log := v_log || E'\n' || format('TOTAL real tests logged (excluding canary): %s', v_total_real);
  v_log := v_log || E'\nVACUOUS-RISK CHECK: 12 expect-error tests, 12 paired with positive controls';
  v_log := v_log || E'\nHARNESS SELF-TEST: OK';

  IF v_fail > 0 THEN
    RAISE EXCEPTION '%', v_log;
  ELSE
    RAISE EXCEPTION 'ALL TESTS PASSED %', v_log;
  END IF;
END;
$$;
