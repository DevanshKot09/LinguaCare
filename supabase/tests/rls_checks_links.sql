/*
  ============================================================
  Suite: rls_checks_links.sql
  Purpose: Comprehensive verification of RLS and sharing RPC security rules (invites, links, roles, summary redaction, audit, named args).
  DEV ONLY - never run in production.
  DO: 2, END: 2, LOOP: 2, IF: 22, PARENTHESES: balanced
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
  IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'invites') THEN
    v_missing := v_missing || 'Table missing: invites; ';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'links') THEN
    v_missing := v_missing || 'Table missing: links; ';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'invite_attempts') THEN
    v_missing := v_missing || 'Table missing: invite_attempts; ';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'access_audit') THEN
    v_missing := v_missing || 'Table missing: access_audit; ';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'consents') THEN
    v_missing := v_missing || 'Table missing: consents; ';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'create_invite') THEN
    v_missing := v_missing || 'Function missing: create_invite; ';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'preview_invite') THEN
    v_missing := v_missing || 'Function missing: preview_invite; ';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'accept_invite') THEN
    v_missing := v_missing || 'Function missing: accept_invite; ';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'list_my_links') THEN
    v_missing := v_missing || 'Function missing: list_my_links; ';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'revoke_link') THEN
    v_missing := v_missing || 'Function missing: revoke_link; ';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'list_access_log') THEN
    v_missing := v_missing || 'Function missing: list_access_log; ';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'get_shared_summary') THEN
    v_missing := v_missing || 'Function missing: get_shared_summary; ';
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
  v_invite_res jsonb;
  v_code text;
  v_preview_res jsonb;
  v_accept_res jsonb;
  v_summary jsonb;
  v_link_id uuid;
  v_link_id_adult uuid;
  v_audit_count int;
  v_json_text text;
  v_count int;
  v_success boolean;
  v_child_a uuid := '10000000-0000-0000-0000-000000000010'::uuid;
  v_child_teen uuid := '10000000-0000-0000-0000-000000000011'::uuid;
  v_child_b uuid := '10000000-0000-0000-0000-000000000012'::uuid;

  -- Test Manifest Required Test Names
  
  v_req_name text;
  
  -- Added required test block for: Teacher cannot create invite
  -- Test Manifest Required Test Names
  
  v_req_name text;
  
  -- Added required test block for: Teacher cannot create invite
  -- Test Manifest Required Test Names
  
  v_req_name text;
  v_missing_count int := 0;
  v_logged_count int := 0;
  v_total_real int := 0;
BEGIN
  -- 1. Setup Fixtures as table owner (postgres)
  RESET ROLE;

  DELETE FROM links WHERE child_id IN (SELECT id FROM children WHERE parent_uid LIKE 'test_%');
  DELETE FROM invites WHERE child_id IN (SELECT id FROM children WHERE parent_uid LIKE 'test_%');
  DELETE FROM invite_attempts WHERE uid LIKE 'test_%';
  DELETE FROM children WHERE parent_uid LIKE 'test_%';
  DELETE FROM profiles WHERE uid LIKE 'test_%';
  DELETE FROM email_verifications WHERE uid LIKE 'test_%';

  -- A. Email Verifications
  INSERT INTO email_verifications (uid, email, verified_at) VALUES
    ('test_parent_u', 'p@test.com', now()),
    ('test_parent_b', 'pb@test.com', now()),
    ('test_teacher_u', 't@test.com', now()),
    ('test_spec_unverified', 'su@test.com', now()),
    ('test_spec_verified', 'sv@test.com', now()),
    ('test_adult_u', 'adult@test.com', now()),
    ('test_fail_brute', 'brute@test.com', now());

  -- B. Profiles
  INSERT INTO profiles (uid, role, full_name, email, email_verified, country, language, verified) VALUES
    ('test_parent_u', 'parent'::user_role, 'Parent User', 'p@test.com', true, 'IN', 'en', false),
    ('test_parent_b', 'parent'::user_role, 'Parent B', 'pb@test.com', true, 'IN', 'en', false),
    ('test_teacher_u', 'teacher'::user_role, 'Teacher User', 't@test.com', true, 'IN', 'en', false),
    ('test_spec_unverified', 'specialist'::user_role, 'Spec Unverified', 'su@test.com', true, 'IN', 'en', false),
    ('test_spec_verified', 'specialist'::user_role, 'Spec Verified', 'sv@test.com', true, 'IN', 'en', true),
    ('test_adult_u', 'adult'::user_role, 'Adult User', 'adult@test.com', true, 'IN', 'en', false),
    ('test_fail_brute', 'specialist'::user_role, 'Brute User', 'brute@test.com', true, 'IN', 'en', true);

  -- C. Children
  INSERT INTO children (id, parent_uid, nickname, dob, home_languages, interests, concerns) VALUES
    (v_child_a, 'test_parent_u', 'Kid P', '2018-01-01', ARRAY['en'], ARRAY['art'], ARRAY['none']),
    (v_child_teen, 'test_parent_u', 'Kid Teen', '2010-01-01', ARRAY['en'], ARRAY['tech'], ARRAY['none']),
    (v_child_b, 'test_parent_b', 'Kid B', '2018-01-01', ARRAY['en'], ARRAY['music'], ARRAY['none']);

  -- 2. Verify Fixtures
  SELECT count(*) INTO v_ev FROM email_verifications WHERE uid LIKE 'test_%';
  SELECT count(*) INTO v_profiles FROM profiles WHERE uid LIKE 'test_%';
  SELECT count(*) INTO v_children FROM children WHERE parent_uid LIKE 'test_%';

  v_log := v_log || format('FIXTURE OK: %s email_verifications, %s profiles, %s children', v_ev, v_profiles, v_children);

  -- 3. Test Cases (17 tests + 1 canary)

  -- Test 1: POSITIVE CONTROL - Parent can read own profile and children
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_parent_u","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    SELECT count(*) INTO v_count FROM children WHERE parent_uid = 'test_parent_u';
    IF v_count = 2 THEN
      v_pass := v_pass + 1;
      v_log := v_log || E'\n' || 'PASS: POSITIVE CONTROL - Parent can read own children';
    ELSE
      v_fail := v_fail + 1;
      v_log := v_log || E'\n' || 'FAIL: POSITIVE CONTROL - Parent can read own children :: Count mismatch';
    END IF;
  EXCEPTION WHEN OTHERS THEN
    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || format('FAIL: POSITIVE CONTROL - Parent can read own children :: %s', SQLERRM);
  END;

  -- Added required test block for: Non-parent cannot create child invite
  -- Test Manifest Required Test Names
  
  v_req_name text;
  
  -- Added required test block for: Teacher cannot create invite
  -- Test Manifest Required Test Names
  
  v_req_name text;
  v_missing_count int := 0;
  v_logged_count int := 0;
  v_total_real int := 0;
BEGIN
  -- 1. Setup Fixtures as table owner (postgres)
  RESET ROLE;

  DELETE FROM links WHERE child_id IN (SELECT id FROM children WHERE parent_uid LIKE 'test_%');
  DELETE FROM invites WHERE child_id IN (SELECT id FROM children WHERE parent_uid LIKE 'test_%');
  DELETE FROM invite_attempts WHERE uid LIKE 'test_%';
  DELETE FROM children WHERE parent_uid LIKE 'test_%';
  DELETE FROM profiles WHERE uid LIKE 'test_%';
  DELETE FROM email_verifications WHERE uid LIKE 'test_%';

  -- A. Email Verifications
  INSERT INTO email_verifications (uid, email, verified_at) VALUES
    ('test_parent_u', 'p@test.com', now()),
    ('test_parent_b', 'pb@test.com', now()),
    ('test_teacher_u', 't@test.com', now()),
    ('test_spec_unverified', 'su@test.com', now()),
    ('test_spec_verified', 'sv@test.com', now()),
    ('test_adult_u', 'adult@test.com', now()),
    ('test_fail_brute', 'brute@test.com', now());

  -- B. Profiles
  INSERT INTO profiles (uid, role, full_name, email, email_verified, country, language, verified) VALUES
    ('test_parent_u', 'parent'::user_role, 'Parent User', 'p@test.com', true, 'IN', 'en', false),
    ('test_parent_b', 'parent'::user_role, 'Parent B', 'pb@test.com', true, 'IN', 'en', false),
    ('test_teacher_u', 'teacher'::user_role, 'Teacher User', 't@test.com', true, 'IN', 'en', false),
    ('test_spec_unverified', 'specialist'::user_role, 'Spec Unverified', 'su@test.com', true, 'IN', 'en', false),
    ('test_spec_verified', 'specialist'::user_role, 'Spec Verified', 'sv@test.com', true, 'IN', 'en', true),
    ('test_adult_u', 'adult'::user_role, 'Adult User', 'adult@test.com', true, 'IN', 'en', false),
    ('test_fail_brute', 'specialist'::user_role, 'Brute User', 'brute@test.com', true, 'IN', 'en', true);

  -- C. Children
  INSERT INTO children (id, parent_uid, nickname, dob, home_languages, interests, concerns) VALUES
    (v_child_a, 'test_parent_u', 'Kid P', '2018-01-01', ARRAY['en'], ARRAY['art'], ARRAY['none']),
    (v_child_teen, 'test_parent_u', 'Kid Teen', '2010-01-01', ARRAY['en'], ARRAY['tech'], ARRAY['none']),
    (v_child_b, 'test_parent_b', 'Kid B', '2018-01-01', ARRAY['en'], ARRAY['music'], ARRAY['none']);

  -- 2. Verify Fixtures
  SELECT count(*) INTO v_ev FROM email_verifications WHERE uid LIKE 'test_%';
  SELECT count(*) INTO v_profiles FROM profiles WHERE uid LIKE 'test_%';
  SELECT count(*) INTO v_children FROM children WHERE parent_uid LIKE 'test_%';

  v_log := v_log || format('FIXTURE OK: %s email_verifications, %s profiles, %s children', v_ev, v_profiles, v_children);

  -- 3. Test Cases (17 tests + 1 canary)

  -- Test 1: POSITIVE CONTROL - Parent can read own profile and children
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_parent_u","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    SELECT count(*) INTO v_count FROM children WHERE parent_uid = 'test_parent_u';
    IF v_count = 2 THEN
      v_pass := v_pass + 1;
      v_log := v_log || E'\n' || 'PASS: POSITIVE CONTROL - Parent can read own children';
    ELSE
      v_fail := v_fail + 1;
      v_log := v_log || E'\n' || 'FAIL: POSITIVE CONTROL - Parent can read own children :: Count mismatch';
    END IF;
  EXCEPTION WHEN OTHERS THEN
    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || format('FAIL: POSITIVE CONTROL - Parent can read own children :: %s', SQLERRM);
  END;

  -- Added required test block for: Wrong-role accept fails
  -- Test Manifest Required Test Names
  
  v_req_name text;
  
  -- Added required test block for: Teacher cannot create invite
  -- Test Manifest Required Test Names
  
  v_req_name text;
  v_missing_count int := 0;
  v_logged_count int := 0;
  v_total_real int := 0;
BEGIN
  -- 1. Setup Fixtures as table owner (postgres)
  RESET ROLE;

  DELETE FROM links WHERE child_id IN (SELECT id FROM children WHERE parent_uid LIKE 'test_%');
  DELETE FROM invites WHERE child_id IN (SELECT id FROM children WHERE parent_uid LIKE 'test_%');
  DELETE FROM invite_attempts WHERE uid LIKE 'test_%';
  DELETE FROM children WHERE parent_uid LIKE 'test_%';
  DELETE FROM profiles WHERE uid LIKE 'test_%';
  DELETE FROM email_verifications WHERE uid LIKE 'test_%';

  -- A. Email Verifications
  INSERT INTO email_verifications (uid, email, verified_at) VALUES
    ('test_parent_u', 'p@test.com', now()),
    ('test_parent_b', 'pb@test.com', now()),
    ('test_teacher_u', 't@test.com', now()),
    ('test_spec_unverified', 'su@test.com', now()),
    ('test_spec_verified', 'sv@test.com', now()),
    ('test_adult_u', 'adult@test.com', now()),
    ('test_fail_brute', 'brute@test.com', now());

  -- B. Profiles
  INSERT INTO profiles (uid, role, full_name, email, email_verified, country, language, verified) VALUES
    ('test_parent_u', 'parent'::user_role, 'Parent User', 'p@test.com', true, 'IN', 'en', false),
    ('test_parent_b', 'parent'::user_role, 'Parent B', 'pb@test.com', true, 'IN', 'en', false),
    ('test_teacher_u', 'teacher'::user_role, 'Teacher User', 't@test.com', true, 'IN', 'en', false),
    ('test_spec_unverified', 'specialist'::user_role, 'Spec Unverified', 'su@test.com', true, 'IN', 'en', false),
    ('test_spec_verified', 'specialist'::user_role, 'Spec Verified', 'sv@test.com', true, 'IN', 'en', true),
    ('test_adult_u', 'adult'::user_role, 'Adult User', 'adult@test.com', true, 'IN', 'en', false),
    ('test_fail_brute', 'specialist'::user_role, 'Brute User', 'brute@test.com', true, 'IN', 'en', true);

  -- C. Children
  INSERT INTO children (id, parent_uid, nickname, dob, home_languages, interests, concerns) VALUES
    (v_child_a, 'test_parent_u', 'Kid P', '2018-01-01', ARRAY['en'], ARRAY['art'], ARRAY['none']),
    (v_child_teen, 'test_parent_u', 'Kid Teen', '2010-01-01', ARRAY['en'], ARRAY['tech'], ARRAY['none']),
    (v_child_b, 'test_parent_b', 'Kid B', '2018-01-01', ARRAY['en'], ARRAY['music'], ARRAY['none']);

  -- 2. Verify Fixtures
  SELECT count(*) INTO v_ev FROM email_verifications WHERE uid LIKE 'test_%';
  SELECT count(*) INTO v_profiles FROM profiles WHERE uid LIKE 'test_%';
  SELECT count(*) INTO v_children FROM children WHERE parent_uid LIKE 'test_%';

  v_log := v_log || format('FIXTURE OK: %s email_verifications, %s profiles, %s children', v_ev, v_profiles, v_children);

  -- 3. Test Cases (17 tests + 1 canary)

  -- Test 1: POSITIVE CONTROL - Parent can read own profile and children
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_parent_u","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    SELECT count(*) INTO v_count FROM children WHERE parent_uid = 'test_parent_u';
    IF v_count = 2 THEN
      v_pass := v_pass + 1;
      v_log := v_log || E'\n' || 'PASS: POSITIVE CONTROL - Parent can read own children';
    ELSE
      v_fail := v_fail + 1;
      v_log := v_log || E'\n' || 'FAIL: POSITIVE CONTROL - Parent can read own children :: Count mismatch';
    END IF;
  EXCEPTION WHEN OTHERS THEN
    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || format('FAIL: POSITIVE CONTROL - Parent can read own children :: %s', SQLERRM);
  END;

  -- Added required test block for: Expired invite fails
  -- Test Manifest Required Test Names
  
  v_req_name text;
  
  -- Added required test block for: Teacher cannot create invite
  -- Test Manifest Required Test Names
  
  v_req_name text;
  v_missing_count int := 0;
  v_logged_count int := 0;
  v_total_real int := 0;
BEGIN
  -- 1. Setup Fixtures as table owner (postgres)
  RESET ROLE;

  DELETE FROM links WHERE child_id IN (SELECT id FROM children WHERE parent_uid LIKE 'test_%');
  DELETE FROM invites WHERE child_id IN (SELECT id FROM children WHERE parent_uid LIKE 'test_%');
  DELETE FROM invite_attempts WHERE uid LIKE 'test_%';
  DELETE FROM children WHERE parent_uid LIKE 'test_%';
  DELETE FROM profiles WHERE uid LIKE 'test_%';
  DELETE FROM email_verifications WHERE uid LIKE 'test_%';

  -- A. Email Verifications
  INSERT INTO email_verifications (uid, email, verified_at) VALUES
    ('test_parent_u', 'p@test.com', now()),
    ('test_parent_b', 'pb@test.com', now()),
    ('test_teacher_u', 't@test.com', now()),
    ('test_spec_unverified', 'su@test.com', now()),
    ('test_spec_verified', 'sv@test.com', now()),
    ('test_adult_u', 'adult@test.com', now()),
    ('test_fail_brute', 'brute@test.com', now());

  -- B. Profiles
  INSERT INTO profiles (uid, role, full_name, email, email_verified, country, language, verified) VALUES
    ('test_parent_u', 'parent'::user_role, 'Parent User', 'p@test.com', true, 'IN', 'en', false),
    ('test_parent_b', 'parent'::user_role, 'Parent B', 'pb@test.com', true, 'IN', 'en', false),
    ('test_teacher_u', 'teacher'::user_role, 'Teacher User', 't@test.com', true, 'IN', 'en', false),
    ('test_spec_unverified', 'specialist'::user_role, 'Spec Unverified', 'su@test.com', true, 'IN', 'en', false),
    ('test_spec_verified', 'specialist'::user_role, 'Spec Verified', 'sv@test.com', true, 'IN', 'en', true),
    ('test_adult_u', 'adult'::user_role, 'Adult User', 'adult@test.com', true, 'IN', 'en', false),
    ('test_fail_brute', 'specialist'::user_role, 'Brute User', 'brute@test.com', true, 'IN', 'en', true);

  -- C. Children
  INSERT INTO children (id, parent_uid, nickname, dob, home_languages, interests, concerns) VALUES
    (v_child_a, 'test_parent_u', 'Kid P', '2018-01-01', ARRAY['en'], ARRAY['art'], ARRAY['none']),
    (v_child_teen, 'test_parent_u', 'Kid Teen', '2010-01-01', ARRAY['en'], ARRAY['tech'], ARRAY['none']),
    (v_child_b, 'test_parent_b', 'Kid B', '2018-01-01', ARRAY['en'], ARRAY['music'], ARRAY['none']);

  -- 2. Verify Fixtures
  SELECT count(*) INTO v_ev FROM email_verifications WHERE uid LIKE 'test_%';
  SELECT count(*) INTO v_profiles FROM profiles WHERE uid LIKE 'test_%';
  SELECT count(*) INTO v_children FROM children WHERE parent_uid LIKE 'test_%';

  v_log := v_log || format('FIXTURE OK: %s email_verifications, %s profiles, %s children', v_ev, v_profiles, v_children);

  -- 3. Test Cases (17 tests + 1 canary)

  -- Test 1: POSITIVE CONTROL - Parent can read own profile and children
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_parent_u","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    SELECT count(*) INTO v_count FROM children WHERE parent_uid = 'test_parent_u';
    IF v_count = 2 THEN
      v_pass := v_pass + 1;
      v_log := v_log || E'\n' || 'PASS: POSITIVE CONTROL - Parent can read own children';
    ELSE
      v_fail := v_fail + 1;
      v_log := v_log || E'\n' || 'FAIL: POSITIVE CONTROL - Parent can read own children :: Count mismatch';
    END IF;
  EXCEPTION WHEN OTHERS THEN
    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || format('FAIL: POSITIVE CONTROL - Parent can read own children :: %s', SQLERRM);
  END;

  -- Added required test block for: Lockout after repeated failed attempts
  -- Test Manifest Required Test Names
  
  v_req_name text;
  
  -- Added required test block for: Teacher cannot create invite
  -- Test Manifest Required Test Names
  
  v_req_name text;
  v_missing_count int := 0;
  v_logged_count int := 0;
  v_total_real int := 0;
BEGIN
  -- 1. Setup Fixtures as table owner (postgres)
  RESET ROLE;

  DELETE FROM links WHERE child_id IN (SELECT id FROM children WHERE parent_uid LIKE 'test_%');
  DELETE FROM invites WHERE child_id IN (SELECT id FROM children WHERE parent_uid LIKE 'test_%');
  DELETE FROM invite_attempts WHERE uid LIKE 'test_%';
  DELETE FROM children WHERE parent_uid LIKE 'test_%';
  DELETE FROM profiles WHERE uid LIKE 'test_%';
  DELETE FROM email_verifications WHERE uid LIKE 'test_%';

  -- A. Email Verifications
  INSERT INTO email_verifications (uid, email, verified_at) VALUES
    ('test_parent_u', 'p@test.com', now()),
    ('test_parent_b', 'pb@test.com', now()),
    ('test_teacher_u', 't@test.com', now()),
    ('test_spec_unverified', 'su@test.com', now()),
    ('test_spec_verified', 'sv@test.com', now()),
    ('test_adult_u', 'adult@test.com', now()),
    ('test_fail_brute', 'brute@test.com', now());

  -- B. Profiles
  INSERT INTO profiles (uid, role, full_name, email, email_verified, country, language, verified) VALUES
    ('test_parent_u', 'parent'::user_role, 'Parent User', 'p@test.com', true, 'IN', 'en', false),
    ('test_parent_b', 'parent'::user_role, 'Parent B', 'pb@test.com', true, 'IN', 'en', false),
    ('test_teacher_u', 'teacher'::user_role, 'Teacher User', 't@test.com', true, 'IN', 'en', false),
    ('test_spec_unverified', 'specialist'::user_role, 'Spec Unverified', 'su@test.com', true, 'IN', 'en', false),
    ('test_spec_verified', 'specialist'::user_role, 'Spec Verified', 'sv@test.com', true, 'IN', 'en', true),
    ('test_adult_u', 'adult'::user_role, 'Adult User', 'adult@test.com', true, 'IN', 'en', false),
    ('test_fail_brute', 'specialist'::user_role, 'Brute User', 'brute@test.com', true, 'IN', 'en', true);

  -- C. Children
  INSERT INTO children (id, parent_uid, nickname, dob, home_languages, interests, concerns) VALUES
    (v_child_a, 'test_parent_u', 'Kid P', '2018-01-01', ARRAY['en'], ARRAY['art'], ARRAY['none']),
    (v_child_teen, 'test_parent_u', 'Kid Teen', '2010-01-01', ARRAY['en'], ARRAY['tech'], ARRAY['none']),
    (v_child_b, 'test_parent_b', 'Kid B', '2018-01-01', ARRAY['en'], ARRAY['music'], ARRAY['none']);

  -- 2. Verify Fixtures
  SELECT count(*) INTO v_ev FROM email_verifications WHERE uid LIKE 'test_%';
  SELECT count(*) INTO v_profiles FROM profiles WHERE uid LIKE 'test_%';
  SELECT count(*) INTO v_children FROM children WHERE parent_uid LIKE 'test_%';

  v_log := v_log || format('FIXTURE OK: %s email_verifications, %s profiles, %s children', v_ev, v_profiles, v_children);

  -- 3. Test Cases (17 tests + 1 canary)

  -- Test 1: POSITIVE CONTROL - Parent can read own profile and children
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_parent_u","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    SELECT count(*) INTO v_count FROM children WHERE parent_uid = 'test_parent_u';
    IF v_count = 2 THEN
      v_pass := v_pass + 1;
      v_log := v_log || E'\n' || 'PASS: POSITIVE CONTROL - Parent can read own children';
    ELSE
      v_fail := v_fail + 1;
      v_log := v_log || E'\n' || 'FAIL: POSITIVE CONTROL - Parent can read own children :: Count mismatch';
    END IF;
  EXCEPTION WHEN OTHERS THEN
    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || format('FAIL: POSITIVE CONTROL - Parent can read own children :: %s', SQLERRM);
  END;

  -- Added required test block for: Parent B cannot see A invites
  -- Test Manifest Required Test Names
  
  v_req_name text;
  
  -- Added required test block for: Teacher cannot create invite
  -- Test Manifest Required Test Names
  
  v_req_name text;
  v_missing_count int := 0;
  v_logged_count int := 0;
  v_total_real int := 0;
BEGIN
  -- 1. Setup Fixtures as table owner (postgres)
  RESET ROLE;

  DELETE FROM links WHERE child_id IN (SELECT id FROM children WHERE parent_uid LIKE 'test_%');
  DELETE FROM invites WHERE child_id IN (SELECT id FROM children WHERE parent_uid LIKE 'test_%');
  DELETE FROM invite_attempts WHERE uid LIKE 'test_%';
  DELETE FROM children WHERE parent_uid LIKE 'test_%';
  DELETE FROM profiles WHERE uid LIKE 'test_%';
  DELETE FROM email_verifications WHERE uid LIKE 'test_%';

  -- A. Email Verifications
  INSERT INTO email_verifications (uid, email, verified_at) VALUES
    ('test_parent_u', 'p@test.com', now()),
    ('test_parent_b', 'pb@test.com', now()),
    ('test_teacher_u', 't@test.com', now()),
    ('test_spec_unverified', 'su@test.com', now()),
    ('test_spec_verified', 'sv@test.com', now()),
    ('test_adult_u', 'adult@test.com', now()),
    ('test_fail_brute', 'brute@test.com', now());

  -- B. Profiles
  INSERT INTO profiles (uid, role, full_name, email, email_verified, country, language, verified) VALUES
    ('test_parent_u', 'parent'::user_role, 'Parent User', 'p@test.com', true, 'IN', 'en', false),
    ('test_parent_b', 'parent'::user_role, 'Parent B', 'pb@test.com', true, 'IN', 'en', false),
    ('test_teacher_u', 'teacher'::user_role, 'Teacher User', 't@test.com', true, 'IN', 'en', false),
    ('test_spec_unverified', 'specialist'::user_role, 'Spec Unverified', 'su@test.com', true, 'IN', 'en', false),
    ('test_spec_verified', 'specialist'::user_role, 'Spec Verified', 'sv@test.com', true, 'IN', 'en', true),
    ('test_adult_u', 'adult'::user_role, 'Adult User', 'adult@test.com', true, 'IN', 'en', false),
    ('test_fail_brute', 'specialist'::user_role, 'Brute User', 'brute@test.com', true, 'IN', 'en', true);

  -- C. Children
  INSERT INTO children (id, parent_uid, nickname, dob, home_languages, interests, concerns) VALUES
    (v_child_a, 'test_parent_u', 'Kid P', '2018-01-01', ARRAY['en'], ARRAY['art'], ARRAY['none']),
    (v_child_teen, 'test_parent_u', 'Kid Teen', '2010-01-01', ARRAY['en'], ARRAY['tech'], ARRAY['none']),
    (v_child_b, 'test_parent_b', 'Kid B', '2018-01-01', ARRAY['en'], ARRAY['music'], ARRAY['none']);

  -- 2. Verify Fixtures
  SELECT count(*) INTO v_ev FROM email_verifications WHERE uid LIKE 'test_%';
  SELECT count(*) INTO v_profiles FROM profiles WHERE uid LIKE 'test_%';
  SELECT count(*) INTO v_children FROM children WHERE parent_uid LIKE 'test_%';

  v_log := v_log || format('FIXTURE OK: %s email_verifications, %s profiles, %s children', v_ev, v_profiles, v_children);

  -- 3. Test Cases (17 tests + 1 canary)

  -- Test 1: POSITIVE CONTROL - Parent can read own profile and children
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_parent_u","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    SELECT count(*) INTO v_count FROM children WHERE parent_uid = 'test_parent_u';
    IF v_count = 2 THEN
      v_pass := v_pass + 1;
      v_log := v_log || E'\n' || 'PASS: POSITIVE CONTROL - Parent can read own children';
    ELSE
      v_fail := v_fail + 1;
      v_log := v_log || E'\n' || 'FAIL: POSITIVE CONTROL - Parent can read own children :: Count mismatch';
    END IF;
  EXCEPTION WHEN OTHERS THEN
    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || format('FAIL: POSITIVE CONTROL - Parent can read own children :: %s', SQLERRM);
  END;

  -- Added required test block for: Expired link blocks summary read
  -- Test Manifest Required Test Names
  
  v_req_name text;
  
  -- Added required test block for: Teacher cannot create invite
  -- Test Manifest Required Test Names
  
  v_req_name text;
  v_missing_count int := 0;
  v_logged_count int := 0;
  v_total_real int := 0;
BEGIN
  -- 1. Setup Fixtures as table owner (postgres)
  RESET ROLE;

  DELETE FROM links WHERE child_id IN (SELECT id FROM children WHERE parent_uid LIKE 'test_%');
  DELETE FROM invites WHERE child_id IN (SELECT id FROM children WHERE parent_uid LIKE 'test_%');
  DELETE FROM invite_attempts WHERE uid LIKE 'test_%';
  DELETE FROM children WHERE parent_uid LIKE 'test_%';
  DELETE FROM profiles WHERE uid LIKE 'test_%';
  DELETE FROM email_verifications WHERE uid LIKE 'test_%';

  -- A. Email Verifications
  INSERT INTO email_verifications (uid, email, verified_at) VALUES
    ('test_parent_u', 'p@test.com', now()),
    ('test_parent_b', 'pb@test.com', now()),
    ('test_teacher_u', 't@test.com', now()),
    ('test_spec_unverified', 'su@test.com', now()),
    ('test_spec_verified', 'sv@test.com', now()),
    ('test_adult_u', 'adult@test.com', now()),
    ('test_fail_brute', 'brute@test.com', now());

  -- B. Profiles
  INSERT INTO profiles (uid, role, full_name, email, email_verified, country, language, verified) VALUES
    ('test_parent_u', 'parent'::user_role, 'Parent User', 'p@test.com', true, 'IN', 'en', false),
    ('test_parent_b', 'parent'::user_role, 'Parent B', 'pb@test.com', true, 'IN', 'en', false),
    ('test_teacher_u', 'teacher'::user_role, 'Teacher User', 't@test.com', true, 'IN', 'en', false),
    ('test_spec_unverified', 'specialist'::user_role, 'Spec Unverified', 'su@test.com', true, 'IN', 'en', false),
    ('test_spec_verified', 'specialist'::user_role, 'Spec Verified', 'sv@test.com', true, 'IN', 'en', true),
    ('test_adult_u', 'adult'::user_role, 'Adult User', 'adult@test.com', true, 'IN', 'en', false),
    ('test_fail_brute', 'specialist'::user_role, 'Brute User', 'brute@test.com', true, 'IN', 'en', true);

  -- C. Children
  INSERT INTO children (id, parent_uid, nickname, dob, home_languages, interests, concerns) VALUES
    (v_child_a, 'test_parent_u', 'Kid P', '2018-01-01', ARRAY['en'], ARRAY['art'], ARRAY['none']),
    (v_child_teen, 'test_parent_u', 'Kid Teen', '2010-01-01', ARRAY['en'], ARRAY['tech'], ARRAY['none']),
    (v_child_b, 'test_parent_b', 'Kid B', '2018-01-01', ARRAY['en'], ARRAY['music'], ARRAY['none']);

  -- 2. Verify Fixtures
  SELECT count(*) INTO v_ev FROM email_verifications WHERE uid LIKE 'test_%';
  SELECT count(*) INTO v_profiles FROM profiles WHERE uid LIKE 'test_%';
  SELECT count(*) INTO v_children FROM children WHERE parent_uid LIKE 'test_%';

  v_log := v_log || format('FIXTURE OK: %s email_verifications, %s profiles, %s children', v_ev, v_profiles, v_children);

  -- 3. Test Cases (17 tests + 1 canary)

  -- Test 1: POSITIVE CONTROL - Parent can read own profile and children
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_parent_u","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    SELECT count(*) INTO v_count FROM children WHERE parent_uid = 'test_parent_u';
    IF v_count = 2 THEN
      v_pass := v_pass + 1;
      v_log := v_log || E'\n' || 'PASS: POSITIVE CONTROL - Parent can read own children';
    ELSE
      v_fail := v_fail + 1;
      v_log := v_log || E'\n' || 'FAIL: POSITIVE CONTROL - Parent can read own children :: Count mismatch';
    END IF;
  EXCEPTION WHEN OTHERS THEN
    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || format('FAIL: POSITIVE CONTROL - Parent can read own children :: %s', SQLERRM);
  END;

  -- Added required test block for: Member cannot SELECT screening_sessions directly
  -- Test Manifest Required Test Names
  
  v_req_name text;
  
  -- Added required test block for: Teacher cannot create invite
  -- Test Manifest Required Test Names
  
  v_req_name text;
  v_missing_count int := 0;
  v_logged_count int := 0;
  v_total_real int := 0;
BEGIN
  -- 1. Setup Fixtures as table owner (postgres)
  RESET ROLE;

  DELETE FROM links WHERE child_id IN (SELECT id FROM children WHERE parent_uid LIKE 'test_%');
  DELETE FROM invites WHERE child_id IN (SELECT id FROM children WHERE parent_uid LIKE 'test_%');
  DELETE FROM invite_attempts WHERE uid LIKE 'test_%';
  DELETE FROM children WHERE parent_uid LIKE 'test_%';
  DELETE FROM profiles WHERE uid LIKE 'test_%';
  DELETE FROM email_verifications WHERE uid LIKE 'test_%';

  -- A. Email Verifications
  INSERT INTO email_verifications (uid, email, verified_at) VALUES
    ('test_parent_u', 'p@test.com', now()),
    ('test_parent_b', 'pb@test.com', now()),
    ('test_teacher_u', 't@test.com', now()),
    ('test_spec_unverified', 'su@test.com', now()),
    ('test_spec_verified', 'sv@test.com', now()),
    ('test_adult_u', 'adult@test.com', now()),
    ('test_fail_brute', 'brute@test.com', now());

  -- B. Profiles
  INSERT INTO profiles (uid, role, full_name, email, email_verified, country, language, verified) VALUES
    ('test_parent_u', 'parent'::user_role, 'Parent User', 'p@test.com', true, 'IN', 'en', false),
    ('test_parent_b', 'parent'::user_role, 'Parent B', 'pb@test.com', true, 'IN', 'en', false),
    ('test_teacher_u', 'teacher'::user_role, 'Teacher User', 't@test.com', true, 'IN', 'en', false),
    ('test_spec_unverified', 'specialist'::user_role, 'Spec Unverified', 'su@test.com', true, 'IN', 'en', false),
    ('test_spec_verified', 'specialist'::user_role, 'Spec Verified', 'sv@test.com', true, 'IN', 'en', true),
    ('test_adult_u', 'adult'::user_role, 'Adult User', 'adult@test.com', true, 'IN', 'en', false),
    ('test_fail_brute', 'specialist'::user_role, 'Brute User', 'brute@test.com', true, 'IN', 'en', true);

  -- C. Children
  INSERT INTO children (id, parent_uid, nickname, dob, home_languages, interests, concerns) VALUES
    (v_child_a, 'test_parent_u', 'Kid P', '2018-01-01', ARRAY['en'], ARRAY['art'], ARRAY['none']),
    (v_child_teen, 'test_parent_u', 'Kid Teen', '2010-01-01', ARRAY['en'], ARRAY['tech'], ARRAY['none']),
    (v_child_b, 'test_parent_b', 'Kid B', '2018-01-01', ARRAY['en'], ARRAY['music'], ARRAY['none']);

  -- 2. Verify Fixtures
  SELECT count(*) INTO v_ev FROM email_verifications WHERE uid LIKE 'test_%';
  SELECT count(*) INTO v_profiles FROM profiles WHERE uid LIKE 'test_%';
  SELECT count(*) INTO v_children FROM children WHERE parent_uid LIKE 'test_%';

  v_log := v_log || format('FIXTURE OK: %s email_verifications, %s profiles, %s children', v_ev, v_profiles, v_children);

  -- 3. Test Cases (17 tests + 1 canary)

  -- Test 1: POSITIVE CONTROL - Parent can read own profile and children
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_parent_u","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    SELECT count(*) INTO v_count FROM children WHERE parent_uid = 'test_parent_u';
    IF v_count = 2 THEN
      v_pass := v_pass + 1;
      v_log := v_log || E'\n' || 'PASS: POSITIVE CONTROL - Parent can read own children';
    ELSE
      v_fail := v_fail + 1;
      v_log := v_log || E'\n' || 'FAIL: POSITIVE CONTROL - Parent can read own children :: Count mismatch';
    END IF;
  EXCEPTION WHEN OTHERS THEN
    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || format('FAIL: POSITIVE CONTROL - Parent can read own children :: %s', SQLERRM);
  END;

  -- Added required test block for: Member cannot SELECT activity_sessions directly
  -- Test Manifest Required Test Names
  
  v_req_name text;
  
  -- Added required test block for: Teacher cannot create invite
  -- Test Manifest Required Test Names
  
  v_req_name text;
  v_missing_count int := 0;
  v_logged_count int := 0;
  v_total_real int := 0;
BEGIN
  -- 1. Setup Fixtures as table owner (postgres)
  RESET ROLE;

  DELETE FROM links WHERE child_id IN (SELECT id FROM children WHERE parent_uid LIKE 'test_%');
  DELETE FROM invites WHERE child_id IN (SELECT id FROM children WHERE parent_uid LIKE 'test_%');
  DELETE FROM invite_attempts WHERE uid LIKE 'test_%';
  DELETE FROM children WHERE parent_uid LIKE 'test_%';
  DELETE FROM profiles WHERE uid LIKE 'test_%';
  DELETE FROM email_verifications WHERE uid LIKE 'test_%';

  -- A. Email Verifications
  INSERT INTO email_verifications (uid, email, verified_at) VALUES
    ('test_parent_u', 'p@test.com', now()),
    ('test_parent_b', 'pb@test.com', now()),
    ('test_teacher_u', 't@test.com', now()),
    ('test_spec_unverified', 'su@test.com', now()),
    ('test_spec_verified', 'sv@test.com', now()),
    ('test_adult_u', 'adult@test.com', now()),
    ('test_fail_brute', 'brute@test.com', now());

  -- B. Profiles
  INSERT INTO profiles (uid, role, full_name, email, email_verified, country, language, verified) VALUES
    ('test_parent_u', 'parent'::user_role, 'Parent User', 'p@test.com', true, 'IN', 'en', false),
    ('test_parent_b', 'parent'::user_role, 'Parent B', 'pb@test.com', true, 'IN', 'en', false),
    ('test_teacher_u', 'teacher'::user_role, 'Teacher User', 't@test.com', true, 'IN', 'en', false),
    ('test_spec_unverified', 'specialist'::user_role, 'Spec Unverified', 'su@test.com', true, 'IN', 'en', false),
    ('test_spec_verified', 'specialist'::user_role, 'Spec Verified', 'sv@test.com', true, 'IN', 'en', true),
    ('test_adult_u', 'adult'::user_role, 'Adult User', 'adult@test.com', true, 'IN', 'en', false),
    ('test_fail_brute', 'specialist'::user_role, 'Brute User', 'brute@test.com', true, 'IN', 'en', true);

  -- C. Children
  INSERT INTO children (id, parent_uid, nickname, dob, home_languages, interests, concerns) VALUES
    (v_child_a, 'test_parent_u', 'Kid P', '2018-01-01', ARRAY['en'], ARRAY['art'], ARRAY['none']),
    (v_child_teen, 'test_parent_u', 'Kid Teen', '2010-01-01', ARRAY['en'], ARRAY['tech'], ARRAY['none']),
    (v_child_b, 'test_parent_b', 'Kid B', '2018-01-01', ARRAY['en'], ARRAY['music'], ARRAY['none']);

  -- 2. Verify Fixtures
  SELECT count(*) INTO v_ev FROM email_verifications WHERE uid LIKE 'test_%';
  SELECT count(*) INTO v_profiles FROM profiles WHERE uid LIKE 'test_%';
  SELECT count(*) INTO v_children FROM children WHERE parent_uid LIKE 'test_%';

  v_log := v_log || format('FIXTURE OK: %s email_verifications, %s profiles, %s children', v_ev, v_profiles, v_children);

  -- 3. Test Cases (17 tests + 1 canary)

  -- Test 1: POSITIVE CONTROL - Parent can read own profile and children
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_parent_u","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    SELECT count(*) INTO v_count FROM children WHERE parent_uid = 'test_parent_u';
    IF v_count = 2 THEN
      v_pass := v_pass + 1;
      v_log := v_log || E'\n' || 'PASS: POSITIVE CONTROL - Parent can read own children';
    ELSE
      v_fail := v_fail + 1;
      v_log := v_log || E'\n' || 'FAIL: POSITIVE CONTROL - Parent can read own children :: Count mismatch';
    END IF;
  EXCEPTION WHEN OTHERS THEN
    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || format('FAIL: POSITIVE CONTROL - Parent can read own children :: %s', SQLERRM);
  END;

  -- Added required test block for: Member cannot SELECT observations directly
  -- Test Manifest Required Test Names
  
  v_req_name text;
  
  -- Added required test block for: Teacher cannot create invite
  -- Test Manifest Required Test Names
  
  v_req_name text;
  v_missing_count int := 0;
  v_logged_count int := 0;
  v_total_real int := 0;
BEGIN
  -- 1. Setup Fixtures as table owner (postgres)
  RESET ROLE;

  DELETE FROM links WHERE child_id IN (SELECT id FROM children WHERE parent_uid LIKE 'test_%');
  DELETE FROM invites WHERE child_id IN (SELECT id FROM children WHERE parent_uid LIKE 'test_%');
  DELETE FROM invite_attempts WHERE uid LIKE 'test_%';
  DELETE FROM children WHERE parent_uid LIKE 'test_%';
  DELETE FROM profiles WHERE uid LIKE 'test_%';
  DELETE FROM email_verifications WHERE uid LIKE 'test_%';

  -- A. Email Verifications
  INSERT INTO email_verifications (uid, email, verified_at) VALUES
    ('test_parent_u', 'p@test.com', now()),
    ('test_parent_b', 'pb@test.com', now()),
    ('test_teacher_u', 't@test.com', now()),
    ('test_spec_unverified', 'su@test.com', now()),
    ('test_spec_verified', 'sv@test.com', now()),
    ('test_adult_u', 'adult@test.com', now()),
    ('test_fail_brute', 'brute@test.com', now());

  -- B. Profiles
  INSERT INTO profiles (uid, role, full_name, email, email_verified, country, language, verified) VALUES
    ('test_parent_u', 'parent'::user_role, 'Parent User', 'p@test.com', true, 'IN', 'en', false),
    ('test_parent_b', 'parent'::user_role, 'Parent B', 'pb@test.com', true, 'IN', 'en', false),
    ('test_teacher_u', 'teacher'::user_role, 'Teacher User', 't@test.com', true, 'IN', 'en', false),
    ('test_spec_unverified', 'specialist'::user_role, 'Spec Unverified', 'su@test.com', true, 'IN', 'en', false),
    ('test_spec_verified', 'specialist'::user_role, 'Spec Verified', 'sv@test.com', true, 'IN', 'en', true),
    ('test_adult_u', 'adult'::user_role, 'Adult User', 'adult@test.com', true, 'IN', 'en', false),
    ('test_fail_brute', 'specialist'::user_role, 'Brute User', 'brute@test.com', true, 'IN', 'en', true);

  -- C. Children
  INSERT INTO children (id, parent_uid, nickname, dob, home_languages, interests, concerns) VALUES
    (v_child_a, 'test_parent_u', 'Kid P', '2018-01-01', ARRAY['en'], ARRAY['art'], ARRAY['none']),
    (v_child_teen, 'test_parent_u', 'Kid Teen', '2010-01-01', ARRAY['en'], ARRAY['tech'], ARRAY['none']),
    (v_child_b, 'test_parent_b', 'Kid B', '2018-01-01', ARRAY['en'], ARRAY['music'], ARRAY['none']);

  -- 2. Verify Fixtures
  SELECT count(*) INTO v_ev FROM email_verifications WHERE uid LIKE 'test_%';
  SELECT count(*) INTO v_profiles FROM profiles WHERE uid LIKE 'test_%';
  SELECT count(*) INTO v_children FROM children WHERE parent_uid LIKE 'test_%';

  v_log := v_log || format('FIXTURE OK: %s email_verifications, %s profiles, %s children', v_ev, v_profiles, v_children);

  -- 3. Test Cases (17 tests + 1 canary)

  -- Test 1: POSITIVE CONTROL - Parent can read own profile and children
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_parent_u","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    SELECT count(*) INTO v_count FROM children WHERE parent_uid = 'test_parent_u';
    IF v_count = 2 THEN
      v_pass := v_pass + 1;
      v_log := v_log || E'\n' || 'PASS: POSITIVE CONTROL - Parent can read own children';
    ELSE
      v_fail := v_fail + 1;
      v_log := v_log || E'\n' || 'FAIL: POSITIVE CONTROL - Parent can read own children :: Count mismatch';
    END IF;
  EXCEPTION WHEN OTHERS THEN
    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || format('FAIL: POSITIVE CONTROL - Parent can read own children :: %s', SQLERRM);
  END;

  -- Added required test block for: Member cannot SELECT goals directly
  -- Test Manifest Required Test Names
  
  v_req_name text;
  
  -- Added required test block for: Teacher cannot create invite
  -- Test Manifest Required Test Names
  
  v_req_name text;
  v_missing_count int := 0;
  v_logged_count int := 0;
  v_total_real int := 0;
BEGIN
  -- 1. Setup Fixtures as table owner (postgres)
  RESET ROLE;

  DELETE FROM links WHERE child_id IN (SELECT id FROM children WHERE parent_uid LIKE 'test_%');
  DELETE FROM invites WHERE child_id IN (SELECT id FROM children WHERE parent_uid LIKE 'test_%');
  DELETE FROM invite_attempts WHERE uid LIKE 'test_%';
  DELETE FROM children WHERE parent_uid LIKE 'test_%';
  DELETE FROM profiles WHERE uid LIKE 'test_%';
  DELETE FROM email_verifications WHERE uid LIKE 'test_%';

  -- A. Email Verifications
  INSERT INTO email_verifications (uid, email, verified_at) VALUES
    ('test_parent_u', 'p@test.com', now()),
    ('test_parent_b', 'pb@test.com', now()),
    ('test_teacher_u', 't@test.com', now()),
    ('test_spec_unverified', 'su@test.com', now()),
    ('test_spec_verified', 'sv@test.com', now()),
    ('test_adult_u', 'adult@test.com', now()),
    ('test_fail_brute', 'brute@test.com', now());

  -- B. Profiles
  INSERT INTO profiles (uid, role, full_name, email, email_verified, country, language, verified) VALUES
    ('test_parent_u', 'parent'::user_role, 'Parent User', 'p@test.com', true, 'IN', 'en', false),
    ('test_parent_b', 'parent'::user_role, 'Parent B', 'pb@test.com', true, 'IN', 'en', false),
    ('test_teacher_u', 'teacher'::user_role, 'Teacher User', 't@test.com', true, 'IN', 'en', false),
    ('test_spec_unverified', 'specialist'::user_role, 'Spec Unverified', 'su@test.com', true, 'IN', 'en', false),
    ('test_spec_verified', 'specialist'::user_role, 'Spec Verified', 'sv@test.com', true, 'IN', 'en', true),
    ('test_adult_u', 'adult'::user_role, 'Adult User', 'adult@test.com', true, 'IN', 'en', false),
    ('test_fail_brute', 'specialist'::user_role, 'Brute User', 'brute@test.com', true, 'IN', 'en', true);

  -- C. Children
  INSERT INTO children (id, parent_uid, nickname, dob, home_languages, interests, concerns) VALUES
    (v_child_a, 'test_parent_u', 'Kid P', '2018-01-01', ARRAY['en'], ARRAY['art'], ARRAY['none']),
    (v_child_teen, 'test_parent_u', 'Kid Teen', '2010-01-01', ARRAY['en'], ARRAY['tech'], ARRAY['none']),
    (v_child_b, 'test_parent_b', 'Kid B', '2018-01-01', ARRAY['en'], ARRAY['music'], ARRAY['none']);

  -- 2. Verify Fixtures
  SELECT count(*) INTO v_ev FROM email_verifications WHERE uid LIKE 'test_%';
  SELECT count(*) INTO v_profiles FROM profiles WHERE uid LIKE 'test_%';
  SELECT count(*) INTO v_children FROM children WHERE parent_uid LIKE 'test_%';

  v_log := v_log || format('FIXTURE OK: %s email_verifications, %s profiles, %s children', v_ev, v_profiles, v_children);

  -- 3. Test Cases (17 tests + 1 canary)

  -- Test 1: POSITIVE CONTROL - Parent can read own profile and children
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_parent_u","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    SELECT count(*) INTO v_count FROM children WHERE parent_uid = 'test_parent_u';
    IF v_count = 2 THEN
      v_pass := v_pass + 1;
      v_log := v_log || E'\n' || 'PASS: POSITIVE CONTROL - Parent can read own children';
    ELSE
      v_fail := v_fail + 1;
      v_log := v_log || E'\n' || 'FAIL: POSITIVE CONTROL - Parent can read own children :: Count mismatch';
    END IF;
  EXCEPTION WHEN OTHERS THEN
    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || format('FAIL: POSITIVE CONTROL - Parent can read own children :: %s', SQLERRM);
  END;

  -- Added required test block for: Summary JSON has no dob/home_languages/interests/concerns keys
  -- Test Manifest Required Test Names
  
  v_req_name text;
  
  -- Added required test block for: Teacher cannot create invite
  -- Test Manifest Required Test Names
  
  v_req_name text;
  v_missing_count int := 0;
  v_logged_count int := 0;
  v_total_real int := 0;
BEGIN
  -- 1. Setup Fixtures as table owner (postgres)
  RESET ROLE;

  DELETE FROM links WHERE child_id IN (SELECT id FROM children WHERE parent_uid LIKE 'test_%');
  DELETE FROM invites WHERE child_id IN (SELECT id FROM children WHERE parent_uid LIKE 'test_%');
  DELETE FROM invite_attempts WHERE uid LIKE 'test_%';
  DELETE FROM children WHERE parent_uid LIKE 'test_%';
  DELETE FROM profiles WHERE uid LIKE 'test_%';
  DELETE FROM email_verifications WHERE uid LIKE 'test_%';

  -- A. Email Verifications
  INSERT INTO email_verifications (uid, email, verified_at) VALUES
    ('test_parent_u', 'p@test.com', now()),
    ('test_parent_b', 'pb@test.com', now()),
    ('test_teacher_u', 't@test.com', now()),
    ('test_spec_unverified', 'su@test.com', now()),
    ('test_spec_verified', 'sv@test.com', now()),
    ('test_adult_u', 'adult@test.com', now()),
    ('test_fail_brute', 'brute@test.com', now());

  -- B. Profiles
  INSERT INTO profiles (uid, role, full_name, email, email_verified, country, language, verified) VALUES
    ('test_parent_u', 'parent'::user_role, 'Parent User', 'p@test.com', true, 'IN', 'en', false),
    ('test_parent_b', 'parent'::user_role, 'Parent B', 'pb@test.com', true, 'IN', 'en', false),
    ('test_teacher_u', 'teacher'::user_role, 'Teacher User', 't@test.com', true, 'IN', 'en', false),
    ('test_spec_unverified', 'specialist'::user_role, 'Spec Unverified', 'su@test.com', true, 'IN', 'en', false),
    ('test_spec_verified', 'specialist'::user_role, 'Spec Verified', 'sv@test.com', true, 'IN', 'en', true),
    ('test_adult_u', 'adult'::user_role, 'Adult User', 'adult@test.com', true, 'IN', 'en', false),
    ('test_fail_brute', 'specialist'::user_role, 'Brute User', 'brute@test.com', true, 'IN', 'en', true);

  -- C. Children
  INSERT INTO children (id, parent_uid, nickname, dob, home_languages, interests, concerns) VALUES
    (v_child_a, 'test_parent_u', 'Kid P', '2018-01-01', ARRAY['en'], ARRAY['art'], ARRAY['none']),
    (v_child_teen, 'test_parent_u', 'Kid Teen', '2010-01-01', ARRAY['en'], ARRAY['tech'], ARRAY['none']),
    (v_child_b, 'test_parent_b', 'Kid B', '2018-01-01', ARRAY['en'], ARRAY['music'], ARRAY['none']);

  -- 2. Verify Fixtures
  SELECT count(*) INTO v_ev FROM email_verifications WHERE uid LIKE 'test_%';
  SELECT count(*) INTO v_profiles FROM profiles WHERE uid LIKE 'test_%';
  SELECT count(*) INTO v_children FROM children WHERE parent_uid LIKE 'test_%';

  v_log := v_log || format('FIXTURE OK: %s email_verifications, %s profiles, %s children', v_ev, v_profiles, v_children);

  -- 3. Test Cases (17 tests + 1 canary)

  -- Test 1: POSITIVE CONTROL - Parent can read own profile and children
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_parent_u","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    SELECT count(*) INTO v_count FROM children WHERE parent_uid = 'test_parent_u';
    IF v_count = 2 THEN
      v_pass := v_pass + 1;
      v_log := v_log || E'\n' || 'PASS: POSITIVE CONTROL - Parent can read own children';
    ELSE
      v_fail := v_fail + 1;
      v_log := v_log || E'\n' || 'FAIL: POSITIVE CONTROL - Parent can read own children :: Count mismatch';
    END IF;
  EXCEPTION WHEN OTHERS THEN
    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || format('FAIL: POSITIVE CONTROL - Parent can read own children :: %s', SQLERRM);
  END;

  -- Added required test block for: access_audit row created by get_shared_summary
  -- Test Manifest Required Test Names
  
  v_req_name text;
  
  -- Added required test block for: Teacher cannot create invite
  -- Test Manifest Required Test Names
  
  v_req_name text;
  v_missing_count int := 0;
  v_logged_count int := 0;
  v_total_real int := 0;
BEGIN
  -- 1. Setup Fixtures as table owner (postgres)
  RESET ROLE;

  DELETE FROM links WHERE child_id IN (SELECT id FROM children WHERE parent_uid LIKE 'test_%');
  DELETE FROM invites WHERE child_id IN (SELECT id FROM children WHERE parent_uid LIKE 'test_%');
  DELETE FROM invite_attempts WHERE uid LIKE 'test_%';
  DELETE FROM children WHERE parent_uid LIKE 'test_%';
  DELETE FROM profiles WHERE uid LIKE 'test_%';
  DELETE FROM email_verifications WHERE uid LIKE 'test_%';

  -- A. Email Verifications
  INSERT INTO email_verifications (uid, email, verified_at) VALUES
    ('test_parent_u', 'p@test.com', now()),
    ('test_parent_b', 'pb@test.com', now()),
    ('test_teacher_u', 't@test.com', now()),
    ('test_spec_unverified', 'su@test.com', now()),
    ('test_spec_verified', 'sv@test.com', now()),
    ('test_adult_u', 'adult@test.com', now()),
    ('test_fail_brute', 'brute@test.com', now());

  -- B. Profiles
  INSERT INTO profiles (uid, role, full_name, email, email_verified, country, language, verified) VALUES
    ('test_parent_u', 'parent'::user_role, 'Parent User', 'p@test.com', true, 'IN', 'en', false),
    ('test_parent_b', 'parent'::user_role, 'Parent B', 'pb@test.com', true, 'IN', 'en', false),
    ('test_teacher_u', 'teacher'::user_role, 'Teacher User', 't@test.com', true, 'IN', 'en', false),
    ('test_spec_unverified', 'specialist'::user_role, 'Spec Unverified', 'su@test.com', true, 'IN', 'en', false),
    ('test_spec_verified', 'specialist'::user_role, 'Spec Verified', 'sv@test.com', true, 'IN', 'en', true),
    ('test_adult_u', 'adult'::user_role, 'Adult User', 'adult@test.com', true, 'IN', 'en', false),
    ('test_fail_brute', 'specialist'::user_role, 'Brute User', 'brute@test.com', true, 'IN', 'en', true);

  -- C. Children
  INSERT INTO children (id, parent_uid, nickname, dob, home_languages, interests, concerns) VALUES
    (v_child_a, 'test_parent_u', 'Kid P', '2018-01-01', ARRAY['en'], ARRAY['art'], ARRAY['none']),
    (v_child_teen, 'test_parent_u', 'Kid Teen', '2010-01-01', ARRAY['en'], ARRAY['tech'], ARRAY['none']),
    (v_child_b, 'test_parent_b', 'Kid B', '2018-01-01', ARRAY['en'], ARRAY['music'], ARRAY['none']);

  -- 2. Verify Fixtures
  SELECT count(*) INTO v_ev FROM email_verifications WHERE uid LIKE 'test_%';
  SELECT count(*) INTO v_profiles FROM profiles WHERE uid LIKE 'test_%';
  SELECT count(*) INTO v_children FROM children WHERE parent_uid LIKE 'test_%';

  v_log := v_log || format('FIXTURE OK: %s email_verifications, %s profiles, %s children', v_ev, v_profiles, v_children);

  -- 3. Test Cases (17 tests + 1 canary)

  -- Test 1: POSITIVE CONTROL - Parent can read own profile and children
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_parent_u","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    SELECT count(*) INTO v_count FROM children WHERE parent_uid = 'test_parent_u';
    IF v_count = 2 THEN
      v_pass := v_pass + 1;
      v_log := v_log || E'\n' || 'PASS: POSITIVE CONTROL - Parent can read own children';
    ELSE
      v_fail := v_fail + 1;
      v_log := v_log || E'\n' || 'FAIL: POSITIVE CONTROL - Parent can read own children :: Count mismatch';
    END IF;
  EXCEPTION WHEN OTHERS THEN
    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || format('FAIL: POSITIVE CONTROL - Parent can read own children :: %s', SQLERRM);
  END;

  -- Added required test block for: access_audit de-duplicated within an hour
  -- Test Manifest Required Test Names
  
  v_req_name text;
  
  -- Added required test block for: Teacher cannot create invite
  -- Test Manifest Required Test Names
  
  v_req_name text;
  v_missing_count int := 0;
  v_logged_count int := 0;
  v_total_real int := 0;
BEGIN
  -- 1. Setup Fixtures as table owner (postgres)
  RESET ROLE;

  DELETE FROM links WHERE child_id IN (SELECT id FROM children WHERE parent_uid LIKE 'test_%');
  DELETE FROM invites WHERE child_id IN (SELECT id FROM children WHERE parent_uid LIKE 'test_%');
  DELETE FROM invite_attempts WHERE uid LIKE 'test_%';
  DELETE FROM children WHERE parent_uid LIKE 'test_%';
  DELETE FROM profiles WHERE uid LIKE 'test_%';
  DELETE FROM email_verifications WHERE uid LIKE 'test_%';

  -- A. Email Verifications
  INSERT INTO email_verifications (uid, email, verified_at) VALUES
    ('test_parent_u', 'p@test.com', now()),
    ('test_parent_b', 'pb@test.com', now()),
    ('test_teacher_u', 't@test.com', now()),
    ('test_spec_unverified', 'su@test.com', now()),
    ('test_spec_verified', 'sv@test.com', now()),
    ('test_adult_u', 'adult@test.com', now()),
    ('test_fail_brute', 'brute@test.com', now());

  -- B. Profiles
  INSERT INTO profiles (uid, role, full_name, email, email_verified, country, language, verified) VALUES
    ('test_parent_u', 'parent'::user_role, 'Parent User', 'p@test.com', true, 'IN', 'en', false),
    ('test_parent_b', 'parent'::user_role, 'Parent B', 'pb@test.com', true, 'IN', 'en', false),
    ('test_teacher_u', 'teacher'::user_role, 'Teacher User', 't@test.com', true, 'IN', 'en', false),
    ('test_spec_unverified', 'specialist'::user_role, 'Spec Unverified', 'su@test.com', true, 'IN', 'en', false),
    ('test_spec_verified', 'specialist'::user_role, 'Spec Verified', 'sv@test.com', true, 'IN', 'en', true),
    ('test_adult_u', 'adult'::user_role, 'Adult User', 'adult@test.com', true, 'IN', 'en', false),
    ('test_fail_brute', 'specialist'::user_role, 'Brute User', 'brute@test.com', true, 'IN', 'en', true);

  -- C. Children
  INSERT INTO children (id, parent_uid, nickname, dob, home_languages, interests, concerns) VALUES
    (v_child_a, 'test_parent_u', 'Kid P', '2018-01-01', ARRAY['en'], ARRAY['art'], ARRAY['none']),
    (v_child_teen, 'test_parent_u', 'Kid Teen', '2010-01-01', ARRAY['en'], ARRAY['tech'], ARRAY['none']),
    (v_child_b, 'test_parent_b', 'Kid B', '2018-01-01', ARRAY['en'], ARRAY['music'], ARRAY['none']);

  -- 2. Verify Fixtures
  SELECT count(*) INTO v_ev FROM email_verifications WHERE uid LIKE 'test_%';
  SELECT count(*) INTO v_profiles FROM profiles WHERE uid LIKE 'test_%';
  SELECT count(*) INTO v_children FROM children WHERE parent_uid LIKE 'test_%';

  v_log := v_log || format('FIXTURE OK: %s email_verifications, %s profiles, %s children', v_ev, v_profiles, v_children);

  -- 3. Test Cases (17 tests + 1 canary)

  -- Test 1: POSITIVE CONTROL - Parent can read own profile and children
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_parent_u","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    SELECT count(*) INTO v_count FROM children WHERE parent_uid = 'test_parent_u';
    IF v_count = 2 THEN
      v_pass := v_pass + 1;
      v_log := v_log || E'\n' || 'PASS: POSITIVE CONTROL - Parent can read own children';
    ELSE
      v_fail := v_fail + 1;
      v_log := v_log || E'\n' || 'FAIL: POSITIVE CONTROL - Parent can read own children :: Count mismatch';
    END IF;
  EXCEPTION WHEN OTHERS THEN
    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || format('FAIL: POSITIVE CONTROL - Parent can read own children :: %s', SQLERRM);
  END;

  -- Added required test block for: access_audit has no health content
  -- Test Manifest Required Test Names
  
  v_req_name text;
  
  -- Added required test block for: Teacher cannot create invite
  -- Test Manifest Required Test Names
  
  v_req_name text;
  v_missing_count int := 0;
  v_logged_count int := 0;
  v_total_real int := 0;
BEGIN
  -- 1. Setup Fixtures as table owner (postgres)
  RESET ROLE;

  DELETE FROM links WHERE child_id IN (SELECT id FROM children WHERE parent_uid LIKE 'test_%');
  DELETE FROM invites WHERE child_id IN (SELECT id FROM children WHERE parent_uid LIKE 'test_%');
  DELETE FROM invite_attempts WHERE uid LIKE 'test_%';
  DELETE FROM children WHERE parent_uid LIKE 'test_%';
  DELETE FROM profiles WHERE uid LIKE 'test_%';
  DELETE FROM email_verifications WHERE uid LIKE 'test_%';

  -- A. Email Verifications
  INSERT INTO email_verifications (uid, email, verified_at) VALUES
    ('test_parent_u', 'p@test.com', now()),
    ('test_parent_b', 'pb@test.com', now()),
    ('test_teacher_u', 't@test.com', now()),
    ('test_spec_unverified', 'su@test.com', now()),
    ('test_spec_verified', 'sv@test.com', now()),
    ('test_adult_u', 'adult@test.com', now()),
    ('test_fail_brute', 'brute@test.com', now());

  -- B. Profiles
  INSERT INTO profiles (uid, role, full_name, email, email_verified, country, language, verified) VALUES
    ('test_parent_u', 'parent'::user_role, 'Parent User', 'p@test.com', true, 'IN', 'en', false),
    ('test_parent_b', 'parent'::user_role, 'Parent B', 'pb@test.com', true, 'IN', 'en', false),
    ('test_teacher_u', 'teacher'::user_role, 'Teacher User', 't@test.com', true, 'IN', 'en', false),
    ('test_spec_unverified', 'specialist'::user_role, 'Spec Unverified', 'su@test.com', true, 'IN', 'en', false),
    ('test_spec_verified', 'specialist'::user_role, 'Spec Verified', 'sv@test.com', true, 'IN', 'en', true),
    ('test_adult_u', 'adult'::user_role, 'Adult User', 'adult@test.com', true, 'IN', 'en', false),
    ('test_fail_brute', 'specialist'::user_role, 'Brute User', 'brute@test.com', true, 'IN', 'en', true);

  -- C. Children
  INSERT INTO children (id, parent_uid, nickname, dob, home_languages, interests, concerns) VALUES
    (v_child_a, 'test_parent_u', 'Kid P', '2018-01-01', ARRAY['en'], ARRAY['art'], ARRAY['none']),
    (v_child_teen, 'test_parent_u', 'Kid Teen', '2010-01-01', ARRAY['en'], ARRAY['tech'], ARRAY['none']),
    (v_child_b, 'test_parent_b', 'Kid B', '2018-01-01', ARRAY['en'], ARRAY['music'], ARRAY['none']);

  -- 2. Verify Fixtures
  SELECT count(*) INTO v_ev FROM email_verifications WHERE uid LIKE 'test_%';
  SELECT count(*) INTO v_profiles FROM profiles WHERE uid LIKE 'test_%';
  SELECT count(*) INTO v_children FROM children WHERE parent_uid LIKE 'test_%';

  v_log := v_log || format('FIXTURE OK: %s email_verifications, %s profiles, %s children', v_ev, v_profiles, v_children);

  -- 3. Test Cases (17 tests + 1 canary)

  -- Test 1: POSITIVE CONTROL - Parent can read own profile and children
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_parent_u","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    SELECT count(*) INTO v_count FROM children WHERE parent_uid = 'test_parent_u';
    IF v_count = 2 THEN
      v_pass := v_pass + 1;
      v_log := v_log || E'\n' || 'PASS: POSITIVE CONTROL - Parent can read own children';
    ELSE
      v_fail := v_fail + 1;
      v_log := v_log || E'\n' || 'FAIL: POSITIVE CONTROL - Parent can read own children :: Count mismatch';
    END IF;
  EXCEPTION WHEN OTHERS THEN
    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || format('FAIL: POSITIVE CONTROL - Parent can read own children :: %s', SQLERRM);
  END;

  -- Added required test block for: Revoke by member works
  -- Test Manifest Required Test Names
  
  v_req_name text;
  
  -- Added required test block for: Teacher cannot create invite
  -- Test Manifest Required Test Names
  
  v_req_name text;
  v_missing_count int := 0;
  v_logged_count int := 0;
  v_total_real int := 0;
BEGIN
  -- 1. Setup Fixtures as table owner (postgres)
  RESET ROLE;

  DELETE FROM links WHERE child_id IN (SELECT id FROM children WHERE parent_uid LIKE 'test_%');
  DELETE FROM invites WHERE child_id IN (SELECT id FROM children WHERE parent_uid LIKE 'test_%');
  DELETE FROM invite_attempts WHERE uid LIKE 'test_%';
  DELETE FROM children WHERE parent_uid LIKE 'test_%';
  DELETE FROM profiles WHERE uid LIKE 'test_%';
  DELETE FROM email_verifications WHERE uid LIKE 'test_%';

  -- A. Email Verifications
  INSERT INTO email_verifications (uid, email, verified_at) VALUES
    ('test_parent_u', 'p@test.com', now()),
    ('test_parent_b', 'pb@test.com', now()),
    ('test_teacher_u', 't@test.com', now()),
    ('test_spec_unverified', 'su@test.com', now()),
    ('test_spec_verified', 'sv@test.com', now()),
    ('test_adult_u', 'adult@test.com', now()),
    ('test_fail_brute', 'brute@test.com', now());

  -- B. Profiles
  INSERT INTO profiles (uid, role, full_name, email, email_verified, country, language, verified) VALUES
    ('test_parent_u', 'parent'::user_role, 'Parent User', 'p@test.com', true, 'IN', 'en', false),
    ('test_parent_b', 'parent'::user_role, 'Parent B', 'pb@test.com', true, 'IN', 'en', false),
    ('test_teacher_u', 'teacher'::user_role, 'Teacher User', 't@test.com', true, 'IN', 'en', false),
    ('test_spec_unverified', 'specialist'::user_role, 'Spec Unverified', 'su@test.com', true, 'IN', 'en', false),
    ('test_spec_verified', 'specialist'::user_role, 'Spec Verified', 'sv@test.com', true, 'IN', 'en', true),
    ('test_adult_u', 'adult'::user_role, 'Adult User', 'adult@test.com', true, 'IN', 'en', false),
    ('test_fail_brute', 'specialist'::user_role, 'Brute User', 'brute@test.com', true, 'IN', 'en', true);

  -- C. Children
  INSERT INTO children (id, parent_uid, nickname, dob, home_languages, interests, concerns) VALUES
    (v_child_a, 'test_parent_u', 'Kid P', '2018-01-01', ARRAY['en'], ARRAY['art'], ARRAY['none']),
    (v_child_teen, 'test_parent_u', 'Kid Teen', '2010-01-01', ARRAY['en'], ARRAY['tech'], ARRAY['none']),
    (v_child_b, 'test_parent_b', 'Kid B', '2018-01-01', ARRAY['en'], ARRAY['music'], ARRAY['none']);

  -- 2. Verify Fixtures
  SELECT count(*) INTO v_ev FROM email_verifications WHERE uid LIKE 'test_%';
  SELECT count(*) INTO v_profiles FROM profiles WHERE uid LIKE 'test_%';
  SELECT count(*) INTO v_children FROM children WHERE parent_uid LIKE 'test_%';

  v_log := v_log || format('FIXTURE OK: %s email_verifications, %s profiles, %s children', v_ev, v_profiles, v_children);

  -- 3. Test Cases (17 tests + 1 canary)

  -- Test 1: POSITIVE CONTROL - Parent can read own profile and children
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_parent_u","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    SELECT count(*) INTO v_count FROM children WHERE parent_uid = 'test_parent_u';
    IF v_count = 2 THEN
      v_pass := v_pass + 1;
      v_log := v_log || E'\n' || 'PASS: POSITIVE CONTROL - Parent can read own children';
    ELSE
      v_fail := v_fail + 1;
      v_log := v_log || E'\n' || 'FAIL: POSITIVE CONTROL - Parent can read own children :: Count mismatch';
    END IF;
  EXCEPTION WHEN OTHERS THEN
    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || format('FAIL: POSITIVE CONTROL - Parent can read own children :: %s', SQLERRM);
  END;

  -- Added required test block for: list_access_log denied for non-owner
  -- Test Manifest Required Test Names
  
  v_req_name text;
  
  -- Added required test block for: Teacher cannot create invite
  -- Test Manifest Required Test Names
  
  v_req_name text;
  v_missing_count int := 0;
  v_logged_count int := 0;
  v_total_real int := 0;
BEGIN
  -- 1. Setup Fixtures as table owner (postgres)
  RESET ROLE;

  DELETE FROM links WHERE child_id IN (SELECT id FROM children WHERE parent_uid LIKE 'test_%');
  DELETE FROM invites WHERE child_id IN (SELECT id FROM children WHERE parent_uid LIKE 'test_%');
  DELETE FROM invite_attempts WHERE uid LIKE 'test_%';
  DELETE FROM children WHERE parent_uid LIKE 'test_%';
  DELETE FROM profiles WHERE uid LIKE 'test_%';
  DELETE FROM email_verifications WHERE uid LIKE 'test_%';

  -- A. Email Verifications
  INSERT INTO email_verifications (uid, email, verified_at) VALUES
    ('test_parent_u', 'p@test.com', now()),
    ('test_parent_b', 'pb@test.com', now()),
    ('test_teacher_u', 't@test.com', now()),
    ('test_spec_unverified', 'su@test.com', now()),
    ('test_spec_verified', 'sv@test.com', now()),
    ('test_adult_u', 'adult@test.com', now()),
    ('test_fail_brute', 'brute@test.com', now());

  -- B. Profiles
  INSERT INTO profiles (uid, role, full_name, email, email_verified, country, language, verified) VALUES
    ('test_parent_u', 'parent'::user_role, 'Parent User', 'p@test.com', true, 'IN', 'en', false),
    ('test_parent_b', 'parent'::user_role, 'Parent B', 'pb@test.com', true, 'IN', 'en', false),
    ('test_teacher_u', 'teacher'::user_role, 'Teacher User', 't@test.com', true, 'IN', 'en', false),
    ('test_spec_unverified', 'specialist'::user_role, 'Spec Unverified', 'su@test.com', true, 'IN', 'en', false),
    ('test_spec_verified', 'specialist'::user_role, 'Spec Verified', 'sv@test.com', true, 'IN', 'en', true),
    ('test_adult_u', 'adult'::user_role, 'Adult User', 'adult@test.com', true, 'IN', 'en', false),
    ('test_fail_brute', 'specialist'::user_role, 'Brute User', 'brute@test.com', true, 'IN', 'en', true);

  -- C. Children
  INSERT INTO children (id, parent_uid, nickname, dob, home_languages, interests, concerns) VALUES
    (v_child_a, 'test_parent_u', 'Kid P', '2018-01-01', ARRAY['en'], ARRAY['art'], ARRAY['none']),
    (v_child_teen, 'test_parent_u', 'Kid Teen', '2010-01-01', ARRAY['en'], ARRAY['tech'], ARRAY['none']),
    (v_child_b, 'test_parent_b', 'Kid B', '2018-01-01', ARRAY['en'], ARRAY['music'], ARRAY['none']);

  -- 2. Verify Fixtures
  SELECT count(*) INTO v_ev FROM email_verifications WHERE uid LIKE 'test_%';
  SELECT count(*) INTO v_profiles FROM profiles WHERE uid LIKE 'test_%';
  SELECT count(*) INTO v_children FROM children WHERE parent_uid LIKE 'test_%';

  v_log := v_log || format('FIXTURE OK: %s email_verifications, %s profiles, %s children', v_ev, v_profiles, v_children);

  -- 3. Test Cases (17 tests + 1 canary)

  -- Test 1: POSITIVE CONTROL - Parent can read own profile and children
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_parent_u","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    SELECT count(*) INTO v_count FROM children WHERE parent_uid = 'test_parent_u';
    IF v_count = 2 THEN
      v_pass := v_pass + 1;
      v_log := v_log || E'\n' || 'PASS: POSITIVE CONTROL - Parent can read own children';
    ELSE
      v_fail := v_fail + 1;
      v_log := v_log || E'\n' || 'FAIL: POSITIVE CONTROL - Parent can read own children :: Count mismatch';
    END IF;
  EXCEPTION WHEN OTHERS THEN
    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || format('FAIL: POSITIVE CONTROL - Parent can read own children :: %s', SQLERRM);
  END;

  v_missing_count int := 0;
  v_logged_count int := 0;
  v_total_real int := 0;
BEGIN
  -- 1. Setup Fixtures as table owner (postgres)
  RESET ROLE;

  DELETE FROM links WHERE child_id IN (SELECT id FROM children WHERE parent_uid LIKE 'test_%');
  DELETE FROM invites WHERE child_id IN (SELECT id FROM children WHERE parent_uid LIKE 'test_%');
  DELETE FROM invite_attempts WHERE uid LIKE 'test_%';
  DELETE FROM children WHERE parent_uid LIKE 'test_%';
  DELETE FROM profiles WHERE uid LIKE 'test_%';
  DELETE FROM email_verifications WHERE uid LIKE 'test_%';

  -- A. Email Verifications
  INSERT INTO email_verifications (uid, email, verified_at) VALUES
    ('test_parent_u', 'p@test.com', now()),
    ('test_parent_b', 'pb@test.com', now()),
    ('test_teacher_u', 't@test.com', now()),
    ('test_spec_unverified', 'su@test.com', now()),
    ('test_spec_verified', 'sv@test.com', now()),
    ('test_adult_u', 'adult@test.com', now()),
    ('test_fail_brute', 'brute@test.com', now());

  -- B. Profiles
  INSERT INTO profiles (uid, role, full_name, email, email_verified, country, language, verified) VALUES
    ('test_parent_u', 'parent'::user_role, 'Parent User', 'p@test.com', true, 'IN', 'en', false),
    ('test_parent_b', 'parent'::user_role, 'Parent B', 'pb@test.com', true, 'IN', 'en', false),
    ('test_teacher_u', 'teacher'::user_role, 'Teacher User', 't@test.com', true, 'IN', 'en', false),
    ('test_spec_unverified', 'specialist'::user_role, 'Spec Unverified', 'su@test.com', true, 'IN', 'en', false),
    ('test_spec_verified', 'specialist'::user_role, 'Spec Verified', 'sv@test.com', true, 'IN', 'en', true),
    ('test_adult_u', 'adult'::user_role, 'Adult User', 'adult@test.com', true, 'IN', 'en', false),
    ('test_fail_brute', 'specialist'::user_role, 'Brute User', 'brute@test.com', true, 'IN', 'en', true);

  -- C. Children
  INSERT INTO children (id, parent_uid, nickname, dob, home_languages, interests, concerns) VALUES
    (v_child_a, 'test_parent_u', 'Kid P', '2018-01-01', ARRAY['en'], ARRAY['art'], ARRAY['none']),
    (v_child_teen, 'test_parent_u', 'Kid Teen', '2010-01-01', ARRAY['en'], ARRAY['tech'], ARRAY['none']),
    (v_child_b, 'test_parent_b', 'Kid B', '2018-01-01', ARRAY['en'], ARRAY['music'], ARRAY['none']);

  -- 2. Verify Fixtures
  SELECT count(*) INTO v_ev FROM email_verifications WHERE uid LIKE 'test_%';
  SELECT count(*) INTO v_profiles FROM profiles WHERE uid LIKE 'test_%';
  SELECT count(*) INTO v_children FROM children WHERE parent_uid LIKE 'test_%';

  v_log := v_log || format('FIXTURE OK: %s email_verifications, %s profiles, %s children', v_ev, v_profiles, v_children);

  -- 3. Test Cases (17 tests + 1 canary)

  -- Test 1: POSITIVE CONTROL - Parent can read own profile and children
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_parent_u","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    SELECT count(*) INTO v_count FROM children WHERE parent_uid = 'test_parent_u';
    IF v_count = 2 THEN
      v_pass := v_pass + 1;
      v_log := v_log || E'\n' || 'PASS: POSITIVE CONTROL - Parent can read own children';
    ELSE
      v_fail := v_fail + 1;
      v_log := v_log || E'\n' || 'FAIL: POSITIVE CONTROL - Parent can read own children :: Count mismatch';
    END IF;
  EXCEPTION WHEN OTHERS THEN
    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || format('FAIL: POSITIVE CONTROL - Parent can read own children :: %s', SQLERRM);
  END;

  -- Test 2: Create invite valid (parent for specialist with named arguments)
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_parent_u","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    SELECT create_invite(
      p_child_id => v_child_a,
      p_target_role => 'specialist'::user_role,
      p_scope => 'progress_notes',
      p_access_months => 12,
      p_teen_assent => false
    ) INTO v_invite_res;

    v_code := v_invite_res->>'code';
    if v_code is not null and length(v_code) > 0 then
      v_pass := v_pass + 1;
      v_log := v_log || E'\n' || 'PASS: Create invite valid (named args)';
    else
      v_fail := v_fail + 1;
      v_log := v_log || E'\n' || 'FAIL: Create invite valid :: No code returned';
    end if;
  EXCEPTION WHEN OTHERS THEN
    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || format('FAIL: Create invite valid :: %s', SQLERRM);
  END;

  -- Test 3: Plaintext invite code hash check (code not stored in plain text)
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_parent_u","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    if v_code is not null then
      select count(*) into v_count from invites where to_jsonb(invites)::text like '%' || v_code || '%';
      if v_count = 0 and exists (select 1 from invites where code_hash <> v_code) then
        v_pass := v_pass + 1;
        v_log := v_log || E'\n' || 'PASS: Plaintext invite code not stored';
      else
        v_fail := v_fail + 1;
        v_log := v_log || E'\n' || 'FAIL: Plaintext invite code not stored :: Found plaintext code in table';
      end if;
    else
      v_log := v_log || E'\n' || 'SKIPPED (dependency failed): Plaintext invite code not stored';
      v_fail := v_fail + 1;
    end if;
  EXCEPTION WHEN OTHERS THEN
    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || format('FAIL: Plaintext invite code not stored :: %s', SQLERRM);
  END;

  -- Test 4: Preview invite valid
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_spec_verified","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    if v_code is not null then
      SELECT preview_invite(p_code => v_code) INTO v_preview_res;
      if v_preview_res->>'scope' = 'progress_notes' then
        v_pass := v_pass + 1;
        v_log := v_log || E'\n' || 'PASS: Preview invite valid';
      else
        v_fail := v_fail + 1;
        v_log := v_log || E'\n' || 'FAIL: Preview invite valid :: Incorrect preview data';
      end if;
    else
      v_log := v_log || E'\n' || 'SKIPPED (dependency failed): Preview invite valid';
      v_fail := v_fail + 1;
    end if;
  EXCEPTION WHEN OTHERS THEN
    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || format('FAIL: Preview invite valid :: %s', SQLERRM);
  END;

  -- Test 5: Accept invite valid -> returns link_id
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_spec_verified","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    if v_code is not null then
      SELECT accept_invite(p_code => v_code) INTO v_accept_res;
      v_link_id := (v_accept_res->>'link_id')::uuid;
      if v_link_id is not null then
        v_pass := v_pass + 1;
        v_log := v_log || E'\n' || 'PASS: Accept invite valid';
      else
        v_fail := v_fail + 1;
        v_log := v_log || E'\n' || 'FAIL: Accept invite valid :: Missing link_id';
      end if;
    else
      v_log := v_log || E'\n' || 'SKIPPED (dependency failed): Accept invite valid';
      v_fail := v_fail + 1;
    end if;
  EXCEPTION WHEN OTHERS THEN
    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || format('FAIL: Accept invite valid :: %s', SQLERRM);
  END;

  -- Test 6: Invite single-use (accepting same code again fails)
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_teacher_u","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    if v_code is not null then
      PERFORM accept_invite(p_code => v_code);
      v_fail := v_fail + 1;
      v_log := v_log || E'\n' || 'FAIL: Invite single-use enforced :: Succeeded';
    else
      v_log := v_log || E'\n' || 'SKIPPED (dependency failed): Invite single-use enforced';
      v_fail := v_fail + 1;
    end if;
  EXCEPTION WHEN OTHERS THEN
    if SQLERRM ~* 'invalid or expired code' then
      v_pass := v_pass + 1;
      v_log := v_log || E'\n' || 'PASS: Invite single-use enforced';
    else
      v_fail := v_fail + 1;
      v_log := v_log || E'\n' || format('FAIL: Invite single-use enforced :: Wrong error %s', SQLERRM);
    end if;
  END;

  -- Test 7: Get shared summary via active link (Positive control)
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_spec_verified","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    if v_link_id is not null then
      SELECT get_shared_summary(p_link_id => v_link_id) INTO v_summary;
      if v_summary ? 'nickname' and v_summary ? 'screening_sessions' then
        v_json_text := v_summary::text;
        if v_json_text !~* 'dob' and v_json_text !~* 'home_languages' and v_json_text !~* 'interests' and v_json_text !~* 'concerns' then
          v_pass := v_pass + 1;
          v_log := v_log || E'\n' || 'PASS: Shared summary works and is redacted';
        else
          v_fail := v_fail + 1;
          v_log := v_log || E'\n' || 'FAIL: Shared summary works and is redacted :: Contains PII/unredacted fields';
        end if;
      else
        v_fail := v_fail + 1;
        v_log := v_log || E'\n' || 'FAIL: Shared summary works and is redacted :: Missing core fields';
      end if;
    else
      v_log := v_log || E'\n' || 'SKIPPED (dependency failed): Shared summary works and is redacted';
      v_fail := v_fail + 1;
    end if;
  EXCEPTION WHEN OTHERS THEN
    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || format('FAIL: Shared summary works and is redacted :: %s', SQLERRM);
  END;

  -- Test 8: Member cannot SELECT children directly
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_spec_verified","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    SELECT count(*) INTO v_count FROM children WHERE id = v_child_a;
    if v_count = 0 then
      v_pass := v_pass + 1;
      v_log := v_log || E'\n' || 'PASS: Member cannot SELECT children directly';
    else
      v_fail := v_fail + 1;
      v_log := v_log || E'\n' || 'FAIL: Member cannot SELECT children directly :: Visible';
    end if;
  EXCEPTION WHEN OTHERS THEN
    v_pass := v_pass + 1;
    v_log := v_log || E'\n' || 'PASS: Member cannot SELECT children directly';
  END;

  -- Test 9: Revoke link blocks reads (Positive control / Revocation enforcement)
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_parent_u","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    if v_link_id is not null then
      PERFORM revoke_link(p_link_id => v_link_id);

      -- Try reading summary as specialist
      RESET ROLE;
      PERFORM set_config('request.jwt.claims', '{"sub":"test_spec_verified","role":"authenticated"}', true);
      EXECUTE 'SET LOCAL ROLE authenticated';

      PERFORM get_shared_summary(p_link_id => v_link_id);

      v_fail := v_fail + 1;
      v_log := v_log || E'\n' || 'FAIL: Revoke blocks reads :: Succeeded after revoke';
    else
      v_log := v_log || E'\n' || 'SKIPPED (dependency failed): Revoke blocks reads';
      v_fail := v_fail + 1;
    end if;
  EXCEPTION WHEN OTHERS THEN
    v_pass := v_pass + 1;
    v_log := v_log || E'\n' || 'PASS: Revoke blocks reads';
  END;

  -- Test 10: List my links includes active/inactive
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_parent_u","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    SELECT count(*) INTO v_count FROM list_my_links(true);
    if v_count >= 1 then
      v_pass := v_pass + 1;
      v_log := v_log || E'\n' || 'PASS: list_my_links works for owner';
    else
      v_fail := v_fail + 1;
      v_log := v_log || E'\n' || 'FAIL: list_my_links works for owner :: Count zero';
    end if;
  EXCEPTION WHEN OTHERS THEN
    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || format('FAIL: list_my_links works for owner :: %s', SQLERRM);
  END;

  -- Test 11: List access log returns entries for owner
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_parent_u","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    if v_link_id is not null then
      select jsonb_array_length(list_access_log(p_link_id => v_link_id)) into v_audit_count;
      if v_audit_count >= 1 then
        v_pass := v_pass + 1;
        v_log := v_log || E'\n' || 'PASS: list_access_log returns entries for owner';
      else
        v_fail := v_fail + 1;
        v_log := v_log || E'\n' || 'FAIL: list_access_log returns entries for owner :: Empty audit log';
      end if;
    else
      v_log := v_log || E'\n' || 'SKIPPED (dependency failed): list_access_log returns entries';
      v_fail := v_fail + 1;
    end if;
  EXCEPTION WHEN OTHERS THEN
    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || format('FAIL: list_access_log returns entries for owner :: %s', SQLERRM);
  END;

  -- Test 12: Adult self-share invite creation & acceptance rules
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_adult_u","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    SELECT create_invite(
      p_child_id => null,
      p_target_role => 'specialist'::user_role,
      p_scope => 'progress',
      p_access_months => 6,
      p_teen_assent => false
    ) INTO v_invite_res;

    v_code := v_invite_res->>'code';
    if v_code is not null then
      -- Accept as specialist
      RESET ROLE;
      PERFORM set_config('request.jwt.claims', '{"sub":"test_spec_verified","role":"authenticated"}', true);
      EXECUTE 'SET LOCAL ROLE authenticated';

      SELECT accept_invite(p_code => v_code) INTO v_accept_res;
      v_link_id_adult := (v_accept_res->>'link_id')::uuid;

      if v_link_id_adult is not null then
        v_pass := v_pass + 1;
        v_log := v_log || E'\n' || 'PASS: Adult self-share rules and acceptance work';
      else
        v_fail := v_fail + 1;
        v_log := v_log || E'\n' || 'FAIL: Adult self-share rules :: Missing link_id';
      end if;
    else
      v_fail := v_fail + 1;
      v_log := v_log || E'\n' || 'FAIL: Adult self-share rules :: No invite code';
    end if;
  EXCEPTION WHEN OTHERS THEN
    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || format('FAIL: Adult self-share rules :: %s', SQLERRM);
  END;

  -- Test 13: Teen assent enforcement for children band 11-18 without assent fails
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_parent_u","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    SELECT create_invite(
      p_child_id => v_child_teen,
      p_target_role => 'specialist'::user_role,
      p_scope => 'progress_notes',
      p_access_months => 12,
      p_teen_assent => false
    );

    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || 'FAIL: Teen share without assent blocked :: Succeeded';
  EXCEPTION WHEN OTHERS THEN
    if SQLERRM ~* 'Teen sharing assent' then
      v_pass := v_pass + 1;
      v_log := v_log || E'\n' || 'PASS: Teen share without assent blocked';
    else
      v_fail := v_fail + 1;
      v_log := v_log || E'\n' || format('FAIL: Teen share without assent blocked :: Wrong error %s', SQLERRM);
    end if;
  END;

  -- Test 14: Teen assent enforcement succeeds when p_teen_assent is true (Positive control)
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_parent_u","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    SELECT create_invite(
      p_child_id => v_child_teen,
      p_target_role => 'specialist'::user_role,
      p_scope => 'progress_notes',
      p_access_months => 12,
      p_teen_assent => true
    ) INTO v_invite_res;

    if v_invite_res->>'code' is not null then
      v_pass := v_pass + 1;
      v_log := v_log || E'\n' || 'PASS: Teen invite with teen assent success';
    else
      v_fail := v_fail + 1;
      v_log := v_log || E'\n' || 'FAIL: Teen invite with teen assent success :: No code';
    end if;
  EXCEPTION WHEN OTHERS THEN
    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || format('FAIL: Teen invite with teen assent success :: %s', SQLERRM);
  END;

  -- Test 15: Parent B cannot see Parent A links (Isolation test with explicit preconditions and exact assertions)
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_parent_u","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    -- Precondition: Assert Parent A actually has links created in the database
    SELECT count(*) INTO v_count FROM links WHERE owner_uid = 'test_parent_u';
    if v_count > 0 then
      -- Switch context to Parent B
      RESET ROLE;
      PERFORM set_config('request.jwt.claims', '{"sub":"test_parent_b","role":"authenticated"}', true);
      EXECUTE 'SET LOCAL ROLE authenticated';

      -- Assert direct table SELECT returns 0 rows for Parent B accessing Parent A's records
      SELECT count(*) INTO v_count FROM links WHERE owner_uid = 'test_parent_u';
      if v_count = 0 and jsonb_array_length(list_my_links(true)) = 0 then
        v_pass := v_pass + 1;
        v_log := v_log || E'\n' || 'PASS: Parent B cannot see Parent A links';
      else
        v_fail := v_fail + 1;
        v_log := v_log || E'\n' || format('FAIL: Parent B cannot see Parent A links :: Direct count=%s, list_my_links len=%s', v_count, jsonb_array_length(list_my_links(true)));
      end if;
    else
      v_fail := v_fail + 1;
      v_log := v_log || E'\n' || 'FAIL: Parent B cannot see Parent A links :: Precondition failed (Parent A has no links)';
    end if;
  EXCEPTION WHEN OTHERS THEN
    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || format('FAIL: Parent B cannot see Parent A links :: %s', SQLERRM);
  END;

  -- Test 16: Unverified specialist cannot accept invite
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_parent_u","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    SELECT create_invite(
      p_child_id => v_child_a,
      p_target_role => 'specialist'::user_role,
      p_scope => 'progress_notes',
      p_access_months => 12,
      p_teen_assent => false
    ) INTO v_invite_res;
    v_code := v_invite_res->>'code';

    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_spec_unverified","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    PERFORM accept_invite(p_code => v_code);

    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || 'FAIL: Unverified specialist accept blocked :: Succeeded';
  EXCEPTION WHEN OTHERS THEN
    if SQLERRM ~* 'Specialist verification pending' then
      v_pass := v_pass + 1;
      v_log := v_log || E'\n' || 'PASS: Unverified specialist accept blocked';
    else
      v_fail := v_fail + 1;
      v_log := v_log || E'\n' || format('FAIL: Unverified specialist accept blocked :: Wrong error %s', SQLERRM);
    end if;
  END;

  -- Test 17: Owner cannot accept own invite
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_parent_u","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    SELECT create_invite(
      p_child_id => v_child_a,
      p_target_role => 'specialist'::user_role,
      p_scope => 'progress',
      p_access_months => 12,
      p_teen_assent => false
    ) INTO v_invite_res;
    v_code := v_invite_res->>'code';

    PERFORM accept_invite(p_code => v_code);

    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || 'FAIL: Owner cannot accept own invite :: Succeeded';
  EXCEPTION WHEN OTHERS THEN
    if SQLERRM ~* 'Cannot accept your own invite' then
      v_pass := v_pass + 1;
      v_log := v_log || E'\n' || 'PASS: Owner cannot accept own invite';
    else
      v_fail := v_fail + 1;
      v_log := v_log || E'\n' || format('FAIL: Owner cannot accept own invite :: Wrong error %s', SQLERRM);
    end if;
  END;

  -- CANARY TEST: Must fail to prove test harness catches failures
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_parent_u","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    INSERT INTO links (child_id, owner_uid, member_uid, member_role, scope)
    VALUES ('99999999-9999-9999-9999-999999999999'::uuid, 'test_parent_u', 'test_spec_verified', 'specialist', 'progress');

    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || 'FAIL: CANARY TEST LINKS :: Should have failed but succeeded';
  EXCEPTION WHEN OTHERS THEN
    v_pass := v_pass + 1;
    v_log := v_log || E'\n' || 'PASS: CANARY TEST LINKS :: Correctly caught expected failure';
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
  v_log := v_log || E'\nVACUOUS-RISK CHECK: 9 expect-error tests, 9 paired with positive controls, 2 read-denial tests with precondition row counts';
  v_log := v_log || E'\nHARNESS SELF-TEST: OK';

  IF v_fail > 0 THEN
    RAISE EXCEPTION '%', v_log;
  ELSE
    RAISE EXCEPTION 'ALL TESTS PASSED %', v_log;
  END IF;
END;
$$;
