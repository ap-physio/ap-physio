-- ---------------------------------------------------------------
-- AP Physio — mise à jour du 3 novembre 2026
-- À coller dans Supabase → SQL Editor → nouvelle requête → Run.
-- Peut être relancé sans risque.
-- ---------------------------------------------------------------

-- 1. Exercices enchaînés : on les fait à la suite, le repos ne vient
--    qu'après le dernier de la chaîne.
alter table public.seance_exercices
  add column if not exists enchaine boolean not null default false;

-- 2. Exercices unilatéraux : à faire de chaque côté.
alter table public.exercices
  add column if not exists unilateral boolean not null default false;

-- 3. Ressenti de fin de séance : 1 très facile, 10 très dure.
alter table public.seance_dates
  add column if not exists ressenti smallint;

do $sd$
begin
  if not exists (select 1 from pg_constraint where conname = 'seance_dates_ressenti_ok') then
    alter table public.seance_dates
      add constraint seance_dates_ressenti_ok
      check (ressenti is null or ressenti between 1 and 10);
  end if;
end
$sd$;

-- 4. Matériel déclaré par la personne, avec un détail libre par matériel.
alter table public.profils
  add column if not exists materiel_details jsonb not null default '{}'::jsonb;

-- La personne peut désormais modifier son propre matériel et ses précisions.
-- Le rôle, l'adresse e-mail et l'identifiant restent verrouillés.
create or replace function public.proteger_profil()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is not null and not public.est_admin() then
    new.role := old.role;
    new.email := old.email;
    new.id := old.id;
  end if;
  return new;
end;
$$;

-- 5. La fonction qui clôt une séance enregistre maintenant le ressenti.
drop function if exists public.terminer_seance(uuid, date);

create or replace function public.terminer_seance(p_seance uuid, p_jour date,
                                                  p_ressenti integer default null)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not exists (
    select 1 from public.seances s
    where s.id = p_seance
      and (s.patient_id = auth.uid() or public.est_admin())
  ) then
    raise exception 'Séance introuvable ou non autorisée';
  end if;

  update public.seance_dates
     set faite = true,
         ressenti = coalesce(p_ressenti, ressenti)
   where seance_id = p_seance and jour = p_jour;

  update public.seance_exercices
     set note = ''
   where seance_id = p_seance and note <> '';
end;
$$;

revoke all on function public.terminer_seance(uuid, date, integer) from public;
grant execute on function public.terminer_seance(uuid, date, integer) to authenticated;
