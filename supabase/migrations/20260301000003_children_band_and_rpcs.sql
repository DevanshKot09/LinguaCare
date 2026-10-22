-- Fix children.band (ensure plain column + trigger)
alter table children drop column if exists band cascade;
alter table children add column if not exists band age_band not null default '5_11'::age_band;

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

-- Tighten profiles UPDATE trigger to prevent changing uid, email, role, or verified from client
create or replace function protect_profile_updates()
returns trigger as $$
begin
  if old.uid <> new.uid or old.email <> new.email or old.role <> new.role or old.verified <> new.verified then
    raise exception 'Unauthorized modification of locked profile fields (uid, email, role, verified).';
  end if;
  return new;
end;
$$ language plpgsql;

drop trigger if exists tr_protect_profile_updates on profiles;
create trigger tr_protect_profile_updates
  before update on profiles
  for each row execute function protect_profile_updates();

-- ==========================================
-- COMPLETE_PROFILE RPC
-- ==========================================
create or replace function complete_profile(
  p_role user_role,
  p_name text,
  p_country text,
  p_language text default 'en',
  p_role_details jsonb default '{}'::jsonb,
  p_initial_child jsonb default null,
  p_consents jsonb default '[]'::jsonb
)
returns void
security definer
set search_path = public
language plpgsql
as $$
declare
  v_uid text;
  v_email text;
  v_consent jsonb;
  v_child_id uuid;
  v_dob date;
  v_nickname text;
  v_home_langs text[];
  v_interests text[];
  v_concerns text[];
begin
  v_uid := auth.jwt()->>'sub';
  if v_uid is null then
    raise exception 'Unauthorized: missing JWT sub';
  end if;

  if p_role = 'admin'::user_role then
    raise exception 'Cannot assign admin role from client';
  end if;

  select email into v_email
  from email_verifications
  where uid = v_uid and verified_at is not null;

  if v_email is null then
    raise exception 'Email verification required before profile creation';
  end if;

  if exists (select 1 from profiles where uid = v_uid) then
    raise exception 'Profile already exists for this user';
  end if;

  insert into profiles (uid, role, full_name, email, email_verified, country, language, verified)
  values (v_uid, p_role, p_name, v_email, true, p_country, p_language, false);

  if p_role = 'specialist'::user_role then
    insert into specialist_details (uid, profession, licence_no, licence_body, workplace)
    values (
      v_uid,
      p_role_details->>'profession',
      p_role_details->>'licence_no',
      p_role_details->>'licence_body',
      p_role_details->>'workplace'
    );
  elsif p_role = 'teacher'::user_role then
    insert into teacher_details (uid, school, grade_subject)
    values (
      v_uid,
      p_role_details->>'school',
      p_role_details->>'grade_subject'
    );
  elsif p_role = 'adult'::user_role then
    declare
      v_adult_dob date;
    begin
      v_adult_dob := (p_role_details->>'dob')::date;
      if v_adult_dob is null or date_part('year', age(current_date, v_adult_dob)) < 18 then
        raise exception 'Adult user must be at least 18 years old';
      end if;
    end;
  end if;

  if p_role = 'parent'::user_role and p_initial_child is not null then
    v_nickname := p_initial_child->>'nickname';
    v_dob := (p_initial_child->>'dob')::date;
    v_home_langs := ARRAY(SELECT jsonb_array_elements_text(p_initial_child->'home_languages'));
    v_interests := ARRAY(SELECT jsonb_array_elements_text(p_initial_child->'interests'));
    v_concerns := ARRAY(SELECT jsonb_array_elements_text(p_initial_child->'concerns'));

    insert into children (parent_uid, nickname, dob, home_languages, interests, concerns)
    values (v_uid, v_nickname, v_dob, v_home_langs, v_interests, v_concerns)
    returning id into v_child_id;
  end if;

  if jsonb_typeof(p_consents) = 'array' then
    for v_consent in select * from jsonb_array_elements(p_consents) loop
      insert into consents (uid, child_id, type, granted)
      values (
        v_uid,
        case when v_consent->>'child_id' is not null then (v_consent->>'child_id')::uuid else v_child_id end,
        v_consent->>'type',
        (v_consent->>'granted')::boolean
      );
    end loop;
  end if;

  insert into access_audit (actor_uid, action, table_name, record_id)
  values (v_uid, 'COMPLETE_PROFILE', 'profiles', v_uid);
end;
$$;

grant execute on function complete_profile to authenticated;

-- ==========================================
-- ADD_CHILD RPC
-- ==========================================
create or replace function add_child(
  p_nickname text,
  p_dob date,
  p_home_languages text[] default '{}',
  p_interests text[] default '{}',
  p_concerns text[] default '{}',
  p_consents jsonb default '[]'::jsonb
)
returns uuid
security definer
set search_path = public
language plpgsql
as $$
declare
  v_uid text;
  v_child_id uuid;
  v_consent jsonb;
begin
  v_uid := auth.jwt()->>'sub';
  if v_uid is null then
    raise exception 'Unauthorized';
  end if;

  if not exists (select 1 from profiles where uid = v_uid and role = 'parent'::user_role) then
    raise exception 'Only parents can add children';
  end if;

  insert into children (parent_uid, nickname, dob, home_languages, interests, concerns)
  values (v_uid, p_nickname, p_dob, p_home_languages, p_interests, p_concerns)
  returning id into v_child_id;

  if jsonb_typeof(p_consents) = 'array' then
    for v_consent in select * from jsonb_array_elements(p_consents) loop
      insert into consents (uid, child_id, type, granted)
      values (v_uid, v_child_id, v_consent->>'type', (v_consent->>'granted')::boolean);
    end loop;
  end if;

  insert into access_audit (actor_uid, action, table_name, record_id)
  values (v_uid, 'ADD_CHILD', 'children', v_child_id::text);

  return v_child_id;
end;
$$;

grant execute on function add_child to authenticated;

drop policy if exists children_parent_owns on children;
create policy children_parent_owns on children
  for all using (parent_uid = auth.jwt()->>'sub')
  with check (parent_uid = auth.jwt()->>'sub');
