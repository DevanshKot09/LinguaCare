-- Migration 000024: Phase B Security Hardening

-- 1. Consents Append-Only Ledger & RPC
REVOKE UPDATE, DELETE ON consents FROM authenticated, anon, PUBLIC;
DROP POLICY IF EXISTS consents_update ON consents;
DROP POLICY IF EXISTS consents_delete ON consents;

CREATE OR REPLACE FUNCTION withdraw_consent(p_type text, p_child_id uuid DEFAULT NULL)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid text;
begin
  v_uid := auth.jwt()->>'sub';
  if v_uid is null then
    raise exception 'Unauthorized';
  end if;

  INSERT INTO consents (uid, child_id, type, granted)
  VALUES (v_uid, p_child_id, p_type, false);
END;
$$;
GRANT EXECUTE ON FUNCTION withdraw_consent(text, uuid) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION withdraw_consent(text) TO authenticated, service_role;

-- 2. Specialist Licence Change Trigger (sets verified = false when licence fields change)
CREATE OR REPLACE FUNCTION handle_specialist_licence_change()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF (TG_OP = 'UPDATE') AND (
    NEW.licence_no IS DISTINCT FROM OLD.licence_no OR
    NEW.licence_body IS DISTINCT FROM OLD.licence_body OR
    NEW.profession IS DISTINCT FROM OLD.profession
  ) THEN
    -- If not service_role or admin
    IF auth.jwt()->>'role' <> 'service_role' THEN
      UPDATE profiles SET verified = false WHERE uid = NEW.uid;
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_specialist_licence_change ON specialist_details;
CREATE TRIGGER trg_specialist_licence_change
AFTER UPDATE ON specialist_details
FOR EACH ROW
EXECUTE FUNCTION handle_specialist_licence_change();

-- 3. Advisory Locks in preview_invite and accept_invite
CREATE OR REPLACE FUNCTION preview_invite(p_code text)
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

  PERFORM pg_advisory_xact_lock(hashtext(v_uid));

  select role, verified into v_role, v_verified from profiles where uid = v_uid;

  -- Rate limit check (max 5 failed attempts in past hour)
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

  insert into invite_attempts (uid, success) values (v_uid, false);
  raise exception 'invalid or expired code';
end;
$$;
grant execute on function preview_invite to authenticated;

CREATE OR REPLACE FUNCTION accept_invite(p_code text)
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

  PERFORM pg_advisory_xact_lock(hashtext(v_uid));

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
      if v_invite.target_role <> v_role then
        insert into invite_attempts (uid, success) values (v_uid, false);
        raise exception 'wrong_role: Invite is for role %', v_invite.target_role;
      end if;

      if v_role = 'specialist'::user_role and not v_verified then
        insert into invite_attempts (uid, success) values (v_uid, false);
        raise exception 'Specialist verification pending approval by admin';
      end if;

      if v_invite.created_by = v_uid then
        insert into invite_attempts (uid, success) values (v_uid, false);
        raise exception 'Owner cannot accept own invite';
      end if;

      if v_invite.child_id is not null then
        if exists (
          select 1 from links
          where child_id = v_invite.child_id
            and member_uid = v_uid
            and status = 'active'
            and (expires_at is null or expires_at > now())
        ) then
          insert into invite_attempts (uid, success) values (v_uid, false);
          raise exception 'Already linked to this child';
        end if;
      else
        if exists (
          select 1 from links
          where subject_uid = v_invite.subject_uid
            and member_uid = v_uid
            and status = 'active'
            and (expires_at is null or expires_at > now())
        ) then
          insert into invite_attempts (uid, success) values (v_uid, false);
          raise exception 'Already linked to this adult';
        end if;
      end if;

      update invites set consumed_at = now() where id = v_invite.id;
      insert into invite_attempts (uid, success) values (v_uid, true);

      v_expires_at := now() + make_interval(months => v_invite.access_months);

      if v_invite.child_id is not null then
        insert into links (child_id, member_uid, member_role, scope, expires_at, status)
        values (v_invite.child_id, v_uid, v_role, v_invite.scope, v_expires_at, 'active')
        returning id into v_link_id;
      else
        insert into links (subject_uid, member_uid, member_role, scope, expires_at, status)
        values (v_invite.subject_uid, v_uid, v_role, v_invite.scope, v_expires_at, 'active')
        returning id into v_link_id;
      end if;

      return jsonb_build_object('link_id', v_link_id, 'status', 'success');
    end if;
  end loop;

  insert into invite_attempts (uid, success) values (v_uid, false);
  raise exception 'invalid or expired code';
end;
$$;
grant execute on function accept_invite to authenticated;

-- 4. Revoke execute on generate_invite_code
REVOKE EXECUTE ON FUNCTION generate_invite_code FROM authenticated, anon, PUBLIC;
