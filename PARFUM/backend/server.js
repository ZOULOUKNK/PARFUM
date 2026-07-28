// =====================================================================
// StockParfum - Serveur API REST (Node.js + Express)
// =====================================================================
require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const path = require('path');
const rateLimit = require('express-rate-limit');

const apiRoutes = require('./src/routes');
const { errorHandler, notFoundHandler } = require('./src/middleware/error.middleware');
const { testConnection } = require('./src/config/db');

const app = express();
const PORT = process.env.PORT || 3000;

// ---------------------------------------------------------------------
// Sécurité & middlewares globaux
// ---------------------------------------------------------------------
app.use(helmet());               // en-têtes HTTP sécurisés
app.use(cors());                 // autorise les requêtes cross-origin (app mobile)
app.use(express.json());         // parsing du JSON
app.use(express.urlencoded({ extended: true }));
app.use(morgan(process.env.NODE_ENV === 'production' ? 'combined' : 'dev'));

// Limite le nombre de requêtes par IP pour se prémunir des attaques par force brute
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 300,
  standardHeaders: true,
  legacyHeaders: false,
  message: { success: false, message: 'Trop de requêtes. Veuillez réessayer plus tard.' },
});
app.use('/api', limiter);

// Limite plus stricte spécifiquement sur la connexion (anti brute-force)
const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 10,
  message: { success: false, message: 'Trop de tentatives de connexion. Réessayez plus tard.' },
});
app.use('/api/auth/login', loginLimiter);

// Sert les images de produits de manière statique
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// ---------------------------------------------------------------------
// Routes
// ---------------------------------------------------------------------
app.get('/', (req, res) => {
  res.json({ success: true, message: 'API StockParfum opérationnelle 🚀' });
});

app.use('/api', apiRoutes);

// ---------------------------------------------------------------------
// Gestion des erreurs (toujours en dernier)
// ---------------------------------------------------------------------
app.use(notFoundHandler);
app.use(errorHandler);

// ---------------------------------------------------------------------
// Démarrage du serveur
// ---------------------------------------------------------------------
async function start() {
  try {
    await testConnection();
    app.listen(PORT, () => {
      console.log(`🚀 Serveur StockParfum démarré sur http://localhost:${PORT}`);
    });
  } catch (error) {
    console.error('❌ Impossible de démarrer le serveur :', error.message);
    process.exit(1);
  }
}

start();
