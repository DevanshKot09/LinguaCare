-- Migration 000017: Fix-17 - Harden author derivation triggers with explicit session role check

CREATE OR REPLACE FUNCTION populate_observation_author()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  v_role user_role;
  v_uid text;
  v_session_role text;
BEGIN
  v_session_role := current_setting('role', true);
  IF v_session_role IS NULL THEN
    v_session_role := current_user;
  END IF;

  IF v_session_role IN ('postgres', 'supabase_admin', 'service_role') THEN
    v_uid := COALESCE(NEW.author_uid, auth.jwt()->>'sub');
    IF v_uid IS NULL THEN
      RAISE EXCEPTION 'Unauthorized: missing author_uid for elevated role';
    END IF;
    NEW.author_uid := v_uid;
    SELECT role INTO v_role FROM profiles WHERE uid = v_uid;
    NEW.author_role := COALESCE(NEW.author_role, v_role, 'parent'::user_role);
  ELSE
    -- For authenticated or anon, ALWAYS overwrite author_uid and author_role from JWT sub and profiles
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

CREATE OR REPLACE FUNCTION populate_goal_author()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  v_role user_role;
  v_uid text;
  v_session_role text;
BEGIN
  v_session_role := current_setting('role', true);
  IF v_session_role IS NULL THEN
    v_session_role := current_user;
  END IF;

  IF v_session_role IN ('postgres', 'supabase_admin', 'service_role') THEN
    v_uid := COALESCE(NEW.author_uid, auth.jwt()->>'sub');
    IF v_uid IS NULL THEN
      RAISE EXCEPTION 'Unauthorized: missing author_uid for elevated role';
    END IF;
    SELECT role INTO v_role FROM profiles WHERE uid = v_uid;
    IF v_role = 'teacher'::user_role THEN
      RAISE EXCEPTION 'Teachers are not permitted to create or edit goals';
    END IF;
    NEW.author_uid := v_uid;
    NEW.author_role := COALESCE(NEW.author_role, v_role, 'parent'::user_role);
  ELSE
    -- For authenticated or anon, ALWAYS overwrite author_uid and author_role from JWT sub and profiles
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
