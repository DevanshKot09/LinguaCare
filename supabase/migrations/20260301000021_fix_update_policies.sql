-- Migration 000021: Add UPDATE policies on screening_sessions, activity_sessions, and observations with USING (true) so triggers always fire and enforce access control

DROP POLICY IF EXISTS "No updates allowed on screening sessions" ON screening_sessions;
DROP POLICY IF EXISTS "Screening sessions update policy" ON screening_sessions;
CREATE POLICY "Screening sessions update policy" ON screening_sessions
  FOR UPDATE
  USING (true)
  WITH CHECK (false);

DROP POLICY IF EXISTS "No update on activity sessions" ON activity_sessions;
DROP POLICY IF EXISTS "Activity sessions update policy" ON activity_sessions;
CREATE POLICY "Activity sessions update policy" ON activity_sessions
  FOR UPDATE
  USING (true)
  WITH CHECK (false);

DROP POLICY IF EXISTS "Observations update policy" ON observations;
CREATE POLICY "Observations update policy" ON observations
  FOR UPDATE
  USING (true)
  WITH CHECK (author_uid = auth.jwt()->>'sub');
