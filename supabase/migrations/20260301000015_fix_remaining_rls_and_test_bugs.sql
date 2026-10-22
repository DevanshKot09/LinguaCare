-- Migration 000015: Fix RLS Insert Policies for Observations & Goals (Trigger timing fix) and list_access_log GROUP BY bug

-- 1. Observations Insert Policy Fix
-- RLS WITH CHECK runs before BEFORE INSERT trigger assigns author_uid.
-- Therefore, checking author_uid = auth.jwt()->>'sub' in INSERT WITH CHECK fails because author_uid is NULL.
-- We rely on populate_observation_author() trigger to set author_uid and author_role.
DROP POLICY IF EXISTS "Observations insert policy" ON observations;
CREATE POLICY "Observations insert policy" ON observations
  FOR INSERT WITH CHECK (
    (auth.jwt()->>'sub') IS NOT NULL
    AND (
      child_id IN (SELECT id FROM children WHERE parent_uid = (auth.jwt()->>'sub'))
      OR EXISTS (
        SELECT 1 FROM links l
        WHERE l.child_id = observations.child_id
          AND l.member_uid = (auth.jwt()->>'sub')
          AND l.status = 'active'
          AND l.scope = 'progress_notes'
          AND (l.expires_at IS NULL OR l.expires_at > NOW())
      )
    )
  );

-- 2. Goals Insert Policy Fix
-- RLS WITH CHECK runs before BEFORE INSERT trigger assigns author_uid and author_role.
DROP POLICY IF EXISTS "Goals insert policy" ON goals;
CREATE POLICY "Goals insert policy" ON goals
  FOR INSERT WITH CHECK (
    (auth.jwt()->>'sub') IS NOT NULL
    AND (
      child_id IN (SELECT id FROM children WHERE parent_uid = (auth.jwt()->>'sub'))
      OR EXISTS (
        SELECT 1 FROM links l
        WHERE l.child_id = goals.child_id
          AND l.member_uid = (auth.jwt()->>'sub')
          AND l.status = 'active'
          AND (l.expires_at IS NULL OR l.expires_at > NOW())
      )
    )
  );

-- 3. Fix list_access_log GROUP BY Bug
CREATE OR REPLACE FUNCTION list_access_log(p_child_id uuid default null, p_link_id uuid default null)
RETURNS jsonb
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
declare
  v_uid text;
  v_result jsonb;
begin
  v_uid := auth.jwt()->>'sub';
  if v_uid is null then
    raise exception 'Unauthorized';
  end if;

  if p_child_id is not null and not exists (select 1 from children where id = p_child_id and parent_uid = v_uid) then
    raise exception 'Unauthorized or child not found';
  end if;

  if p_link_id is not null and not exists (select 1 from links where id = p_link_id and owner_uid = v_uid) then
    raise exception 'Unauthorized or link not found';
  end if;

  select jsonb_agg(
    jsonb_build_object(
      'member_name', t.full_name,
      'member_role', t.member_role,
      'action', t.action,
      'timestamp', t.at
    )
  ) into v_result
  from (
    select p.full_name, l.member_role, a.action, a.at
    from access_audit a
    join links l on a.record_id = l.id::text
    join profiles p on a.actor_uid = p.uid
    where (l.owner_uid = v_uid)
      and (p_link_id is null or l.id = p_link_id)
      and (p_child_id is null or l.child_id = p_child_id)
      and a.action in ('ACCEPT_INVITE', 'GET_SHARED_SUMMARY', 'REVOKE_LINK')
    group by p.full_name, l.member_role, a.action, a.at
    order by a.at desc
  ) t;

  return coalesce(v_result, '[]'::jsonb);
end;
$$;
GRANT EXECUTE ON FUNCTION list_access_log TO authenticated;
