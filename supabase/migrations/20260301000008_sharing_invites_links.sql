-- Migration: Sharing Invites, Links, Access Logs, and RPCs
-- LinguaCare Phase 4A

-- 1. Tables
create table if not exists invites (
  id uuid primary key default gen_random_uuid(),
  code_hash text unique not null,
  created_by text not null references profiles(uid) on delete cascade,
  child_id uuid null references children(id) on delete cascade,
  subject_uid text null references profiles(uid) on delete cascade,
  target_role user_role not null check (target_role in ('teacher', 'specialist')),
  scope text not null check (scope in ('progress', 'progress_notes')),
  access_months int null,
  expires_at timestamptz not null,
  consumed_at timestamptz null,
  consumed_by text null references profiles(uid) on delete set null,
  created_at timestamptz not null default now(),
  constraint invites_subject_check check (
    (child_id is not null and subject_uid is null) or
    (child_id is null and subject_uid is not null)
  )
);

create table if not exists links (
  id uuid primary key default gen_random_uuid(),
  child_id uuid null references children(id) on delete cascade,
  subject_uid text null references profiles(uid) on delete cascade,
  owner_uid text not null references profiles(uid) on delete cascade,
  member_uid text not null references profiles(uid) on delete cascade,
  member_role user_role not null check (member_role in ('teacher', 'specialist')),
  scope text not null check (scope in ('progress', 'progress_notes')),
  status text not null check (status in ('active', 'revoked', 'expired')) default 'active',
  expires_at timestamptz null,
  created_at timestamptz not null default now(),
  revoked_at timestamptz null,
  revoked_by text null references profiles(uid) on delete set null,
  constraint links_subject_check check (
    (child_id is not null and subject_uid is null) or
    (child_id is null and subject_uid is not null)
  )
);

create table if not exists invite_attempts (
  id bigserial primary key,
  uid text not null,
  at timestamptz not null default now(),
  success boolean not null
);

-- Indexes for FKs and lookups
create index if not exists idx_invites_created_by on invites(created_by);
create index if not exists idx_invites_child_id on invites(child_id);
create index if not exists idx_invites_expires_at on invites(expires_at);
create index if not exists idx_links_owner_uid on links(owner_uid);
create index if not exists idx_links_member_uid on links(member_uid);
create index if not exists idx_links_child_id on links(child_id);
create index if not exists idx_links_subject_uid on links(subject_uid);
create index if not exists idx_invite_attempts_uid_at on invite_attempts(uid, at desc);

-- Partial unique indexes for active links
create unique index if not exists idx_unique_active_child_link on links(child_id, member_uid) where status = 'active';
create unique index if not exists idx_unique_active_subject_link on links(subject_uid, member_uid) where status = 'active';

-- Enable RLS
alter table invites enable row level security;
alter table links enable row level security;
alter table invite_attempts enable row level security;

-- RLS Policies
-- Owners may SELECT their own invites and links
create policy "Owners select own invites" on invites
  for select using (created_by = auth.jwt()->>'sub');

create policy "Owners and members select own links" on links
  for select using (owner_uid = auth.jwt()->>'sub' or member_uid = auth.jwt()->>'sub');

-- No direct client write access
create policy "No client write invites" on invites for all using (false) with check (false);
create policy "No client write links" on links for all using (false) with check (false);
create policy "No client write invite_attempts" on invite_attempts for all using (false) with check (false);


-- 2. Helper: Generate Crockford Base32 Code
create or replace function generate_invite_code()
returns text
language plpgsql
as $$
declare
  chars text := '0123456789ABCDEFGHJKMNPQRSTVWXYZ';
  result text := '';
  bytes bytea;
  i int;
  val int;
begin
  bytes := extensions.gen_random_bytes(8);
  for i in 0..9 loop
    val := get_byte(bytes, i % 8);
    result := result || substr(chars, (val % length(chars)) + 1, 1);
  end loop;
  return result;
end;
$$;


-- 3. RPC: create_invite
create or replace function create_invite(
  p_child_id uuid,
  p_target_role user_role,
  p_scope text,
  p_access_months int,
  p_teen_assent boolean
)
returns jsonb
security definer
set search_path = public
language plpgsql
as $$
declare
  v_uid text;
  v_role user_role;
  v_band age_band;
  v_code text;
  v_code_hash text;
  v_salt text;
  v_active_count int;
  v_expires_at timestamptz;
begin
  v_uid := auth.jwt()->>'sub';
  if v_uid is null then
    raise exception 'Unauthorized';
  end if;

  select role into v_role from profiles where uid = v_uid;

  -- Validate permissions & targets
  if p_child_id is not null then
    if v_role <> 'parent'::user_role then
      raise exception 'Only parents can create child invites';
    end if;
    if not exists (select 1 from children where id = p_child_id and parent_uid = v_uid) then
      raise exception 'Child not found or not owned by caller';
    end if;
    select band into v_band from children where id = p_child_id;
    if v_band = '11_18'::age_band and not p_teen_assent then
      raise exception 'Teen sharing assent is required for children in band 11-18';
    end if;
    if v_band = '11_18'::age_band and p_teen_assent then
      insert into consents (uid, child_id, type, granted)
      values (v_uid, p_child_id, 'teen_sharing_assent', true);
    end if;
  else
    -- Adult self-share
    if v_role <> 'adult'::user_role then
      raise exception 'Only adults can create self invites';
    end if;
    if p_target_role <> 'specialist'::user_role then
      raise exception 'Adults can only share with specialists';
    end if;
  end if;

  -- Max 5 active invites per owner
  select count(*) into v_active_count
  from invites
  where created_by = v_uid and consumed_at is null and expires_at > now();

  if v_active_count >= 5 then
    raise exception 'Maximum active invites limit (5) reached';
  end if;

  v_code := generate_invite_code();
  v_salt := encode(extensions.gen_random_bytes(16), 'hex');
  v_code_hash := encode(extensions.digest(v_code || v_salt, 'sha256'), 'hex') || ':' || v_salt;
  v_expires_at := now() + interval '72 hours';

  insert into invites (code_hash, created_by, child_id, subject_uid, target_role, scope, access_months, expires_at)
  values (
    v_code_hash,
    v_uid,
    p_child_id,
    case when p_child_id is null then v_uid else null end,
    p_target_role,
    p_scope,
    coalesce(p_access_months, 12),
    v_expires_at
  );

  return jsonb_build_object(
    'code', v_code,
    'expires_at', v_expires_at
  );
end;
$$;
grant execute on function create_invite to authenticated;


-- 4. RPC: preview_invite
create or replace function preview_invite(p_code text)
returns jsonb
security definer
set search_path = public
language plpgsql
as $$
declare
  v_uid text;
  v_role user_role;
  v_verified boolean;
  v_fail_count int;
  v_invite record;
  v_hash_parts text[];
  v_salt text;
  v_computed_hash text;
  v_inviter_name text;
  v_child_nickname text;
  v_child_band age_band;
  v_subject_kind text;
begin
  v_uid := auth.jwt()->>'sub';
  if v_uid is null then
    raise exception 'Unauthorized';
  end if;

  select role, verified into v_role, v_verified from profiles where uid = v_uid;

  -- Rate limit check (max 5 failed attempts in past hour)
  select count(*) into v_fail_count
  from invite_attempts
  where uid = v_uid and success = false and at > now() - interval '1 hour';

  if v_fail_count >= 5 then
    raise exception 'Too many failed attempts. Please try again later.';
  end if;

  -- Find invite by matching hash across unconsumed, unexpired invites
  -- Since hash includes salt stored as hash_parts[2], we iterate active invites or use pgcrypto
  for v_invite in select * from invites where consumed_at is null and expires_at > now() loop
    v_hash_parts := string_to_array(v_invite.code_hash, ':');
    v_salt := v_hash_parts[2];
    v_computed_hash := encode(extensions.digest(p_code || v_salt, 'sha256'), 'hex');
    if v_computed_hash = v_hash_parts[1] then
      -- Found matching invite!
      -- Validate role and specialist verification
      if v_invite.target_role <> v_role then
        insert into invite_attempts (uid, success) values (v_uid, false);
        raise exception 'invalid or expired code';
      end if;

      if v_role = 'specialist'::user_role and not v_verified then
        insert into invite_attempts (uid, success) values (v_uid, false);
        raise exception 'Specialist verification pending approval by admin';
      end if;

      select split_part(full_name, ' ', 1) into v_inviter_name from profiles where uid = v_invite.created_by;

      if v_invite.child_id is not null then
        v_subject_kind := 'child';
        select nickname, band into v_child_nickname, v_child_band from children where id = v_invite.child_id;
      else
        v_subject_kind := 'adult';
        select full_name into v_child_nickname from profiles where uid = v_invite.subject_uid;
        v_child_band := null;
      end if;

      return jsonb_build_object(
        'target_role', v_invite.target_role,
        'scope', v_invite.scope,
        'access_months', v_invite.access_months,
        'subject_kind', v_subject_kind,
        'child_nickname', v_child_nickname,
        'child_band', v_child_band,
        'inviter_first_name', v_inviter_name
      );
    end if;
  end loop;

  -- No match found -> log failure and generic error
  insert into invite_attempts (uid, success) values (v_uid, false);
  raise exception 'invalid or expired code';
end;
$$;
grant execute on function preview_invite to authenticated;


-- 5. RPC: accept_invite
create or replace function accept_invite(p_code text)
returns jsonb
security definer
set search_path = public
language plpgsql
as $$
declare
  v_uid text;
  v_role user_role;
  v_verified boolean;
  v_fail_count int;
  v_invite record;
  v_hash_parts text[];
  v_salt text;
  v_computed_hash text;
  v_expires_at timestamptz;
  v_link_id uuid;
begin
  v_uid := auth.jwt()->>'sub';
  if v_uid is null then
    raise exception 'Unauthorized';
  end if;

  select role, verified into v_role, v_verified from profiles where uid = v_uid;

  select count(*) into v_fail_count
  from invite_attempts
  where uid = v_uid and success = false and at > now() - interval '1 hour';

  if v_fail_count >= 5 then
    raise exception 'Too many failed attempts. Please try again later.';
  end if;

  for v_invite in select * from invites where consumed_at is null and expires_at > now() loop
    v_hash_parts := string_to_array(v_invite.code_hash, ':');
    v_salt := v_hash_parts[2];
    v_computed_hash := encode(extensions.digest(p_code || v_salt, 'sha256'), 'hex');
    if v_computed_hash = v_hash_parts[1] then
      if v_invite.created_by = v_uid then
        insert into invite_attempts (uid, success) values (v_uid, false);
        raise exception 'Cannot accept your own invite';
      end if;

      if v_invite.target_role <> v_role then
        insert into invite_attempts (uid, success) values (v_uid, false);
        raise exception 'invalid or expired code';
      end if;

      if v_role = 'specialist'::user_role and not v_verified then
        insert into invite_attempts (uid, success) values (v_uid, false);
        raise exception 'Specialist verification pending approval by admin';
      end if;

      -- Mark invite consumed
      update invites
      set consumed_at = now(), consumed_by = v_uid
      where id = v_invite.id;

      -- Compute link expiration
      if v_invite.access_months is not null then
        v_expires_at := now() + (v_invite.access_months || ' months')::interval;
      else
        v_expires_at := null; -- until revoke
      end if;

      -- Insert active link (upsert/handle existing if any)
      insert into links (child_id, subject_uid, owner_uid, member_uid, member_role, scope, status, expires_at)
      values (
        v_invite.child_id,
        v_invite.subject_uid,
        v_invite.created_by,
        v_uid,
        v_invite.target_role,
        v_invite.scope,
        'active',
        v_expires_at
      )
      returning id into v_link_id;

      insert into invite_attempts (uid, success) values (v_uid, true);
      insert into access_audit (actor_uid, action, table_name, record_id)
      values (v_uid, 'ACCEPT_INVITE', 'links', v_link_id::text);

      return jsonb_build_object(
        'link_id', v_link_id,
        'status', 'active',
        'expires_at', v_expires_at
      );
    end if;
  end loop;

  insert into invite_attempts (uid, success) values (v_uid, false);
  raise exception 'invalid or expired code';
end;
$$;
grant execute on function accept_invite to authenticated;


-- 6. RPC: list_my_links
create or replace function list_my_links(p_include_inactive boolean default false)
returns jsonb
security definer
set search_path = public
language plpgsql
as $$
declare
  v_uid text;
  v_result jsonb;
begin
  v_uid := auth.jwt()->>'sub';
  if v_uid is null then
    raise exception 'Unauthorized';
  end if;

  -- Lazy expiry update
  update links
  set status = 'expired'
  where status = 'active' and expires_at is not null and expires_at < now();

  -- Return links where user is owner or member
  select jsonb_agg(
    jsonb_build_object(
      'link_id', l.id,
      'child_id', l.child_id,
      'subject_uid', l.subject_uid,
      'child_nickname', coalesce(c.nickname, p_sub.full_name),
      'child_band', c.band,
      'owner_uid', l.owner_uid,
      'owner_name', p_owner.full_name,
      'member_uid', l.member_uid,
      'member_name', p_member.full_name,
      'member_role', l.member_role,
      'member_verified', p_member.verified,
      'member_workplace', coalesce(sd.workplace, td.school),
      'scope', l.scope,
      'status', l.status,
      'expires_at', l.expires_at,
      'created_at', l.created_at
    )
  ) into v_result
  from links l
  left join children c on l.child_id = c.id
  left join profiles p_sub on l.subject_uid = p_sub.uid
  left join profiles p_owner on l.owner_uid = p_owner.uid
  left join profiles p_member on l.member_uid = p_member.uid
  left join specialist_details sd on l.member_uid = sd.uid
  left join teacher_details td on l.member_uid = td.uid
  where (l.owner_uid = v_uid or l.member_uid = v_uid)
    and (p_include_inactive or l.status = 'active');

  return coalesce(v_result, '[]'::jsonb);
end;
$$;
grant execute on function list_my_links to authenticated;


-- 7. RPC: revoke_link
create or replace function revoke_link(p_link_id uuid)
returns void
security definer
set search_path = public
language plpgsql
as $$
declare
  v_uid text;
begin
  v_uid := auth.jwt()->>'sub';
  if v_uid is null then
    raise exception 'Unauthorized';
  end if;

  if not exists (select 1 from links where id = p_link_id and (owner_uid = v_uid or member_uid = v_uid)) then
    raise exception 'Link not found or unauthorized';
  end if;

  update links
  set status = 'revoked', revoked_at = now(), revoked_by = v_uid
  where id = p_link_id;

  insert into access_audit (actor_uid, action, table_name, record_id)
  values (v_uid, 'REVOKE_LINK', 'links', p_link_id::text);
end;
$$;
grant execute on function revoke_link to authenticated;


-- 8. RPC: get_shared_summary
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

  -- De-duplicated access audit (at most one row per member per link per hour)
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

  -- Fetch screening sessions (last 12 months, capped at 100)
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

  -- Fetch activity sessions (last 12 months, capped at 500)
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

  return jsonb_build_object(
    'nickname', v_nickname,
    'band', v_band,
    'scope', v_link.scope,
    'screening_sessions', v_screening_json,
    'activity_sessions', v_activity_json
  );
end;
$$;
grant execute on function get_shared_summary to authenticated;


-- 9. RPC: list_access_log
create or replace function list_access_log(p_child_id uuid default null, p_link_id uuid default null)
returns jsonb
security definer
set search_path = public
language plpgsql
as $$
declare
  v_uid text;
  v_result jsonb;
begin
  v_uid := auth.jwt()->>'sub';
  if v_uid is null then
    raise exception 'Unauthorized';
  end if;

  -- Verify ownership of child or link
  if p_child_id is not null and not exists (select 1 from children where id = p_child_id and parent_uid = v_uid) then
    raise exception 'Unauthorized or child not found';
  end if;

  if p_link_id is not null and not exists (select 1 from links where id = p_link_id and owner_uid = v_uid) then
    raise exception 'Unauthorized or link not found';
  end if;

  select jsonb_agg(
    jsonb_build_object(
      'member_name', p.full_name,
      'member_role', l.member_role,
      'action', a.action,
      'timestamp', a.at
    )
  ) into v_result
  from access_audit a
  join links l on a.record_id = l.id::text
  join profiles p on a.actor_uid = p.uid
  where (l.owner_uid = v_uid)
    and (p_link_id is null or l.id = p_link_id)
    and (p_child_id is null or l.child_id = p_child_id)
    and a.action in ('ACCEPT_INVITE', 'GET_SHARED_SUMMARY', 'REVOKE_LINK')
  order by a.at desc;

  return coalesce(v_result, '[]'::jsonb);
end;
$$;
grant execute on function list_access_log to authenticated;
