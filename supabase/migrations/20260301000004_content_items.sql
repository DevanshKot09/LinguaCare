-- Phase 3A Content Infrastructure Migration
create type content_status as enum ('draft', 'slp_review', 'approved', 'published');
create type content_type as enum ('article', 'myth_fact', 'checklist', 'tip_card');

create table if not exists content_items (
  id uuid primary key default gen_random_uuid(),
  slug text unique not null,
  type content_type not null default 'article',
  topic text not null,
  title text not null,
  summary text not null,
  blocks jsonb not null default '[]'::jsonb,
  audience user_role[] not null,
  age_band age_band,
  goal text,
  modifier text,
  language text not null default 'en',
  reading_minutes int not null default 3,
  sources jsonb default '[]'::jsonb,
  status content_status not null default 'draft',
  reviewed_by text,
  reviewed_at timestamptz,
  version int not null default 1,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table content_items enable row level security;

drop policy if exists content_items_published_select on content_items;
create policy content_items_published_select on content_items
  for select using (status = 'published'::content_status);

create index if not exists idx_content_items_status on content_items(status);
create index if not exists idx_content_items_topic on content_items(topic);
create index if not exists idx_content_items_audience on content_items using gin(audience);

create trigger update_content_items_updated_at
  before update on content_items
  for each row execute function update_updated_at_column();
