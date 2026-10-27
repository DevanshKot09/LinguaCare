-- Migration 000027: reset_profile RPC and security hardening

CREATE OR REPLACE FUNCTION reset_profile(p_confirm text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid text;
  v_role user_role;
  v_verified boolean;
  v_has_assessments boolean := false;
  v_has_active_link boolean := false;
BEGIN
  v_uid := auth.jwt()->>'sub';
  if v_uid is null then
    raise exception 'Unauthorized';
  end if;

  if p_confirm IS DISTINCT FROM 'RESET' then
    raise exception 'Confirmation text must be RESET';
  end if;

  select role, verified into v_role, v_verified from profiles where uid = v_uid;
  if v_role = 'admin'::user_role then
    raise exception 'Reset profile blocked for admin';
  end if;

  if v_role = 'specialist'::user_role and v_verified then
    raise exception 'Reset profile blocked for verified specialist';
  end if;

  if v_role = 'specialist'::user_role then
    select exists (
      select 1 from clinical_assessments where specialist_uid = v_uid
    ) into v_has_assessments;

    if v_has_assessments then
      raise exception 'Reset profile blocked for specialist with assessments';
    end if;
  end if;

  -- Check if user is member of any active link
  select exists (
    select 1 from links
    where member_uid = v_uid
      and status = 'active'
      and (expires_at is null or expires_at > now())
  ) into v_has_active_link;

  if v_has_active_link then
    raise exception 'Reset profile blocked for member of active link';
  end if;

  -- Cascade delete child data (which cascades to screening sessions, activity sessions, observations, goals, etc.)
  delete from children where parent_uid = v_uid;

  -- Delete role detail rows
  delete from teacher_details where uid = v_uid;
  delete from specialist_details where uid = v_uid;

  -- Delete profile row
  delete from profiles where uid = v_uid;

  -- Write access audit row without PII
  insert into access_audit (actor_uid, action, table_name)
  values (v_uid, 'reset_profile', 'profiles');
END;
$$;

REVOKE EXECUTE ON FUNCTION reset_profile(text) FROM anon, public;
GRANT EXECUTE ON FUNCTION reset_profile(text) TO authenticated;
