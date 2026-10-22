-- Phase 3B Screening Sessions Schema & RLS
create table if not exists screening_sessions (
  id uuid primary key default gen_random_uuid(),
  child_id uuid references children(id) on delete cascade,
  subject_uid text references profiles(uid) on delete cascade,
  respondent_uid text not null references profiles(uid) on delete cascade,
  respondent_role user_role not null,
  instrument_id text not null,
  instrument_version text not null,
  instrument_status text not null,
  answers jsonb not null,
  domain_scores jsonb not null,
  domain_levels jsonb not null,
  risk_level text not null,
  also_check text[] not null,
  urgent boolean not null,
  completeness numeric not null,
  config_version text not null,
  created_at timestamptz not null default now(),
  constraint screening_subject_check check (
    (child_id is not null and subject_uid is null) or
    (child_id is null and subject_uid is not null)
  )
);

alter table screening_sessions enable row level security;

-- Indexes
create index if not exists idx_screening_sessions_child_id on screening_sessions(child_id, created_at desc);
create index if not exists idx_screening_sessions_subject_uid on screening_sessions(subject_uid, created_at desc);

-- RLS Policies
drop policy if exists "Parents can insert screening sessions for own children" on screening_sessions;
drop policy if exists "Parents can select screening sessions for own children" on screening_sessions;
drop policy if exists "Parents can delete screening sessions for own children" on screening_sessions;
drop policy if exists "Adults can insert self screening sessions" on screening_sessions;
drop policy if exists "Adults can select self screening sessions" on screening_sessions;
drop policy if exists "Adults can delete self screening sessions" on screening_sessions;
drop policy if exists "No updates allowed on screening sessions" on screening_sessions;

create policy "Parents can insert screening sessions for own children"
  on screening_sessions for insert
  with check (
    child_id is not null
    and respondent_uid = (auth.jwt()->>'sub')
    and child_id in (select id from children where parent_uid = (auth.jwt()->>'sub'))
  );

create policy "Parents can select screening sessions for own children"
  on screening_sessions for select
  using (
    child_id is not null
    and child_id in (select id from children where parent_uid = (auth.jwt()->>'sub'))
  );

create policy "Parents can delete screening sessions for own children"
  on screening_sessions for delete
  using (
    child_id is not null
    and child_id in (select id from children where parent_uid = (auth.jwt()->>'sub'))
  );

create policy "Adults can insert self screening sessions"
  on screening_sessions for insert
  with check (
    subject_uid is not null
    and subject_uid = (auth.jwt()->>'sub')
    and respondent_uid = (auth.jwt()->>'sub')
  );

create policy "Adults can select self screening sessions"
  on screening_sessions for select
  using (
    subject_uid is not null
    and subject_uid = (auth.jwt()->>'sub')
  );

create policy "Adults can delete self screening sessions"
  on screening_sessions for delete
  using (
    subject_uid is not null
    and subject_uid = (auth.jwt()->>'sub')
  );

create policy "No updates allowed on screening sessions"
  on screening_sessions for update
  using (false);
