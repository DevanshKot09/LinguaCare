DO $$
DECLARE
  v_admin_uid text;
  v_res jsonb;
BEGIN
  -- Verify admin_overview function exists and security constraints work
  if to_regproc('admin_overview') is null then
    raise exception 'FAIL: admin_overview function does not exist';
  end if;

  -- Test call as unauthenticated (anon) should fail or raise unauthorized/forbidden
  perform set_config('request.jwt.claims', '{"sub": "anon_user", "role": "anon"}', true);
  begin
    perform admin_overview();
    raise exception 'FAIL: anon was allowed to call admin_overview';
  exception when others then
    if sqlerrm like '%FAIL:%' then
      raise;
    end if;
    -- Expected denial
  end;

  RAISE EXCEPTION 'ADMIN_OVERVIEW_CHECK: PASS';
END $$;
