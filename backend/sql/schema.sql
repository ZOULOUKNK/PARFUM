-- =====================================================================
-- StockParfum - Script de création de la base de données MySQL
-- =====================================================================
-- Ce script crée automatiquement toutes les tables nécessaires ainsi
-- que leurs relations (clés étrangères) et quelques index utiles.
-- =====================================================================

CREATE DATABASE IF NOT EXISTS stockparfum
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE stockparfum;

-- ---------------------------------------------------------------------
-- Table : admins
-- Comptes administrateurs autorisés à se connecter à l'application
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS admins (
  id            INT AUTO_INCREMENT PRIMARY KEY,
  nom           VARCHAR(100) NOT NULL,
  email         VARCHAR(150) NOT NULL UNIQUE,
  mot_de_passe  VARCHAR(255) NOT NULL,        -- hash bcrypt
  created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- Table : categories
-- Catégories fixes de produits (Parfums, Antares, Déodorants, Crèmes)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS categories (
  id    INT AUTO_INCREMENT PRIMARY KEY,
  nom   VARCHAR(100) NOT NULL UNIQUE
) ENGINE=InnoDB;

INSERT INTO categories (nom) VALUES
  ('Parfums'), ('Antares'), ('Déodorants'), ('Crèmes pour le visage')
ON DUPLICATE KEY UPDATE nom = VALUES(nom);

-- ---------------------------------------------------------------------
-- Table : fournisseurs
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS fournisseurs (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  nom         VARCHAR(150) NOT NULL,
  telephone   VARCHAR(30)  NOT NULL,
  adresse     VARCHAR(255) DEFAULT NULL,
  created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- Table : produits
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS produits (
  id                INT AUTO_INCREMENT PRIMARY KEY,
  nom               VARCHAR(150) NOT NULL,
  categorie_id      INT NOT NULL,
  marque            VARCHAR(100) DEFAULT NULL,
  prix_achat        DECIMAL(12,2) NOT NULL DEFAULT 0,
  prix_vente        DECIMAL(12,2) NOT NULL DEFAULT 0,
  quantite_stock    INT NOT NULL DEFAULT 0,
  seuil_minimum     INT NOT NULL DEFAULT 5,
  image_url         VARCHAR(255) DEFAULT NULL,
  fournisseur_id    INT DEFAULT NULL,
  date_ajout        DATE NOT NULL DEFAULT (CURRENT_DATE),
  created_at        TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at        TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_produit_categorie
    FOREIGN KEY (categorie_id) REFERENCES categories(id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_produit_fournisseur
    FOREIGN KEY (fournisseur_id) REFERENCES fournisseurs(id)
    ON UPDATE CASCADE ON DELETE SET NULL,
  INDEX idx_produit_nom (nom),
  INDEX idx_produit_categorie (categorie_id)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- Table : mouvements_stock
-- Historique de TOUS les mouvements (entrées ET sorties).
-- type_mouvement = 'ENTREE' ou 'SORTIE'
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS mouvements_stock (
  id              INT AUTO_INCREMENT PRIMARY KEY,
  produit_id      INT NOT NULL,
  type_mouvement  ENUM('ENTREE','SORTIE') NOT NULL,
  quantite        INT NOT NULL,
  motif           VARCHAR(255) DEFAULT NULL,
  admin_id        INT DEFAULT NULL,
  date_mouvement  DATE NOT NULL DEFAULT (CURRENT_DATE),
  heure_mouvement TIME NOT NULL DEFAULT (CURRENT_TIME),
  created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_mouvement_produit
    FOREIGN KEY (produit_id) REFERENCES produits(id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_mouvement_admin
    FOREIGN KEY (admin_id) REFERENCES admins(id)
    ON UPDATE CASCADE ON DELETE SET NULL,
  INDEX idx_mouvement_type (type_mouvement),
  INDEX idx_mouvement_date (date_mouvement)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- Compte administrateur par défaut
-- Le mot de passe doit être haché avec bcrypt : ne JAMAIS insérer de
-- mot de passe en clair. Utilisez le script "npm run seed" (voir
-- backend/src/utils/seed.js) qui crée le compte défini par les
-- variables SEED_ADMIN_* du fichier .env avec un hash bcrypt valide.
-- ---------------------------------------------------------------------
