-- Ajoute le petit mot facultatif de fin de séance (500 caractères au plus).
-- À coller une seule fois dans Supabase > SQL Editor > Run. Sans danger si relancé.

alter table public.seance_dates add column if not exists commentaire text;
do $sc$
begin
  if not exists (select 1 from pg_constraint where conname = 'seance_dates_commentaire_ok') then
    alter table public.seance_dates
      add constraint seance_dates_commentaire_ok
      check (commentaire is null or char_length(commentaire) <= 500);
  end if;
end
$sc$;

drop function if exists public.terminer_seance(uuid, date, integer);

create or replace function public.terminer_seance(p_seance uuid, p_jour date,
                                                  p_ressenti integer default null,
                                                  p_commentaire text default null)
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
         ressenti = coalesce(p_ressenti, ressenti),
         commentaire = coalesce(nullif(left(btrim(p_commentaire), 500), ''), commentaire)
   where seance_id = p_seance and jour = p_jour;

  update public.seance_exercices
     set note = ''
   where seance_id = p_seance and note <> '';
end;
$$;

revoke all on function public.terminer_seance(uuid, date, integer, text) from public;
grant execute on function public.terminer_seance(uuid, date, integer, text) to authenticated;
