-- Migration 000020: Add deny_updates triggers for screening_sessions and activity_sessions, and strengthen observation update protection

CREATE OR REPLACE FUNCTION deny_updates()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  RAISE EXCEPTION 'Updates are not permitted on this table';
END;
$$;

DROP TRIGGER IF EXISTS trg_deny_screening_updates ON screening_sessions;
CREATE TRIGGER trg_deny_screening_updates
  BEFORE UPDATE ON screening_sessions
  FOR EACH ROW
  EXECUTE FUNCTION deny_updates();

DROP TRIGGER IF EXISTS trg_deny_activity_updates ON activity_sessions;
CREATE TRIGGER trg_deny_activity_updates
  BEFORE UPDATE ON activity_sessions
  FOR EACH ROW
  EXECUTE FUNCTION deny_updates();

CREATE OR REPLACE FUNCTION protect_observation_updates()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY INVOKER
AS $$
BEGIN
  IF NEW.author_uid <> OLD.author_uid OR NEW.author_role <> OLD.author_role OR NEW.child_id <> OLD.child_id OR NEW.created_at <> OLD.created_at THEN
    RAISE EXCEPTION 'Protected observation fields cannot be modified';
  END IF;
  IF OLD.author_uid <> COALESCE(auth.jwt()->>'sub', current_user) THEN
    RAISE EXCEPTION 'Non-author cannot update observation';
  END IF;
  NEW.updated_at := NOW();
  RETURN NEW;
END;
$$;

ALTER FUNCTION deny_updates() SET search_path = public;
ALTER FUNCTION protect_observation_updates() SET search_path = public;
