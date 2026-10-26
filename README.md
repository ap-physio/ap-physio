# ap-physio.ch

Site du cabinet AP Physio (Aurèle Pouchelet, physiothérapeute) et espace coaching des patients.

## Contenu

| Chemin | Rôle |
| --- | --- |
| `index.html` | Page d'accueil du cabinet |
| `espace-coaching/index.html` | Espace coaching : séances, exercices, respiration |
| `manifest.webmanifest` | Permet d'installer l'espace coaching comme une appli |
| `sw.js` | Service worker : l'appli reste ouvrable hors connexion |
| `assets/` | Images du site (logo, photos, QR code) |
| `icons/` | Icônes de l'appli installée |
| `netlify.toml` | Réglages de la mise en ligne |

## Travailler en local

```sh
python3 -m http.server 8000
```

Puis ouvrir http://localhost:8000

## Mise en ligne

Chaque modification envoyée sur la branche `main` est publiée automatiquement par Netlify sur https://ap-physio.ch

## À faire

- [ ] Brancher Supabase (comptes patients, séances, vidéos)
- [ ] Mentions légales et politique de confidentialité
- [ ] Remplacer la photo de portrait par la vraie
- [ ] Téléverser les vidéos d'exercices
