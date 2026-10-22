-- Migration: Harden RLS policies and table permissions (Fix activity_sessions UPDATE bug & audit hardening)
-- LinguaCare Phase 3 Security Harden

-- 1. Activity Sessions: Replace FOR ALL with explicit SELECT, INSERT, DELETE and deny UPDATE
DROP POLICY IF EXISTS "Parents manage child activity sessions" ON activity_sessions;
DROP POLICY IF EXISTS "Adults manage self activity sessions" ON activity_sessions;
DROP POLICY IF EXISTS "No update on activity sessions" ON activity_sessions;

CREATE POLICY "Parents select child activity sessions" ON activity_sessions
    FOR SELECT
    USING (
        child_id IS NOT NULL AND
        child_id IN (SELECT id FROM children WHERE parent_uid = (auth.jwt()->>'sub'))
    );

CREATE POLICY "Parents insert child activity sessions" ON activity_sessions
    FOR INSERT
    WITH CHECK (
        child_id IS NOT NULL AND
        actor_uid = (auth.jwt()->>'sub') AND
        child_id IN (SELECT id FROM children WHERE parent_uid = (auth.jwt()->>'sub'))
    );

CREATE POLICY "Parents delete child activity sessions" ON activity_sessions
    FOR DELETE
    USING (
        child_id IS NOT NULL AND
        child_id IN (SELECT id FROM children WHERE parent_uid = (auth.jwt()->>'sub'))
    );

CREATE POLICY "Adults select self activity sessions" ON activity_sessions
    FOR SELECT
    USING (
        subject_uid IS NOT NULL AND
        subject_uid = (auth.jwt()->>'sub')
    );

CREATE POLICY "Adults insert self activity sessions" ON activity_sessions
    FOR INSERT
    WITH CHECK (
        subject_uid IS NOT NULL AND
        subject_uid = (auth.jwt()->>'sub') AND
        actor_uid = (auth.jwt()->>'sub')
    );

CREATE POLICY "Adults delete self activity sessions" ON activity_sessions
    FOR DELETE
    USING (
        subject_uid IS NOT NULL AND
        subject_uid = (auth.jwt()->>'sub')
    );

CREATE POLICY "No update on activity sessions" ON activity_sessions
    FOR UPDATE
    USING (false);


-- 2. Children: Replace FOR ALL with explicit per-command policies
DROP POLICY IF EXISTS children_parent_owns ON children;

CREATE POLICY children_select ON children
    FOR SELECT USING (parent_uid = (auth.jwt()->>'sub'));

CREATE POLICY children_insert ON children
    FOR INSERT WITH CHECK (parent_uid = (auth.jwt()->>'sub'));

CREATE POLICY children_update ON children
    FOR UPDATE USING (parent_uid = (auth.jwt()->>'sub'))
    WITH CHECK (parent_uid = (auth.jwt()->>'sub'));

CREATE POLICY children_delete ON children
    FOR DELETE USING (parent_uid = (auth.jwt()->>'sub'));


-- 3. Consents: Replace FOR ALL with explicit per-command policies
DROP POLICY IF EXISTS consents_owner ON consents;

CREATE POLICY consents_select ON consents
    FOR SELECT USING (uid = (auth.jwt()->>'sub'));

CREATE POLICY consents_insert ON consents
    FOR INSERT WITH CHECK (uid = (auth.jwt()->>'sub'));

CREATE POLICY consents_update ON consents
    FOR UPDATE USING (uid = (auth.jwt()->>'sub'))
    WITH CHECK (uid = (auth.jwt()->>'sub'));

CREATE POLICY consents_delete ON consents
    FOR DELETE USING (uid = (auth.jwt()->>'sub'));


-- 4. Observations: Replace FOR ALL with explicit per-command policies
DROP POLICY IF EXISTS "Observations access policy" ON observations;
DROP POLICY IF EXISTS "Parent and author manage observations" ON observations;

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
            )
        )
    );

CREATE POLICY "Observations update policy" ON observations
    FOR UPDATE USING (author_uid = (auth.jwt()->>'sub'))
    WITH CHECK (author_uid = (auth.jwt()->>'sub'));

CREATE POLICY "Observations delete policy" ON observations
    FOR DELETE USING (
        author_uid = (auth.jwt()->>'sub')
        OR child_id IN (SELECT id FROM children WHERE parent_uid = (auth.jwt()->>'sub'))
    );


-- 5. Goals: Replace FOR ALL with explicit per-command policies
DROP POLICY IF EXISTS "Goals access policy" ON goals;
DROP POLICY IF EXISTS "Parent and author manage goals" ON goals;

CREATE POLICY "Goals select policy" ON goals
    FOR SELECT USING (
        author_uid = (auth.jwt()->>'sub')
        OR child_id IN (SELECT id FROM children WHERE parent_uid = (auth.jwt()->>'sub'))
        OR EXISTS (
            SELECT 1 FROM links l
            WHERE l.child_id = goals.child_id
              AND l.member_uid = (auth.jwt()->>'sub')
              AND l.status = 'active'
        )
    );

CREATE POLICY "Goals insert policy" ON goals
    FOR INSERT WITH CHECK (
        author_uid = (auth.jwt()->>'sub')
        AND (
            child_id IN (SELECT id FROM children WHERE parent_uid = (auth.jwt()->>'sub'))
            OR EXISTS (
                SELECT 1 FROM links l
                WHERE l.child_id = goals.child_id
                  AND l.member_uid = (auth.jwt()->>'sub')
                  AND l.status = 'active'
            )
        )
    );

CREATE POLICY "Goals update policy" ON goals
    FOR UPDATE USING (author_uid = (auth.jwt()->>'sub') OR child_id IN (SELECT id FROM children WHERE parent_uid = (auth.jwt()->>'sub')))
    WITH CHECK (author_uid = (auth.jwt()->>'sub') OR child_id IN (SELECT id FROM children WHERE parent_uid = (auth.jwt()->>'sub')));

CREATE POLICY "Goals delete policy" ON goals
    FOR DELETE USING (
        author_uid = (auth.jwt()->>'sub')
        OR child_id IN (SELECT id FROM children WHERE parent_uid = (auth.jwt()->>'sub'))
    );


-- 6. REVOKE grants for tables with no direct client write access
REVOKE UPDATE ON screening_sessions, activity_sessions FROM authenticated, anon;
REVOKE INSERT, UPDATE, DELETE ON invites, links, invite_attempts, otp_codes, access_audit, email_verifications, content_items FROM authenticated, anon;
