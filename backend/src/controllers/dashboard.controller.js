// =====================================================================
// Contrôleur du tableau de bord : agrège les statistiques globales
// affichées sur l'écran d'accueil de l'application.
// =====================================================================
const { pool } = require('../config/db');

// GET /api/dashboard
async function getStats(req, res, next) {
  try {
    const [[{ total_produits }]] = await pool.query(
      'SELECT COUNT(*) AS total_produits FROM produits'
    );

    const [[{ total_stock }]] = await pool.query(
      'SELECT COALESCE(SUM(quantite_stock), 0) AS total_stock FROM produits'
    );

    const [[{ stock_faible }]] = await pool.query(
      'SELECT COUNT(*) AS stock_faible FROM produits WHERE quantite_stock <= seuil_minimum'
    );

    const [derniersProduits] = await pool.query(
      `SELECT p.id, p.nom, p.marque, p.prix_vente, p.quantite_stock, p.image_url,
              p.date_ajout, c.nom AS categorie
       FROM produits p
       JOIN categories c ON c.id = p.categorie_id
       ORDER BY p.created_at DESC
       LIMIT 5`
    );

    return res.json({
      success: true,
      data: {
        total_produits,
        total_stock,
        stock_faible,
        derniers_produits: derniersProduits,
      },
    });
  } catch (error) {
    next(error);
  }
}

module.exports = { getStats };
