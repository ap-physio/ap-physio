-- 2026-11-20 : matériel par exercice de séance, et même exercice plusieurs fois.
-- À exécuter une fois dans Supabase (SQL Editor). Sans danger si relancé.

-- 1. Un même exercice peut revenir plusieurs fois dans une séance.
drop index if exists public.seance_exercices_unique;

-- 2. Matériel à prévoir (type et poids), texte libre de 80 caractères au plus.
alter table public.seance_exercices add column if not exists materiel text not null default '';
do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'seance_ex_materiel_len') then
    alter table public.seance_exercices
      add constraint seance_ex_materiel_len check (char_length(materiel) <= 80);
  end if;
end $$;
