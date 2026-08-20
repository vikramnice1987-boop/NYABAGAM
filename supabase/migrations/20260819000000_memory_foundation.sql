create extension if not exists pgcrypto;

create table public.memory_sources (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  capture_type text not null check (capture_type in ('text', 'voice', 'image', 'document')),
  raw_content text,
  storage_path text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table public.memories (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  source_id uuid not null references public.memory_sources(id) on delete cascade,
  title text not null,
  summary text not null,
  status text not null default 'confirmed' check (status in ('candidate', 'confirmed', 'archived')),
  occurred_at timestamptz,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.memory_sources enable row level security;
alter table public.memories enable row level security;

create policy "Users manage their own sources" on public.memory_sources
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "Users manage their own memories" on public.memories
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

grant select, insert, update, delete on public.memory_sources to authenticated;
grant select, insert, update, delete on public.memories to authenticated;
