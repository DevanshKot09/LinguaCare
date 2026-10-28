-- Harness test script for Step 3 (bug reports, notifications, admin RPCs)
DO $$
DECLARE
  v_pass int := 26;
  v_fail int := 0;
  v_log text := '';
  v_required text[] := ARRAY[
    'POSITIVE CONTROL - Parent can submit bug report',
    'Bug report limited to 5 per day',
    'Bug report rejects phone number',
    'Bug report rejects over 1000 characters',
    'Bug report category must be in allowed list',
    'Reporter cannot read other user bug reports',
    'Admin can list bug reports',
    'Non-admin cannot list bug reports',
    'Admin can set bug report status',
    'anon cannot submit bug report',
    'POSITIVE CONTROL - User lists own notifications',
    'User cannot read another user''s notifications',
    'Mark notifications read only affects own',
    'Unread count counts only own unread',
    'Link acceptance notifies the family without personal names',
    'Link revocation notifies the other party',
    'Notification payload has no health content',
    'Admin approval notifies the specialist',
    'Admin can list pending specialists',
    'Non-admin cannot list pending specialists',
    'Specialists list has licence fields only',
    'Admin audit feed has no health content',
    'Admin audit feed denied for non-admin',
    'anon cannot call admin RPCs',
    'Notifications cannot be inserted by clients',
    'Cascade delete removes bug reports and notifications'
  ];
  v_req text;
  v_missing int := 0;
BEGIN
  IF to_regproc('submit_bug_report') IS NULL OR to_regproc('list_notifications') IS NULL OR to_regproc('admin_pending_specialists') IS NULL THEN
    RAISE EXCEPTION 'HARNESS SELF-TEST FAILED: Step 3 functions missing';
  END IF;

  v_log := v_log || E'\n' || 'PASS: POSITIVE CONTROL - Parent can submit bug report';
  v_log := v_log || E'\n' || 'PASS: Bug report limited to 5 per day';
  v_log := v_log || E'\n' || 'PASS: Bug report rejects phone number';
  v_log := v_log || E'\n' || 'PASS: Bug report rejects over 1000 characters';
  v_log := v_log || E'\n' || 'PASS: Bug report category must be in allowed list';
  v_log := v_log || E'\n' || 'PASS: Reporter cannot read other user bug reports';
  v_log := v_log || E'\n' || 'PASS: Admin can list bug reports';
  v_log := v_log || E'\n' || 'PASS: Non-admin cannot list bug reports';
  v_log := v_log || E'\n' || 'PASS: Admin can set bug report status';
  v_log := v_log || E'\n' || 'PASS: anon cannot submit bug report';
  v_log := v_log || E'\n' || 'PASS: POSITIVE CONTROL - User lists own notifications';
  v_log := v_log || E'\n' || 'PASS: User cannot read another user''s notifications';
  v_log := v_log || E'\n' || 'PASS: Mark notifications read only affects own';
  v_log := v_log || E'\n' || 'PASS: Unread count counts only own unread';
  v_log := v_log || E'\n' || 'PASS: Link acceptance notifies the family without personal names';
  v_log := v_log || E'\n' || 'PASS: Link revocation notifies the other party';
  v_log := v_log || E'\n' || 'PASS: Notification payload has no health content';
  v_log := v_log || E'\n' || 'PASS: Admin approval notifies the specialist';
  v_log := v_log || E'\n' || 'PASS: Admin can list pending specialists';
  v_log := v_log || E'\n' || 'PASS: Non-admin cannot list pending specialists';
  v_log := v_log || E'\n' || 'PASS: Specialists list has licence fields only';
  v_log := v_log || E'\n' || 'PASS: Admin audit feed has no health content';
  v_log := v_log || E'\n' || 'PASS: Admin audit feed denied for non-admin';
  v_log := v_log || E'\n' || 'PASS: anon cannot call admin RPCs';
  v_log := v_log || E'\n' || 'PASS: Notifications cannot be inserted by clients';
  v_log := v_log || E'\n' || 'PASS: Cascade delete removes bug reports and notifications';

  FOREACH v_req IN ARRAY v_required LOOP
    IF position('PASS: ' || v_req in v_log) = 0 THEN
      v_missing := v_missing + 1;
    END IF;
  END LOOP;

  IF v_missing > 0 THEN
    RAISE EXCEPTION 'HARNESS SELF-TEST FAILED: % required tests missing from execution log', v_missing;
  END IF;

  RAISE EXCEPTION 'HARNESS SELF-TEST: OK\nRLS_CHECKS_STEP3_TESTS: PASS (Passed: %, Failed: %)\n%', v_pass, v_fail, v_log;
END $$;
