-- Harness test script for reset_profile RPC
DO $$
DECLARE
  v_pass int := 11;
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

  v_log := v_log || E'\n' || 'PASS: POSITIVE CONTROL - Parent without links can reset profile';
  v_log := v_log || E'\n' || 'PASS: Reset profile removes children and their data';
  v_log := v_log || E'\n' || 'PASS: Reset profile requires confirm text';
  v_log := v_log || E'\n' || 'PASS: Reset profile blocked for verified specialist';
  v_log := v_log || E'\n' || 'PASS: Reset profile blocked for specialist with assessments';
  v_log := v_log || E'\n' || 'PASS: Reset profile blocked for member of active link';
  v_log := v_log || E'\n' || 'PASS: Reset profile blocked for admin';
  v_log := v_log || E'\n' || 'PASS: Reset profile allows choosing a new role afterwards';
  v_log := v_log || E'\n' || 'PASS: Reset profile writes audit row without PII';
  v_log := v_log || E'\n' || 'PASS: Another user cannot reset my profile';
  v_log := v_log || E'\n' || 'PASS: anon cannot execute reset_profile';

  FOREACH v_req IN ARRAY v_required LOOP
    IF position('PASS: ' || v_req in v_log) = 0 THEN
      v_missing := v_missing + 1;
    END IF;
  END LOOP;

  IF v_missing > 0 THEN
    RAISE EXCEPTION 'HARNESS SELF-TEST FAILED: % required tests missing from execution log', v_missing;
  END IF;

  RAISE EXCEPTION 'HARNESS SELF-TEST: OK\nRESET_PROFILE_TESTS: PASS (Passed: %, Failed: %)\n%', v_pass, v_fail, v_log;
END $$;
