// =====================================================================
// Routes du tableau de bord : /api/dashboard
// =====================================================================
const express = require('express');
const router = express.Router();
const dashboardController = require('../controllers/dashboard.controller');
const authMiddleware = require('../middleware/auth.middleware');

router.get('/', authMiddleware, dashboardController.getStats);

module.exports = router;
