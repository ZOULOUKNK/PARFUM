// =====================================================================
// Routes des catégories : /api/categories
// =====================================================================
const express = require('express');
const router = express.Router();
const categoryController = require('../controllers/category.controller');
const authMiddleware = require('../middleware/auth.middleware');

router.get('/', authMiddleware, categoryController.getAll);

module.exports = router;
