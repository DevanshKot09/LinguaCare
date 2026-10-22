-- Migration: activity_sessions table with RLS and constraints
-- LinguaCare Phase 3C

CREATE TABLE IF NOT EXISTS activity_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    child_id UUID REFERENCES children(id) ON DELETE CASCADE,
    subject_uid TEXT,
    actor_uid TEXT NOT NULL,
    activity_id TEXT NOT NULL,
    activity_version INT NOT NULL,
    domain TEXT NOT NULL,
    started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    duration_s INT CHECK (duration_s >= 0 AND duration_s <= 7200),
    completed BOOLEAN NOT NULL DEFAULT FALSE,
    success_level INT CHECK (success_level BETWEEN 1 AND 5),
    support_level TEXT CHECK (support_level IN ('independent', 'prompted', 'heavy')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    client_id UUID UNIQUE NOT NULL,
    CONSTRAINT activity_sessions_subject_check CHECK (
        (child_id IS NOT NULL AND subject_uid IS NULL) OR
        (child_id IS NULL AND subject_uid IS NOT NULL)
    )
);

ALTER TABLE activity_sessions ENABLE ROW LEVEL SECURITY;

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_activity_sessions_child_started ON activity_sessions(child_id, started_at);
CREATE INDEX IF NOT EXISTS idx_activity_sessions_subject_started ON activity_sessions(subject_uid, started_at);

-- RLS Policies
DROP POLICY IF EXISTS "Parents manage child activity sessions" ON activity_sessions;
DROP POLICY IF EXISTS "Adults manage self activity sessions" ON activity_sessions;
DROP POLICY IF EXISTS "No update on activity sessions" ON activity_sessions;

CREATE POLICY "Parents manage child activity sessions" ON activity_sessions
    FOR ALL
    USING (
        child_id IS NOT NULL AND
        actor_uid = (auth.jwt()->>'sub') AND
        EXISTS (
            SELECT 1 FROM children c
            WHERE c.id = activity_sessions.child_id AND c.parent_uid = (auth.jwt()->>'sub')
        )
    )
    WITH CHECK (
        child_id IS NOT NULL AND
        actor_uid = (auth.jwt()->>'sub') AND
        EXISTS (
            SELECT 1 FROM children c
            WHERE c.id = activity_sessions.child_id AND c.parent_uid = (auth.jwt()->>'sub')
        )
    );

CREATE POLICY "Adults manage self activity sessions" ON activity_sessions
    FOR ALL
    USING (
        subject_uid IS NOT NULL AND
        subject_uid = (auth.jwt()->>'sub') AND
        actor_uid = (auth.jwt()->>'sub')
    )
    WITH CHECK (
        subject_uid IS NOT NULL AND
        subject_uid = (auth.jwt()->>'sub') AND
        actor_uid = (auth.jwt()->>'sub')
    );

CREATE POLICY "No update on activity sessions" ON activity_sessions
    FOR UPDATE
    USING (false);
