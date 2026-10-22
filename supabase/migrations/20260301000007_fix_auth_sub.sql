-- Migration: Fix auth.uid() usage for Firebase UIDs (replace with auth.jwt()->>'sub')
-- LinguaCare Fix-2

-- 1. Ensure actor_uid in activity_sessions is TEXT, not UUID (Firebase UIDs are strings)
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'activity_sessions' AND column_name = 'actor_uid' AND data_type = 'uuid'
  ) THEN
    ALTER TABLE activity_sessions ALTER COLUMN actor_uid TYPE TEXT USING actor_uid::TEXT;
  END IF;
END $$;

-- ==========================================
-- 2. RECREATE SCREENING_SESSIONS POLICIES
-- ==========================================
DROP POLICY IF EXISTS "Parents can insert screening sessions for own children" ON screening_sessions;
DROP POLICY IF EXISTS "Parents can select screening sessions for own children" ON screening_sessions;
DROP POLICY IF EXISTS "Parents can delete screening sessions for own children" ON screening_sessions;
DROP POLICY IF EXISTS "Adults can insert self screening sessions" ON screening_sessions;
DROP POLICY IF EXISTS "Adults can select self screening sessions" ON screening_sessions;
DROP POLICY IF EXISTS "Adults can delete self screening sessions" ON screening_sessions;
DROP POLICY IF EXISTS "No updates allowed on screening sessions" ON screening_sessions;

CREATE POLICY "Parents can insert screening sessions for own children"
  ON screening_sessions FOR INSERT
  WITH CHECK (
    child_id IS NOT NULL
    AND respondent_uid = auth.jwt()->>'sub'
    AND child_id IN (SELECT id FROM children WHERE parent_uid = auth.jwt()->>'sub')
  );

CREATE POLICY "Parents can select screening sessions for own children"
  ON screening_sessions FOR SELECT
  USING (
    child_id IS NOT NULL
    AND child_id IN (SELECT id FROM children WHERE parent_uid = auth.jwt()->>'sub')
  );

CREATE POLICY "Parents can delete screening sessions for own children"
  ON screening_sessions FOR DELETE
  USING (
    child_id IS NOT NULL
    AND child_id IN (SELECT id FROM children WHERE parent_uid = auth.jwt()->>'sub')
  );

CREATE POLICY "Adults can insert self screening sessions"
  ON screening_sessions FOR INSERT
  WITH CHECK (
    subject_uid IS NOT NULL
    AND subject_uid = auth.jwt()->>'sub'
    AND respondent_uid = auth.jwt()->>'sub'
  );

CREATE POLICY "Adults can select self screening sessions"
  ON screening_sessions FOR SELECT
  USING (
    subject_uid IS NOT NULL
    AND subject_uid = auth.jwt()->>'sub'
  );

CREATE POLICY "Adults can delete self screening sessions"
  ON screening_sessions FOR DELETE
  USING (
    subject_uid IS NOT NULL
    AND subject_uid = auth.jwt()->>'sub'
  );

CREATE POLICY "No updates allowed on screening sessions"
  ON screening_sessions FOR UPDATE
  USING (false);


-- ==========================================
-- 3. RECREATE ACTIVITY_SESSIONS POLICIES
-- ==========================================
DROP POLICY IF EXISTS "Parents manage child activity sessions" ON activity_sessions;
DROP POLICY IF EXISTS "Adults manage self activity sessions" ON activity_sessions;
DROP POLICY IF EXISTS "No update on activity sessions" ON activity_sessions;

CREATE POLICY "Parents manage child activity sessions" ON activity_sessions
    FOR ALL
    USING (
        child_id IS NOT NULL AND
        actor_uid = auth.jwt()->>'sub' AND
        EXISTS (
            SELECT 1 FROM children c
            WHERE c.id = activity_sessions.child_id AND c.parent_uid = auth.jwt()->>'sub'
        )
    )
    WITH CHECK (
        child_id IS NOT NULL AND
        actor_uid = auth.jwt()->>'sub' AND
        EXISTS (
            SELECT 1 FROM children c
            WHERE c.id = activity_sessions.child_id AND c.parent_uid = auth.jwt()->>'sub'
        )
    );

CREATE POLICY "Adults manage self activity sessions" ON activity_sessions
    FOR ALL
    USING (
        subject_uid IS NOT NULL AND
        subject_uid = auth.jwt()->>'sub' AND
        actor_uid = auth.jwt()->>'sub'
    )
    WITH CHECK (
        subject_uid IS NOT NULL AND
        subject_uid = auth.jwt()->>'sub' AND
        actor_uid = auth.jwt()->>'sub'
    );

CREATE POLICY "No update on activity sessions" ON activity_sessions
    FOR UPDATE
    USING (false);
