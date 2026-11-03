-- ---------------------------------------------------------------
-- AP Physio — suppression de compte depuis l'interface
-- À coller dans Supabase → SQL Editor → nouvelle requête → Run.
-- Peut être relancé sans risque.
-- ---------------------------------------------------------------
--
-- Efface le compte de connexion et tout ce qui s'y rattache : le profil,
-- les séances, les exercices de ces séances, les dates et les ressentis.
-- Tout se fait en une seule transaction : si une étape échoue, rien n'est
-- supprimé et l'erreur remonte à l'écran.
--
-- Sans argument, la fonction supprime le compte de la personne connectée.
-- Avec un identifiant, elle supprime ce compte-là, et seul
-- l'administrateur en a le droit.

create or replace function public.supprimer_compte(p_id uuid default null)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_id    uuid;
  v_admin boolean;
begin
  v_id    := coalesce(p_id, auth.uid());
  v_admin := public.est_admin();

  if v_id is null then
    raise exception 'Aucun compte visé';
  end if;

  -- On ne supprime que son propre compte, sauf si on est l'administrateur.
  if v_id <> auth.uid() and not v_admin then
    raise exception 'Suppression non autorisée';
  end if;

  -- Garde-fou : l'administrateur ne peut pas effacer son propre compte
  -- depuis l'interface, ce qui le priverait de tout accès.
  if v_id = auth.uid() and v_admin then
    raise exception 'Le compte administrateur ne se supprime pas depuis l''interface';
  end if;

  -- Les séances emportent leurs exercices et leurs dates (cascade).
  delete from public.seances where patient_id = v_id;
  delete from public.profils where id = v_id;
  delete from auth.users  where id = v_id;
end;
$$;

revoke all on function public.supprimer_compte(uuid) from public;
grant execute on function public.supprimer_compte(uuid) to authenticated;
