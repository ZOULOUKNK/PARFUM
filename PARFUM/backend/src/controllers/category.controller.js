// =====================================================================
// Contrôleur des catégories. Les catégories sont fixes (créées par le
// script SQL) mais exposées via l'API pour peupler les listes
// déroulantes du frontend Flutter.
// =====================================================================
const { pool } = require('../config/db');

// GET /api/categories
async function getAll(req, res, next) {
  try {
    const [rows] = await pool.query('SELECT * FROM categories ORDER BY id ASC');
    return res.json({ success: true, data: rows });
  } catch (error) {
    next(error);
  }
}

module.exports = { getAll };
