# Registre des activités de traitement

Document interne, non publié. Prévu par l'article 12 de la loi fédérale sur
la protection des données. À tenir à jour et à présenter sur demande du
Préposé fédéral à la protection des données et à la transparence.

Dernière mise à jour : 26 octobre 2026

## Responsable du traitement

| | |
| --- | --- |
| Raison sociale | Pouchelet Aurèle physiothérapie |
| Forme juridique | Entreprise individuelle |
| Numéro IDE | CHE-440.817.245 |
| Responsable | Aurèle Pouchelet, physiothérapeute diplômé |
| Adresse | Grand-Rue 10, 1896 Vouvry |
| Contact | physiotherapiepouchelet@gmail.com · 076 458 28 36 |
| Conseiller à la protection des données | aucun (non obligatoire) |

## Traitement 1 — Comptes de l'espace coaching

| | |
| --- | --- |
| Finalité | Donner accès aux séances d'exercices préparées pour la personne, et en suivre l'avancement |
| Catégories de personnes | Patients du cabinet et clients du coaching sportif ayant créé un compte |
| Catégories de données | Prénom, nom, adresse e-mail, mot de passe haché, matériel à domicile, séances attribuées, dates, séances marquées comme faites |
| Données sensibles | Oui, par prudence : l'existence d'un compte chez un physiothérapeute peut révéler une information de santé |
| Base | Inscription volontaire et exécution de la prestation convenue |
| Durée de conservation | Tant que le compte existe. La personne peut le supprimer elle-même depuis son espace : l'effacement est alors immédiat et irréversible. L'administrateur peut aussi le faire depuis la fiche de la personne. Suppression des comptes inutilisés après 3 ans, avec avertissement préalable |
| Destinataires | Aucun tiers. Sous-traitant : Supabase, Inc. |
| Transfert à l'étranger | Irlande (EEE), protection reconnue comme adéquate par la Suisse |
| Mesures de sécurité | Chiffrement en transit ; cloisonnement par compte au niveau de la base ; rôle administrateur non modifiable par l'utilisateur ; accès administrateur réservé au responsable ; vidéos servies par adresses signées temporaires |

## Traitement 2 — Vidéos d'exercices

| | |
| --- | --- |
| Finalité | Montrer l'exécution correcte de chaque exercice |
| Catégories de personnes | Le responsable lui-même, qui apparaît dans les vidéos |
| Catégories de données | Images et sons du responsable |
| Base | Contenu produit par le responsable pour son propre usage professionnel |
| Durée de conservation | Tant que l'exercice figure dans la bibliothèque |
| Destinataires | Personnes connectées à l'espace coaching |
| Transfert à l'étranger | Irlande (EEE) |
| Mesures de sécurité | Dossier de stockage privé ; adresses signées valables deux heures |

## Traitement 3 — Prise de rendez-vous (ePhysio)

ePhysio agit comme **responsable distinct**, et non comme sous-traitant :
il décide lui-même des moyens et des finalités de ce traitement, qui relève
de son propre registre. Aucun contrat de sous-traitance n'est donc requis.
Cette fiche est conservée pour mémoire, parce que le site oriente les
visiteurs vers cet agenda.

| | |
| --- | --- |
| Finalité | Permettre la réservation d'une séance au cabinet |
| Catégories de personnes | Personnes prenant rendez-vous |
| Catégories de données | Nom, coordonnées, créneau choisi, motif éventuel |
| Responsable du traitement | ePhysio, établi en Suisse |
| Rôle du cabinet | Destinataire des rendez-vous le concernant |
| Transfert à l'étranger | Aucun : hébergement en Suisse |

## Traitement 4 — Journaux techniques du site

| | |
| --- | --- |
| Finalité | Faire fonctionner le site et le protéger contre les abus |
| Catégories de personnes | Visiteurs du site |
| Catégories de données | Adresse IP, horodatage, page demandée, type de navigateur |
| Base | Intérêt légitime au bon fonctionnement et à la sécurité du site |
| Durée de conservation | Quelques semaines, selon les pratiques de l'hébergeur |
| Destinataires | Sous-traitant : Netlify, Inc. |
| Transfert à l'étranger | États-Unis, couvert par les clauses contractuelles types du contrat de traitement des données de Netlify, reconnues par le PFPDT. Si Netlify est certifié au Swiss-U.S. Data Privacy Framework, le transfert relève en outre de la décision d'adéquation du Conseil fédéral du 15 septembre 2024. |
| Portée | Journaux techniques uniquement. Les données des comptes de l'espace coaching ne transitent pas par Netlify : le navigateur s'adresse directement à Supabase. |
| Mesures de sécurité | HTTPS ; en-têtes de sécurité définis dans netlify.toml |

## Traitement 5 — Mesure d'audience des pages publiques

| | |
| --- | --- |
| Finalité | Savoir combien de personnes consultent le site et quelles pages sont lues |
| Catégories de personnes | Visiteurs des pages publiques du site |
| Catégories de données | Page consultée, site d'origine (référent), pays, type d'appareil et de navigateur, code de réponse. Aucun cookie, aucun identifiant déposé sur l'appareil, aucune empreinte de navigateur, aucun comptage de visiteurs uniques. |
| Base | Intérêt légitime à connaître la fréquentation de son propre site, l'outil ne permettant pas d'identifier les personnes |
| Durée de conservation | Agrégats conservés par Cloudflare selon ses propres durées ; aucune donnée individuelle conservée par moi |
| Destinataires | Sous-traitant : Cloudflare, Inc. (Cloudflare Web Analytics) |
| Transfert à l'étranger | États-Unis, couvert par les clauses contractuelles types du contrat de traitement des données de Cloudflare. |
| Portée | **Pages publiques uniquement.** La balise n'est pas présente sur `/espace-coaching/`, où les informations relèvent du secret professionnel. |
| Mesures de sécurité | Script chargé en `defer` depuis le domaine de l'éditeur ; aucune donnée de compte accessible depuis les pages concernées |

## Points à revoir

- Télécharger le contrat de traitement des données de Netlify depuis le tableau de bord et en conserver une copie datée avec ce registre.
- Vérifier sur dataprivacyframework.gov si Netlify figure parmi les entreprises certifiées au Swiss-U.S. Data Privacy Framework, et le noter ici le cas échéant.
- Conserver une copie datée du contrat de traitement des données de Cloudflare, et vérifier si Cloudflare figure parmi les entreprises certifiées au Swiss-U.S. Data Privacy Framework.

## En cas de violation de données

Annoncer dans les meilleurs délais au Préposé fédéral à la protection des
données et à la transparence toute violation présentant un risque élevé
pour la personnalité ou les droits fondamentaux des personnes concernées,
et informer ces personnes lorsque c'est nécessaire à leur protection.
