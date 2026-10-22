-- Migration 000019: Harden Security, Revoke Anon Access, Fix Search Paths, Remove Client UPDATE on Screening/Activity Sessions

-- 1. Revoke all public table, view, and sequence access from anon and public
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM anon, public;
REVOKE ALL ON ALL SEQUENCES IN SCHEMA public FROM anon, public;
REVOKE ALL ON ALL FUNCTIONS IN SCHEMA public FROM anon, public;

ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE ALL ON TABLES FROM anon, public;
ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE ALL ON SEQUENCES FROM anon, public;
ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE ALL ON FUNCTIONS FROM anon, public;

-- Grant table/sequence access to authenticated (RLS enforced)
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO authenticated;

-- Specifically revoke UPDATE on tables where client updates are forbidden by design
REVOKE UPDATE ON screening_sessions FROM authenticated;
REVOKE UPDATE ON activity_sessions FROM authenticated;
REVOKE UPDATE ON invites FROM authenticated;
REVOKE UPDATE ON links FROM authenticated;
REVOKE UPDATE ON invite_attempts FROM authenticated;
REVOKE UPDATE ON access_audit FROM authenticated;
REVOKE UPDATE ON content_items FROM authenticated;

GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- Grant EXECUTE only to authenticated on client-called RPCs
GRANT EXECUTE ON FUNCTION complete_profile TO authenticated;
GRANT EXECUTE ON FUNCTION add_child TO authenticated;
GRANT EXECUTE ON FUNCTION create_invite TO authenticated;
GRANT EXECUTE ON FUNCTION preview_invite TO authenticated;
GRANT EXECUTE ON FUNCTION accept_invite TO authenticated;
GRANT EXECUTE ON FUNCTION list_my_links TO authenticated;
GRANT EXECUTE ON FUNCTION revoke_link TO authenticated;
GRANT EXECUTE ON FUNCTION get_shared_summary TO authenticated;
GRANT EXECUTE ON FUNCTION list_access_log TO authenticated;

-- 2. Fix search_path on advisor-flagged functions
ALTER FUNCTION update_updated_at_column() SET search_path = public;
ALTER FUNCTION compute_child_band_and_enforce_age() SET search_path = public;
ALTER FUNCTION protect_profile_updates() SET search_path = public;
ALTER FUNCTION generate_invite_code() SET search_path = public;
ALTER FUNCTION populate_observation_author() SET search_path = public;
ALTER FUNCTION protect_observation_updates() SET search_path = public;
ALTER FUNCTION populate_goal_author() SET search_path = public;
ALTER FUNCTION protect_goal_updates() SET search_path = public;

-- 3. Ensure no UPDATE policies exist for screening_sessions and activity_sessions
DROP POLICY IF EXISTS "No update on activity sessions" ON activity_sessions;
DROP POLICY IF EXISTS "No updates allowed on screening sessions" ON screening_sessions;

-- 4. Refine Observations and Goals UPDATE and DELETE Policies
DROP POLICY IF EXISTS "Observations update policy" ON observations;
CREATE POLICY "Observations update policy" ON observations
  FOR UPDATE
  USING (
    author_uid = auth.jwt()->>'sub'
    AND (
      child_id IN (SELECT id FROM children WHERE parent_uid = auth.jwt()->>'sub')
      OR EXISTS (
        SELECT 1 FROM links l
        JOIN profiles p ON p.uid = l.member_uid
        WHERE l.child_id = observations.child_id
          AND l.member_uid = auth.jwt()->>'sub'
          AND l.status = 'active'
          AND l.scope = 'progress_notes'
          AND (l.expires_at IS NULL OR l.expires_at > now())
          AND (l.member_role <> 'specialist'::user_role OR p.verified = true)
      )
    )
  )
  WITH CHECK (
    author_uid = auth.jwt()->>'sub'
  );

DROP POLICY IF EXISTS "Observations delete policy" ON observations;
CREATE POLICY "Observations delete policy" ON observations
  FOR DELETE
  USING (
    author_uid = auth.jwt()->>'sub'
    OR (
      NOT private
      AND child_id IN (SELECT id FROM children WHERE parent_uid = auth.jwt()->>'sub')
    )
  );

DROP POLICY IF EXISTS "Goals update policy" ON goals;
CREATE POLICY "Goals update policy" ON goals
  FOR UPDATE
  USING (
    author_uid = auth.jwt()->>'sub'
    OR child_id IN (SELECT id FROM children WHERE parent_uid = auth.jwt()->>'sub')
  )
  WITH CHECK (
    author_uid = auth.jwt()->>'sub'
    OR child_id IN (SELECT id FROM children WHERE parent_uid = auth.jwt()->>'sub')
  );

DROP POLICY IF EXISTS "Goals delete policy" ON goals;
CREATE POLICY "Goals delete policy" ON goals
  FOR DELETE
  USING (
    author_uid = auth.jwt()->>'sub'
    OR child_id IN (SELECT id FROM children WHERE parent_uid = auth.jwt()->>'sub')
  );
