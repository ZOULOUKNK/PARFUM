// =====================================================================
// Point d'entrée unique pour toutes les routes de l'API.
// Monté sur /api dans server.js.
// =====================================================================
const express = require('express');
const router = express.Router();

router.use('/auth', require('./auth.routes'));
router.use('/dashboard', require('./dashboard.routes'));
router.use('/products', require('./product.routes'));
router.use('/stock', require('./stock.routes'));
router.use('/suppliers', require('./supplier.routes'));
router.use('/categories', require('./category.routes'));

module.exports = router;
