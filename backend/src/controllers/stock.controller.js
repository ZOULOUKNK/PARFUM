// =====================================================================
// Contrôleur de gestion des stocks : enregistre les entrées et sorties,
// met à jour automatiquement la quantité du produit concerné, et
// expose l'historique complet des sorties.
// Toutes les opérations critiques utilisent une transaction MySQL pour
// garantir la cohérence entre "mouvements_stock" et "produits".
// =====================================================================
const { pool } = require('../config/db');

// POST /api/stock/entree
async function enregistrerEntree(req, res, next) {
  // Obtenue dans le try : si MySQL est injoignable, l'erreur part vers
  // le gestionnaire d'erreurs au lieu de laisser la requête sans réponse.
  let connection;
  try {
    connection = await pool.getConnection();
    const { produit_id, quantite, motif } = req.body;

    if (!produit_id || !quantite || quantite <= 0) {
      return res.status(400).json({
        success: false,
        message: 'produit_id et une quantite positive sont requis.',
      });
    }

    await connection.beginTransaction();

    const [produits] = await connection.query(
      'SELECT * FROM produits WHERE id = ? FOR UPDATE',
      [produit_id]
    );
    if (produits.length === 0) {
      await connection.rollback();
      return res.status(404).json({ success: false, message: 'Produit introuvable.' });
    }

    await connection.query(
      'UPDATE produits SET quantite_stock = quantite_stock + ? WHERE id = ?',
      [quantite, produit_id]
    );

    await connection.query(
      `INSERT INTO mouvements_stock (produit_id, type_mouvement, quantite, motif, admin_id)
       VALUES (?, 'ENTREE', ?, ?, ?)`,
      [produit_id, quantite, motif || null, req.admin?.id || null]
    );

    await connection.commit();

    const [updatedProduct] = await pool.query('SELECT quantite_stock FROM produits WHERE id = ?', [produit_id]);

    return res.status(201).json({
      success: true,
      message: 'Entrée de stock enregistrée.',
      data: { nouvelle_quantite: updatedProduct[0].quantite_stock },
    });
  } catch (error) {
    if (connection) await connection.rollback().catch(() => {});
    next(error);
  } finally {
    if (connection) connection.release();
  }
}

// POST /api/stock/sortie
async function enregistrerSortie(req, res, next) {
  // Obtenue dans le try : si MySQL est injoignable, l'erreur part vers
  // le gestionnaire d'erreurs au lieu de laisser la requête sans réponse.
  let connection;
  try {
    connection = await pool.getConnection();
    const { produit_id, quantite, motif } = req.body;

    if (!produit_id || !quantite || quantite <= 0) {
      return res.status(400).json({
        success: false,
        message: 'produit_id et une quantite positive sont requis.',
      });
    }

    await connection.beginTransaction();

    const [produits] = await connection.query(
      'SELECT * FROM produits WHERE id = ? FOR UPDATE',
      [produit_id]
    );
    if (produits.length === 0) {
      await connection.rollback();
      return res.status(404).json({ success: false, message: 'Produit introuvable.' });
    }

    const produit = produits[0];
    if (produit.quantite_stock < quantite) {
      await connection.rollback();
      return res.status(400).json({
        success: false,
        message: `Stock insuffisant. Quantité disponible : ${produit.quantite_stock}.`,
      });
    }

    await connection.query(
      'UPDATE produits SET quantite_stock = quantite_stock - ? WHERE id = ?',
      [quantite, produit_id]
    );

    await connection.query(
      `INSERT INTO mouvements_stock (produit_id, type_mouvement, quantite, motif, admin_id)
       VALUES (?, 'SORTIE', ?, ?, ?)`,
      [produit_id, quantite, motif || null, req.admin?.id || null]
    );

    await connection.commit();

    const [updatedProduct] = await pool.query('SELECT quantite_stock FROM produits WHERE id = ?', [produit_id]);
    const alerteStockFaible = updatedProduct[0].quantite_stock <= produit.seuil_minimum;

    return res.status(201).json({
      success: true,
      message: 'Sortie de stock enregistrée.',
      data: {
        nouvelle_quantite: updatedProduct[0].quantite_stock,
        alerte_stock_faible: alerteStockFaible,
      },
    });
  } catch (error) {
    if (connection) await connection.rollback().catch(() => {});
    next(error);
  } finally {
    if (connection) connection.release();
  }
}

// GET /api/stock/alertes  -> produits en stock faible
async function getAlertes(req, res, next) {
  try {
    const [rows] = await pool.query(
      `SELECT p.id, p.nom, p.quantite_stock, p.seuil_minimum, c.nom AS categorie
       FROM produits p
       JOIN categories c ON c.id = p.categorie_id
       WHERE p.quantite_stock <= p.seuil_minimum
       ORDER BY p.quantite_stock ASC`
    );
    return res.json({ success: true, data: rows });
  } catch (error) {
    next(error);
  }
}

// GET /api/stock/historique-sorties
// Historique complet des sorties : nom produit, catégorie, quantité, date, heure
async function getHistoriqueSorties(req, res, next) {
  try {
    const { date_debut, date_fin, produit_id } = req.query;
    const conditions = [`m.type_mouvement = 'SORTIE'`];
    const params = [];

    if (date_debut) {
      conditions.push('m.date_mouvement >= ?');
      params.push(date_debut);
    }
    if (date_fin) {
      conditions.push('m.date_mouvement <= ?');
      params.push(date_fin);
    }
    if (produit_id) {
      conditions.push('m.produit_id = ?');
      params.push(produit_id);
    }

    const [rows] = await pool.query(
      `SELECT m.id, p.nom AS produit_nom, c.nom AS categorie, m.quantite,
              m.date_mouvement AS date, m.heure_mouvement AS heure, m.motif
       FROM mouvements_stock m
       JOIN produits p ON p.id = m.produit_id
       JOIN categories c ON c.id = p.categorie_id
       WHERE ${conditions.join(' AND ')}
       ORDER BY m.date_mouvement DESC, m.heure_mouvement DESC`,
      params
    );

    return res.json({ success: true, data: rows });
  } catch (error) {
    next(error);
  }
}

module.exports = { enregistrerEntree, enregistrerSortie, getAlertes, getHistoriqueSorties };
