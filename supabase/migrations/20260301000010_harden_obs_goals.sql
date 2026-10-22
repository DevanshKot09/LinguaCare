-- Migration: Harden Observations & Goals (Phase 4B Security & Compliance)
-- LinguaCare Fix-3 / Task 2

-- 1. Re-structure Observations Table with strict constraints
DROP TABLE IF EXISTS observations CASCADE;
CREATE TABLE observations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  child_id UUID NOT NULL REFERENCES children(id) ON DELETE CASCADE,
  author_uid TEXT NOT NULL REFERENCES profiles(uid) ON DELETE CASCADE,
  author_role user_role NOT NULL,
  tags TEXT[] CHECK (array_length(tags, 1) <= 8),
  setting TEXT CHECK (setting IN ('Home', 'Classroom', 'Clinic', 'Playground', 'Other')),
  note TEXT NOT NULL CHECK (length(note) <= 500 AND note !~* '\d{3}[-\.\s]?\d{3}[-\.\s]?\d{4}' AND note !~* '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}'),
  private BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. Re-structure Goals Table with strict constraints
DROP TABLE IF EXISTS goals CASCADE;
CREATE TABLE goals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  child_id UUID NOT NULL REFERENCES children(id) ON DELETE CASCADE,
  author_uid TEXT NOT NULL REFERENCES profiles(uid) ON DELETE CASCADE,
  author_role user_role NOT NULL,
  domain TEXT NOT NULL CHECK (domain IN ('vocabulary', 'understanding', 'grammar', 'narrative', 'conversation', 'confidence')),
  description TEXT NOT NULL CHECK (length(description) <= 300),
  target_date DATE,
  status TEXT NOT NULL CHECK (status IN ('active', 'achieved', 'paused')) DEFAULT 'active',
  progress INT NOT NULL DEFAULT 0 CHECK (progress BETWEEN 0 AND 100),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_observations_child_id ON observations(child_id, created_at DESC);
CREATE INDEX idx_observations_author_uid ON observations(author_uid);
CREATE INDEX idx_goals_child_id ON goals(child_id, target_date);
CREATE INDEX idx_goals_author_uid ON goals(author_uid);

-- Enable RLS
ALTER TABLE observations ENABLE ROW LEVEL SECURITY;
ALTER TABLE goals ENABLE ROW LEVEL SECURITY;

-- Strict RLS Policies (No direct member SELECT; members read exclusively via RPC)
CREATE POLICY "Parent and author manage observations" ON observations
  FOR ALL
  USING (
    author_uid = (auth.jwt()->>'sub')
    OR child_id IN (SELECT id FROM children WHERE parent_uid = (auth.jwt()->>'sub'))
  )
  WITH CHECK (
    author_uid = (auth.jwt()->>'sub')
    OR child_id IN (SELECT id FROM children WHERE parent_uid = (auth.jwt()->>'sub'))
  );

CREATE POLICY "Parent and author manage goals" ON goals
  FOR ALL
  USING (
    author_uid = (auth.jwt()->>'sub')
    OR child_id IN (SELECT id FROM children WHERE parent_uid = (auth.jwt()->>'sub'))
  )
  WITH CHECK (
    author_uid = (auth.jwt()->>'sub')
    OR child_id IN (SELECT id FROM children WHERE parent_uid = (auth.jwt()->>'sub'))
  );


-- 3. Secure RPC for Linked Members to Read Observations & Goals (via get_shared_summary)
CREATE OR REPLACE FUNCTION get_shared_summary(p_link_id UUID)
RETURNS JSONB
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
  v_uid TEXT;
  v_link RECORD;
  v_child_id UUID;
  v_subject_uid TEXT;
  v_nickname TEXT;
  v_band age_band;
  v_screening_json JSONB;
  v_activity_json JSONB;
  v_observation_json JSONB;
  v_goal_json JSONB;
  v_recent_audit BOOLEAN;
BEGIN
  v_uid := (auth.jwt()->>'sub');
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  SELECT * INTO v_link FROM links WHERE id = p_link_id AND member_uid = v_uid AND status = 'active';
  IF v_link.id IS NULL THEN
    RAISE EXCEPTION 'Active link not found or unauthorized';
  END IF;

  IF v_link.expires_at IS NOT NULL AND v_link.expires_at < NOW() THEN
    UPDATE links SET status = 'expired' WHERE id = v_link.id;
    RAISE EXCEPTION 'Link has expired';
  END IF;

  v_child_id := v_link.child_id;
  v_subject_uid := v_link.subject_uid;

  IF v_child_id IS NOT NULL THEN
    SELECT nickname, band INTO v_nickname, v_band FROM children WHERE id = v_child_id;
  ELSE
    SELECT full_name INTO v_nickname FROM profiles WHERE uid = v_subject_uid;
    v_band := NULL;
  END IF;

  -- De-duplicated access audit
  SELECT EXISTS (
    SELECT 1 FROM access_audit
    WHERE actor_uid = v_uid
      AND table_name = 'links'
      AND record_id = p_link_id::TEXT
      AND action = 'GET_SHARED_SUMMARY'
      AND at > NOW() - INTERVAL '1 hour'
  ) INTO v_recent_audit;

  IF NOT v_recent_audit THEN
    INSERT INTO access_audit (actor_uid, action, table_name, record_id)
    VALUES (v_uid, 'GET_SHARED_SUMMARY', 'links', p_link_id::TEXT);
  END IF;

  -- Screening sessions (capped 100)
  IF v_child_id IS NOT NULL THEN
    SELECT COALESCE(jsonb_agg(to_jsonb(t)), '[]'::JSONB) INTO v_screening_json
    FROM (
      SELECT created_at, instrument_id, instrument_version, instrument_status, risk_level, domain_levels, also_check, urgent, completeness
      FROM screening_sessions
      WHERE child_id = v_child_id AND created_at > NOW() - INTERVAL '12 months'
      ORDER BY created_at DESC
      LIMIT 100
    ) t;
  ELSE
    SELECT COALESCE(jsonb_agg(to_jsonb(t)), '[]'::JSONB) INTO v_screening_json
    FROM (
      SELECT created_at, instrument_id, instrument_version, instrument_status, risk_level, domain_levels, also_check, urgent, completeness
      FROM screening_sessions
      WHERE subject_uid = v_subject_uid AND created_at > NOW() - INTERVAL '12 months'
      ORDER BY created_at DESC
      LIMIT 100
    ) t;
  END IF;

  -- Activity sessions (capped 500)
  IF v_child_id IS NOT NULL THEN
    SELECT COALESCE(jsonb_agg(to_jsonb(t)), '[]'::JSONB) INTO v_activity_json
    FROM (
      SELECT started_at::DATE AS date, domain, duration_s, completed, success_level, support_level
      FROM activity_sessions
      WHERE child_id = v_child_id AND started_at > NOW() - INTERVAL '12 months'
      ORDER BY started_at DESC
      LIMIT 500
    ) t;
  ELSE
    SELECT COALESCE(jsonb_agg(to_jsonb(t)), '[]'::JSONB) INTO v_activity_json
    FROM (
      SELECT started_at::DATE AS date, domain, duration_s, completed, success_level, support_level
      FROM activity_sessions
      WHERE subject_uid = v_subject_uid AND started_at > NOW() - INTERVAL '12 months'
      ORDER BY started_at DESC
      LIMIT 500
    ) t;
  END IF;

  -- Observations (strictly if scope is progress_notes and not private)
  v_observation_json := '[]'::JSONB;
  IF v_link.scope = 'progress_notes' AND v_child_id IS NOT NULL THEN
    SELECT COALESCE(jsonb_agg(to_jsonb(t)), '[]'::JSONB) INTO v_observation_json
    FROM (
      SELECT o.created_at, o.tags, o.note, o.setting, p.full_name AS author_name, o.author_role
      FROM observations o
      JOIN profiles p ON o.author_uid = p.uid
      WHERE o.child_id = v_child_id AND o.private = FALSE
      ORDER BY o.created_at DESC
      LIMIT 100
    ) t;
  END IF;

  -- Goals (accessible under both progress and progress_notes scopes)
  v_goal_json := '[]'::JSONB;
  IF v_child_id IS NOT NULL THEN
    SELECT COALESCE(jsonb_agg(to_jsonb(t)), '[]'::JSONB) INTO v_goal_json
    FROM (
      SELECT domain, description, target_date, status, progress, created_at
      FROM goals
      WHERE child_id = v_child_id
      ORDER BY target_date ASC NULLS LAST
    ) t;
  END IF;

  RETURN jsonb_build_object(
    'nickname', v_nickname,
    'band', v_band,
    'scope', v_link.scope,
    'screening_sessions', v_screening_json,
    'activity_sessions', v_activity_json,
    'observations', v_observation_json,
    'goals', v_goal_json
  );
END;
$$;
GRANT EXECUTE ON FUNCTION get_shared_summary TO authenticated;
