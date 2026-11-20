-- =====================================================================
--  AP Physio — base de données de l'espace coaching
--  À coller dans Supabase : SQL Editor → New query → Run.
--  Le script peut être relancé sans dommage.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. Profils des patients
--    Un profil par compte. Aucune donnée de santé, aucun diagnostic :
--    seulement un nom et le matériel disponible à la maison.
-- ---------------------------------------------------------------------
create table if not exists public.profils (
  id         uuid primary key references auth.users (id) on delete cascade,
  prenom     text not null default '',
  nom        text not null default '',
  -- Recopiée depuis le compte, pour que l'administrateur voie à qui il
  -- a affaire sans avoir accès à la table des comptes.
  email      text not null default '',
  role       text not null default 'patient' check (role in ('patient', 'admin')),
  materiel   text[] not null default '{}',
  -- Précisions libres saisies par la personne, une par matériel coché :
  -- {"Élastiques": "une rouge et une noire", "Haltères": "2 x 8 kg"}
  materiel_details jsonb not null default '{}'::jsonb,
  cree_le    timestamptz not null default now()
);

alter table public.profils
  add column if not exists materiel_details jsonb not null default '{}'::jsonb;

-- Crée le profil automatiquement à l'inscription.
create or replace function public.gerer_nouvel_utilisateur()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profils (id, prenom, nom, email)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'prenom', ''),
    coalesce(new.raw_user_meta_data ->> 'nom', ''),
    coalesce(new.email, '')
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists au_nouvel_utilisateur on auth.users;
create trigger au_nouvel_utilisateur
  after insert on auth.users
  for each row execute function public.gerer_nouvel_utilisateur();

-- Dit si le compte connecté est l'administrateur.
-- security definer : la fonction lit la table sans repasser par les
-- règles d'accès, ce qui évite une récursion infinie dans les règles.
create or replace function public.est_admin()
returns boolean
language sql
security definer
stable
set search_path = ''
as $$
  select exists (
    select 1 from public.profils p
    where p.id = auth.uid() and p.role = 'admin'
  );
$$;

alter table public.profils add column if not exists email text not null default '';

-- Rattrape les comptes créés avant l'ajout de la colonne.
update public.profils p
set email = u.email
from auth.users u
where u.id = p.id and p.email = '' and u.email is not null;

-- Un patient peut corriger son prénom et son nom, mais ni se déclarer
-- administrateur, ni s'attribuer du matériel : ces deux colonnes ne
-- changent que si c'est l'administrateur qui écrit.
create or replace function public.proteger_profil()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  -- auth.uid() est vide quand l'écriture vient du SQL Editor ou d'une clé de
  -- service : c'est déjà un accès de confiance, on ne bride rien.
  -- La personne déclare elle-même son matériel et ses précisions :
  -- materiel et materiel_details restent modifiables. Le rôle, l'adresse
  -- e-mail et l'identifiant, eux, ne bougent pas.
  if auth.uid() is not null and not public.est_admin() then
    new.role := old.role;
    new.email := old.email;
    new.id := old.id;
  end if;
  return new;
end;
$$;

drop trigger if exists avant_maj_profil on public.profils;
create trigger avant_maj_profil
  before update on public.profils
  for each row execute function public.proteger_profil();

-- ---------------------------------------------------------------------
-- 2. Bibliothèque d'exercices
-- ---------------------------------------------------------------------
create table if not exists public.exercices (
  id         uuid primary key default gen_random_uuid(),
  nom        text not null unique,
  categorie  text not null check (categorie in (
               'Membre supérieur', 'Membre inférieur',
               'Mobilité / stretching', 'Tronc')),
  consigne   text not null default '',
  materiel   text[] not null default '{}',
  -- 'reps' : un nombre de répétitions. 'sec' : une durée à tenir.
  unite      text not null default 'reps' check (unite in ('reps', 'sec')),
  -- Secondes par répétition, pour estimer la durée d'une séance.
  tempo      integer not null default 4 check (tempo between 1 and 30),
  -- Exercice à faire de chaque côté (gainage latéral, fente...).
  unilateral boolean not null default false,
  video      text,
  cree_le    timestamptz not null default now()
);

-- Colonnes ajoutées après coup, si la table existait déjà.
alter table public.exercices add column if not exists unite text not null default 'reps';
alter table public.exercices add column if not exists unilateral boolean not null default false;
alter table public.exercices add column if not exists tempo integer not null default 4;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'exercices_nom_key' and conrelid = 'public.exercices'::regclass
  ) then
    alter table public.exercices add constraint exercices_nom_key unique (nom);
  end if;
end $$;

create index if not exists exercices_categorie_idx on public.exercices (categorie);

-- ---------------------------------------------------------------------
-- 3. Séances préparées pour un patient
-- ---------------------------------------------------------------------
create table if not exists public.seances (
  id         uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.profils (id) on delete cascade,
  titre      text not null default 'Séance',
  note       text not null default '',
  -- Repos entre deux exercices, en secondes.
  repos_exercice integer not null default 30 check (repos_exercice between 0 and 600),
  cree_le    timestamptz not null default now()
);

alter table public.seances add column if not exists repos_exercice integer not null default 30;

create index if not exists seances_patient_idx on public.seances (patient_id);

create table if not exists public.seance_exercices (
  id             uuid primary key default gen_random_uuid(),
  seance_id      uuid not null references public.seances (id) on delete cascade,
  exercice_id    uuid not null references public.exercices (id) on delete restrict,
  position       integer not null default 0,
  series         integer not null default 3  check (series between 1 and 20),
  -- Nombre de répétitions, ou nombre de secondes selon l'unité de l'exercice.
  valeur         integer not null default 12 check (valeur between 1 and 300),
  -- Repos entre deux séries, en secondes.
  repos          integer not null default 45 check (repos between 0 and 600),
  -- Consigne propre à cet exercice dans cette séance, en plus de la
  -- consigne générale de l'exercice.
  note           text not null default '',
  -- Enchaîné avec l'exercice suivant : on les fait à la suite, le repos
  -- ne vient qu'après le dernier de la chaîne.
  enchaine       boolean not null default false
);

alter table public.seance_exercices add column if not exists valeur integer not null default 12;
alter table public.seance_exercices add column if not exists repos  integer not null default 45;
alter table public.seance_exercices add column if not exists note   text not null default '';
alter table public.seance_exercices add column if not exists enchaine boolean not null default false;
alter table public.seance_exercices drop column if exists repetitions;
alter table public.seance_exercices drop column if exists repos_series;
alter table public.seance_exercices drop column if exists repos_exercice;

-- Un même exercice peut revenir plusieurs fois dans une séance : l'ancienne
-- contrainte d'unicité est retirée.
drop index if exists public.seance_exercices_unique;

-- Matériel à prévoir pour cet exercice dans cette séance (type et poids),
-- saisi librement par l'administrateur et montré à la personne avant le départ.
alter table public.seance_exercices add column if not exists materiel text not null default '';
do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'seance_ex_materiel_len') then
    alter table public.seance_exercices
      add constraint seance_ex_materiel_len check (char_length(materiel) <= 80);
  end if;
end $$;

create index if not exists seance_exercices_seance_idx
  on public.seance_exercices (seance_id, position);

create table if not exists public.seance_dates (
  id        uuid primary key default gen_random_uuid(),
  seance_id uuid not null references public.seances (id) on delete cascade,
  jour      date not null,
  faite     boolean not null default false,
  -- Ressenti de la personne à la fin de la séance : 1 très facile, 10 très dure.
  ressenti  smallint check (ressenti is null or ressenti between 1 and 10),
  -- Petit mot facultatif de la personne, 500 caractères au plus.
  commentaire text check (commentaire is null or char_length(commentaire) <= 500),
  unique (seance_id, jour)
);

alter table public.seance_dates add column if not exists ressenti smallint;
alter table public.seance_dates add column if not exists commentaire text;
do $sd$
begin
  if not exists (select 1 from pg_constraint where conname = 'seance_dates_ressenti_ok') then
    alter table public.seance_dates
      add constraint seance_dates_ressenti_ok
      check (ressenti is null or ressenti between 1 and 10);
  end if;
end
$sd$;
do $sc$
begin
  if not exists (select 1 from pg_constraint where conname = 'seance_dates_commentaire_ok') then
    alter table public.seance_dates
      add constraint seance_dates_commentaire_ok
      check (commentaire is null or char_length(commentaire) <= 500);
  end if;
end
$sc$;

create index if not exists seance_dates_jour_idx on public.seance_dates (jour);

-- ---------------------------------------------------------------------
-- 4. Règles d'accès
--    Rien n'est lisible par défaut : chaque patient ne voit que ce qui
--    le concerne, et seul l'administrateur peut modifier.
-- ---------------------------------------------------------------------
alter table public.profils           enable row level security;
alter table public.exercices         enable row level security;
alter table public.seances           enable row level security;
alter table public.seance_exercices  enable row level security;
alter table public.seance_dates      enable row level security;

-- Profils
drop policy if exists "profil lisible par son titulaire" on public.profils;
create policy "profil lisible par son titulaire" on public.profils
  for select to authenticated
  using (id = auth.uid() or public.est_admin());

drop policy if exists "profil modifiable par son titulaire" on public.profils;
create policy "profil modifiable par son titulaire" on public.profils
  for update to authenticated
  using (id = auth.uid() or public.est_admin())
  with check (id = auth.uid() or public.est_admin());

-- Exercices : tout patient connecté les consulte, seul l'admin les change.
drop policy if exists "exercices visibles des connectes" on public.exercices;
create policy "exercices visibles des connectes" on public.exercices
  for select to authenticated using (true);

drop policy if exists "exercices geres par l admin" on public.exercices;
create policy "exercices geres par l admin" on public.exercices
  for all to authenticated
  using (public.est_admin()) with check (public.est_admin());

-- Séances
drop policy if exists "seances visibles du patient" on public.seances;
create policy "seances visibles du patient" on public.seances
  for select to authenticated
  using (patient_id = auth.uid() or public.est_admin());

drop policy if exists "seances gerees par l admin" on public.seances;
create policy "seances gerees par l admin" on public.seances
  for all to authenticated
  using (public.est_admin()) with check (public.est_admin());

-- Exercices d'une séance
drop policy if exists "exercices de seance visibles du patient" on public.seance_exercices;
create policy "exercices de seance visibles du patient" on public.seance_exercices
  for select to authenticated
  using (
    public.est_admin() or exists (
      select 1 from public.seances s
      where s.id = seance_exercices.seance_id and s.patient_id = auth.uid()
    )
  );

drop policy if exists "exercices de seance geres par l admin" on public.seance_exercices;
create policy "exercices de seance geres par l admin" on public.seance_exercices
  for all to authenticated
  using (public.est_admin()) with check (public.est_admin());

-- Dates : le patient coche lui-même ses séances faites.
drop policy if exists "dates visibles du patient" on public.seance_dates;
create policy "dates visibles du patient" on public.seance_dates
  for select to authenticated
  using (
    public.est_admin() or exists (
      select 1 from public.seances s
      where s.id = seance_dates.seance_id and s.patient_id = auth.uid()
    )
  );

drop policy if exists "patient coche sa seance" on public.seance_dates;
create policy "patient coche sa seance" on public.seance_dates
  for update to authenticated
  using (
    exists (
      select 1 from public.seances s
      where s.id = seance_dates.seance_id and s.patient_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from public.seances s
      where s.id = seance_dates.seance_id and s.patient_id = auth.uid()
    )
  );

drop policy if exists "dates gerees par l admin" on public.seance_dates;
create policy "dates gerees par l admin" on public.seance_dates
  for all to authenticated
  using (public.est_admin()) with check (public.est_admin());

-- ---------------------------------------------------------------------
--    Fin de séance
--    Appelée par la personne quand elle termine sa séance. Elle coche la
--    date et efface les consignes ponctuelles, qui n'ont plus lieu d'être.
--    En security definer, parce qu'un patient n'a pas le droit d'écrire
--    dans seance_exercices : la fonction vérifie elle-même que la séance
--    lui appartient.
-- ---------------------------------------------------------------------
drop function if exists public.terminer_seance(uuid, date);
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

-- ---------------------------------------------------------------------
--    Suppression d'un compte. Sans argument, c'est son propre compte ;
--    avec un identifiant, c'est celui de quelqu'un, et seul
--    l'administrateur en a le droit. Tout part en une transaction :
--    si une étape échoue, rien n'est supprimé.
-- ---------------------------------------------------------------------
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


-- ---------------------------------------------------------------------
-- 5. Stockage des vidéos d'exercices
--    Dossier privé : les vidéos ne sont pas accessibles sans compte.
-- ---------------------------------------------------------------------
insert into storage.buckets (id, name, public)
values ('videos', 'videos', false)
on conflict (id) do nothing;

drop policy if exists "videos visibles des connectes" on storage.objects;
create policy "videos visibles des connectes" on storage.objects
  for select to authenticated
  using (bucket_id = 'videos');

drop policy if exists "videos gerees par l admin" on storage.objects;
create policy "videos gerees par l admin" on storage.objects
  for all to authenticated
  using (bucket_id = 'videos' and public.est_admin())
  with check (bucket_id = 'videos' and public.est_admin());

-- ---------------------------------------------------------------------
-- 6. Les 12 exercices repris du prototype
--    La colonne video reste vide : elle sera remplie quand les vidéos
--    auront été filmées et téléversées.
-- ---------------------------------------------------------------------
insert into public.exercices (nom, categorie, consigne, materiel) values
  ('Pont fessier', 'Membre inférieur', 'Pieds à plat, genoux pliés. Monte le bassin sans creuser le bas du dos et marque une pause en haut.', '{"Tapis"}'),
  ('Squat au mur', 'Membre inférieur', 'Dos plaqué au mur, genoux au-dessus des chevilles. Tiens la position.', '{}'),
  ('Gainage planche', 'Tronc', 'Avant-bras au sol, corps aligné de la tête aux talons. Respire calmement.', '{"Tapis"}'),
  ('Fente arrière', 'Membre inférieur', 'Recule un pied, descends en gardant le buste droit, puis remonte en poussant dans la jambe avant.', '{}'),
  ('Rowing avec élastique', 'Membre supérieur', 'Tire vers ta taille en serrant les omoplates, puis reviens lentement.', '{"Élastiques"}'),
  ('Étirement des ischio-jambiers', 'Mobilité / stretching', 'Jambe tendue devant toi, penche le buste vers l’avant en gardant le dos long. Étirement doux.', '{}'),
  ('Étirement du psoas', 'Mobilité / stretching', 'Genou au sol, pousse doucement le bassin vers l’avant. Garde le buste droit.', '{"Tapis"}'),
  ('Étirement des mollets', 'Mobilité / stretching', 'Mains au mur, jambe arrière tendue, talon au sol. Avance le bassin vers le mur.', '{}'),
  ('Rotation thoracique', 'Mobilité / stretching', 'À quatre pattes, une main derrière la tête. Ouvre le coude vers le plafond puis reviens.', '{"Tapis"}'),
  ('Mobilité de hanche 90/90', 'Mobilité / stretching', 'Assis, genoux à 90°. Fais pivoter les genoux d’un côté à l’autre sans aide des mains.', '{"Tapis"}'),
  ('Chat-vache', 'Mobilité / stretching', 'À quatre pattes, arrondis puis creuse le dos en suivant ta respiration.', '{"Tapis"}'),
  ('Montées sur pointes', 'Membre inférieur', 'Debout, monte sur la pointe des pieds, marque une pause, puis redescends lentement.', '{}')
on conflict (nom) do nothing;

-- =====================================================================
--  DERNIÈRE ÉTAPE, À FAIRE APRÈS AVOIR CRÉÉ TON PROPRE COMPTE
--  dans l'espace coaching. Elle te donne les droits d'administrateur.
--  Relance juste cette commande seule, dans le SQL Editor :
--
--  update public.profils set role = 'admin'
--  where id = (select id from auth.users
--              where email = 'physiotherapiepouchelet@gmail.com');
-- =====================================================================
