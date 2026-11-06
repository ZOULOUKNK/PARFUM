const { test } = require('node:test');
const assert = require('node:assert/strict');
const { validateEnv } = require('../src/config/env');

test('refuse de démarrer sans JWT_SECRET', () => {
  assert.throws(() => validateEnv({}), /JWT_SECRET est vide/);
});

test('refuse un JWT_SECRET trop court', () => {
  assert.throws(() => validateEnv({ JWT_SECRET: 'secret' }), /au moins 32/);
});

test('accepte un JWT_SECRET suffisamment long', () => {
  assert.doesNotThrow(() => validateEnv({ JWT_SECRET: 'x'.repeat(48) }));
});
