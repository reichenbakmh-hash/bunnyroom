-- ============================================================
-- BUNNYROOM — SCHÉMA INITIAL
-- À exécuter dans Supabase : SQL Editor → New query → coller → Run
-- ============================================================

-- ------------------------------------------------------------
-- EXTENSIONS
-- ------------------------------------------------------------
create extension if not exists "pgcrypto";

-- ------------------------------------------------------------
-- PROFILES
-- Un profil par utilisateur Supabase Auth.
-- ------------------------------------------------------------
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null,
  created_at timestamptz not null default now()
);

-- ------------------------------------------------------------
-- RELATIONSHIPS
-- ------------------------------------------------------------
create table public.relationships (
  id uuid primary key default gen_random_uuid(),
  status text not null default 'active' check (status in ('active', 'paused', 'archived')),
  started_at timestamptz not null default now(),
  invite_code text unique,
  created_by uuid not null references public.profiles(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ------------------------------------------------------------
-- RELATIONSHIP_MEMBERS
-- Exactement 2 membres par relation (1 mistress, 1 submissive),
-- imposé par l'application plutôt que par une contrainte SQL rigide.
-- ------------------------------------------------------------
create table public.relationship_members (
  relationship_id uuid not null references public.relationships(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  role text not null check (role in ('mistress', 'submissive')),
  joined_at timestamptz not null default now(),
  primary key (relationship_id, user_id),
  unique (relationship_id, role)
);

-- ------------------------------------------------------------
-- RULES
-- ------------------------------------------------------------
create table public.rules (
  id uuid primary key default gen_random_uuid(),
  relationship_id uuid not null references public.relationships(id) on delete cascade,
  article_number integer not null,
  title text not null,
  category text not null default 'other',
  description text not null default '',
  status text not null default 'draft' check (status in ('draft', 'active', 'suspended', 'expired', 'archived')),
  frequency text,
  priority text not null default 'medium' check (priority in ('low', 'medium', 'high')),
  effective_date date,
  expiration_date date,
  created_by uuid not null references public.profiles(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ------------------------------------------------------------
-- TASKS
-- ------------------------------------------------------------
create table public.tasks (
  id uuid primary key default gen_random_uuid(),
  relationship_id uuid not null references public.relationships(id) on delete cascade,
  title text not null,
  description text not null default '',
  assigned_date date not null default current_date,
  due_date date,
  recurrence text,
  priority text not null default 'medium' check (priority in ('low', 'medium', 'high')),
  points integer not null default 0,
  proof_required boolean not null default false,
  proof_content text,
  status text not null default 'assigned' check (status in ('assigned', 'in_progress', 'submitted', 'approved', 'rejected', 'expired')),
  feedback text,
  assigned_by uuid not null references public.profiles(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ------------------------------------------------------------
-- RITUALS + RITUAL_STEPS
-- ------------------------------------------------------------
create table public.rituals (
  id uuid primary key default gen_random_uuid(),
  relationship_id uuid not null references public.relationships(id) on delete cascade,
  title text not null,
  description text not null default '',
  schedule text,
  recurrence text,
  active boolean not null default true,
  created_by uuid not null references public.profiles(id),
  created_at timestamptz not null default now()
);

create table public.ritual_steps (
  id uuid primary key default gen_random_uuid(),
  ritual_id uuid not null references public.rituals(id) on delete cascade,
  order_index integer not null,
  content text not null,
  last_completed_at timestamptz
);

-- ------------------------------------------------------------
-- REQUESTS
-- ------------------------------------------------------------
create table public.requests (
  id uuid primary key default gen_random_uuid(),
  relationship_id uuid not null references public.relationships(id) on delete cascade,
  requested_by uuid not null references public.profiles(id),
  title text not null,
  message text not null default '',
  status text not null default 'pending' check (status in ('pending', 'approved', 'rejected', 'cancelled')),
  mistress_response text,
  created_at timestamptz not null default now(),
  responded_at timestamptz
);

-- ------------------------------------------------------------
-- REWARDS + REWARD_REDEMPTIONS
-- ------------------------------------------------------------
create table public.rewards (
  id uuid primary key default gen_random_uuid(),
  relationship_id uuid not null references public.relationships(id) on delete cascade,
  title text not null,
  description text not null default '',
  point_cost integer not null default 0,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table public.reward_redemptions (
  id uuid primary key default gen_random_uuid(),
  relationship_id uuid not null references public.relationships(id) on delete cascade,
  reward_id uuid not null references public.rewards(id) on delete cascade,
  redeemed_by uuid not null references public.profiles(id),
  status text not null default 'pending' check (status in ('pending', 'confirmed', 'cancelled')),
  created_at timestamptz not null default now(),
  confirmed_at timestamptz
);

-- ------------------------------------------------------------
-- POINT_TRANSACTIONS
-- ------------------------------------------------------------
create table public.point_transactions (
  id uuid primary key default gen_random_uuid(),
  relationship_id uuid not null references public.relationships(id) on delete cascade,
  user_id uuid not null references public.profiles(id),
  amount integer not null,
  reason text not null,
  created_by uuid not null references public.profiles(id),
  created_at timestamptz not null default now()
);

-- ------------------------------------------------------------
-- JOURNAL_ENTRIES
-- ------------------------------------------------------------
create table public.journal_entries (
  id uuid primary key default gen_random_uuid(),
  relationship_id uuid not null references public.relationships(id) on delete cascade,
  author_id uuid not null references public.profiles(id),
  title text not null,
  content text not null default '',
  mood text,
  tags text[] not null default '{}',
  visibility text not null default 'private' check (visibility in ('private', 'shared', 'mistress_note')),
  created_at timestamptz not null default now()
);

-- ------------------------------------------------------------
-- AGREEMENT (une ligne "courante" par relation) + ACKNOWLEDGEMENTS
-- ------------------------------------------------------------
create table public.agreement (
  relationship_id uuid primary key references public.relationships(id) on delete cascade,
  content text not null default '',
  version integer not null default 1,
  updated_by uuid references public.profiles(id),
  updated_at timestamptz not null default now()
);

create table public.agreement_acknowledgements (
  relationship_id uuid not null references public.relationships(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  version integer not null,
  acknowledged_at timestamptz not null default now(),
  primary key (relationship_id, user_id, version)
);

-- ------------------------------------------------------------
-- ACTIVITY_LOG
-- ------------------------------------------------------------
create table public.activity_log (
  id uuid primary key default gen_random_uuid(),
  relationship_id uuid not null references public.relationships(id) on delete cascade,
  actor_id uuid references public.profiles(id),
  category text not null check (category in ('rule', 'task', 'ritual', 'request', 'reward', 'agreement', 'points', 'journal')),
  description text not null,
  created_at timestamptz not null default now()
);

-- ------------------------------------------------------------
-- NOTIFICATIONS
-- ------------------------------------------------------------
create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  relationship_id uuid not null references public.relationships(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  type text not null,
  read boolean not null default false,
  created_at timestamptz not null default now()
);

