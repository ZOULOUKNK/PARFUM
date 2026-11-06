// =====================================================================
// Middleware générique qui vérifie le résultat des règles de
// validation express-validator déclarées dans chaque route.
// =====================================================================
const { validationResult } = require('express-validator');
const { discardUpload } = require('./upload.middleware');

function validate(req, res, next) {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    discardUpload(req); // image envoyée avec un formulaire refusé
    return res.status(400).json({
      success: false,
      message: 'Données invalides.',
      errors: errors.array().map((e) => ({ champ: e.path, message: e.msg })),
    });
  }
  next();
}

module.exports = validate;
