// =====================================================================
// Middleware global de gestion des erreurs.
// Toute erreur non interceptée dans les contrôleurs (via next(err))
// atterrit ici et renvoie une réponse JSON homogène au frontend.
// =====================================================================
const { discardUpload } = require('./upload.middleware');

// Codes d'erreur signalant une base MySQL injoignable ou mal configurée
const DB_UNAVAILABLE = ['ECONNREFUSED', 'ETIMEDOUT', 'PROTOCOL_CONNECTION_LOST', 'ER_ACCESS_DENIED_ERROR', 'ER_BAD_DB_ERROR'];

function errorHandler(err, req, res, next) {
  console.error('❌ Erreur:', err.message);

  // Une requête refusée ne doit pas laisser d'image orpheline sur le disque
  discardUpload(req);

  if (DB_UNAVAILABLE.includes(err.code)) {
    return res.status(503).json({
      success: false,
      message: 'Base de données indisponible. Réessayez dans quelques instants.',
    });
  }

  // Erreur MySQL : entrée dupliquée (ex : email déjà utilisé)
  if (err.code === 'ER_DUP_ENTRY') {
    return res.status(409).json({
      success: false,
      message: 'Cette valeur existe déjà (doublon détecté).',
    });
  }

  // Erreur MySQL : contrainte de clé étrangère
  if (err.code === 'ER_ROW_IS_REFERENCED_2' || err.code === 'ER_NO_REFERENCED_ROW_2') {
    return res.status(409).json({
      success: false,
      message: 'Opération impossible : cet élément est lié à d\'autres données.',
    });
  }

  // Erreur d'upload (fichier trop volumineux, format invalide, etc.)
  if (err.name === 'MulterError') {
    return res.status(400).json({ success: false, message: `Erreur d'upload : ${err.message}` });
  }

  // Erreurs prévues (4xx) : message destiné à l'utilisateur. Erreurs
  // imprévues (500) : message générique, le détail (SQL, chemins…) reste
  // dans les journaux du serveur.
  const statusCode = err.statusCode || 500;
  return res.status(statusCode).json({
    success: false,
    message: statusCode < 500 ? err.message : 'Erreur interne du serveur.',
  });
}

// Middleware pour les routes non trouvées (404)
function notFoundHandler(req, res) {
  res.status(404).json({ success: false, message: 'Ressource non trouvée.' });
}

module.exports = { errorHandler, notFoundHandler };
