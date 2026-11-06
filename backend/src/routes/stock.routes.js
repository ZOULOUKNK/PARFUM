// =====================================================================
// Routes des mouvements de stock : /api/stock/*
// =====================================================================
const express = require('express');
const router = express.Router();
const { body } = require('express-validator');
const stockController = require('../controllers/stock.controller');
const authMiddleware = require('../middleware/auth.middleware');
const validate = require('../middleware/validate.middleware');

router.use(authMiddleware);

const mouvementRules = [
  body('produit_id').isInt().withMessage('produit_id est requis.'),
  body('quantite').isInt({ min: 1 }).withMessage('La quantité doit être un entier positif.'),
];

router.post('/entree', mouvementRules, validate, stockController.enregistrerEntree);
router.post('/sortie', mouvementRules, validate, stockController.enregistrerSortie);
router.get('/alertes', stockController.getAlertes);
router.get('/historique-sorties', stockController.getHistoriqueSorties);

module.exports = router;
