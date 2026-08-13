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
