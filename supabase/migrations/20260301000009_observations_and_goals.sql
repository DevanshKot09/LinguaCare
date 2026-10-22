-- Migration: Observations and Goals tables with RLS and shared summary update
-- LinguaCare Phase 4B

-- 1. Observations Table
create table if not exists observations (
  id uuid primary key default gen_random_uuid(),
  child_id uuid references children(id) on delete cascade,
  author_uid text not null references profiles(uid) on delete cascade,
  tags text[],
  note text not null,
  setting text,
  private boolean not null default false,
  created_at timestamptz not null default now()
);

-- 2. Goals Table
create table if not exists goals (
  id uuid primary key default gen_random_uuid(),
  child_id uuid references children(id) on delete cascade,
  author_uid text not null references profiles(uid) on delete cascade,
  domain text not null,
  description text not null,
  target_date date,
  status text not null check (status in ('active', 'completed', 'paused')) default 'active',
  progress int not null default 0 check (progress between 0 and 100),
  created_at timestamptz not null default now()
);

-- Indexes
create index if not exists idx_observations_child_id on observations(child_id, created_at desc);
create index if not exists idx_observations_author_uid on observations(author_uid);
create index if not exists idx_goals_child_id on goals(child_id, target_date);
create index if not exists idx_goals_author_uid on goals(author_uid);

-- Enable RLS
alter table observations enable row level security;
alter table goals enable row level security;

-- RLS Policies for Observations
-- Parents who own the child can manage/read non-private or own observations
-- Authors can manage/read their own observations
-- Linked members with scope = 'progress_notes' can read non-private observations
create policy "Observations access policy" on observations
  for all
  using (
    author_uid = auth.jwt()->>'sub'
    or (not private and child_id in (select id from children where parent_uid = auth.jwt()->>'sub'))
    or (not private and exists (
      select 1 from links l
      where l.child_id = observations.child_id
        and l.member_uid = auth.jwt()->>'sub'
        and l.status = 'active'
        and l.scope = 'progress_notes'
    ))
  )
  with check (
    author_uid = auth.jwt()->>'sub'
    or child_id in (select id from children where parent_uid = auth.jwt()->>'sub')
  );

-- RLS Policies for Goals
-- Parents who own the child, authors, or linked members (progress or progress_notes) can read/manage goals
create policy "Goals access policy" on goals
  for all
  using (
    author_uid = auth.jwt()->>'sub'
    or child_id in (select id from children where parent_uid = auth.jwt()->>'sub')
    or exists (
      select 1 from links l
      where l.child_id = goals.child_id
        and l.member_uid = auth.jwt()->>'sub'
        and l.status = 'active'
    )
  )
  with check (
    author_uid = auth.jwt()->>'sub'
    or child_id in (select id from children where parent_uid = auth.jwt()->>'sub')
  );


-- 3. Update get_shared_summary RPC to include observations and goals if scope allows
create or replace function get_shared_summary(p_link_id uuid)
returns jsonb
security definer
set search_path = public
language plpgsql
as $$
declare
  v_uid text;
  v_link record;
  v_child_id uuid;
  v_subject_uid text;
  v_nickname text;
  v_band age_band;
  v_screening_json jsonb;
  v_activity_json jsonb;
  v_observation_json jsonb;
  v_goal_json jsonb;
  v_recent_audit boolean;
begin
  v_uid := auth.jwt()->>'sub';
  if v_uid is null then
    raise exception 'Unauthorized';
  end if;

  select * into v_link from links where id = p_link_id and member_uid = v_uid and status = 'active';
  if v_link.id is null then
    raise exception 'Active link not found or unauthorized';
  end if;

  if v_link.expires_at is not null and v_link.expires_at < now() then
    update links set status = 'expired' where id = v_link.id;
    raise exception 'Link has expired';
  end if;

  v_child_id := v_link.child_id;
  v_subject_uid := v_link.subject_uid;

  if v_child_id is not null then
    select nickname, band into v_nickname, v_band from children where id = v_child_id;
  else
    select full_name into v_nickname from profiles where uid = v_subject_uid;
    v_band := null;
  end if;

  -- De-duplicated access audit
  select exists (
    select 1 from access_audit
    where actor_uid = v_uid
      and table_name = 'links'
      and record_id = p_link_id::text
      and action = 'GET_SHARED_SUMMARY'
      and at > now() - interval '1 hour'
  ) into v_recent_audit;

  if not v_recent_audit then
    insert into access_audit (actor_uid, action, table_name, record_id)
    values (v_uid, 'GET_SHARED_SUMMARY', 'links', p_link_id::text);
  end if;

  -- Screening sessions
  if v_child_id is not null then
    select coalesce(jsonb_agg(to_jsonb(t)), '[]'::jsonb) into v_screening_json
    from (
      select created_at, instrument_id, instrument_version, instrument_status, risk_level, domain_levels, also_check, urgent, completeness
      from screening_sessions
      where child_id = v_child_id and created_at > now() - interval '12 months'
      order by created_at desc
      limit 100
    ) t;
  else
    select coalesce(jsonb_agg(to_jsonb(t)), '[]'::jsonb) into v_screening_json
    from (
      select created_at, instrument_id, instrument_version, instrument_status, risk_level, domain_levels, also_check, urgent, completeness
      from screening_sessions
      where subject_uid = v_subject_uid and created_at > now() - interval '12 months'
      order by created_at desc
      limit 100
    ) t;
  end if;

  -- Activity sessions
  if v_child_id is not null then
    select coalesce(jsonb_agg(to_jsonb(t)), '[]'::jsonb) into v_activity_json
    from (
      select started_at::date as date, domain, duration_s, completed, success_level, support_level
      from activity_sessions
      where child_id = v_child_id and started_at > now() - interval '12 months'
      order by started_at desc
      limit 500
    ) t;
  else
    select coalesce(jsonb_agg(to_jsonb(t)), '[]'::jsonb) into v_activity_json
    from (
      select started_at::date as date, domain, duration_s, completed, success_level, support_level
      from activity_sessions
      where subject_uid = v_subject_uid and started_at > now() - interval '12 months'
      order by started_at desc
      limit 500
    ) t;
  end if;

  -- Observations (only if scope is progress_notes and not private)
  v_observation_json := '[]'::jsonb;
  if v_link.scope = 'progress_notes' and v_child_id is not null then
    select coalesce(jsonb_agg(to_jsonb(t)), '[]'::jsonb) into v_observation_json
    from (
      select o.created_at, o.tags, o.note, o.setting, p.full_name as author_name
      from observations o
      join profiles p on o.author_uid = p.uid
      where o.child_id = v_child_id and o.private = false
      order by o.created_at desc
      limit 100
    ) t;
  end if;

  -- Goals
  v_goal_json := '[]'::jsonb;
  if v_child_id is not null then
    select coalesce(jsonb_agg(to_jsonb(t)), '[]'::jsonb) into v_goal_json
    from (
      select domain, description, target_date, status, progress, created_at
      from goals
      where child_id = v_child_id
      order by target_date asc nulls last
    ) t;
  end if;

  return jsonb_build_object(
    'nickname', v_nickname,
    'band', v_band,
    'scope', v_link.scope,
    'screening_sessions', v_screening_json,
    'activity_sessions', v_activity_json,
    'observations', v_observation_json,
    'goals', v_goal_json
  );
end;
$$;
grant execute on function get_shared_summary to authenticated;
