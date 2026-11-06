// =====================================================================
// Contrôleur de gestion des produits : création, lecture, mise à jour,
// suppression, recherche et association d'une image.
// =====================================================================
const { pool } = require('../config/db');
const { publicUrl, deleteImage, discardUpload } = require('../middleware/upload.middleware');

const BASE_SELECT = `
  SELECT p.id, p.nom, p.categorie_id, c.nom AS categorie, p.marque,
         p.prix_achat, p.prix_vente, p.quantite_stock, p.seuil_minimum,
         p.image_url, p.fournisseur_id, f.nom AS fournisseur_nom,
         p.date_ajout, p.created_at, p.updated_at
  FROM produits p
  JOIN categories c ON c.id = p.categorie_id
  LEFT JOIN fournisseurs f ON f.id = p.fournisseur_id
`;

// GET /api/products?search=&categorie_id=
async function getAll(req, res, next) {
  try {
    const { search, categorie_id } = req.query;
    const conditions = [];
    const params = [];

    if (search) {
      conditions.push('(p.nom LIKE ? OR p.marque LIKE ?)');
      params.push(`%${search}%`, `%${search}%`);
    }
    if (categorie_id) {
      conditions.push('p.categorie_id = ?');
      params.push(categorie_id);
    }

    const whereClause = conditions.length ? `WHERE ${conditions.join(' AND ')}` : '';
    const [rows] = await pool.query(
      `${BASE_SELECT} ${whereClause} ORDER BY p.created_at DESC`,
      params
    );

    return res.json({ success: true, data: rows });
  } catch (error) {
    next(error);
  }
}

// GET /api/products/:id
async function getById(req, res, next) {
  try {
    const [rows] = await pool.query(`${BASE_SELECT} WHERE p.id = ?`, [req.params.id]);
    if (rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Produit introuvable.' });
    }
    return res.json({ success: true, data: rows[0] });
  } catch (error) {
    next(error);
  }
}

// Enregistre un mouvement de stock dans la transaction en cours, pour que
// l'historique explique toujours la quantité affichée.
async function recordMovement(connection, produitId, difference, motif, adminId) {
  if (!difference) return;
  await connection.query(
    `INSERT INTO mouvements_stock (produit_id, type_mouvement, quantite, motif, admin_id)
     VALUES (?, '${difference > 0 ? 'ENTREE' : 'SORTIE'}', ?, ?, ?)`,
    [produitId, Math.abs(difference), motif, adminId || null]
  );
}

// POST /api/products
async function create(req, res, next) {
  let connection;
  try {
    const {
      nom, categorie_id, marque, prix_achat, prix_vente,
      quantite_stock, seuil_minimum, fournisseur_id, date_ajout,
    } = req.body;

    if (!nom || !categorie_id || prix_vente === undefined) {
      discardUpload(req);
      return res.status(400).json({
        success: false,
        message: 'Les champs nom, categorie_id et prix_vente sont obligatoires.',
      });
    }

    // Chemin relatif de l'image si un fichier a été envoyé (voir upload.middleware)
    const imageUrl = req.file ? publicUrl(req.file.filename) : null;
    const quantiteInitiale = Number(quantite_stock) || 0;

    connection = await pool.getConnection();
    await connection.beginTransaction();

    const [result] = await connection.query(
      `INSERT INTO produits
        (nom, categorie_id, marque, prix_achat, prix_vente, quantite_stock,
         seuil_minimum, image_url, fournisseur_id, date_ajout)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        nom,
        categorie_id,
        marque || null,
        prix_achat || 0,
        prix_vente,
        quantiteInitiale,
        seuil_minimum || 5,
        imageUrl,
        fournisseur_id || null,
        date_ajout || new Date().toISOString().slice(0, 10),
      ]
    );

    await recordMovement(connection, result.insertId, quantiteInitiale, 'Stock initial', req.admin?.id);
    await connection.commit();

    const [rows] = await pool.query(`${BASE_SELECT} WHERE p.id = ?`, [result.insertId]);
    return res.status(201).json({
      success: true,
      message: 'Produit ajouté avec succès.',
      data: rows[0],
    });
  } catch (error) {
    if (connection) await connection.rollback().catch(() => {});
    next(error);
  } finally {
    if (connection) connection.release();
  }
}

// PUT /api/products/:id
// La quantité reste modifiable depuis la fiche produit, mais tout écart est
// enregistré comme mouvement d'ajustement : sinon l'historique ne
// correspondait plus au stock.
async function update(req, res, next) {
  let connection;
  try {
    const { id } = req.params;

    connection = await pool.getConnection();
    await connection.beginTransaction();

    const [existingRows] = await connection.query('SELECT * FROM produits WHERE id = ? FOR UPDATE', [id]);
    if (existingRows.length === 0) {
      await connection.rollback();
      discardUpload(req);
      return res.status(404).json({ success: false, message: 'Produit introuvable.' });
    }
    const existing = existingRows[0];

    const {
      nom, categorie_id, marque, prix_achat, prix_vente,
      quantite_stock, seuil_minimum, fournisseur_id, date_ajout,
    } = req.body;

    // Nouvelle image uniquement si le client en envoie une, sinon on garde l'ancienne
    const imageUrl = req.file ? publicUrl(req.file.filename) : existing.image_url;
    const nouvelleQuantite = quantite_stock === undefined || quantite_stock === ''
      ? Number(existing.quantite_stock)
      : Number(quantite_stock);

    await connection.query(
      `UPDATE produits SET
        nom = ?, categorie_id = ?, marque = ?, prix_achat = ?, prix_vente = ?,
        quantite_stock = ?, seuil_minimum = ?, image_url = ?, fournisseur_id = ?, date_ajout = ?
       WHERE id = ?`,
      [
        nom ?? existing.nom,
        categorie_id ?? existing.categorie_id,
        marque ?? existing.marque,
        prix_achat ?? existing.prix_achat,
        prix_vente ?? existing.prix_vente,
        nouvelleQuantite,
        seuil_minimum ?? existing.seuil_minimum,
        imageUrl,
        fournisseur_id ?? existing.fournisseur_id,
        date_ajout ?? existing.date_ajout,
        id,
      ]
    );

    await recordMovement(
      connection,
      Number(id),
      nouvelleQuantite - Number(existing.quantite_stock),
      'Ajustement manuel (modification de la fiche produit)',
      req.admin?.id
    );
    await connection.commit();

    // L'ancienne image, remplacée, n'est plus référencée : on la supprime.
    if (req.file && existing.image_url) deleteImage(existing.image_url);

    const [rows] = await pool.query(`${BASE_SELECT} WHERE p.id = ?`, [id]);
    return res.json({ success: true, message: 'Produit mis à jour.', data: rows[0] });
  } catch (error) {
    if (connection) await connection.rollback().catch(() => {});
    next(error);
  } finally {
    if (connection) connection.release();
  }
}

// DELETE /api/products/:id
async function remove(req, res, next) {
  try {
    const [rows] = await pool.query('SELECT image_url FROM produits WHERE id = ?', [req.params.id]);
    if (rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Produit introuvable.' });
    }

    await pool.query('DELETE FROM produits WHERE id = ?', [req.params.id]);
    deleteImage(rows[0].image_url); // après la suppression : si elle échoue, l'image reste

    return res.json({ success: true, message: 'Produit supprimé.' });
  } catch (error) {
    next(error);
  }
}

module.exports = { getAll, getById, create, update, remove };
