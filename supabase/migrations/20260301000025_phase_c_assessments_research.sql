-- Migration 000025: Phase C Clinical Assessments and Research Consents

-- 1. Clinical Assessments Table
CREATE TABLE IF NOT EXISTS clinical_assessments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  child_id uuid REFERENCES children(id) ON DELETE CASCADE,
  subject_uid text,
  specialist_uid text NOT NULL,
  assessed_on date NOT NULL CHECK (assessed_on <= current_date),
  tools_used text[] NOT NULL CHECK (array_length(tools_used, 1) <= 6),
  languages_assessed text[] NOT NULL CHECK (array_length(languages_assessed, 1) <= 5),
  hearing_status text NOT NULL CHECK (hearing_status IN ('normal', 'impaired', 'not_tested')),
  outcome text NOT NULL CHECK (outcome IN ('typical', 'dld', 'language_difficulty_other_cause', 'speech_sound_disorder', 'other')),
  domains_affected text[] NOT NULL CHECK (domains_affected <@ ARRAY['understanding', 'expressive', 'vocabulary', 'grammar', 'narrative', 'pragmatics']::text[]),
  severity text CHECK (severity IS NULL OR severity IN ('mild', 'moderate', 'severe')),
  note text CHECK (note IS NULL OR (length(note) <= 500 AND NOT (note ~* '\m[+0-9() -]{7,}\M' OR note ~* '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}'))),
  supersedes_id uuid REFERENCES clinical_assessments(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT chk_clinical_assessment_target CHECK (
    (child_id IS NOT NULL AND subject_uid IS NULL) OR
    (child_id IS NULL AND subject_uid IS NOT NULL)
  )
);

CREATE INDEX IF NOT EXISTS idx_clinical_assessments_child_id ON clinical_assessments(child_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_clinical_assessments_subject_uid ON clinical_assessments(subject_uid, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_clinical_assessments_specialist_uid ON clinical_assessments(specialist_uid);

ALTER TABLE clinical_assessments ENABLE ROW LEVEL SECURITY;

REVOKE INSERT, UPDATE, DELETE ON clinical_assessments FROM authenticated, anon, PUBLIC;

DROP POLICY IF EXISTS "Clinical assessments select policy" ON clinical_assessments;
CREATE POLICY "Clinical assessments select policy" ON clinical_assessments
  FOR SELECT
  USING (
    specialist_uid = auth.jwt()->>'sub' OR
    EXISTS (SELECT 1 FROM children c WHERE c.id = clinical_assessments.child_id AND c.parent_uid = auth.jwt()->>'sub') OR
    subject_uid = auth.jwt()->>'sub'
  );

-- RPC: record_assessment
CREATE OR REPLACE FUNCTION record_assessment(
  p_child_id uuid,
  p_subject_uid text,
  p_assessed_on date,
  p_tools_used text[],
  p_languages_assessed text[],
  p_hearing_status text,
  p_outcome text,
  p_domains_affected text[],
  p_severity text,
  p_note text,
  p_supersedes_id uuid DEFAULT NULL
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid text;
  v_role user_role;
  v_verified boolean;
  v_assessment_id uuid;
  v_link_active boolean := false;
BEGIN
  v_uid := auth.jwt()->>'sub';
  if v_uid is null then
    raise exception 'Unauthorized';
  end if;

  select role, verified into v_role, v_verified from profiles where uid = v_uid;
  if v_role <> 'specialist' or not v_verified then
    raise exception 'Only verified specialists can record assessments';
  end if;

  -- Verify active, unexpired link of scope progress_notes
  if p_child_id is not null then
    select exists (
      select 1 from links
      where child_id = p_child_id
        and member_uid = v_uid
        and status = 'active'
        and scope = 'progress_notes'
        and (expires_at is null or expires_at > now())
    ) into v_link_active;
  elsif p_subject_uid is not null then
    select exists (
      select 1 from links
      where subject_uid = p_subject_uid
        and member_uid = v_uid
        and status = 'active'
        and scope = 'progress_notes'
        and (expires_at is null or expires_at > now())
    ) into v_link_active;
  else
    raise exception 'Must specify child_id or subject_uid';
  end if;

  if not v_link_active then
    raise exception 'No active progress_notes link found for this subject';
  end if;

  INSERT INTO clinical_assessments (
    child_id, subject_uid, specialist_uid, assessed_on, tools_used,
    languages_assessed, hearing_status, outcome, domains_affected, severity, note, supersedes_id
  ) VALUES (
    p_child_id, p_subject_uid, v_uid, p_assessed_on, p_tools_used,
    p_languages_assessed, p_hearing_status, p_outcome, p_domains_affected, p_severity, p_note, p_supersedes_id
  )
  RETURNING id into v_assessment_id;

  INSERT INTO access_audit (uid, child_id, subject_uid, action)
  VALUES (v_uid, p_child_id, p_subject_uid, 'record_assessment');

  RETURN v_assessment_id;
END;
$$;
GRANT EXECUTE ON FUNCTION record_assessment(uuid, text, date, text[], text[], text, text, text[], text, text, uuid) TO authenticated, service_role;
REVOKE EXECUTE ON FUNCTION record_assessment(uuid, text, date, text[], text[], text, text, text[], text, text, uuid) FROM anon, public;


-- 2. Research Consents Table & RPCs
CREATE TABLE IF NOT EXISTS research_consents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  grantor_uid text NOT NULL,
  child_id uuid REFERENCES children(id) ON DELETE CASCADE,
  subject_uid text,
  consent_version text NOT NULL,
  scopes text[] NOT NULL CHECK (scopes <@ ARRAY['questionnaire', 'tasks', 'clinical_label']::text[]),
  child_assent boolean NOT NULL DEFAULT false,
  granted boolean NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT chk_research_consent_target CHECK (
    (child_id IS NOT NULL AND subject_uid IS NULL) OR
    (child_id IS NULL AND subject_uid IS NOT NULL)
  )
);

CREATE INDEX IF NOT EXISTS idx_research_consents_grantor ON research_consents(grantor_uid, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_research_consents_child ON research_consents(child_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_research_consents_subject ON research_consents(subject_uid, created_at DESC);

ALTER TABLE research_consents ENABLE ROW LEVEL SECURITY;

REVOKE INSERT, UPDATE, DELETE ON research_consents FROM authenticated, anon, PUBLIC;

DROP POLICY IF EXISTS "Research consents owner select" ON research_consents;
CREATE POLICY "Research consents owner select" ON research_consents
  FOR SELECT
  USING (grantor_uid = auth.jwt()->>'sub');

-- RPC: grant_research_consent
CREATE OR REPLACE FUNCTION grant_research_consent(
  p_child_id uuid,
  p_subject_uid text,
  p_consent_version text,
  p_scopes text[],
  p_child_assent boolean
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid text;
  v_band age_band;
  v_consent_id uuid;
BEGIN
  v_uid := auth.jwt()->>'sub';
  if v_uid is null then
    raise exception 'Unauthorized';
  end if;

  if p_child_id is not null then
    if not exists (select 1 from children where id = p_child_id and parent_uid = v_uid) then
      raise exception 'Unauthorized for child consent';
    end if;
    select band into v_band from children where id = p_child_id;
    if v_band = '11_18' and not p_child_assent then
      raise exception 'Teen assent mandatory for band 11-18';
    end if;
  elsif p_subject_uid is not null then
    if p_subject_uid <> v_uid then
      raise exception 'Unauthorized for adult consent';
    end if;
  else
    raise exception 'Invalid target';
  end if;

  INSERT INTO research_consents (grantor_uid, child_id, subject_uid, consent_version, scopes, child_assent, granted)
  VALUES (v_uid, p_child_id, p_subject_uid, p_consent_version, p_scopes, coalesce(p_child_assent, false), true)
  RETURNING id into v_consent_id;

  RETURN v_consent_id;
END;
$$;
GRANT EXECUTE ON FUNCTION grant_research_consent(uuid, text, text, text[], boolean) TO authenticated, service_role;

-- RPC: withdraw_research_consent
CREATE OR REPLACE FUNCTION withdraw_research_consent(
  p_child_id uuid,
  p_subject_uid text,
  p_consent_version text
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid text;
  v_consent_id uuid;
BEGIN
  v_uid := auth.jwt()->>'sub';
  if v_uid is null then
    raise exception 'Unauthorized';
  end if;

  if p_child_id is not null then
    if not exists (select 1 from children where id = p_child_id and parent_uid = v_uid) then
      raise exception 'Unauthorized for child consent withdrawal';
    end if;
  elsif p_subject_uid is not null then
    if p_subject_uid <> v_uid then
      raise exception 'Unauthorized for adult consent withdrawal';
    end if;
  else
    raise exception 'Invalid target';
  end if;

  INSERT INTO research_consents (grantor_uid, child_id, subject_uid, consent_version, scopes, child_assent, granted)
  VALUES (v_uid, p_child_id, p_subject_uid, p_consent_version, ARRAY[]::text[], false, false)
  RETURNING id into v_consent_id;

  RETURN v_consent_id;
END;
$$;
GRANT EXECUTE ON FUNCTION withdraw_research_consent(uuid, text, text) TO authenticated, service_role;


-- 3. Research Settings & Export View
CREATE TABLE IF NOT EXISTS research_settings (
  id int PRIMARY KEY DEFAULT 1 CHECK (id = 1),
  salt bytea NOT NULL DEFAULT extensions.gen_random_bytes(32)
);

INSERT INTO research_settings (id) VALUES (1) ON CONFLICT (id) DO NOTHING;

REVOKE ALL ON research_settings FROM anon, authenticated;
GRANT ALL ON research_settings TO postgres, service_role;

-- View: research_export_v1
CREATE OR REPLACE VIEW research_export_v1 AS
WITH latest_consent AS (
  SELECT DISTINCT ON (coalesce(child_id::text, subject_uid))
    child_id,
    subject_uid,
    granted,
    scopes
  FROM research_consents
  ORDER BY coalesce(child_id::text, subject_uid), created_at DESC
),
consented AS (
  SELECT * FROM latest_consent WHERE granted = true
)
SELECT
  encode(extensions.digest(coalesce(c.id::text, rc.subject_uid) || convert_to(rs.salt::text, 'UTF8'), 'sha256'), 'hex') AS pseudo_id,
  (date_part('year', age(current_date, c.dob)) * 12 + date_part('month', age(current_date, c.dob)))::int AS age_months,
  c.band,
  p.country,
  (cardinality(c.home_languages) > 1) AS multilingual
FROM consented rc
JOIN children c ON c.id = rc.child_id
JOIN profiles p ON p.uid = c.parent_uid
CROSS JOIN research_settings rs
UNION
SELECT
  encode(extensions.digest(coalesce(rc.child_id::text, rc.subject_uid) || convert_to(rs.salt::text, 'UTF8'), 'sha256'), 'hex') AS pseudo_id,
  null::int AS age_months,
  null::age_band AS band,
  p.country,
  false AS multilingual
FROM consented rc
JOIN profiles p ON p.uid = rc.subject_uid
CROSS JOIN research_settings rs;

REVOKE ALL ON research_export_v1 FROM anon, authenticated;
GRANT SELECT ON research_export_v1 TO postgres, service_role;
