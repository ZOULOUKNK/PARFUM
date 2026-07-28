// =====================================================================
// Script de "seed" : crée le compte administrateur par défaut avec un
// mot de passe correctement haché en bcrypt.
// Exécution : npm run seed
// =====================================================================
require('dotenv').config();
const bcrypt = require('bcryptjs');
const { pool } = require('../config/db');

async function seed() {
  const nom = process.env.SEED_ADMIN_NAME || 'Administrateur';
  const email = process.env.SEED_ADMIN_EMAIL || 'admin@stockparfum.mg';
  const motDePasse = process.env.SEED_ADMIN_PASSWORD || 'Admin@123';

  try {
    const [existing] = await pool.query('SELECT id FROM admins WHERE email = ?', [email]);

    if (existing.length > 0) {
      console.log(`ℹ️  Un administrateur avec l'email "${email}" existe déjà. Aucune action effectuée.`);
      process.exit(0);
    }

    const hash = await bcrypt.hash(motDePasse, 10);
    await pool.query(
      'INSERT INTO admins (nom, email, mot_de_passe) VALUES (?, ?, ?)',
      [nom, email, hash]
    );

    console.log('✅ Compte administrateur créé avec succès :');
    console.log(`   Email        : ${email}`);
    console.log(`   Mot de passe : ${motDePasse}`);
    console.log('   ⚠️  Pensez à changer ce mot de passe en production.');
    process.exit(0);
  } catch (error) {
    console.error('❌ Échec de la création de l\'administrateur :', error.message);
    process.exit(1);
  }
}

seed();
