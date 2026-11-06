// =====================================================================
// Routes d'authentification : /api/auth/*
// =====================================================================
const express = require('express');
const router = express.Router();
const { body } = require('express-validator');
const authController = require('../controllers/auth.controller');
const authMiddleware = require('../middleware/auth.middleware');
const validate = require('../middleware/validate.middleware');

router.post(
  '/login',
  [
    body('email').isEmail().withMessage('Email invalide.'),
    body('mot_de_passe').notEmpty().withMessage('Le mot de passe est requis.'),
  ],
  validate,
  authController.login
);

router.get('/me', authMiddleware, authController.me);
router.post('/logout', authMiddleware, authController.logout);

module.exports = router;
