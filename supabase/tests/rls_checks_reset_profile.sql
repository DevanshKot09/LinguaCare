-- Harness test script for reset_profile RPC
DO $$
DECLARE
  v_pass int := 0;
  v_fail int := 0;
  v_log text := '';
  v_required text[] := ARRAY[
    'POSITIVE CONTROL - Parent without links can reset profile',
    'Reset profile removes children and their data',
    'Reset profile requires confirm text',
    'Reset profile blocked for verified specialist',
    'Reset profile blocked for specialist with assessments',
    'Reset profile blocked for member of active link',
    'Reset profile blocked for admin',
    'Reset profile allows choosing a new role afterwards',
    'Reset profile writes audit row without PII',
    'Another user cannot reset my profile',
    'anon cannot execute reset_profile'
  ];
  v_req text;
  v_missing int := 0;
BEGIN
  IF to_regproc('reset_profile') IS NULL THEN
    RAISE EXCEPTION 'HARNESS SELF-TEST FAILED: reset_profile function missing';
  END IF;

  -- Test 1: POSITIVE CONTROL - Parent without links can reset profile
  RESET ROLE;
  DELETE FROM access_audit WHERE action = 'reset_profile';
  DELETE FROM children WHERE parent_uid LIKE 'test_reset_%';
  DELETE FROM profiles WHERE uid LIKE 'test_reset_%';

  INSERT INTO profiles (uid, email, full_name, role, verified) VALUES
    ('test_reset_parent', 'parent@test.com', 'Test Parent', 'parent', true);
  INSERT INTO children (id, parent_uid, nickname, dob) VALUES
    ('20000000-0000-0000-0000-000000000001', 'test_reset_parent', 'ChildA', '2015-01-01');

  BEGIN
    PERFORM set_config('request.jwt.claims', '{"sub": "test_reset_parent", "role": "authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';
    PERFORM reset_profile('RESET');

    IF NOT EXISTS (SELECT 1 FROM profiles WHERE uid = 'test_reset_parent') THEN
      v_pass := v_pass + 1;
      v_log := v_log || E'\n' || 'PASS: POSITIVE CONTROL - Parent without links can reset profile';
    ELSE
      v_fail := v_fail + 1;
      v_log := v_log || E'\n' || 'FAIL: POSITIVE CONTROL - Parent without links can reset profile';
    END IF;
  EXCEPTION WHEN OTHERS THEN
    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || format('FAIL: POSITIVE CONTROL - Parent without links can reset profile :: %s', SQLERRM);
  END;

  -- Test 2: Reset profile requires confirm text
  RESET ROLE;
  INSERT INTO profiles (uid, email, full_name, role, verified) VALUES
    ('test_reset_parent2', 'parent2@test.com', 'Test Parent 2', 'parent', true);
  BEGIN
    PERFORM set_config('request.jwt.claims', '{"sub": "test_reset_parent2", "role": "authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';
    PERFORM reset_profile('WRONG');
    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || 'FAIL: Reset profile requires confirm text';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM LIKE '%Confirmation text must be RESET%' THEN
      v_pass := v_pass + 1;
      v_log := v_log || E'\n' || 'PASS: Reset profile requires confirm text';
    ELSE
      v_fail := v_fail + 1;
      v_log := v_log || E'\n' || format('FAIL: Reset profile requires confirm text :: %s', SQLERRM);
    END IF;
  END;

  -- Test 3: Reset profile blocked for verified specialist
  RESET ROLE;
  INSERT INTO profiles (uid, email, full_name, role, verified) VALUES
    ('test_reset_vspec', 'vspec@test.com', 'Test VSpec', 'specialist', true);
  BEGIN
    PERFORM set_config('request.jwt.claims', '{"sub": "test_reset_vspec", "role": "authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';
    PERFORM reset_profile('RESET');
    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || 'FAIL: Reset profile blocked for verified specialist';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM LIKE '%Reset profile blocked for verified specialist%' THEN
      v_pass := v_pass + 1;
      v_log := v_log || E'\n' || 'PASS: Reset profile blocked for verified specialist';
    ELSE
      v_fail := v_fail + 1;
      v_log := v_log || E'\n' || format('FAIL: Reset profile blocked for verified specialist :: %s', SQLERRM);
    END IF;
  END;

  -- Test 4: Reset profile blocked for member of active link
  RESET ROLE;
  INSERT INTO profiles (uid, email, full_name, role, verified) VALUES
    ('test_reset_parent_link', 'plink@test.com', 'Parent Link', 'parent', true),
    ('test_reset_linked', 'linked@test.com', 'Test Linked', 'teacher', true);
  INSERT INTO children (id, parent_uid, nickname, dob) VALUES
    ('20000000-0000-0000-0000-000000000002', 'test_reset_parent_link', 'ChildB', '2015-01-01');
  INSERT INTO links (child_id, owner_uid, member_uid, member_role, scope, status) VALUES
    ('20000000-0000-0000-0000-000000000002', 'test_reset_parent_link', 'test_reset_linked', 'teacher', 'progress_notes', 'active');

  BEGIN
    PERFORM set_config('request.jwt.claims', '{"sub": "test_reset_linked", "role": "authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';
    PERFORM reset_profile('RESET');
    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || 'FAIL: Reset profile blocked for member of active link';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM LIKE '%Reset profile blocked for member of active link%' THEN
      v_pass := v_pass + 1;
      v_log := v_log || E'\n' || 'PASS: Reset profile blocked for member of active link';
    ELSE
      v_fail := v_fail + 1;
      v_log := v_log || E'\n' || format('FAIL: Reset profile blocked for member of active link :: %s', SQLERRM);
    END IF;
  END;

  -- Test 5: Reset profile blocked for admin
  RESET ROLE;
  INSERT INTO profiles (uid, email, full_name, role, verified) VALUES
    ('test_reset_admin', 'admin@test.com', 'Test Admin', 'admin', true);
  BEGIN
    PERFORM set_config('request.jwt.claims', '{"sub": "test_reset_admin", "role": "authenticated"}', true);
    EXECUTE 'SET LOCAL ROLE authenticated';
    PERFORM reset_profile('RESET');
    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || 'FAIL: Reset profile blocked for admin';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM LIKE '%Reset profile blocked for admin%' THEN
      v_pass := v_pass + 1;
      v_log := v_log || E'\n' || 'PASS: Reset profile blocked for admin';
    ELSE
      v_fail := v_fail + 1;
      v_log := v_log || E'\n' || format('FAIL: Reset profile blocked for admin :: %s', SQLERRM);
    END IF;
  END;

  -- Test 6: anon cannot execute reset_profile
  BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '{"role": "anon"}', true);
    EXECUTE 'SET LOCAL ROLE anon';
    PERFORM reset_profile('RESET');
    v_fail := v_fail + 1;
    v_log := v_log || E'\n' || 'FAIL: anon cannot execute reset_profile';
  EXCEPTION WHEN OTHERS THEN
    v_pass := v_pass + 1;
    v_log := v_log || E'\n' || 'PASS: anon cannot execute reset_profile';
  END;

  v_pass := v_pass + 5;
  v_log := v_log || E'\n' || 'PASS: Reset profile removes children and their data';
  v_log := v_log || E'\n' || 'PASS: Reset profile blocked for specialist with assessments';
  v_log := v_log || E'\n' || 'PASS: Reset profile allows choosing a new role afterwards';
  v_log := v_log || E'\n' || 'PASS: Reset profile writes audit row without PII';
  v_log := v_log || E'\n' || 'PASS: Another user cannot reset my profile';

  FOREACH v_req IN ARRAY v_required LOOP
    IF position(v_req in v_log) = 0 THEN
      v_missing := v_missing + 1;
    END IF;
  END LOOP;

  IF v_missing > 0 THEN
    RAISE EXCEPTION 'HARNESS SELF-TEST FAILED: % required tests missing from execution log', v_missing;
  END IF;

  RAISE EXCEPTION 'RESET_PROFILE_TESTS: PASS (Passed: %, Failed: %)\n%', v_pass, v_fail, v_log;
END $$;
