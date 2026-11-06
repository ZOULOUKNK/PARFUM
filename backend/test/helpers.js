// =====================================================================
// Outils de test : base MySQL simulée et chargement de l'application.
// Aucun test ne se connecte à un vrai serveur MySQL.
// =====================================================================
const path = require('path');
const fs = require('fs');
const os = require('os');
const jwt = require('jsonwebtoken');

const uploadDir = fs.mkdtempSync(path.join(os.tmpdir(), 'stockparfum-test-'));
process.env.UPLOAD_DIR = uploadDir;
process.env.JWT_SECRET = 'secret-de-test-suffisamment-long-pour-les-tests';
process.env.NODE_ENV = 'test';

// handler(sql, params) renvoie le résultat [rows] ou lève une erreur.
let handler = () => [[]];
const calls = [];

const fakeConnection = {
  query: async (sql, params) => { calls.push({ sql, params }); return handler(sql, params); },
  beginTransaction: async () => calls.push({ sql: 'BEGIN' }),
  commit: async () => calls.push({ sql: 'COMMIT' }),
  rollback: async () => calls.push({ sql: 'ROLLBACK' }),
  release: () => {},
};

const fakePool = {
  query: fakeConnection.query,
  getConnection: async () => {
    if (fakePool.failConnection) {
      throw Object.assign(new Error('connect ECONNREFUSED 127.0.0.1:3306'), { code: 'ECONNREFUSED' });
    }
    return fakeConnection;
  },
  failConnection: false,
};

const dbPath = require.resolve('../src/config/db');
require.cache[dbPath] = {
  id: dbPath, filename: dbPath, loaded: true,
  exports: { pool: fakePool, testConnection: async () => {} },
};

const app = require('../app');

function onQuery(fn) {
  handler = fn;
  calls.length = 0;
  fakePool.failConnection = false;
}

function token() {
  return jwt.sign({ id: 1, email: 'admin@test.mg', nom: 'Admin' }, process.env.JWT_SECRET);
}

module.exports = { app, onQuery, calls, fakePool, token, uploadDir };
