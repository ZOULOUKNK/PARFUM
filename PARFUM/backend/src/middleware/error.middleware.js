// =====================================================================
// Middleware global de gestion des erreurs.
// Toute erreur non interceptée dans les contrôleurs (via next(err))
// atterrit ici et renvoie une réponse JSON homogène au frontend.
// =====================================================================
function errorHandler(err, req, res, next) {
  console.error('❌ Erreur:', err.message);

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

  const statusCode = err.statusCode || 500;
  return res.status(statusCode).json({
    success: false,
    message: err.message || 'Erreur interne du serveur.',
  });
}

// Middleware pour les routes non trouvées (404)
function notFoundHandler(req, res) {
  res.status(404).json({ success: false, message: 'Ressource non trouvée.' });
}

module.exports = { errorHandler, notFoundHandler };
