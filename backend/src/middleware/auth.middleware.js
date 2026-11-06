// =====================================================================
// Middleware d'authentification : vérifie le token JWT envoyé dans
// l'en-tête "Authorization: Bearer <token>" et protège les routes.
// =====================================================================
const jwt = require('jsonwebtoken');

function authMiddleware(req, res, next) {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({
      success: false,
      message: 'Accès refusé : token d\'authentification manquant.',
    });
  }

  const token = authHeader.split(' ')[1];

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    // On attache les infos de l'admin décodées à la requête
    req.admin = { id: decoded.id, email: decoded.email, nom: decoded.nom };
    next();
  } catch (error) {
    return res.status(401).json({
      success: false,
      message: 'Token invalide ou expiré. Veuillez vous reconnecter.',
    });
  }
}

module.exports = authMiddleware;
