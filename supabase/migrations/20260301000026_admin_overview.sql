-- Migration 000026: Admin Overview Aggregates RPC

CREATE OR REPLACE FUNCTION admin_overview()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid text;
  v_role user_role;
  v_users_by_role jsonb;
  v_specialists jsonb;
  v_children_by_band jsonb;
  v_screening_count bigint;
  v_activity_count bigint;
  v_active_links bigint;
  v_signups_by_week jsonb;
BEGIN
  v_uid := auth.jwt()->>'sub';
  if v_uid is null then
    raise exception 'Unauthorized';
  end if;

  select role into v_role from profiles where uid = v_uid;
  if v_role <> 'admin' then
    raise exception 'Forbidden: admin role required';
  end if;

  -- Users by role
  select jsonb_object_agg(role, cnt) into v_users_by_role
  from (
    select role::text as role, count(*) as cnt
    from profiles
    group by role
  ) t;

  -- Specialists verified/pending
  select jsonb_build_object(
    'verified', count(*) filter (where role = 'specialist' and verified = true),
    'pending', count(*) filter (where role = 'specialist' and verified = false)
  ) into v_specialists
  from profiles;

  -- Children by band
  select jsonb_object_agg(band, cnt) into v_children_by_band
  from (
    select band, count(*) as cnt
    from children
    group by band
  ) t;

  -- Screening sessions count
  select count(*) into v_screening_count from screening_sessions;

  -- Activity sessions count
  select count(*) into v_activity_count from activity_sessions;

  -- Active links
  select count(*) into v_active_links from links where status = 'active';

  -- Signups by week for 12 weeks
  select coalesce(jsonb_agg(jsonb_build_object('week', w, 'count', cnt)), '[]'::jsonb) into v_signups_by_week
  from (
    select date_trunc('week', created_at)::date as w, count(*) as cnt
    from profiles
    where created_at >= now() - interval '12 weeks'
    group by date_trunc('week', created_at)
    order by w asc
  ) t;

  return jsonb_build_object(
    'users_by_role', coalesce(v_users_by_role, '{}'::jsonb),
    'specialists', coalesce(v_specialists, '{}'::jsonb),
    'children_by_band', coalesce(v_children_by_band, '{}'::jsonb),
    'screening_sessions_count', v_screening_count,
    'activity_sessions_count', v_activity_count,
    'active_links_count', v_active_links,
    'signups_by_week', v_signups_by_week
  );
END;
$$;

REVOKE EXECUTE ON FUNCTION admin_overview() FROM anon, public;
GRANT EXECUTE ON FUNCTION admin_overview() TO authenticated;
