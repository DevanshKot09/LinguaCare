-- Migration 000030: Use clock_timestamp() in withdraw_consent for strict ordering

CREATE OR REPLACE FUNCTION withdraw_consent(p_type text, p_child_id uuid DEFAULT NULL)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid text;
begin
  v_uid := auth.jwt()->>'sub';
  if v_uid is null then
    raise exception 'Unauthorized';
  end if;

  INSERT INTO consents (uid, child_id, type, granted, at)
  VALUES (v_uid, p_child_id, p_type, false, clock_timestamp());
END;
$$;
GRANT EXECUTE ON FUNCTION withdraw_consent(text, uuid) TO authenticated, service_role;
