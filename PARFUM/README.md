# StockParfum

Application mobile complète de gestion de stock pour une boutique commercialisant
des **parfums, Antares, déodorants et produits de soins du visage**.

- **Frontend** : Flutter (Material Design 3)
- **Backend** : Node.js + Express.js (API REST sécurisée)
- **Base de données** : MySQL

```
stockparfum/
├── backend/     → API REST Node.js/Express + scripts SQL
└── frontend/
    └── stockparfum/  → Application Flutter
```

## 1. Mise en place de la base de données

```bash
mysql -u root -p < backend/sql/schema.sql
```

Ce script crée automatiquement la base `stockparfum`, toutes les tables
(`admins`, `categories`, `fournisseurs`, `produits`, `mouvements_stock`) avec
leurs relations, ainsi que les 4 catégories par défaut.

## 2. Lancement du backend

```bash
cd backend
cp .env.example .env      # puis renseignez vos identifiants MySQL et un JWT_SECRET
npm install
npm run seed               # crée le compte admin (admin@stockparfum.mg / Admin@123)
npm run dev                 # démarre le serveur sur http://localhost:3000
```

L'API est documentée dans `backend/README.md`.

## 3. Lancement de l'application Flutter

Le dossier `frontend/stockparfum` contient le code Dart (`lib/`) et le
`pubspec.yaml`, mais **pas** les dossiers de plateforme (`android/`, `ios/`)
qui doivent être générés localement par le SDK Flutter :

```bash
cd frontend/stockparfum
flutter create .            # génère android/, ios/, etc. sans écraser lib/
flutter pub get
```

Puis ouvrez `lib/core/constants/app_constants.dart` et adaptez `baseUrl` :

- **Émulateur Android** : `http://10.0.2.2:3000/api` (valeur par défaut)
- **Appareil physique** : `http://<IP_DE_VOTRE_MACHINE>:3000/api`

Enfin, dans `android/app/src/main/AndroidManifest.xml`, ajoutez (si absent) :

```xml
<uses-permission android:name="android.permission.INTERNET" />
```

Et, pour autoriser les appels HTTP non chiffrés en développement local
(sans certificat HTTPS), ajoutez `android:usesCleartextTraffic="true"` à la
balise `<application>` — à retirer avant une mise en production avec HTTPS.

Lancez ensuite l'application :

```bash
flutter run
```

Connectez-vous avec `admin@stockparfum.mg` / `Admin@123` (modifiable via les
variables `SEED_ADMIN_*` du fichier `.env` avant d'exécuter `npm run seed`).

## Fonctionnalités

- **Authentification** : connexion/déconnexion administrateur (JWT)
- **Tableau de bord** : total produits, quantité totale en stock, produits en
  stock faible, derniers produits ajoutés
- **Produits** : CRUD complet, recherche, image, catégories fixes (Parfums,
  Antares, Déodorants, Crèmes pour le visage)
- **Stock** : entrées/sorties avec mise à jour automatique des quantités et
  alerte de seuil minimum
- **Historique des sorties** : page dédiée (produit, catégorie, quantité,
  date, heure)
- **Fournisseurs** : CRUD complet, recherche (nom, téléphone, adresse)

## Sécurité

- Mots de passe hachés avec bcrypt
- Authentification par JWT (expiration configurable)
- Limitation du débit (rate limiting) globale et renforcée sur `/auth/login`
- En-têtes HTTP sécurisés via Helmet
- Validation systématique des entrées (express-validator)
- Transactions MySQL pour garantir la cohérence des mouvements de stock
