-- Migration 000023: Comprehensive Security Hardening and Policy Fixes

-- 1. Screening and Activity Sessions: Remove UPDATE policy and revoke UPDATE from authenticated, anon, PUBLIC
DROP POLICY IF EXISTS "Screening sessions update policy" ON screening_sessions;
DROP POLICY IF EXISTS "No updates allowed on screening sessions" ON screening_sessions;
REVOKE UPDATE ON screening_sessions FROM authenticated, anon, PUBLIC;

DROP POLICY IF EXISTS "Activity sessions update policy" ON activity_sessions;
DROP POLICY IF EXISTS "No update on activity sessions" ON activity_sessions;
REVOKE UPDATE ON activity_sessions FROM authenticated, anon, PUBLIC;

-- Ensure no client writes/updates on read-only/audit/system tables
REVOKE INSERT, UPDATE, DELETE ON invites FROM authenticated, anon, PUBLIC;
REVOKE INSERT, UPDATE, DELETE ON links FROM authenticated, anon, PUBLIC;
REVOKE INSERT, UPDATE, DELETE ON invite_attempts FROM authenticated, anon, PUBLIC;
REVOKE INSERT, UPDATE, DELETE ON access_audit FROM authenticated, anon, PUBLIC;
REVOKE INSERT, UPDATE, DELETE ON otp_codes FROM authenticated, anon, PUBLIC;
REVOKE INSERT, UPDATE, DELETE ON email_verifications FROM authenticated, anon, PUBLIC;
REVOKE INSERT, UPDATE, DELETE ON content_items FROM authenticated, anon, PUBLIC;

-- Grant INSERT on access_audit to authenticated (for audit logging via RPC / trigger if needed, or handled via security definer RPCs)
GRANT INSERT ON access_audit TO authenticated;

-- 2. Observations and Goals Policies & Immutability
-- observations UPDATE policy: author can update only if author_uid = auth.jwt()->>'sub' AND (parent of child OR active valid linked teacher/specialist with scope progress_notes, and verified specialist if specialist)
DROP POLICY IF EXISTS "Observations update policy" ON observations;
CREATE POLICY "Observations update policy" ON observations
  FOR UPDATE
  USING (
    author_uid = auth.jwt()->>'sub' AND (
      EXISTS (SELECT 1 FROM children c WHERE c.id = observations.child_id AND c.parent_uid = author_uid) OR
      EXISTS (
        SELECT 1 FROM links l
        JOIN profiles p ON p.uid = author_uid
        WHERE l.child_id = observations.child_id
          AND l.member_uid = author_uid
          AND l.status = 'active'
          AND l.scope = 'progress_notes'
          AND (l.expires_at IS NULL OR l.expires_at > now())
          AND (p.role <> 'specialist' OR p.verified = true)
      )
    )
  )
  WITH CHECK (
    author_uid = auth.jwt()->>'sub' AND (
      EXISTS (SELECT 1 FROM children c WHERE c.id = observations.child_id AND c.parent_uid = author_uid) OR
      EXISTS (
        SELECT 1 FROM links l
        JOIN profiles p ON p.uid = author_uid
        WHERE l.child_id = observations.child_id
          AND l.member_uid = author_uid
          AND l.status = 'active'
          AND l.scope = 'progress_notes'
          AND (l.expires_at IS NULL OR l.expires_at > now())
          AND (p.role <> 'specialist' OR p.verified = true)
      )
    )
  );

-- observations DELETE policy: parent may delete non-private observations of own child, author may delete own
DROP POLICY IF EXISTS "Observations delete policy" ON observations;
CREATE POLICY "Observations delete policy" ON observations
  FOR DELETE
  USING (
    author_uid = auth.jwt()->>'sub' OR
    EXISTS (
      SELECT 1 FROM children c
      WHERE c.id = observations.child_id AND c.parent_uid = auth.jwt()->>'sub' AND observations.private = false
    )
  );

-- goals UPDATE policy: parent may update status/progress or edit goals on own child; specialist may edit goals they authored under same link conditions; teachers neither create nor edit goals.
DROP POLICY IF EXISTS "Goals update policy" ON goals;
CREATE POLICY "Goals update policy" ON goals
  FOR UPDATE
  USING (
    EXISTS (SELECT 1 FROM children c WHERE c.id = goals.child_id AND c.parent_uid = auth.jwt()->>'sub')
    OR (
      author_uid = auth.jwt()->>'sub' AND (
        EXISTS (SELECT 1 FROM children c WHERE c.id = goals.child_id AND c.parent_uid = author_uid) OR
        EXISTS (
          SELECT 1 FROM links l
          JOIN profiles p ON p.uid = author_uid
          WHERE l.child_id = goals.child_id
            AND l.member_uid = author_uid
            AND l.status = 'active'
            AND l.scope = 'progress_notes'
            AND (l.expires_at IS NULL OR l.expires_at > now())
            AND (p.role <> 'specialist' OR p.verified = true)
        )
      )
    )
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM children c WHERE c.id = goals.child_id AND c.parent_uid = auth.jwt()->>'sub')
    OR (
      author_uid = auth.jwt()->>'sub' AND (
        EXISTS (SELECT 1 FROM children c WHERE c.id = goals.child_id AND c.parent_uid = author_uid) OR
        EXISTS (
          SELECT 1 FROM links l
          JOIN profiles p ON p.uid = author_uid
          WHERE l.child_id = goals.child_id
            AND l.member_uid = author_uid
            AND l.status = 'active'
            AND l.scope = 'progress_notes'
            AND (l.expires_at IS NULL OR l.expires_at > now())
            AND (p.role <> 'specialist' OR p.verified = true)
        )
      )
    )
  );

-- Immutability triggers for observations and goals (author_uid, author_role, child_id, created_at immutable for authenticated)
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

CREATE OR REPLACE FUNCTION protect_goal_updates()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY INVOKER
AS $$
BEGIN
  IF NEW.author_uid <> OLD.author_uid OR NEW.author_role <> OLD.author_role OR NEW.child_id <> OLD.child_id OR NEW.created_at <> OLD.created_at THEN
    RAISE EXCEPTION 'Protected goal fields cannot be modified';
  END IF;
  NEW.updated_at := NOW();
  RETURN NEW;
END;
$$;

-- 3. Privileges and Default Privileges Hardening
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM anon, PUBLIC;
REVOKE ALL ON ALL SEQUENCES IN SCHEMA public FROM anon, PUBLIC;
REVOKE ALL ON ALL FUNCTIONS IN SCHEMA public FROM anon, PUBLIC;

-- Grant EXECUTE only to authenticated on Flutter client RPCs
GRANT EXECUTE ON FUNCTION complete_profile(user_role, text, text, text, jsonb, jsonb, jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION add_child(text, date, text[], text[], text[], jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION create_invite(uuid, user_role, text, integer, boolean) TO authenticated;
GRANT EXECUTE ON FUNCTION preview_invite(text) TO authenticated;
GRANT EXECUTE ON FUNCTION accept_invite(text) TO authenticated;
GRANT EXECUTE ON FUNCTION list_my_links(boolean) TO authenticated;
GRANT EXECUTE ON FUNCTION revoke_link(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION get_shared_summary(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION list_access_log(uuid, uuid) TO authenticated;

-- Keep service_role grants
GRANT ALL ON ALL TABLES IN SCHEMA public TO service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO service_role;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO service_role;

-- Fix default privileges (pg_default_acl) so future objects are not re-granted to anon/PUBLIC
ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE EXECUTE ON FUNCTIONS FROM anon, PUBLIC;
ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE SELECT, INSERT, UPDATE, DELETE ON TABLES FROM anon, PUBLIC;
ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE USAGE ON SEQUENCES FROM anon, PUBLIC;

ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT EXECUTE ON FUNCTIONS TO authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT USAGE ON SEQUENCES TO authenticated, service_role;

-- Set search_path = public on every function flagged by advisor (and all public functions)
ALTER FUNCTION accept_invite(text) SET search_path = public;
ALTER FUNCTION add_child(text, date, text[], text[], text[], jsonb) SET search_path = public;
ALTER FUNCTION complete_profile(user_role, text, text, text, jsonb, jsonb, jsonb) SET search_path = public;
ALTER FUNCTION create_invite(uuid, user_role, text, integer, boolean) SET search_path = public;
ALTER FUNCTION get_shared_summary(uuid) SET search_path = public;
ALTER FUNCTION list_access_log(uuid, uuid) SET search_path = public;
ALTER FUNCTION list_my_links(boolean) SET search_path = public;
ALTER FUNCTION preview_invite(text) SET search_path = public;
ALTER FUNCTION revoke_link(uuid) SET search_path = public;
ALTER FUNCTION compute_child_band_and_enforce_age() SET search_path = public;
ALTER FUNCTION update_updated_at_column() SET search_path = public;
ALTER FUNCTION protect_profile_updates() SET search_path = public;
ALTER FUNCTION protect_observation_updates() SET search_path = public;
ALTER FUNCTION protect_goal_updates() SET search_path = public;
ALTER FUNCTION generate_invite_code() SET search_path = public;
ALTER FUNCTION populate_observation_author() SET search_path = public;
ALTER FUNCTION populate_goal_author() SET search_path = public;
ALTER FUNCTION deny_updates() SET search_path = public;
