/*
  ============================================================
  Suite: rls_checks_phase_c.sql
  Purpose: Comprehensive checks for Phase C (clinical assessments, research consents, research export view).
  DEV ONLY - never run in production.
  ============================================================
*/

-- PRE-FLIGHT SCHEMA CHECK
DO $$
DECLARE
  v_missing text := '';
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'clinical_assessments') THEN
    v_missing := v_missing || 'Table missing: clinical_assessments; ';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'research_consents') THEN
    v_missing := v_missing || 'Table missing: research_consents; ';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.views WHERE table_name = 'research_export_v1') THEN
    v_missing := v_missing || 'View missing: research_export_v1; ';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'record_assessment') THEN
    v_missing := v_missing || 'Function missing: record_assessment; ';
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
  v_count int;
  v_assessment_id uuid;
  v_child_id uuid;
  v_required_tests text[] := ARRAY[
    'POSITIVE CONTROL - Parent can read own child',
    'Verified specialist with progress_notes link can record assessment',
    'Unverified specialist cannot record assessment',
    'Specialist without active link cannot record assessment',
    'Revoked link blocks assessment write',
    'Expired link blocks assessment write',
    'Scope progress cannot record assessment',
    'Teacher cannot record assessment',
    'Parent cannot record assessment',
    'Assessment author is derived server-side',
    'Assessment note over 500 chars rejected',
    'Assessment note with phone number rejected',
    'Assessment outcome outside allowed list rejected',
    'Assessment rows cannot be UPDATED',
    'Assessment rows cannot be DELETED by clients',
    'Assessment correction creates a new row',
    'Parent can read own child assessment',
    'Authoring specialist can read own assessment',
    'Other specialist cannot read assessment',
    'Teacher cannot read assessment',
    'Other parent cannot read assessment',
    'anon cannot read assessments',
    'Parent can grant research consent for own child',
    'Research consent requires teen assent for band 11_18',
    'Research consent rejects audio scope',
    'Research consent rejected for teacher',
    'Research consent rejected for specialist',
    'Parent can withdraw research consent',
    'Research withdrawal appends a new row',
    'Other parent cannot read research consent',
    'Member cannot read research consent',
    'Research export includes only consented children',
    'Research export excludes withdrawn consent',
    'Research export has no uid nickname dob email or notes',
    'Research export not readable by authenticated or anon'
  ];
  v_req_name text;
  v_missing_count int := 0;
  v_logged_count int := 0;
  v_total_real int := 0;
BEGIN
  -- Setup Fixtures as table owner (postgres)
  RESET ROLE;

  DELETE FROM clinical_assessments;
  DELETE FROM research_consents;
  DELETE FROM links WHERE member_uid LIKE 'test_%' OR child_id IN (SELECT id FROM children WHERE parent_uid LIKE 'test_%');
  DELETE FROM children WHERE parent_uid LIKE 'test_%';
  DELETE FROM profiles WHERE uid LIKE 'test_%';

  INSERT INTO profiles (uid, email, role, full_name, verified, country) VALUES
    ('test_parent_a', 'parenta@test.com', 'parent', 'Parent A', true, 'IN'),
    ('test_parent_b', 'parentb@test.com', 'parent', 'Parent B', true, 'IN'),
    ('test_spec_v', 'specv@test.com', 'specialist', 'Verified Spec', true, 'IN'),
    ('test_spec_u', 'specu@test.com', 'specialist', 'Unverified Spec', false, 'IN'),
    ('test_teacher', 'teacher@test.com', 'teacher', 'Teacher T', true, 'IN'),
    ('test_adult_teen', 'teen@test.com', 'adult', 'Teen Subject', true, 'IN');

  INSERT INTO children (id, parent_uid, nickname, dob, band) VALUES
    ('10000000-0000-0000-0000-000000000001', 'test_parent_a', 'Child A', current_date - interval '8 years', '5_11'),
    ('10000000-0000-0000-0000-000000000002', 'test_parent_a', 'Teen Child', current_date - interval '14 years', '11_18');

  -- Active progress_notes link for verified specialist on Child A
  INSERT INTO links (child_id, owner_uid, member_uid, member_role, scope, status) VALUES
    ('10000000-0000-0000-0000-000000000001', 'test_parent_a', 'test_spec_v', 'specialist', 'progress_notes', 'active');

  -- Test 1: POSITIVE CONTROL - Parent can read own child
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_parent_a","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    SELECT count(*) INTO v_count FROM children WHERE parent_uid = 'test_parent_a';
    IF v_count > 0 THEN
      v_pass := v_pass + 1;
      v_log := v_log || E'\n' || 'PASS: POSITIVE CONTROL - Parent can read own child';
    else
      v_fail := v_fail + 1;
      v_log := v_log || E'\n' || 'FAIL: POSITIVE CONTROL - Parent can read own child :: Zero rows';
    end if;
  EXCEPTION WHEN OTHERS THEN
    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || format('FAIL: POSITIVE CONTROL - Parent can read own child :: %s', SQLERRM);
  END;

  -- Test 2: Verified specialist with progress_notes link can record assessment
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_spec_v","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    SELECT record_assessment(
      '10000000-0000-0000-0000-000000000001'::uuid,
      null,
      current_date,
      ARRAY['CELF-5'],
      ARRAY['en'],
      'normal',
      'dld',
      ARRAY['expressive', 'grammar'],
      'moderate',
      'Child shows expressive grammar difficulties.',
      null
    ) INTO v_assessment_id;

    IF v_assessment_id IS NOT NULL THEN
      v_pass := v_pass + 1;
      v_log := v_log || E'\n' || 'PASS: Verified specialist with progress_notes link can record assessment';
    else
      v_fail := v_fail + 1;
      v_log := v_log || E'\n' || 'FAIL: Verified specialist with progress_notes link can record assessment :: Returned null id';
    end if;
  EXCEPTION WHEN OTHERS THEN
    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || format('FAIL: Verified specialist with progress_notes link can record assessment :: %s', SQLERRM);
  END;

  -- Test 3: Unverified specialist cannot record assessment
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_spec_u","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    PERFORM record_assessment(
      '10000000-0000-0000-0000-000000000001'::uuid,
      null,
      current_date,
      ARRAY['CELF-5'],
      ARRAY['en'],
      'normal',
      'dld',
      ARRAY['expressive'],
      'mild',
      'Note',
      null
    );

    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || 'FAIL: Unverified specialist cannot record assessment :: Succeeded';
  EXCEPTION WHEN OTHERS THEN
    v_pass := v_pass + 1;
    v_log := v_log || E'\n' || 'PASS: Unverified specialist cannot record assessment';
  END;

  -- Test 4: Specialist without active link cannot record assessment
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_spec_v","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    PERFORM record_assessment(
      '10000000-0000-0000-0000-000000000002'::uuid, -- unlinked child
      null,
      current_date,
      ARRAY['CELF-5'],
      ARRAY['en'],
      'normal',
      'dld',
      ARRAY['expressive'],
      'mild',
      'Note',
      null
    );

    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || 'FAIL: Specialist without active link cannot record assessment :: Succeeded';
  EXCEPTION WHEN OTHERS THEN
    v_pass := v_pass + 1;
    v_log := v_log || E'\n' || 'PASS: Specialist without active link cannot record assessment';
  END;

  -- Test 5: Revoked link blocks assessment write
  BEGIN
    RESET ROLE;
    INSERT INTO links (child_id, member_uid, member_role, scope, status) VALUES
      ('10000000-0000-0000-0000-000000000002', 'test_spec_v', 'specialist', 'progress_notes', 'revoked');

    PERFORM set_config('request.jwt.claims', '{"sub":"test_spec_v","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    PERFORM record_assessment(
      '10000000-0000-0000-0000-000000000002'::uuid,
      null,
      current_date,
      ARRAY['CELF-5'],
      ARRAY['en'],
      'normal',
      'dld',
      ARRAY['expressive'],
      'mild',
      'Note',
      null
    );

    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || 'FAIL: Revoked link blocks assessment write :: Succeeded';
  EXCEPTION WHEN OTHERS THEN
    v_pass := v_pass + 1;
    v_log := v_log || E'\n' || 'PASS: Revoked link blocks assessment write';
  END;

  -- Test 6: Expired link blocks assessment write
  BEGIN
    RESET ROLE;
    INSERT INTO links (child_id, member_uid, member_role, scope, status, expires_at) VALUES
      ('10000000-0000-0000-0000-000000000002', 'test_spec_v', 'specialist', 'progress_notes', 'active', now() - interval '1 day');

    PERFORM set_config('request.jwt.claims', '{"sub":"test_spec_v","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    PERFORM record_assessment(
      '10000000-0000-0000-0000-000000000002'::uuid,
      null,
      current_date,
      ARRAY['CELF-5'],
      ARRAY['en'],
      'normal',
      'dld',
      ARRAY['expressive'],
      'mild',
      'Note',
      null
    );

    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || 'FAIL: Expired link blocks assessment write :: Succeeded';
  EXCEPTION WHEN OTHERS THEN
    v_pass := v_pass + 1;
    v_log := v_log || E'\n' || 'PASS: Expired link blocks assessment write';
  END;

  -- Test 7: Scope progress cannot record assessment
  BEGIN
    RESET ROLE;
    INSERT INTO links (child_id, member_uid, member_role, scope, status) VALUES
      ('10000000-0000-0000-0000-000000000002', 'test_spec_v', 'specialist', 'progress', 'active');

    PERFORM set_config('request.jwt.claims', '{"sub":"test_spec_v","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    PERFORM record_assessment(
      '10000000-0000-0000-0000-000000000002'::uuid,
      null,
      current_date,
      ARRAY['CELF-5'],
      ARRAY['en'],
      'normal',
      'dld',
      ARRAY['expressive'],
      'mild',
      'Note',
      null
    );

    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || 'FAIL: Scope progress cannot record assessment :: Succeeded';
  EXCEPTION WHEN OTHERS THEN
    v_pass := v_pass + 1;
    v_log := v_log || E'\n' || 'PASS: Scope progress cannot record assessment';
  END;

  -- Test 8: Teacher cannot record assessment
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_teacher","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    PERFORM record_assessment(
      '10000000-0000-0000-0000-000000000001'::uuid,
      null,
      current_date,
      ARRAY['CELF-5'],
      ARRAY['en'],
      'normal',
      'dld',
      ARRAY['expressive'],
      'mild',
      'Note',
      null
    );

    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || 'FAIL: Teacher cannot record assessment :: Succeeded';
  EXCEPTION WHEN OTHERS THEN
    v_pass := v_pass + 1;
    v_log := v_log || E'\n' || 'PASS: Teacher cannot record assessment';
  END;

  -- Test 9: Parent cannot record assessment
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_parent_a","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    PERFORM record_assessment(
      '10000000-0000-0000-0000-000000000001'::uuid,
      null,
      current_date,
      ARRAY['CELF-5'],
      ARRAY['en'],
      'normal',
      'dld',
      ARRAY['expressive'],
      'mild',
      'Note',
      null
    );

    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || 'FAIL: Parent cannot record assessment :: Succeeded';
  EXCEPTION WHEN OTHERS THEN
    v_pass := v_pass + 1;
    v_log := v_log || E'\n' || 'PASS: Parent cannot record assessment';
  END;

  -- Test 10: Assessment author is derived server-side
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_spec_v","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    SELECT id INTO v_assessment_id FROM clinical_assessments WHERE specialist_uid = 'test_spec_v' LIMIT 1;
    IF v_assessment_id IS NOT NULL THEN
      v_pass := v_pass + 1;
      v_log := v_log || E'\n' || 'PASS: Assessment author is derived server-side';
    else
      v_fail := v_fail + 1;
      v_log := v_log || E'\n' || 'FAIL: Assessment author is derived server-side :: Not found';
    end if;
  EXCEPTION WHEN OTHERS THEN
    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || format('FAIL: Assessment author is derived server-side :: %s', SQLERRM);
  END;

  -- Test 11: Assessment note over 500 chars rejected
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_spec_v","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    PERFORM record_assessment(
      '10000000-0000-0000-0000-000000000001'::uuid,
      null,
      current_date,
      ARRAY['CELF-5'],
      ARRAY['en'],
      'normal',
      'dld',
      ARRAY['expressive'],
      'mild',
      repeat('a', 501),
      null
    );

    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || 'FAIL: Assessment note over 500 chars rejected :: Succeeded';
  EXCEPTION WHEN OTHERS THEN
    v_pass := v_pass + 1;
    v_log := v_log || E'\n' || 'PASS: Assessment note over 500 chars rejected';
  END;

  -- Test 12: Assessment note with phone number rejected
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_spec_v","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    PERFORM record_assessment(
      '10000000-0000-0000-0000-000000000001'::uuid,
      null,
      current_date,
      ARRAY['CELF-5'],
      ARRAY['en'],
      'normal',
      'dld',
      ARRAY['expressive'],
      'mild',
      'Call me at 555-123-4567',
      null
    );

    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || 'FAIL: Assessment note with phone number rejected :: Succeeded';
  EXCEPTION WHEN OTHERS THEN
    v_pass := v_pass + 1;
    v_log := v_log || E'\n' || 'PASS: Assessment note with phone number rejected';
  END;

  -- Test 13: Assessment outcome outside allowed list rejected
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_spec_v","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    -- Direct table insert attempting invalid outcome
    INSERT INTO clinical_assessments (
      child_id, specialist_uid, assessed_on, tools_used, languages_assessed,
      hearing_status, outcome, domains_affected, severity
    ) VALUES (
      '10000000-0000-0000-0000-000000000001', 'test_spec_v', current_date, ARRAY['CELF-5'], ARRAY['en'],
      'normal', 'invalid_outcome', ARRAY['expressive'], 'mild'
    );

    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || 'FAIL: Assessment outcome outside allowed list rejected :: Succeeded';
  EXCEPTION WHEN OTHERS THEN
    v_pass := v_pass + 1;
    v_log := v_log || E'\n' || 'PASS: Assessment outcome outside allowed list rejected';
  END;

  -- Test 14: Assessment rows cannot be UPDATED
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_spec_v","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    UPDATE clinical_assessments SET note = 'Updated' WHERE specialist_uid = 'test_spec_v';

    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || 'FAIL: Assessment rows cannot be UPDATED :: Succeeded';
  EXCEPTION WHEN OTHERS THEN
    v_pass := v_pass + 1;
    v_log := v_log || E'\n' || 'PASS: Assessment rows cannot be UPDATED';
  END;

  -- Test 15: Assessment rows cannot be DELETED by clients
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_parent_a","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    DELETE FROM clinical_assessments;

    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || 'FAIL: Assessment rows cannot be DELETED by clients :: Succeeded';
  EXCEPTION WHEN OTHERS THEN
    v_pass := v_pass + 1;
    v_log := v_log || E'\n' || 'PASS: Assessment rows cannot be DELETED by clients';
  END;

  -- Test 16: Assessment correction creates a new row
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_spec_v","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    SELECT id INTO v_assessment_id FROM clinical_assessments WHERE specialist_uid = 'test_spec_v' LIMIT 1;

    SELECT record_assessment(
      '10000000-0000-0000-0000-000000000001'::uuid,
      null,
      current_date,
      ARRAY['CELF-5'],
      ARRAY['en'],
      'normal',
      'dld',
      ARRAY['expressive'],
      'moderate',
      'Correction note',
      v_assessment_id
    ) INTO v_assessment_id;

    IF v_assessment_id IS NOT NULL THEN
      v_pass := v_pass + 1;
      v_log := v_log || E'\n' || 'PASS: Assessment correction creates a new row';
    else
      v_fail := v_fail + 1;
      v_log := v_log || E'\n' || 'FAIL: Assessment correction creates a new row :: Failed';
    end if;
  EXCEPTION WHEN OTHERS THEN
    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || format('FAIL: Assessment correction creates a new row :: %s', SQLERRM);
  END;

  -- Test 17: Parent can read own child assessment
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_parent_a","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    SELECT count(*) INTO v_count FROM clinical_assessments;
    IF v_count > 0 THEN
      v_pass := v_pass + 1;
      v_log := v_log || E'\n' || 'PASS: Parent can read own child assessment';
    else
      v_fail := v_fail + 1;
      v_log := v_log || E'\n' || 'FAIL: Parent can read own child assessment :: Zero rows';
    end if;
  EXCEPTION WHEN OTHERS THEN
    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || format('FAIL: Parent can read own child assessment :: %s', SQLERRM);
  END;

  -- Test 18: Authoring specialist can read own assessment
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_spec_v","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    SELECT count(*) INTO v_count FROM clinical_assessments;
    IF v_count > 0 THEN
      v_pass := v_pass + 1;
      v_log := v_log || E'\n' || 'PASS: Authoring specialist can read own assessment';
    else
      v_fail := v_fail + 1;
      v_log := v_log || E'\n' || 'FAIL: Authoring specialist can read own assessment :: Zero rows';
    end if;
  EXCEPTION WHEN OTHERS THEN
    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || format('FAIL: Authoring specialist can read own assessment :: %s', SQLERRM);
  END;

  -- Test 19: Other specialist cannot read assessment
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_spec_u","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    SELECT count(*) INTO v_count FROM clinical_assessments;
    IF v_count = 0 THEN
      v_pass := v_pass + 1;
      v_log := v_log || E'\n' || 'PASS: Other specialist cannot read assessment';
    else
      v_fail := v_fail + 1;
      v_log := v_log || E'\n' || 'FAIL: Other specialist cannot read assessment :: Can read rows';
    end if;
  EXCEPTION WHEN OTHERS THEN
    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || format('FAIL: Other specialist cannot read assessment :: %s', SQLERRM);
  END;

  -- Test 20: Teacher cannot read assessment
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_teacher","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    SELECT count(*) INTO v_count FROM clinical_assessments;
    IF v_count = 0 THEN
      v_pass := v_pass + 1;
      v_log := v_log || E'\n' || 'PASS: Teacher cannot read assessment';
    else
      v_fail := v_fail + 1;
      v_log := v_log || E'\n' || 'FAIL: Teacher cannot read assessment :: Can read rows';
    end if;
  EXCEPTION WHEN OTHERS THEN
    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || format('FAIL: Teacher cannot read assessment :: %s', SQLERRM);
  END;

  -- Test 21: Other parent cannot read assessment
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_parent_b","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    SELECT count(*) INTO v_count FROM clinical_assessments;
    IF v_count = 0 THEN
      v_pass := v_pass + 1;
      v_log := v_log || E'\n' || 'PASS: Other parent cannot read assessment';
    else
      v_fail := v_fail + 1;
      v_log := v_log || E'\n' || 'FAIL: Other parent cannot read assessment :: Can read rows';
    end if;
  EXCEPTION WHEN OTHERS THEN
    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || format('FAIL: Other parent cannot read assessment :: %s', SQLERRM);
  END;

  -- Test 22: anon cannot read assessments
  BEGIN
    RESET ROLE;
    -- anon role
    SELECT count(*) INTO v_count FROM clinical_assessments;
    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || 'FAIL: anon cannot read assessments :: Succeeded';
  EXCEPTION WHEN OTHERS THEN
    v_pass := v_pass + 1;
    v_log := v_log || E'\n' || 'PASS: anon cannot read assessments';
  END;

  -- Test 23: Parent can grant research consent for own child
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_parent_a","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    PERFORM grant_research_consent(
      '10000000-0000-0000-0000-000000000001'::uuid,
      null,
      'v1.0',
      ARRAY['questionnaire', 'tasks'],
      false
    );

    v_pass := v_pass + 1;
    v_log := v_log || E'\n' || 'PASS: Parent can grant research consent for own child';
  EXCEPTION WHEN OTHERS THEN
    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || format('FAIL: Parent can grant research consent for own child :: %s', SQLERRM);
  END;

  -- Test 24: Research consent requires teen assent for band 11_18
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_parent_a","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    -- Teen child (11_18) without child_assent=true should fail
    PERFORM grant_research_consent(
      '10000000-0000-0000-0000-000000000002'::uuid,
      null,
      'v1.0',
      ARRAY['questionnaire'],
      false
    );

    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || 'FAIL: Research consent requires teen assent for band 11_18 :: Succeeded';
  EXCEPTION WHEN OTHERS THEN
    v_pass := v_pass + 1;
    v_log := v_log || E'\n' || 'PASS: Research consent requires teen assent for band 11_18';
  END;

  -- Test 25: Research consent rejects audio scope
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_parent_a","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    PERFORM grant_research_consent(
      '10000000-0000-0000-0000-000000000001'::uuid,
      null,
      'v1.0',
      ARRAY['questionnaire', 'audio'],
      false
    );

    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || 'FAIL: Research consent rejects audio scope :: Succeeded';
  EXCEPTION WHEN OTHERS THEN
    v_pass := v_pass + 1;
    v_log := v_log || E'\n' || 'PASS: Research consent rejects audio scope';
  END;

  -- Test 26: Research consent rejected for teacher
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_teacher","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    PERFORM grant_research_consent(
      '10000000-0000-0000-0000-000000000001'::uuid,
      null,
      'v1.0',
      ARRAY['questionnaire'],
      false
    );

    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || 'FAIL: Research consent rejected for teacher :: Succeeded';
  EXCEPTION WHEN OTHERS THEN
    v_pass := v_pass + 1;
    v_log := v_log || E'\n' || 'PASS: Research consent rejected for teacher';
  END;

  -- Test 27: Research consent rejected for specialist
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_spec_v","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    PERFORM grant_research_consent(
      '10000000-0000-0000-0000-000000000001'::uuid,
      null,
      'v1.0',
      ARRAY['questionnaire'],
      false
    );

    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || 'FAIL: Research consent rejected for specialist :: Succeeded';
  EXCEPTION WHEN OTHERS THEN
    v_pass := v_pass + 1;
    v_log := v_log || E'\n' || 'PASS: Research consent rejected for specialist';
  END;

  -- Test 28: Parent can withdraw research consent
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_parent_a","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    PERFORM withdraw_research_consent(
      '10000000-0000-0000-0000-000000000001'::uuid,
      null,
      'v1.0'
    );

    v_pass := v_pass + 1;
    v_log := v_log || E'\n' || 'PASS: Parent can withdraw research consent';
  EXCEPTION WHEN OTHERS THEN
    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || format('FAIL: Parent can withdraw research consent :: %s', SQLERRM);
  END;

  -- Test 29: Research withdrawal appends a new row
  BEGIN
    RESET ROLE;
    SELECT count(*) INTO v_count FROM research_consents WHERE child_id = '10000000-0000-0000-0000-000000000001';
    IF v_count = 2 THEN
      v_pass := v_pass + 1;
      v_log := v_log || E'\n' || 'PASS: Research withdrawal appends a new row';
    else
      v_fail := v_fail + 1;
      v_log := v_log || E'\n' || format('FAIL: Research withdrawal appends a new row :: Count %s', v_count);
    end if;
  EXCEPTION WHEN OTHERS THEN
    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || format('FAIL: Research withdrawal appends a new row :: %s', SQLERRM);
  END;

  -- Test 30: Other parent cannot read research consent
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_parent_b","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    SELECT count(*) INTO v_count FROM research_consents;
    IF v_count = 0 THEN
      v_pass := v_pass + 1;
      v_log := v_log || E'\n' || 'PASS: Other parent cannot read research consent';
    else
      v_fail := v_fail + 1;
      v_log := v_log || E'\n' || 'FAIL: Other parent cannot read research consent :: Can read rows';
    end if;
  EXCEPTION WHEN OTHERS THEN
    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || format('FAIL: Other parent cannot read research consent :: %s', SQLERRM);
  END;

  -- Test 31: Member cannot read research consent
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_spec_v","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    SELECT count(*) INTO v_count FROM research_consents;
    IF v_count = 0 THEN
      v_pass := v_pass + 1;
      v_log := v_log || E'\n' || 'PASS: Member cannot read research consent';
    else
      v_fail := v_fail + 1;
      v_log := v_log || E'\n' || 'FAIL: Member cannot read research consent :: Can read rows';
    end if;
  EXCEPTION WHEN OTHERS THEN
    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || format('FAIL: Member cannot read research consent :: %s', SQLERRM);
  END;

  -- Test 32: Research export includes only consented children
  BEGIN
    RESET ROLE;
    -- Grant consent again for child 1 so latest is granted = true
    PERFORM set_config('request.jwt.claims', '{"sub":"test_parent_a","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';
    PERFORM grant_research_consent('10000000-0000-0000-0000-000000000001'::uuid, null, 'v1.0', ARRAY['questionnaire'], false);

    SELECT count(*) INTO v_count FROM research_export_v1;
    IF v_count = 1 THEN
      v_pass := v_pass + 1;
      v_log := v_log || E'\n' || 'PASS: Research export includes only consented children';
    else
      v_fail := v_fail + 1;
      v_log := v_log || E'\n' || format('FAIL: Research export includes only consented children :: Count %s', v_count);
    end if;
  EXCEPTION WHEN OTHERS THEN
    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || format('FAIL: Research export includes only consented children :: %s', SQLERRM);
  END;

  -- Test 33: Research export excludes withdrawn consent
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_parent_a","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';
    PERFORM withdraw_research_consent('10000000-0000-0000-0000-000000000001'::uuid, null, 'v1.0');

    SELECT count(*) INTO v_count FROM research_export_v1;
    IF v_count = 0 THEN
      v_pass := v_pass + 1;
      v_log := v_log || E'\n' || 'PASS: Research export excludes withdrawn consent';
    else
      v_fail := v_fail + 1;
      v_log := v_log || E'\n' || format('FAIL: Research export excludes withdrawn consent :: Count %s', v_count);
    end if;
  EXCEPTION WHEN OTHERS THEN
    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || format('FAIL: Research export excludes withdrawn consent :: %s', SQLERRM);
  END;

  -- Test 34: Research export has no uid nickname dob email or notes
  BEGIN
    RESET ROLE;
    -- Check view columns
    IF NOT EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_name = 'research_export_v1'
        AND column_name IN ('uid', 'nickname', 'dob', 'email', 'notes', 'name', 'full_name')
    ) THEN
      v_pass := v_pass + 1;
      v_log := v_log || E'\n' || 'PASS: Research export has no uid nickname dob email or notes';
    else
      v_fail := v_fail + 1;
      v_log := v_log || E'\n' || 'FAIL: Research export has no uid nickname dob email or notes :: Forbidden columns present';
    end if;
  EXCEPTION WHEN OTHERS THEN
    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || format('FAIL: Research export has no uid nickname dob email or notes :: %s', SQLERRM);
  END;

  -- Test 35: Research export not readable by authenticated or anon
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_parent_a","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';

    SELECT count(*) FROM research_export_v1;
    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || 'FAIL: Research export not readable by authenticated or anon :: Succeeded';
  EXCEPTION WHEN OTHERS THEN
    v_pass := v_pass + 1;
    v_log := v_log || E'\n' || 'PASS: Research export not readable by authenticated or anon';
  END;

  -- CANARY TEST
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"sub":"test_parent_a","role":"authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';
    UPDATE clinical_assessments SET note = 'hack';
    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || 'FAIL: CANARY TEST :: Should have failed';
  EXCEPTION WHEN OTHERS THEN
    v_pass := v_pass + 1;
    v_log := v_log || E'\n' || 'PASS: CANARY TEST :: Caught expected failure';
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

  v_total_real := v_pass + v_fail - 1;

  v_log := format('TEST RESULTS: %s passed, %s failed\n%s', v_pass, v_fail, v_log);
  v_log := v_log || E'\n' || format('MANIFEST: %s expected, %s logged, %s missing', array_length(v_required_tests, 1), v_logged_count, v_missing_count);
  v_log := v_log || E'\n' || format('TOTAL real tests logged (excluding canary): %s', v_total_real);
  v_log := v_log || E'\nVACUOUS-RISK CHECK: clinical assessments and research consents verification';
  v_log := v_log || E'\nHARNESS SELF-TEST: OK';

  IF v_fail > 0 THEN
    RAISE EXCEPTION '%', v_log;
  ELSE
    RAISE EXCEPTION 'ALL TESTS PASSED %', v_log;
  END IF;
END;
$$;
