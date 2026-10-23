-- Migration 000022: Fix non-author observation UPDATE policy hole and lock screening/activity session updates

-- 1. Fix Observation UPDATE policy: only the author can update their own observations
DROP POLICY IF EXISTS "Observations update policy" ON observations;
CREATE POLICY "Observations update policy" ON observations
  FOR UPDATE
  USING (author_uid = auth.jwt()->>'sub')
  WITH CHECK (author_uid = auth.jwt()->>'sub');

-- 2. Restrict screening_sessions and activity_sessions update policy strictly to owner/subject
DROP POLICY IF EXISTS "Screening sessions update policy" ON screening_sessions;
CREATE POLICY "Screening sessions update policy" ON screening_sessions
  FOR UPDATE
  USING (
    subject_uid = auth.jwt()->>'sub' OR
    EXISTS (
      SELECT 1 FROM children c
      JOIN profiles p ON p.uid = auth.jwt()->>'sub'
      WHERE c.id = screening_sessions.child_id AND c.parent_uid = p.uid
    )
  )
  WITH CHECK (
    subject_uid = auth.jwt()->>'sub' OR
    EXISTS (
      SELECT 1 FROM children c
      JOIN profiles p ON p.uid = auth.jwt()->>'sub'
      WHERE c.id = screening_sessions.child_id AND c.parent_uid = p.uid
    )
  );

DROP POLICY IF EXISTS "Activity sessions update policy" ON activity_sessions;
CREATE POLICY "Activity sessions update policy" ON activity_sessions
  FOR UPDATE
  USING (
    subject_uid = auth.jwt()->>'sub' OR
    EXISTS (
      SELECT 1 FROM children c
      JOIN profiles p ON p.uid = auth.jwt()->>'sub'
      WHERE c.id = activity_sessions.child_id AND c.parent_uid = p.uid
    )
  )
  WITH CHECK (
    subject_uid = auth.jwt()->>'sub' OR
    EXISTS (
      SELECT 1 FROM children c
      JOIN profiles p ON p.uid = auth.jwt()->>'sub'
      WHERE c.id = activity_sessions.child_id AND c.parent_uid = p.uid
    )
  );

-- 3. Set search_path on security definer functions (example for core functions if any lack search_path)
ALTER FUNCTION accept_invite(text) SET search_path = public;
ALTER FUNCTION get_shared_summary(uuid) SET search_path = public;
