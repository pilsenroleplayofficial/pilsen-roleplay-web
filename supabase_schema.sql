-- Pilsen Roleplay: starting database blueprint (Supabase / PostgreSQL)
-- Apply only after reviewing. All records are fictional RP data.
create extension if not exists pgcrypto;
create type public.membership_status as enum ('pending','active','suspended','removed');
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null,
  rp_id text unique,
  locale text not null default 'cs' check(locale in ('cs','sk')),
  created_at timestamptz not null default now()
);
create table public.departments (
  id uuid primary key default gen_random_uuid(),
  slug text unique not null,
  name text not null,
  description text default '',
  theme jsonb not null default '{}'::jsonb,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);
create table public.roles (
  id uuid primary key default gen_random_uuid(),
  name text unique not null,
  rank_order integer not null default 0,
  color text default '#168cff',
  permissions jsonb not null default '{}'::jsonb
);
create table public.memberships (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  department_id uuid references public.departments(id),
  role_id uuid references public.roles(id),
  status public.membership_status not null default 'pending',
  created_at timestamptz not null default now(),
  unique(user_id,department_id)
);
create table public.content_items (
  id uuid primary key default gen_random_uuid(),
  kind text not null check(kind in ('news','event','page','gallery','rule')),
  title text not null,
  body text not null default '',
  metadata jsonb not null default '{}'::jsonb,
  published boolean not null default false,
  published_at timestamptz,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create table public.rp_records (
  id uuid primary key default gen_random_uuid(),
  department_id uuid not null references public.departments(id),
  record_type text not null,
  reference_no text not null,
  title text not null,
  status text not null default 'draft',
  rp_subject_id text,
  payload jsonb not null default '{}'::jsonb,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(department_id,reference_no)
);
create table public.access_requests (
  id uuid primary key default gen_random_uuid(),
  requester_id uuid not null references auth.users(id),
  department_id uuid not null references public.departments(id),
  record_id uuid references public.rp_records(id),
  rp_id text not null,
  reason text not null,
  status text not null default 'pending' check(status in ('pending','approved','rejected','expired','closed')),
  created_at timestamptz not null default now(),
  decided_by uuid references auth.users(id),
  decided_at timestamptz
);
create table public.audit_log (
  id bigint generated always as identity primary key,
  actor_id uuid references auth.users(id),
  action text not null,
  table_name text not null,
  record_id text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);
alter table public.profiles enable row level security;
alter table public.departments enable row level security;
alter table public.roles enable row level security;
alter table public.memberships enable row level security;
alter table public.content_items enable row level security;
alter table public.rp_records enable row level security;
alter table public.access_requests enable row level security;
alter table public.audit_log enable row level security;
-- Deliberately no permissive policies are added here. Until policies and
-- server-side authorization are implemented, authenticated clients cannot
-- read or mutate these tables. Never expose the service_role key in a browser.
