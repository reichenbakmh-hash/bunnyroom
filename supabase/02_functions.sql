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

