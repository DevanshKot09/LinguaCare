-- Phase 2A Core Auth Schema & Security
create extension if not exists pgcrypto;

do $$ begin
  create type user_role as enum ('specialist','adult','parent','teacher','admin');
exception
  when duplicate_object then null;
end $$;

do $$ begin
  create type age_band as enum ('5_11','11_18');
exception
  when duplicate_object then null;
end $$;

-- 1. Email Verifications (Source of truth for verified emails before profile creation)
create table if not exists email_verifications (
  uid text primary key,
  email text not null,
  verified_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);
alter table email_verifications enable row level security;

-- 2. OTP Codes (Hashed, rate-limited, service role only)
create table if not exists otp_codes (
  id uuid primary key default gen_random_uuid(),
  uid text not null,
  email text not null,
  code_hash text not null,
  expires_at timestamptz not null,
  attempts int not null default 0,
  consumed boolean not null default false,
  send_count int not null default 1,
  window_start timestamptz not null default now(),
  created_at timestamptz not null default now()
);
alter table otp_codes enable row level security;

-- 3. Profiles
create table if not exists profiles (
  uid text primary key,
  role user_role not null,
  full_name text not null,
  email text not null,
  email_verified boolean not null default false,
  country text,
  language text not null default 'en',
  verified boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
alter table profiles enable row level security;

-- 4. Specialist Details
create table if not exists specialist_details (
  uid text primary key references profiles(uid) on delete cascade,
  profession text,
  licence_no text,
  licence_body text,
  workplace text
);
alter table specialist_details enable row level security;

-- 5. Teacher Details
create table if not exists teacher_details (
  uid text primary key references profiles(uid) on delete cascade,
  school text,
  grade_subject text
);
alter table teacher_details enable row level security;

-- 6. Children
create table if not exists children (
  id uuid primary key default gen_random_uuid(),
  parent_uid text not null references profiles(uid) on delete cascade,
  nickname text not null,
  dob date not null,
  band age_band,
  home_languages text[],
  interests text[],
  concerns text[],
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
alter table children enable row level security;

-- Function to compute band and enforce age 5-17
create or replace function compute_child_band_and_enforce_age()
returns trigger as $$
declare
  age_years int;
begin
  age_years := date_part('year', age(current_date, new.dob));
  if age_years < 5 or age_years > 17 then
    raise exception 'Child age must be between 5 and 17 years old.';
  end if;
  if age_years < 11 then
    new.band := '5_11'::age_band;
  else
    new.band := '11_18'::age_band;
  end if;
  return new;
end;
$$ language plpgsql;

drop trigger if exists tr_children_band on children;
create trigger tr_children_band
  before insert or update on children
  for each row execute function compute_child_band_and_enforce_age();

-- 7. Consents
create table if not exists consents (
  id uuid primary key default gen_random_uuid(),
  uid text not null references profiles(uid) on delete cascade,
  child_id uuid references children(id) on delete cascade,
  type text not null,
  granted boolean not null,
  at timestamptz not null default now()
);
alter table consents enable row level security;

-- 8. Access Audit Log
create table if not exists access_audit (
  id bigserial primary key,
  actor_uid text,
  action text not null,
  table_name text not null,
  record_id text,
  at timestamptz not null default now()
);
alter table access_audit enable row level security;

-- ==========================================
-- RLS POLICIES & CONSTRAINTS
-- ==========================================

-- Profiles Policies
create policy profiles_select_authenticated on profiles
  for select using (auth.jwt()->>'role' = 'authenticated');

create policy profiles_insert_owner on profiles
  for insert with check (
    uid = auth.jwt()->>'sub'
    and role <> 'admin'::user_role
    and verified = false
    and exists (
      select 1 from email_verifications ev
      where ev.uid = auth.jwt()->>'sub'
        and ev.verified_at is not null
    )
  );

create policy profiles_update_owner on profiles
  for update using (uid = auth.jwt()->>'sub')
  with check (
    uid = auth.jwt()->>'sub'
    and role = (select p.role from profiles p where p.uid = auth.jwt()->>'sub')
    and verified = (select p.verified from profiles p where p.uid = auth.jwt()->>'sub')
  );

-- Specialist Details Policies
create policy specialist_select on specialist_details
  for select using (auth.jwt()->>'role' = 'authenticated');

create policy specialist_insert_owner on specialist_details
  for insert with check (uid = auth.jwt()->>'sub');

create policy specialist_update_owner on specialist_details
  for update using (uid = auth.jwt()->>'sub')
  with check (uid = auth.jwt()->>'sub');

-- Teacher Details Policies
create policy teacher_select on teacher_details
  for select using (auth.jwt()->>'role' = 'authenticated');

create policy teacher_insert_owner on teacher_details
  for insert with check (uid = auth.jwt()->>'sub');

create policy teacher_update_owner on teacher_details
  for update using (uid = auth.jwt()->>'sub')
  with check (uid = auth.jwt()->>'sub');

-- Children Policies
create policy children_parent_owns on children
  for all using (parent_uid = auth.jwt()->>'sub')
  with check (parent_uid = auth.jwt()->>'sub');

-- Consents Policies
create policy consents_owner on consents
  for all using (uid = auth.jwt()->>'sub')
  with check (uid = auth.jwt()->>'sub');

-- Audit Log Policies
create policy audit_insert on access_audit
  for insert with check (auth.jwt()->>'role' = 'authenticated');

-- ==========================================
-- INDEXES & TRIGGERS
-- ==========================================
create index if not exists idx_children_parent_uid on children(parent_uid);
create index if not exists idx_otp_codes_email on otp_codes(email);
create index if not exists idx_otp_codes_uid on otp_codes(uid);
create index if not exists idx_consents_uid on consents(uid);

create or replace function update_updated_at_column()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger update_profiles_updated_at
  before update on profiles
  for each row execute function update_updated_at_column();

create trigger update_children_updated_at
  before update on children
  for each row execute function update_updated_at_column();
