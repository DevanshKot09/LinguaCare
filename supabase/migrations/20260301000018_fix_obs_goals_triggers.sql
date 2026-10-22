-- Migration 000018: Fix observation and goal triggers for elevated roles (postgres, service_role, supabase_admin) and authenticated/anon roles
-- Uses SECURITY INVOKER and auth.role() to ensure correct role evaluation and permit fixture insertions while strictly enforcing auth.jwt()->>'sub' for client requests.

CREATE OR REPLACE FUNCTION populate_observation_author()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY INVOKER
AS $$
DECLARE
  v_role user_role;
  v_uid text;
  v_session_role text;
BEGIN
  v_session_role := COALESCE(auth.role(), current_user);

  IF v_session_role IN ('postgres', 'service_role', 'supabase_admin', 'cli_login_postgres', 'supabase_privileged_role') THEN
    v_uid := NEW.author_uid;
    IF v_uid IS NULL OR v_uid = '' THEN
      RAISE EXCEPTION 'Unauthorized: missing author_uid for elevated role';
    END IF;
    NEW.author_uid := v_uid;
    SELECT role INTO v_role FROM profiles WHERE uid = v_uid;
    NEW.author_role := COALESCE(NEW.author_role, v_role, 'parent'::user_role);
  ELSE
    -- authenticated or anon: require non-null sub, and ALWAYS overwrite author_uid and author_role from JWT sub and profiles
    v_uid := auth.jwt()->>'sub';
    IF v_uid IS NULL OR v_uid = '' THEN
      RAISE EXCEPTION 'Unauthorized: missing or null JWT sub';
    END IF;
    NEW.author_uid := v_uid;
    SELECT role INTO v_role FROM profiles WHERE uid = v_uid;
    NEW.author_role := COALESCE(v_role, 'parent'::user_role);
  END IF;

  NEW.updated_at := NOW();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_populate_observation_author ON observations;
CREATE TRIGGER trg_populate_observation_author
  BEFORE INSERT ON observations
  FOR EACH ROW
  EXECUTE FUNCTION populate_observation_author();

CREATE OR REPLACE FUNCTION protect_observation_updates()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY INVOKER
AS $$
BEGIN
  IF NEW.author_uid <> OLD.author_uid OR NEW.author_role <> OLD.author_role OR NEW.child_id <> OLD.child_id OR NEW.created_at <> OLD.created_at THEN
    RAISE EXCEPTION 'Protected observation fields cannot be modified';
  END IF;
  NEW.updated_at := NOW();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_protect_observation_updates ON observations;
CREATE TRIGGER trg_protect_observation_updates
  BEFORE UPDATE ON observations
  FOR EACH ROW
  EXECUTE FUNCTION protect_observation_updates();

CREATE OR REPLACE FUNCTION populate_goal_author()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY INVOKER
AS $$
DECLARE
  v_role user_role;
  v_uid text;
  v_session_role text;
BEGIN
  v_session_role := COALESCE(auth.role(), current_user);

  IF v_session_role IN ('postgres', 'service_role', 'supabase_admin', 'cli_login_postgres', 'supabase_privileged_role') THEN
    v_uid := NEW.author_uid;
    IF v_uid IS NULL OR v_uid = '' THEN
      RAISE EXCEPTION 'Unauthorized: missing author_uid for elevated role';
    END IF;
    SELECT role INTO v_role FROM profiles WHERE uid = v_uid;
    IF v_role = 'teacher'::user_role THEN
      RAISE EXCEPTION 'Teachers are not permitted to create or edit goals';
    END IF;
    NEW.author_uid := v_uid;
    NEW.author_role := COALESCE(NEW.author_role, v_role, 'parent'::user_role);
  ELSE
    -- authenticated or anon: require non-null sub, and ALWAYS overwrite author_uid and author_role from JWT sub and profiles
    v_uid := auth.jwt()->>'sub';
    IF v_uid IS NULL OR v_uid = '' THEN
      RAISE EXCEPTION 'Unauthorized: missing or null JWT sub';
    END IF;
    SELECT role INTO v_role FROM profiles WHERE uid = v_uid;
    IF v_role = 'teacher'::user_role THEN
      RAISE EXCEPTION 'Teachers are not permitted to create or edit goals';
    END IF;
    NEW.author_uid := v_uid;
    NEW.author_role := COALESCE(v_role, 'parent'::user_role);
  END IF;

  NEW.updated_at := NOW();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_populate_goal_author ON goals;
CREATE TRIGGER trg_populate_goal_author
  BEFORE INSERT ON goals
  FOR EACH ROW
  EXECUTE FUNCTION populate_goal_author();

CREATE OR REPLACE FUNCTION protect_goal_updates()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY INVOKER
AS $$
DECLARE
  v_role user_role;
  v_session_role text;
  v_uid text;
  v_prole user_role;
BEGIN
  v_session_role := COALESCE(auth.role(), current_user);
  IF v_session_role NOT IN ('postgres', 'service_role', 'supabase_admin', 'cli_login_postgres', 'supabase_privileged_role') THEN
    v_uid := auth.jwt()->>'sub';
    SELECT role INTO v_prole FROM profiles WHERE uid = v_uid;
    IF v_prole = 'teacher'::user_role THEN
      RAISE EXCEPTION 'Teachers are not permitted to create or edit goals';
    END IF;
  END IF;

  IF NEW.author_uid <> OLD.author_uid OR NEW.author_role <> OLD.author_role OR NEW.child_id <> OLD.child_id OR NEW.created_at <> OLD.created_at THEN
    RAISE EXCEPTION 'Protected goal fields cannot be modified';
  END IF;
  NEW.updated_at := NOW();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_protect_goal_updates ON goals;
CREATE TRIGGER trg_protect_goal_updates
  BEFORE UPDATE ON goals
  FOR EACH ROW
  EXECUTE FUNCTION protect_goal_updates();
