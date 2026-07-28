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

router.get('/', productController.getAll);
router.get('/:id', param('id').isInt(), validate, productController.getById);

router.post(
  '/',
  upload.single('image'),
  [
    body('nom').notEmpty().withMessage('Le nom du produit est requis.'),
    body('categorie_id').isInt().withMessage('La catégorie est requise.'),
    body('prix_vente').isFloat({ min: 0 }).withMessage('Le prix de vente doit être un nombre positif.'),
  ],
  validate,
  productController.create
);

router.put(
  '/:id',
  upload.single('image'),
  [param('id').isInt()],
  validate,
  productController.update
);

router.delete('/:id', param('id').isInt(), validate, productController.remove);

module.exports = router;
