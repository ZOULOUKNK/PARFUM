// =====================================================================
// Contrôleur d'authentification.
// La "déconnexion" est gérée côté client (suppression du token stocké)
// car l'API utilise des JWT sans état (stateless) : il n'y a rien à
// invalider côté serveur pour une architecture simple sans blacklist.
// =====================================================================
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { pool } = require('../config/db');

// POST /api/auth/login
async function login(req, res, next) {
  try {
    const { email, mot_de_passe } = req.body;

    if (!email || !mot_de_passe) {
      return res.status(400).json({
        success: false,
        message: 'Email et mot de passe sont requis.',
      });
    }

    const [rows] = await pool.query('SELECT * FROM admins WHERE email = ?', [email]);

    if (rows.length === 0) {
      return res.status(401).json({ success: false, message: 'Identifiants incorrects.' });
    }

    const admin = rows[0];
    const isPasswordValid = await bcrypt.compare(mot_de_passe, admin.mot_de_passe);

    if (!isPasswordValid) {
      return res.status(401).json({ success: false, message: 'Identifiants incorrects.' });
    }

    const token = jwt.sign(
      { id: admin.id, email: admin.email, nom: admin.nom },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN || '1d' }
    );

    return res.json({
      success: true,
      message: 'Connexion réussie.',
      data: {
        token,
        admin: { id: admin.id, nom: admin.nom, email: admin.email },
      },
    });
  } catch (error) {
    next(error);
  }
}

// GET /api/auth/me  (route protégée : renvoie le profil de l'admin connecté)
async function me(req, res, next) {
  try {
    const [rows] = await pool.query(
      'SELECT id, nom, email, created_at FROM admins WHERE id = ?',
      [req.admin.id]
    );
    if (rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Administrateur introuvable.' });
    }
    return res.json({ success: true, data: rows[0] });
  } catch (error) {
    next(error);
  }
}

// POST /api/auth/logout
// Stateless : on confirme simplement au client qu'il peut supprimer
// son token local. Prévu en base pour une future blacklist si besoin.
async function logout(req, res) {
  return res.json({ success: true, message: 'Déconnexion réussie.' });
}

module.exports = { login, me, logout };
