-- Migration 000033: Step 3 Bug Reports, Notifications, and Admin RPCs

-- 1. Bug Reports Table
CREATE TABLE IF NOT EXISTS bug_reports (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  reporter_uid text NOT NULL REFERENCES profiles(uid) ON DELETE CASCADE,
  category text NOT NULL CHECK (category IN ('bug', 'idea', 'account', 'other')),
  message text NOT NULL CHECK (length(message) <= 1000 AND NOT (message ~* '\m[+0-9() -]{7,}\M' OR message ~* '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}')),
  app_version text CHECK (app_version IS NULL OR length(app_version) <= 20),
  platform text CHECK (platform IS NULL OR length(platform) <= 20),
  os_version text CHECK (os_version IS NULL OR length(os_version) <= 40),
  screen text CHECK (screen IS NULL OR length(screen) <= 40),
  status text NOT NULL CHECK (status IN ('open', 'triaged', 'resolved', 'wont_fix')) DEFAULT 'open',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_bug_reports_reporter ON bug_reports(reporter_uid, created_at DESC);
ALTER TABLE bug_reports ENABLE ROW LEVEL SECURITY;

REVOKE INSERT, UPDATE, DELETE ON bug_reports FROM authenticated, anon, PUBLIC;

CREATE POLICY "Bug reports select policy" ON bug_reports
  FOR SELECT
  USING (reporter_uid = auth.jwt()->>'sub' OR (SELECT role FROM profiles WHERE uid = auth.jwt()->>'sub') = 'admin');

-- RPC: submit_bug_report
CREATE OR REPLACE FUNCTION submit_bug_report(
  p_category text,
  p_message text,
  p_app_version text DEFAULT NULL,
  p_platform text DEFAULT NULL,
  p_os_version text DEFAULT NULL,
  p_screen text DEFAULT NULL
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid text;
  v_count int;
  v_report_id uuid;
BEGIN
  v_uid := auth.jwt()->>'sub';
  if v_uid is null then
    raise exception 'Unauthorized';
  end if;

  select count(*) into v_count
  from bug_reports
  where reporter_uid = v_uid and created_at > now() - interval '24 hours';

  if v_count >= 5 then
    raise exception 'Rate limit exceeded: maximum 5 bug reports per 24 hours';
  end if;

  INSERT INTO bug_reports (reporter_uid, category, message, app_version, platform, os_version, screen)
  VALUES (v_uid, p_category, p_message, p_app_version, p_platform, p_os_version, p_screen)
  RETURNING id into v_report_id;

  return v_report_id;
END;
$$;
REVOKE EXECUTE ON FUNCTION submit_bug_report(text, text, text, text, text, text) FROM anon, public;
GRANT EXECUTE ON FUNCTION submit_bug_report(text, text, text, text, text, text) TO authenticated;

-- 2. Notifications Table
CREATE TABLE IF NOT EXISTS notifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_uid text NOT NULL REFERENCES profiles(uid) ON DELETE CASCADE,
  kind text NOT NULL,
  payload jsonb NOT NULL DEFAULT '{}'::jsonb,
  read_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications(user_uid, created_at DESC);
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

REVOKE INSERT, UPDATE, DELETE ON notifications FROM authenticated, anon, PUBLIC;

CREATE POLICY "Notifications select policy" ON notifications
  FOR SELECT
  USING (user_uid = auth.jwt()->>'sub');

-- RPCs for notifications
CREATE OR REPLACE FUNCTION list_notifications(p_limit int DEFAULT 20, p_cursor timestamptz DEFAULT NULL)
RETURNS SETOF notifications
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid text;
BEGIN
  v_uid := auth.jwt()->>'sub';
  if v_uid is null then
    raise exception 'Unauthorized';
  end if;

  return query
  select * from notifications
  where user_uid = v_uid
    and (p_cursor is null or created_at < p_cursor)
  order by created_at desc
  limit p_limit;
END;
$$;
GRANT EXECUTE ON FUNCTION list_notifications(int, timestamptz) TO authenticated;

CREATE OR REPLACE FUNCTION mark_notifications_read(p_ids uuid[])
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid text;
BEGIN
  v_uid := auth.jwt()->>'sub';
  if v_uid is null then
    raise exception 'Unauthorized';
  end if;

  update notifications
  set read_at = now()
  where user_uid = v_uid
    and id = ANY(p_ids)
    and read_at is null;
END;
$$;
GRANT EXECUTE ON FUNCTION mark_notifications_read(uuid[]) TO authenticated;

CREATE OR REPLACE FUNCTION unread_notification_count()
RETURNS bigint
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid text;
  v_count bigint;
BEGIN
  v_uid := auth.jwt()->>'sub';
  if v_uid is null then
    raise exception 'Unauthorized';
  end if;

  select count(*) into v_count
  from notifications
  where user_uid = v_uid and read_at is null;

  return v_count;
END;
$$;
GRANT EXECUTE ON FUNCTION unread_notification_count() TO authenticated;

-- 3. Admin RPCs
CREATE OR REPLACE FUNCTION admin_pending_specialists()
RETURNS TABLE (
  uid text,
  full_name text,
  profession text,
  licence_no text,
  licence_body text,
  workplace text,
  country text,
  created_at timestamptz,
  masked_email text
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid text;
  v_role user_role;
BEGIN
  v_uid := auth.jwt()->>'sub';
  if v_uid is null then
    raise exception 'Unauthorized';
  end if;

  select role into v_role from profiles where uid = v_uid;
  if v_role is null or v_role <> 'admin' then
    raise exception 'Forbidden: admin role required';
  end if;

  return query
  select
    p.uid,
    p.full_name,
    sd.profession,
    sd.licence_no,
    sd.licence_body,
    sd.workplace,
    p.country,
    p.created_at,
    left(p.email, 1) || '***@' || split_part(p.email, '@', 2) as masked_email
  from profiles p
  join specialist_details sd on p.uid = sd.uid
  where p.role = 'specialist' and p.verified = false;
END;
$$;
GRANT EXECUTE ON FUNCTION admin_pending_specialists() TO authenticated;

CREATE OR REPLACE FUNCTION admin_set_specialist_verified(p_uid text, p_approve boolean, p_reason text DEFAULT NULL)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_admin_uid text;
  v_role user_role;
BEGIN
  v_admin_uid := auth.jwt()->>'sub';
  if v_admin_uid is null then
    raise exception 'Unauthorized';
  end if;

  select role into v_role from profiles where uid = v_admin_uid;
  if v_role is null or v_role <> 'admin' then
    raise exception 'Forbidden: admin role required';
  end if;

  update profiles
  set verified = p_approve
  where uid = p_uid and role = 'specialist';

  insert into access_audit (actor_uid, action, table_name, record_id)
  values (v_admin_uid, case when p_approve then 'approve_specialist' else 'reject_specialist' end, 'profiles', p_uid);

  insert into notifications (user_uid, kind, payload)
  values (p_uid, case when p_approve then 'specialist_approved' else 'specialist_rejected' end, jsonb_build_object('reason', coalesce(p_reason, '')));
END;
$$;
GRANT EXECUTE ON FUNCTION admin_set_specialist_verified(text, boolean, text) TO authenticated;

CREATE OR REPLACE FUNCTION admin_list_bug_reports(p_status text DEFAULT NULL, p_limit int DEFAULT 20, p_cursor timestamptz DEFAULT NULL)
RETURNS SETOF bug_reports
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid text;
  v_role user_role;
BEGIN
  v_uid := auth.jwt()->>'sub';
  if v_uid is null then
    raise exception 'Unauthorized';
  end if;

  select role into v_role from profiles where uid = v_uid;
  if v_role is null or v_role <> 'admin' then
    raise exception 'Forbidden: admin role required';
  end if;

  return query
  select * from bug_reports
  where (p_status is null or status = p_status)
    and (p_cursor is null or created_at < p_cursor)
  order by created_at desc
  limit p_limit;
END;
$$;
GRANT EXECUTE ON FUNCTION admin_list_bug_reports(text, int, timestamptz) TO authenticated;

CREATE OR REPLACE FUNCTION admin_set_bug_status(p_id uuid, p_status text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid text;
  v_role user_role;
BEGIN
  v_uid := auth.jwt()->>'sub';
  if v_uid is null then
    raise exception 'Unauthorized';
  end if;

  select role into v_role from profiles where uid = v_uid;
  if v_role is null or v_role <> 'admin' then
    raise exception 'Forbidden: admin role required';
  end if;

  update bug_reports
  set status = p_status, updated_at = now()
  where id = p_id;

  insert into access_audit (actor_uid, action, table_name, record_id)
  values (v_uid, 'set_bug_status', 'bug_reports', p_id::text);
END;
$$;
GRANT EXECUTE ON FUNCTION admin_set_bug_status(uuid, text) TO authenticated;

CREATE OR REPLACE FUNCTION admin_audit_feed(p_limit int DEFAULT 20, p_cursor timestamptz DEFAULT NULL)
RETURNS TABLE (
  id bigint,
  pseudonymous_actor text,
  action text,
  table_name text,
  record_id text,
  at timestamptz
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid text;
  v_role user_role;
BEGIN
  v_uid := auth.jwt()->>'sub';
  if v_uid is null then
    raise exception 'Unauthorized';
  end if;

  select role into v_role from profiles where uid = v_uid;
  if v_role is null or v_role <> 'admin' then
    raise exception 'Forbidden: admin role required';
  end if;

  return query
  select
    a.id,
    left(encode(extensions.digest(coalesce(a.actor_uid, 'system'), 'sha256'), 'hex'), 8) as pseudonymous_actor,
    a.action,
    a.table_name,
    a.record_id,
    a.at
  from access_audit a
  where (p_cursor is null or a.at < p_cursor)
  order by a.at desc
  limit p_limit;
END;
$$;
GRANT EXECUTE ON FUNCTION admin_audit_feed(int, timestamptz) TO authenticated;

-- 4. Triggers for notifications on links
CREATE OR REPLACE FUNCTION notify_link_created()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  insert into notifications (user_uid, kind, payload)
  values (NEW.owner_uid, 'link_accepted', jsonb_build_object('role', NEW.member_role));
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_notify_link_created ON links;
CREATE TRIGGER trg_notify_link_created
AFTER INSERT ON links
FOR EACH ROW
EXECUTE FUNCTION notify_link_created();

CREATE OR REPLACE FUNCTION notify_link_revoked()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF (OLD.status = 'active' AND NEW.status = 'revoked') THEN
    insert into notifications (user_uid, kind, payload)
    values (NEW.member_uid, 'link_revoked', jsonb_build_object('scope', NEW.scope));
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_notify_link_revoked ON links;
CREATE TRIGGER trg_notify_link_revoked
AFTER UPDATE ON links
FOR EACH ROW
EXECUTE FUNCTION notify_link_revoked();
