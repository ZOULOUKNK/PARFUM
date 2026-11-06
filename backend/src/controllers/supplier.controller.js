// =====================================================================
// Contrôleur de gestion des fournisseurs.
// =====================================================================
const { pool } = require('../config/db');

// GET /api/suppliers?search=
async function getAll(req, res, next) {
  try {
    const { search } = req.query;
    let query = 'SELECT * FROM fournisseurs';
    const params = [];

    if (search) {
      query += ' WHERE nom LIKE ? OR telephone LIKE ? OR adresse LIKE ?';
      params.push(`%${search}%`, `%${search}%`, `%${search}%`);
    }
    query += ' ORDER BY nom ASC';

    const [rows] = await pool.query(query, params);
    return res.json({ success: true, data: rows });
  } catch (error) {
    next(error);
  }
}

// GET /api/suppliers/:id
async function getById(req, res, next) {
  try {
    const [rows] = await pool.query('SELECT * FROM fournisseurs WHERE id = ?', [req.params.id]);
    if (rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Fournisseur introuvable.' });
    }
    return res.json({ success: true, data: rows[0] });
  } catch (error) {
    next(error);
  }
}

// POST /api/suppliers
async function create(req, res, next) {
  try {
    const { nom, telephone, adresse } = req.body;
    if (!nom || !telephone) {
      return res.status(400).json({
        success: false,
        message: 'Les champs nom et telephone sont obligatoires.',
      });
    }

    const [result] = await pool.query(
      'INSERT INTO fournisseurs (nom, telephone, adresse) VALUES (?, ?, ?)',
      [nom, telephone, adresse || null]
    );

    const [rows] = await pool.query('SELECT * FROM fournisseurs WHERE id = ?', [result.insertId]);
    return res.status(201).json({
      success: true,
      message: 'Fournisseur ajouté avec succès.',
      data: rows[0],
    });
  } catch (error) {
    next(error);
  }
}

// PUT /api/suppliers/:id
async function update(req, res, next) {
  try {
    const { id } = req.params;
    const [existingRows] = await pool.query('SELECT * FROM fournisseurs WHERE id = ?', [id]);
    if (existingRows.length === 0) {
      return res.status(404).json({ success: false, message: 'Fournisseur introuvable.' });
    }
    const existing = existingRows[0];
    const { nom, telephone, adresse } = req.body;

    await pool.query(
      'UPDATE fournisseurs SET nom = ?, telephone = ?, adresse = ? WHERE id = ?',
      [nom ?? existing.nom, telephone ?? existing.telephone, adresse ?? existing.adresse, id]
    );

    const [rows] = await pool.query('SELECT * FROM fournisseurs WHERE id = ?', [id]);
    return res.json({ success: true, message: 'Fournisseur mis à jour.', data: rows[0] });
  } catch (error) {
    next(error);
  }
}

// DELETE /api/suppliers/:id
async function remove(req, res, next) {
  try {
    const [result] = await pool.query('DELETE FROM fournisseurs WHERE id = ?', [req.params.id]);
    if (result.affectedRows === 0) {
      return res.status(404).json({ success: false, message: 'Fournisseur introuvable.' });
    }
    return res.json({ success: true, message: 'Fournisseur supprimé.' });
  } catch (error) {
    next(error);
  }
}

module.exports = { getAll, getById, create, update, remove };
