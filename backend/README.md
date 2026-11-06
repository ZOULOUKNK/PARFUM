# StockParfum — Backend (API REST)

## Installation

```bash
npm install
cp .env.example .env   # à compléter avec vos identifiants MySQL et un JWT_SECRET
mysql -u root -p < sql/schema.sql
npm run seed            # crée l'administrateur par défaut
npm run dev              # ou "npm start" en production
```

## Architecture

```
backend/
├── server.js                    # point d'entrée Express
├── sql/schema.sql               # création des tables + relations
└── src/
    ├── config/db.js             # pool de connexions MySQL
    ├── middleware/               # auth JWT, validation, upload, erreurs
    ├── controllers/              # logique métier par ressource
    └── routes/                   # définition des endpoints REST
```

## Authentification

Toutes les routes (sauf `/auth/login`) exigent un en-tête :

```
Authorization: Bearer <token JWT>
```

## Endpoints principaux

| Méthode | Route                              | Description                              |
|---------|-------------------------------------|-------------------------------------------|
| POST    | `/api/auth/login`                   | Connexion admin                           |
| POST    | `/api/auth/logout`                  | Déconnexion                               |
| GET     | `/api/auth/me`                      | Profil de l'admin connecté                |
| GET     | `/api/dashboard`                    | Statistiques du tableau de bord           |
| GET     | `/api/categories`                   | Liste des catégories                      |
| GET     | `/api/products?search=&categorie_id=` | Liste/recherche des produits            |
| POST    | `/api/products` (multipart)         | Créer un produit (+ image)                |
| PUT     | `/api/products/:id` (multipart)     | Modifier un produit                       |
| DELETE  | `/api/products/:id`                 | Supprimer un produit                      |
| POST    | `/api/stock/entree`                 | Enregistrer une entrée de stock           |
| POST    | `/api/stock/sortie`                 | Enregistrer une sortie de stock           |
| GET     | `/api/stock/alertes`                | Produits en stock faible                  |
| GET     | `/api/stock/historique-sorties`     | Historique complet des sorties            |
| GET     | `/api/suppliers?search=`            | Liste/recherche des fournisseurs          |
| POST    | `/api/suppliers`                    | Créer un fournisseur                      |
| PUT     | `/api/suppliers/:id`                | Modifier un fournisseur                   |
| DELETE  | `/api/suppliers/:id`                | Supprimer un fournisseur                  |

Toutes les réponses suivent le format :

```json
{ "success": true, "message": "...", "data": { } }
```

ou en cas d'erreur :

```json
{ "success": false, "message": "..." }
```
