-- NYABAGAM V1 Core Production Database Schema
-- Extensions
create extension if not exists pgcrypto;
create extension if not exists vector;

-- 1. Profiles & User Preferences
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  email text,
  timezone text default 'UTC',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.user_preferences (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references auth.users(id) on delete cascade,
  notifications_enabled boolean not null default true,
  audio_transcription_enabled boolean not null default true,
  theme_preference text not null default 'system' check (theme_preference in ('system', 'light', 'dark')),
  retention_days integer default 365,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Automatic profile creation on auth.users signup
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, display_name, email)
  values (new.id, coalesce(new.raw_user_meta_data->>'display_name', split_part(new.email, '@', 1)), new.email)
  on conflict (id) do update set email = excluded.email;

  insert into public.user_preferences (user_id)
  values (new.id)
  on conflict (user_id) do nothing;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- 2. Domain Entities: People, Organizations, Things, Places, Events
create table if not exists public.people (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  normalized_name text generated always as (lower(trim(name))) stored,
  phone text,
  email text,
  notes text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.organizations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  normalized_name text generated always as (lower(trim(name))) stored,
  phone text,
  website text,
  notes text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.things (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  category text, -- e.g., appliance, vehicle, document, subscription
  current_status text default 'active', -- active, needs_service, resolved, broken, archived
  notes text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.places (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  address text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  event_type text not null default 'general', -- service, purchase, repair, appointment, conversation
  occurred_at timestamptz not null default now(),
  cost_amount numeric(12,2),
  cost_currency text default 'INR',
  notes text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

-- 3. Relationships Graph (Typed directional links between entities)
create table if not exists public.relationships (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  source_type text not null check (source_type in ('person', 'organization', 'thing', 'place', 'event')),
  source_id uuid not null,
  relationship_type text not null, -- works_for, serviced, owns, located_at, participant_in, related_to
  target_type text not null check (target_type in ('person', 'organization', 'thing', 'place', 'event')),
  target_id uuid not null,
  valid_from timestamptz,
  valid_to timestamptz,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

-- 4. Memory Sources & Canonical Memories
create table if not exists public.memory_sources (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  capture_type text not null check (capture_type in ('text', 'voice', 'image', 'document')),
  raw_content text,
  storage_path text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.memories (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  source_id uuid references public.memory_sources(id) on delete set null,
  title text not null,
  summary text not null,
  memory_type text not null default 'general', -- fact, service, purchase, reminder, event
  status text not null default 'confirmed' check (status in ('candidate', 'confirmed', 'archived', 'forgotten')),
  occurred_at timestamptz,
  version integer not null default 1,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Memory Entity Links (Links memories directly to entities)
create table if not exists public.memory_entities (
  id uuid primary key default gen_random_uuid(),
  memory_id uuid not null references public.memories(id) on delete cascade,
  entity_type text not null check (entity_type in ('person', 'organization', 'thing', 'place', 'event')),
  entity_id uuid not null,
  created_at timestamptz not null default now()
);

-- 5. Memory Embeddings (pgvector)
create table if not exists public.memory_embeddings (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  memory_id uuid not null references public.memories(id) on delete cascade,
  embedding vector(1536) not null,
  content_hash text,
  model_version text not null default 'text-embedding-3-small',
  created_at timestamptz not null default now()
);

-- 6. Actions, Approvals, Events & Outcomes
create table if not exists public.actions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  memory_id uuid references public.memories(id) on delete set null,
  action_type text not null check (action_type in ('message', 'phone_call', 'reminder', 'calendar', 'manual')),
  title text not null,
  proposal jsonb not null default '{}'::jsonb,
  status text not null default 'proposed' check (status in ('proposed', 'approved', 'executing', 'completed', 'failed', 'cancelled', 'expired')),
  idempotency_key text,
  approved_at timestamptz,
  executed_at timestamptz,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.approvals (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  action_id uuid not null references public.actions(id) on delete cascade,
  approved_payload jsonb not null,
  approved_at timestamptz not null default now()
);

create table if not exists public.action_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  action_id uuid not null references public.actions(id) on delete cascade,
  event_type text not null, -- proposed, approved, dispatched, completed, failed
  details jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.outcomes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  action_id uuid references public.actions(id) on delete set null,
  thing_id uuid references public.things(id) on delete set null,
  status text not null default 'resolved' check (status in ('resolved', 'partial', 'unresolved', 'cancelled', 'unknown')),
  summary text not null,
  source_id uuid references public.memory_sources(id) on delete set null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.state_history (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  entity_type text not null,
  entity_id uuid not null,
  previous_status text,
  new_status text not null,
  reason text,
  created_at timestamptz not null default now()
);

-- 7. Conversations, Messages, Context Requests & Audit
create table if not exists public.conversations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  sender_role text not null check (sender_role in ('user', 'assistant', 'system')),
  content text not null,
  evidence_ids jsonb not null default '[]'::jsonb,
  suggested_actions jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.audit_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  action_name text not null,
  entity_type text,
  entity_id uuid,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

-- 8. Indexes
create index if not exists idx_memories_user_status on public.memories(user_id, status, created_at desc);
create index if not exists idx_people_user_name on public.people(user_id, normalized_name);
create index if not exists idx_orgs_user_name on public.organizations(user_id, normalized_name);
create index if not exists idx_things_user on public.things(user_id, current_status);
create index if not exists idx_events_user on public.events(user_id, occurred_at desc);
create index if not exists idx_relationships_user on public.relationships(user_id, source_id, target_id);
create index if not exists idx_actions_user on public.actions(user_id, status);

-- 9. Row Level Security (RLS)
alter table public.profiles enable row level security;
alter table public.user_preferences enable row level security;
alter table public.people enable row level security;
alter table public.organizations enable row level security;
alter table public.things enable row level security;
alter table public.places enable row level security;
alter table public.events enable row level security;
alter table public.relationships enable row level security;
alter table public.memory_sources enable row level security;
alter table public.memories enable row level security;
alter table public.memory_entities enable row level security;
alter table public.memory_embeddings enable row level security;
alter table public.actions enable row level security;
alter table public.approvals enable row level security;
alter table public.action_events enable row level security;
alter table public.outcomes enable row level security;
alter table public.state_history enable row level security;
alter table public.conversations enable row level security;
alter table public.messages enable row level security;
alter table public.audit_events enable row level security;

-- Policies
create policy "Users manage their own profile" on public.profiles for all using (auth.uid() = id) with check (auth.uid() = id);
create policy "Users manage their own preferences" on public.user_preferences for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "Users manage their own people" on public.people for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "Users manage their own orgs" on public.organizations for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "Users manage their own things" on public.things for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "Users manage their own places" on public.places for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "Users manage their own events" on public.events for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "Users manage their own relationships" on public.relationships for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "Users manage their own sources" on public.memory_sources for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "Users manage their own memories" on public.memories for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "Users manage their own memory entities" on public.memory_entities for all using (exists (select 1 from public.memories m where m.id = memory_entities.memory_id and m.user_id = auth.uid()));
create policy "Users manage their own embeddings" on public.memory_embeddings for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "Users manage their own actions" on public.actions for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "Users manage their own approvals" on public.approvals for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "Users manage their own action events" on public.action_events for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "Users manage their own outcomes" on public.outcomes for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "Users manage their own state history" on public.state_history for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "Users manage their own conversations" on public.conversations for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "Users manage their own messages" on public.messages for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "Users manage their own audit events" on public.audit_events for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- 10. Database Stored Functions / RPCs

-- Hybrid Vector + Keyword Search RPC
create or replace function public.search_memories(
  p_query text,
  p_embedding vector(1536) default null,
  p_limit integer default 10
)
returns table (
  memory_id uuid,
  title text,
  summary text,
  occurred_at timestamptz,
  similarity float,
  metadata jsonb
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
begin
  if v_user_id is null then
    raise exception 'Not authenticated';
  end if;

  if p_embedding is not null then
    return query
    select
      m.id as memory_id,
      m.title,
      m.summary,
      m.occurred_at,
      (1 - (e.embedding <=> p_embedding))::float as similarity,
      m.metadata
    from public.memories m
    join public.memory_embeddings e on e.memory_id = m.id
    where m.user_id = v_user_id
      and m.status in ('confirmed', 'active')
    order by e.embedding <=> p_embedding
    limit p_limit;
  else
    return query
    select
      m.id as memory_id,
      m.title,
      m.summary,
      m.occurred_at,
      case when m.title ilike '%' || p_query || '%' or m.summary ilike '%' || p_query || '%' then 1.0 else 0.5 end as similarity,
      m.metadata
    from public.memories m
    where m.user_id = v_user_id
      and m.status in ('confirmed', 'active')
      and (m.title ilike '%' || p_query || '%' or m.summary ilike '%' || p_query || '%')
    order by m.created_at desc
    limit p_limit;
  end if;
end;
$$;

-- Find Related Context for Context Bridge RPC
create or replace function public.find_related_context(
  p_entity_name text,
  p_limit integer default 5
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_result jsonb;
begin
  if v_user_id is null then
    raise exception 'Not authenticated';
  end if;

  select jsonb_build_object(
    'entity', (select to_jsonb(t) from public.things t where t.user_id = v_user_id and t.name ilike '%' || p_entity_name || '%' limit 1),
    'memories', coalesce((
      select jsonb_agg(to_jsonb(m))
      from (
        select m.id, m.title, m.summary, m.occurred_at, m.metadata
        from public.memories m
        where m.user_id = v_user_id
          and m.status in ('confirmed', 'active')
          and (m.title ilike '%' || p_entity_name || '%' or m.summary ilike '%' || p_entity_name || '%')
        order by m.occurred_at desc nulls last, m.created_at desc
        limit p_limit
      ) m
    ), '[]'::jsonb),
    'people', coalesce((
      select jsonb_agg(to_jsonb(p))
      from public.people p
      where p.user_id = v_user_id
      limit p_limit
    ), '[]'::jsonb)
  ) into v_result;

  return v_result;
end;
$$;