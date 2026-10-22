create table if not exists auth_probe (
  id uuid primary key default gen_random_uuid(),
  uid text default (auth.jwt()->>'sub'),
  note text,
  created_at timestamptz default now()
);

alter table auth_probe enable row level security;

drop policy if exists auth_probe_owner on auth_probe;
create policy auth_probe_owner on auth_probe for all
  using (uid = auth.jwt()->>'sub')
  with check (uid = auth.jwt()->>'sub');
