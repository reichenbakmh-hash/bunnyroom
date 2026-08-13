-- ============================================================
-- RESET — à exécuter UNE FOIS avant de relancer 01, 02, 03
-- Supprime tout ce qui aurait pu être créé lors des tentatives précédentes.
-- Sans danger : si une table n'existe pas encore, "if exists" l'ignore.
-- ============================================================

drop table if exists public.notifications cascade;
drop table if exists public.activity_log cascade;
drop table if exists public.agreement_acknowledgements cascade;
drop table if exists public.agreement cascade;
drop table if exists public.journal_entries cascade;
drop table if exists public.point_transactions cascade;
drop table if exists public.reward_redemptions cascade;
drop table if exists public.rewards cascade;
drop table if exists public.requests cascade;
drop table if exists public.ritual_steps cascade;
drop table if exists public.rituals cascade;
drop table if exists public.tasks cascade;
drop table if exists public.rules cascade;
drop table if exists public.relationship_members cascade;
drop table if exists public.relationships cascade;
drop table if exists public.profiles cascade;

drop function if exists public.is_relationship_member(uuid) cascade;
drop function if exists public.has_role(uuid, text) cascade;
