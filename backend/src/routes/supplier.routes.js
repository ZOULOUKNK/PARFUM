// =====================================================================
// Routes des fournisseurs : /api/suppliers/*
// =====================================================================
const express = require('express');
const router = express.Router();
const { body, param } = require('express-validator');
const supplierController = require('../controllers/supplier.controller');
const authMiddleware = require('../middleware/auth.middleware');
const validate = require('../middleware/validate.middleware');

router.use(authMiddleware);

router.get('/', supplierController.getAll);
router.get('/:id', param('id').isInt(), validate, supplierController.getById);

router.post(
  '/',
  [
    body('nom').notEmpty().withMessage('Le nom du fournisseur est requis.'),
    body('telephone').notEmpty().withMessage('Le téléphone est requis.'),
  ],
  validate,
  supplierController.create
);

router.put('/:id', param('id').isInt(), validate, supplierController.update);
router.delete('/:id', param('id').isInt(), validate, supplierController.remove);

module.exports = router;
