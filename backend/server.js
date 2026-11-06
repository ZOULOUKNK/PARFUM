// =====================================================================
// StockParfum - Démarrage du serveur API REST (Node.js + Express)
// =====================================================================
require('dotenv').config();
const app = require('./app');
const { testConnection } = require('./src/config/db');
const { validateEnv } = require('./src/config/env');

const PORT = process.env.PORT || 3000;

// ---------------------------------------------------------------------
// Démarrage du serveur
// ---------------------------------------------------------------------
async function start() {
  try {
    validateEnv();
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
