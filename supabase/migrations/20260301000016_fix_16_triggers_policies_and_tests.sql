-- Migration 000016: Fix-16 - Robust triggers, strict WITH CHECK policies, and test fixes

-- 1. Observations Author Derivation Trigger (Unconditionally overwrites author_uid & author_role)
CREATE OR REPLACE FUNCTION populate_observation_author()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  v_role user_role;
  v_uid text;
BEGIN
  v_uid := COALESCE(
    auth.jwt()->>'sub',
    CASE WHEN current_user IN ('postgres', 'supabase_admin') THEN NEW.author_uid ELSE NULL END
  );
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Unauthorized: missing JWT sub';
  END IF;
  NEW.author_uid := v_uid;
  SELECT role INTO v_role FROM profiles WHERE uid = v_uid;
  NEW.author_role := COALESCE(v_role, 'parent'::user_role);
  NEW.updated_at := NOW();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_populate_observation_author ON observations;
CREATE TRIGGER trg_populate_observation_author
  BEFORE INSERT ON observations
  FOR EACH ROW
  EXECUTE FUNCTION populate_observation_author();

-- Observations Update Protection Trigger
CREATE OR REPLACE FUNCTION protect_observation_updates()
RETURNS TRIGGER
LANGUAGE plpgsql
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

-- 2. Goals Author Derivation Trigger (Unconditionally overwrites author_uid & author_role)
CREATE OR REPLACE FUNCTION populate_goal_author()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  v_role user_role;
  v_uid text;
BEGIN
  v_uid := COALESCE(
    auth.jwt()->>'sub',
    CASE WHEN current_user IN ('postgres', 'supabase_admin') THEN NEW.author_uid ELSE NULL END
  );
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Unauthorized: missing JWT sub';
  END IF;
  SELECT role INTO v_role FROM profiles WHERE uid = v_uid;
  IF v_role = 'teacher'::user_role THEN
    RAISE EXCEPTION 'Teachers are not permitted to create or edit goals';
  END IF;
  NEW.author_uid := v_uid;
  NEW.author_role := COALESCE(v_role, 'parent'::user_role);
  NEW.updated_at := NOW();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_populate_goal_author ON goals;
CREATE TRIGGER trg_populate_goal_author
  BEFORE INSERT ON goals
  FOR EACH ROW
  EXECUTE FUNCTION populate_goal_author();

-- Goals Update Protection Trigger
CREATE OR REPLACE FUNCTION protect_goal_updates()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  v_role user_role;
  v_uid text;
BEGIN
  v_uid := COALESCE(auth.jwt()->>'sub', NEW.author_uid);
  SELECT role INTO v_role FROM profiles WHERE uid = v_uid;
  IF v_role = 'teacher'::user_role THEN
    RAISE EXCEPTION 'Teachers are not permitted to create or edit goals';
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

-- 3. Restore Strict WITH CHECK Policies for Observations & Goals
DROP POLICY IF EXISTS "Observations insert policy" ON observations;
CREATE POLICY "Observations insert policy" ON observations
  FOR INSERT WITH CHECK (
    author_uid = (auth.jwt()->>'sub')
    AND (
      child_id IN (SELECT id FROM children WHERE parent_uid = (auth.jwt()->>'sub'))
      OR EXISTS (
        SELECT 1 FROM links l
        WHERE l.child_id = observations.child_id
          AND l.member_uid = (auth.jwt()->>'sub')
          AND l.status = 'active'
          AND l.scope = 'progress_notes'
          AND (l.expires_at IS NULL OR l.expires_at > NOW())
      )
    )
  );

DROP POLICY IF EXISTS "Goals insert policy" ON goals;
CREATE POLICY "Goals insert policy" ON goals
  FOR INSERT WITH CHECK (
    author_uid = (auth.jwt()->>'sub')
    AND author_role <> 'teacher'::user_role
    AND (
      child_id IN (SELECT id FROM children WHERE parent_uid = (auth.jwt()->>'sub'))
      OR EXISTS (
        SELECT 1 FROM links l
        WHERE l.child_id = goals.child_id
          AND l.member_uid = (auth.jwt()->>'sub')
          AND l.status = 'active'
          AND (l.expires_at IS NULL OR l.expires_at > NOW())
      )
    )
  );
