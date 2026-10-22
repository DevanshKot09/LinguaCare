-- Migration: Fix RLS, triggers, grant permissions, and RPC bugs (Migration 000014)
-- LinguaCare Security Harden & Test Fixes

-- 1. Ensure auth.jwt() helper function exists in auth schema
CREATE SCHEMA IF NOT EXISTS auth;
CREATE OR REPLACE FUNCTION auth.jwt()
RETURNS JSONB
LANGUAGE SQL
STABLE
AS $$
  SELECT COALESCE(
    NULLIF(CURRENT_SETTING('request.jwt.claims', true), '')::JSONB,
    jsonb_build_object('sub', CURRENT_SETTING('request.jwt.sub', true), 'role', CURRENT_SETTING('request.jwt.role', true))
  );
$$;

-- 2. Screening Sessions Policies
DROP POLICY IF EXISTS "Parents can insert screening sessions for own children" ON screening_sessions;
DROP POLICY IF EXISTS "Parents can select screening sessions for own children" ON screening_sessions;
DROP POLICY IF EXISTS "Parents can delete screening sessions for own children" ON screening_sessions;
DROP POLICY IF EXISTS "Adults can insert self screening sessions" ON screening_sessions;
DROP POLICY IF EXISTS "Adults can select self screening sessions" ON screening_sessions;
DROP POLICY IF EXISTS "Adults can delete self screening sessions" ON screening_sessions;

CREATE POLICY "Parents can insert screening sessions for own children"
  ON screening_sessions FOR INSERT
  WITH CHECK (
    child_id IS NOT NULL
    AND respondent_uid = (auth.jwt()->>'sub')
    AND (
      child_id IN (SELECT id FROM children WHERE parent_uid = (auth.jwt()->>'sub'))
      OR respondent_uid = (auth.jwt()->>'sub')
    )
  );

CREATE POLICY "Parents can select screening sessions for own children"
  ON screening_sessions FOR SELECT
  USING (
    (child_id IS NOT NULL AND child_id IN (SELECT id FROM children WHERE parent_uid = (auth.jwt()->>'sub')))
    OR respondent_uid = (auth.jwt()->>'sub')
    OR (subject_uid IS NOT NULL AND subject_uid = (auth.jwt()->>'sub'))
  );

CREATE POLICY "Parents can delete screening sessions for own children"
  ON screening_sessions FOR DELETE
  USING (
    (child_id IS NOT NULL AND child_id IN (SELECT id FROM children WHERE parent_uid = (auth.jwt()->>'sub')))
    OR respondent_uid = (auth.jwt()->>'sub')
  );

CREATE POLICY "Adults can insert self screening sessions"
  ON screening_sessions FOR INSERT
  WITH CHECK (
    subject_uid IS NOT NULL
    AND subject_uid = (auth.jwt()->>'sub')
    AND respondent_uid = (auth.jwt()->>'sub')
  );

CREATE POLICY "Adults can select self screening sessions"
  ON screening_sessions FOR SELECT
  USING (
    subject_uid IS NOT NULL
    AND subject_uid = (auth.jwt()->>'sub')
  );

CREATE POLICY "Adults can delete self screening sessions"
  ON screening_sessions FOR DELETE
  USING (
    subject_uid IS NOT NULL
    AND subject_uid = (auth.jwt()->>'sub')
  );

-- 3. Children Table Update Privileges & Trigger
REVOKE UPDATE ON children FROM authenticated, anon;
GRANT UPDATE (nickname, dob, home_languages, interests, concerns) ON children TO authenticated;

CREATE OR REPLACE FUNCTION protect_children_updates()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.parent_uid <> OLD.parent_uid OR NEW.id <> OLD.id OR NEW.created_at <> OLD.created_at THEN
    RAISE EXCEPTION 'Unauthorized attempt to modify protected child fields';
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_protect_children_updates ON children;
CREATE TRIGGER trg_protect_children_updates
  BEFORE UPDATE ON children
  FOR EACH ROW
  EXECUTE FUNCTION protect_children_updates();

-- 4. Observations & Goals Server-Side Author Derivation and Protection Triggers
CREATE OR REPLACE FUNCTION populate_observation_author()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  v_role user_role;
  v_uid text;
BEGIN
  v_uid := (auth.jwt()->>'sub');
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

CREATE OR REPLACE FUNCTION populate_goal_author()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  v_role user_role;
  v_uid text;
BEGIN
  v_uid := (auth.jwt()->>'sub');
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

CREATE OR REPLACE FUNCTION protect_goal_updates()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  v_role user_role;
  v_uid text;
BEGIN
  v_uid := (auth.jwt()->>'sub');
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

-- 5. Observations & Goals Policies
DROP POLICY IF EXISTS "Observations select policy" ON observations;
DROP POLICY IF EXISTS "Observations insert policy" ON observations;
DROP POLICY IF EXISTS "Observations update policy" ON observations;
DROP POLICY IF EXISTS "Observations delete policy" ON observations;

CREATE POLICY "Observations select policy" ON observations
  FOR SELECT USING (
    author_uid = (auth.jwt()->>'sub')
    OR (NOT private AND child_id IN (SELECT id FROM children WHERE parent_uid = (auth.jwt()->>'sub')))
    OR (NOT private AND EXISTS (
      SELECT 1 FROM links l
      WHERE l.child_id = observations.child_id
        AND l.member_uid = (auth.jwt()->>'sub')
        AND l.status = 'active'
        AND l.scope = 'progress_notes'
        AND (l.expires_at IS NULL OR l.expires_at > NOW())
    ))
  );

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

CREATE POLICY "Observations update policy" ON observations
  FOR UPDATE USING (
    author_uid = (auth.jwt()->>'sub')
    AND (
      author_uid IN (SELECT parent_uid FROM children WHERE id = child_id)
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

CREATE POLICY "Observations delete policy" ON observations
  FOR DELETE USING (
    author_uid = (auth.jwt()->>'sub')
    OR child_id IN (SELECT id FROM children WHERE parent_uid = (auth.jwt()->>'sub'))
  );

-- Goals Policies
DROP POLICY IF EXISTS "Goals select policy" ON goals;
DROP POLICY IF EXISTS "Goals insert policy" ON goals;
DROP POLICY IF EXISTS "Goals update policy" ON goals;
DROP POLICY IF EXISTS "Goals delete policy" ON goals;

CREATE POLICY "Goals select policy" ON goals
  FOR SELECT USING (
    author_uid = (auth.jwt()->>'sub')
    OR child_id IN (SELECT id FROM children WHERE parent_uid = (auth.jwt()->>'sub'))
    OR EXISTS (
      SELECT 1 FROM links l
      WHERE l.child_id = goals.child_id
        AND l.member_uid = (auth.jwt()->>'sub')
        AND l.status = 'active'
        AND (l.expires_at IS NULL OR l.expires_at > NOW())
    )
  );

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

CREATE POLICY "Goals update policy" ON goals
  FOR UPDATE USING (
    author_role <> 'teacher'::user_role
    AND (
      child_id IN (SELECT id FROM children WHERE parent_uid = (auth.jwt()->>'sub'))
      OR (
        author_uid = (auth.jwt()->>'sub')
        AND EXISTS (
          SELECT 1 FROM links l
          WHERE l.child_id = goals.child_id
            AND l.member_uid = (auth.jwt()->>'sub')
            AND l.status = 'active'
            AND (l.expires_at IS NULL OR l.expires_at > NOW())
        )
      )
    )
  );

CREATE POLICY "Goals delete policy" ON goals
  FOR DELETE USING (
    author_uid = (auth.jwt()->>'sub')
    OR child_id IN (SELECT id FROM children WHERE parent_uid = (auth.jwt()->>'sub'))
  );

-- 6. Fix list_access_log GROUP BY bug
CREATE OR REPLACE FUNCTION list_access_log(p_child_id uuid default null, p_link_id uuid default null)
RETURNS jsonb
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
declare
  v_uid text;
  v_result jsonb;
begin
  v_uid := auth.jwt()->>'sub';
  if v_uid is null then
    raise exception 'Unauthorized';
  end if;

  if p_child_id is not null and not exists (select 1 from children where id = p_child_id and parent_uid = v_uid) then
    raise exception 'Unauthorized or child not found';
  end if;

  if p_link_id is not null and not exists (select 1 from links where id = p_link_id and owner_uid = v_uid) then
    raise exception 'Unauthorized or link not found';
  end if;

  select jsonb_agg(
    jsonb_build_object(
      'member_name', t.full_name,
      'member_role', t.member_role,
      'action', t.action,
      'timestamp', t.at
    )
  ) into v_result
  from (
    select p.full_name, l.member_role, a.action, a.at
    from access_audit a
    join links l on a.record_id = l.id::text
    join profiles p on a.actor_uid = p.uid
    where (l.owner_uid = v_uid)
      and (p_link_id is null or l.id = p_link_id)
      and (p_child_id is null or l.child_id = p_child_id)
      and a.action in ('ACCEPT_INVITE', 'GET_SHARED_SUMMARY', 'REVOKE_LINK')
    order by a.at desc
  ) t;

  return coalesce(v_result, '[]'::jsonb);
end;
$$;
GRANT EXECUTE ON FUNCTION list_access_log TO authenticated;
