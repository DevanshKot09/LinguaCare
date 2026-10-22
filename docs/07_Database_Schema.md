# 07 · Supabase Database Schema & RLS

> Firebase UID (text) is the user key. Enable Supabase Third-Party Auth for Firebase so `auth.jwt()->>'sub'` returns the Firebase UID.
> **CRITICAL AUTH RULE:** Always use `(auth.jwt()->>'sub')`, never `auth.uid()`. Since Firebase UIDs are non-UUID strings, `auth.uid()` attempts to cast `sub` to UUID and will throw a Postgres casting error. All RLS policies and functions must use `(auth.jwt()->>'sub')`.

## 1. Tables (SQL)
```sql
create extension if not exists pgcrypto;

create type user_role as enum ('specialist','adult','parent','teacher');
create type age_band as enum ('5_11','11_18');

create table profiles (
  uid text primary key,                 -- Firebase UID
  role user_role not null,
  full_name text not null,
  email text not null,
  email_verified boolean default false,
  country text, language text default 'en',
  verified boolean default false,       -- specialists
  created_at timestamptz default now()
);

create table specialist_details (
  uid text primary key references profiles(uid) on delete cascade,
  profession text, licence_no text, licence_body text, workplace text
);
create table teacher_details (
  uid text primary key references profiles(uid) on delete cascade,
  school text, grade_subject text
);

create table children (
  id uuid primary key default gen_random_uuid(),
  parent_uid text references profiles(uid) on delete cascade,
  nickname text not null, dob date not null,
  band age_band generated always as (
    case when date_part('year', age(dob)) < 11 then '5_11'::age_band else '11_18'::age_band end) stored,
  home_languages text[], interests text[], concerns text[],
  created_at timestamptz default now()
);

create table otp_codes (                -- accessed by Edge Function only (service role)
  id uuid primary key default gen_random_uuid(),
  email text not null, code_hash text not null,
  expires_at timestamptz not null, attempts int default 0, consumed boolean default false,
  created_at timestamptz default now()
);

create table links (                    -- parent-approved sharing
  id uuid primary key default gen_random_uuid(),
  child_id uuid references children(id) on delete cascade,
  parent_uid text references profiles(uid),
  member_uid text references profiles(uid),     -- teacher/specialist
  scope text check (scope in ('progress','progress_notes')) default 'progress',
  status text check (status in ('pending','active','revoked')) default 'pending',
  invite_code text unique, created_at timestamptz default now()
);

create table content_items (            -- learn articles, myth-busters, tips
  id uuid primary key default gen_random_uuid(),
  type text, title text, body_md text, goal text, audience user_role[],
  age_band age_band, language text default 'en',
  sources text[], reviewed_by text, version int default 1, published boolean default false
);

create table activities (
  id uuid primary key default gen_random_uuid(),
  domain text,                    -- vocabulary|grammar|narrative|comprehension|conversation|confidence
  title text, instructions_md text, age_band age_band, difficulty int,
  assets jsonb, est_minutes int, published boolean default false
);

create table activity_sessions (
  id uuid primary key default gen_random_uuid(),
  child_id uuid references children(id) on delete cascade,
  adult_uid text references profiles(uid),
  activity_id uuid references activities(id),
  started_at timestamptz default now(), duration_s int,
  success_level int check (success_level between 1 and 5),   -- caregiver-rated
  support_level text,             -- independent|prompted|heavy
  note text
);

create table screening_results (
  id uuid primary key default gen_random_uuid(),
  child_id uuid references children(id) on delete cascade,
  respondent_uid text references profiles(uid),
  respondent_role user_role, checklist_version text,
  answers jsonb, outcome text check (outcome in ('no_concerns','some_signs','consider_assessment')),
  created_at timestamptz default now()
);

create table observations (            -- teacher/specialist/parent logs
  id uuid primary key default gen_random_uuid(),
  child_id uuid references children(id) on delete cascade,
  author_uid text references profiles(uid),
  tags text[], note text, setting text, private boolean default false,
  created_at timestamptz default now()
);

create table goals (
  id uuid primary key default gen_random_uuid(),
  child_id uuid references children(id) on delete cascade,
  author_uid text references profiles(uid),
  domain text, description text, target_date date,
  status text default 'active', progress int default 0
);

create table adult_journal (
  id uuid primary key default gen_random_uuid(),
  uid text references profiles(uid) on delete cascade,
  mood int, situation text, note text, created_at timestamptz default now()
);

create table comm_cards (
  id uuid primary key default gen_random_uuid(),
  owner_uid text references profiles(uid) on delete cascade,
  child_id uuid references children(id), needs text[], custom_text text
);

create table consents (
  id uuid primary key default gen_random_uuid(),
  uid text references profiles(uid) on delete cascade,
  child_id uuid references children(id), type text, granted boolean, at timestamptz default now()
);
```

## 2. RLS Principles
```sql
alter table children enable row level security;
create policy parent_owns on children for all
  using (parent_uid = auth.jwt()->>'sub') with check (parent_uid = auth.jwt()->>'sub');

create policy linked_can_read on children for select using (
  exists (select 1 from links l where l.child_id = children.id
          and l.member_uid = auth.jwt()->>'sub' and l.status='active'));
```
- Enable RLS on **every** table. `otp_codes` has **no** client policy (service role only).
- Observations: `private=true` → readable by author only.
- `links.scope='progress'` hides notes from linked members.
- Reads of `content_items`/`activities`: `published = true` for authenticated users.
- Add indexes on `child_id`, `parent_uid`, `member_uid`, `(child_id, created_at)`.

## 3. Storage Buckets
`avatars` (private), `activity-assets` (public-read, admin-write), `voice-clips` (private, auto-expire 30 days, opt-in only), `exports` (private, signed URLs).

---
# v2 ADDENDUM – Clinical Labels, Research Consent & ML

```sql
alter type user_role add value if not exists 'admin';

create table clinical_assessments (            -- gold-standard labels, entered by verified specialists
  id uuid primary key default gen_random_uuid(),
  child_id uuid references children(id) on delete cascade,     -- or adult_uid for adults
  adult_uid text references profiles(uid),
  specialist_uid text references profiles(uid) not null,
  assessed_on date not null,
  tools_used text[], languages_assessed text[],
  hearing_status text check (hearing_status in ('normal','impaired','not_tested')),
  outcome text check (outcome in ('typical','dld','language_difficulty_other_cause','speech_sound_disorder','other')) not null,
  domains_affected text[],      -- understanding|expressive|vocabulary|grammar|narrative|pragmatics
  severity text check (severity in ('mild','moderate','severe')),
  notes text, created_at timestamptz default now()
);

create table screening_sessions_v2 (
  id uuid primary key default gen_random_uuid(),
  child_id uuid references children(id) on delete cascade,
  level int check (level in (1,2)),            -- 1 questionnaire, 2 in-app tasks
  source_role user_role, instrument_version text,
  item_responses jsonb, task_metrics jsonb,    -- accuracy, response_ms, error types
  quality_flag text,                           -- ok|distracted|tired|tech_issue
  risk_level text check (risk_level in ('low','some_signs','high')),
  domain_profile jsonb, also_check text[],
  model_version text, created_at timestamptz default now()
);

create table research_consents (
  id uuid primary key default gen_random_uuid(),
  grantor_uid text references profiles(uid) not null,   -- parent or adult
  child_id uuid references children(id),
  consent_version text not null,
  scope text[] check (scope <@ array['questionnaire','tasks','audio','clinical_label']),
  child_assent boolean,
  granted boolean not null, granted_at timestamptz default now(), withdrawn_at timestamptz
);

-- De-identified feature store (ideally in a SEPARATE research database)
create table ml_records (
  pseudo_id uuid primary key default gen_random_uuid(),   -- no link table in this DB
  age_months int, band age_band, home_languages text[], region text,
  features jsonb, label_outcome text, label_domains text[], label_severity text,
  consent_version text, dataset_version text, created_at timestamptz default now()
);

create table model_versions (
  id uuid primary key default gen_random_uuid(),
  name text, version text, trained_on_dataset text,
  metrics jsonb,          -- sensitivity, specificity, AUC, per-subgroup
  status text check (status in ('draft','shadow','released','retired')),
  model_card_url text, approved_by text, created_at timestamptz default now()
);

create table access_audit (
  id bigserial primary key, actor_uid text, action text, table_name text, record_id text, at timestamptz default now()
);
```
**RLS notes:** `clinical_assessments` insert only if `profiles.role='specialist' and verified=true` and an **active link** to that child exists; parent can read. `research_consents`, `ml_records`, `model_versions`: no client access except parent reading/withdrawing own consent; export via service-role job only. Withdrawal sets `withdrawn_at` and excludes records from future exports.
