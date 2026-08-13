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

-- ============================================================
-- FONCTIONS D'AUTORISATION
-- security definer : contournent RLS en interne pour lire
-- relationship_members sans provoquer de récursion de policy.
-- ============================================================

create or replace function public.is_relationship_member(rel_id uuid)
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1 from relationship_members
    where relationship_id = rel_id and user_id = auth.uid()
  );
$$;

create or replace function public.has_role(rel_id uuid, required_role text)
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1 from relationship_members
    where relationship_id = rel_id and user_id = auth.uid() and role = required_role
  );
$$;

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================

alter table public.profiles enable row level security;
alter table public.relationships enable row level security;
alter table public.relationship_members enable row level security;
alter table public.rules enable row level security;
alter table public.tasks enable row level security;
alter table public.rituals enable row level security;
alter table public.ritual_steps enable row level security;
alter table public.requests enable row level security;
alter table public.rewards enable row level security;
alter table public.reward_redemptions enable row level security;
alter table public.point_transactions enable row level security;
alter table public.journal_entries enable row level security;
alter table public.agreement enable row level security;
alter table public.agreement_acknowledgements enable row level security;
alter table public.activity_log enable row level security;
alter table public.notifications enable row level security;

-- ---------- PROFILES ----------
create policy "profiles_select_own" on public.profiles
  for select using (id = auth.uid());

create policy "profiles_update_own" on public.profiles
  for update using (id = auth.uid());

create policy "profiles_insert_own" on public.profiles
  for insert with check (id = auth.uid());

-- ---------- RELATIONSHIPS ----------
create policy "relationships_select_member" on public.relationships
  for select using (public.is_relationship_member(id));

create policy "relationships_insert_creator" on public.relationships
  for insert with check (created_by = auth.uid());

create policy "relationships_update_member" on public.relationships
  for update using (public.is_relationship_member(id));

-- ---------- RELATIONSHIP_MEMBERS ----------
create policy "members_select_self_relationship" on public.relationship_members
  for select using (public.is_relationship_member(relationship_id));

create policy "members_insert_self" on public.relationship_members
  for insert with check (user_id = auth.uid());

-- ---------- RULES (création/édition/suppression réservées à la Mistress) ----------
create policy "rules_select_member" on public.rules
  for select using (public.is_relationship_member(relationship_id));

create policy "rules_write_mistress" on public.rules
  for insert with check (public.has_role(relationship_id, 'mistress'));

create policy "rules_update_mistress" on public.rules
  for update using (public.has_role(relationship_id, 'mistress'));

create policy "rules_delete_mistress" on public.rules
  for delete using (public.has_role(relationship_id, 'mistress'));

-- ---------- TASKS ----------
create policy "tasks_select_member" on public.tasks
  for select using (public.is_relationship_member(relationship_id));

create policy "tasks_insert_mistress" on public.tasks
  for insert with check (public.has_role(relationship_id, 'mistress'));

-- update ouvert aux deux rôles : la submissive fait progresser le statut
-- (assigned -> in_progress -> submitted), la Mistress approuve/rejette.
-- Le contrôle fin du workflow est fait côté application.
create policy "tasks_update_member" on public.tasks
  for update using (public.is_relationship_member(relationship_id));

create policy "tasks_delete_mistress" on public.tasks
  for delete using (public.has_role(relationship_id, 'mistress'));

-- ---------- RITUALS / RITUAL_STEPS ----------
create policy "rituals_select_member" on public.rituals
  for select using (public.is_relationship_member(relationship_id));

create policy "rituals_write_mistress" on public.rituals
  for insert with check (public.has_role(relationship_id, 'mistress'));

create policy "rituals_update_mistress" on public.rituals
  for update using (public.has_role(relationship_id, 'mistress'));

create policy "rituals_delete_mistress" on public.rituals
  for delete using (public.has_role(relationship_id, 'mistress'));

create policy "ritual_steps_select_member" on public.ritual_steps
  for select using (
    exists (select 1 from rituals r where r.id = ritual_id and public.is_relationship_member(r.relationship_id))
  );

create policy "ritual_steps_write_mistress" on public.ritual_steps
  for insert with check (
    exists (select 1 from rituals r where r.id = ritual_id and public.has_role(r.relationship_id, 'mistress'))
  );

-- update ouvert aux deux : la submissive coche les étapes complétées.
create policy "ritual_steps_update_member" on public.ritual_steps
  for update using (
    exists (select 1 from rituals r where r.id = ritual_id and public.is_relationship_member(r.relationship_id))
  );

create policy "ritual_steps_delete_mistress" on public.ritual_steps
  for delete using (
    exists (select 1 from rituals r where r.id = ritual_id and public.has_role(r.relationship_id, 'mistress'))
  );

-- ---------- REQUESTS ----------
create policy "requests_select_member" on public.requests
  for select using (public.is_relationship_member(relationship_id));

create policy "requests_insert_submissive" on public.requests
  for insert with check (public.has_role(relationship_id, 'submissive') and requested_by = auth.uid());

-- update ouvert aux deux : la Mistress répond, la submissive peut annuler.
create policy "requests_update_member" on public.requests
  for update using (public.is_relationship_member(relationship_id));

-- ---------- REWARDS ----------
create policy "rewards_select_member" on public.rewards
  for select using (public.is_relationship_member(relationship_id));

create policy "rewards_write_mistress" on public.rewards
  for insert with check (public.has_role(relationship_id, 'mistress'));

create policy "rewards_update_mistress" on public.rewards
  for update using (public.has_role(relationship_id, 'mistress'));

create policy "rewards_delete_mistress" on public.rewards
  for delete using (public.has_role(relationship_id, 'mistress'));

-- ---------- REWARD_REDEMPTIONS ----------
create policy "redemptions_select_member" on public.reward_redemptions
  for select using (public.is_relationship_member(relationship_id));

create policy "redemptions_insert_submissive" on public.reward_redemptions
  for insert with check (public.has_role(relationship_id, 'submissive') and redeemed_by = auth.uid());

create policy "redemptions_update_mistress" on public.reward_redemptions
  for update using (public.has_role(relationship_id, 'mistress'));

-- ---------- POINT_TRANSACTIONS ----------
create policy "points_select_member" on public.point_transactions
  for select using (public.is_relationship_member(relationship_id));

create policy "points_insert_mistress" on public.point_transactions
  for insert with check (public.has_role(relationship_id, 'mistress'));

-- ---------- JOURNAL_ENTRIES ----------
-- private : visible uniquement par l'auteur
-- shared : visible par les deux membres
-- mistress_note : visible uniquement par la Mistress
create policy "journal_select_scoped" on public.journal_entries
  for select using (
    public.is_relationship_member(relationship_id)
    and (
      visibility = 'shared'
      or author_id = auth.uid()
      or (visibility = 'mistress_note' and public.has_role(relationship_id, 'mistress'))
    )
  );

create policy "journal_insert_own" on public.journal_entries
  for insert with check (
    public.is_relationship_member(relationship_id) and author_id = auth.uid()
  );

create policy "journal_update_own" on public.journal_entries
  for update using (author_id = auth.uid());

create policy "journal_delete_own" on public.journal_entries
  for delete using (author_id = auth.uid());

-- ---------- AGREEMENT ----------
create policy "agreement_select_member" on public.agreement
  for select using (public.is_relationship_member(relationship_id));

create policy "agreement_insert_mistress" on public.agreement
  for insert with check (public.has_role(relationship_id, 'mistress'));

create policy "agreement_update_mistress" on public.agreement
  for update using (public.has_role(relationship_id, 'mistress'));

-- ---------- AGREEMENT_ACKNOWLEDGEMENTS ----------
create policy "ack_select_member" on public.agreement_acknowledgements
  for select using (public.is_relationship_member(relationship_id));

create policy "ack_insert_own" on public.agreement_acknowledgements
  for insert with check (user_id = auth.uid());

-- ---------- ACTIVITY_LOG ----------
create policy "activity_select_member" on public.activity_log
  for select using (public.is_relationship_member(relationship_id));

create policy "activity_insert_member" on public.activity_log
  for insert with check (public.is_relationship_member(relationship_id));

-- ---------- NOTIFICATIONS ----------
create policy "notifications_select_own" on public.notifications
  for select using (user_id = auth.uid());

create policy "notifications_update_own" on public.notifications
  for update using (user_id = auth.uid());

create policy "notifications_insert_member" on public.notifications
  for insert with check (public.is_relationship_member(relationship_id));
