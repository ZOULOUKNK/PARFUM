// =====================================================================
// Routes des produits : /api/products/*
// =====================================================================
const express = require('express');
const router = express.Router();
const { body, param } = require('express-validator');
const productController = require('../controllers/product.controller');
const authMiddleware = require('../middleware/auth.middleware');
const validate = require('../middleware/validate.middleware');
const upload = require('../middleware/upload.middleware');

router.use(authMiddleware); // toutes les routes produits nécessitent une authentification

// Champs facultatifs : refusés s'ils sont négatifs (vides acceptés)
const nombresPositifs = [
  body('quantite_stock').optional({ values: 'falsy' }).isInt({ min: 0 }).withMessage('La quantité doit être un entier positif ou nul.'),
  body('seuil_minimum').optional({ values: 'falsy' }).isInt({ min: 0 }).withMessage('Le seuil minimum doit être un entier positif ou nul.'),
  body('prix_achat').optional({ values: 'falsy' }).isFloat({ min: 0 }).withMessage("Le prix d'achat doit être un nombre positif."),
];

router.get('/', productController.getAll);
router.get('/:id', param('id').isInt(), validate, productController.getById);

router.post(
  '/',
  upload.single('image'),
  [
    body('nom').notEmpty().withMessage('Le nom du produit est requis.'),
    body('categorie_id').isInt().withMessage('La catégorie est requise.'),
    body('prix_vente').isFloat({ min: 0 }).withMessage('Le prix de vente doit être un nombre positif.'),
    ...nombresPositifs,
  ],
  validate,
  productController.create
);

router.put(
  '/:id',
  upload.single('image'),
  [
    param('id').isInt(),
    body('prix_vente').optional({ values: 'falsy' }).isFloat({ min: 0 }).withMessage('Le prix de vente doit être un nombre positif.'),
    ...nombresPositifs,
  ],
  validate,
  productController.update
);

router.delete('/:id', param('id').isInt(), validate, productController.remove);

module.exports = router;
