// =====================================================================
// Configuration du pool de connexions MySQL.
// Un pool est utilisé (plutôt qu'une connexion unique) pour supporter
// plusieurs requêtes simultanées sans bloquer l'application.
// =====================================================================
const mysql = require('mysql2/promise');
require('dotenv').config();

const pool = mysql.createPool({
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 3306,
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME || 'stockparfum',
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
  dateStrings: true, // renvoie les DATE/TIME MySQL sous forme de chaînes simples
});

// Vérifie la connexion au démarrage du serveur (voir server.js)
async function testConnection() {
  const connection = await pool.getConnection();
  try {
    await connection.ping();
    console.log('✅ Connexion à la base de données MySQL établie.');
  } finally {
    connection.release();
  }
}

module.exports = { pool, testConnection };
