const { test, describe } = require('node:test');
const assert = require('node:assert/strict');
const path = require('path');
const fs = require('fs');
const bcrypt = require('bcryptjs');
const request = require('supertest');
const { app, onQuery, calls, fakePool, token, uploadDir } = require('./helpers');

const auth = () => ({ Authorization: `Bearer ${token()}` });

describe('Authentification', () => {
  test('refuse une route protégée sans jeton', async () => {
    const res = await request(app).get('/api/products');
    assert.equal(res.status, 401);
  });

  test('connecte un administrateur avec le bon mot de passe', async () => {
    const hash = await bcrypt.hash('Secret@123', 4);
    onQuery(() => [[{ id: 1, nom: 'Admin', email: 'admin@test.mg', mot_de_passe: hash }]]);

    const ok = await request(app).post('/api/auth/login').send({ email: 'admin@test.mg', mot_de_passe: 'Secret@123' });
    assert.equal(ok.status, 200);
    assert.ok(ok.body.data.token);
    assert.equal(ok.body.data.admin.mot_de_passe, undefined);

    const ko = await request(app).post('/api/auth/login').send({ email: 'admin@test.mg', mot_de_passe: 'faux' });
    assert.equal(ko.status, 401);
  });
});

describe('Erreurs', () => {
  test("ne divulgue pas le détail d'une erreur SQL", async () => {
    onQuery(() => { throw new Error("Unknown column 'colonne_secrete' in 'field list'"); });

    const res = await request(app).get('/api/products').set(auth());
    assert.equal(res.status, 500);
    assert.doesNotMatch(JSON.stringify(res.body), /colonne_secrete/);
  });

  test("répond 503 au lieu de rester bloqué si MySQL est injoignable", async () => {
    onQuery(() => [[]]);
    fakePool.failConnection = true;

    const res = await request(app).post('/api/stock/entree').set(auth())
      .send({ produit_id: 1, quantite: 3 }).timeout(2000);
    assert.equal(res.status, 503);
  });

  test("refuse un fichier qui n'est pas une image avec un 400", async () => {
    onQuery(() => [[]]);
    const res = await request(app).post('/api/products').set(auth())
      .field('nom', 'Parfum').field('categorie_id', '1').field('prix_vente', '10')
      .attach('image', Buffer.from('MZ...'), { filename: 'virus.exe', contentType: 'application/octet-stream' });
    assert.equal(res.status, 400);
  });
});

describe('Stock', () => {
  const produit = { id: 1, nom: 'Eau de parfum', quantite_stock: 5, seuil_minimum: 2 };

  test('refuse une sortie supérieure au stock', async () => {
    onQuery((sql) => (/FOR UPDATE/.test(sql) ? [[produit]] : [[]]));
    const res = await request(app).post('/api/stock/sortie').set(auth()).send({ produit_id: 1, quantite: 9 });
    assert.equal(res.status, 400);
    assert.ok(calls.some((c) => c.sql === 'ROLLBACK'));
    assert.ok(!calls.some((c) => /UPDATE produits/.test(c.sql)));
  });

  test('enregistre une sortie dans une transaction et signale le stock faible', async () => {
    onQuery((sql) => {
      if (/FOR UPDATE/.test(sql)) return [[produit]];
      if (/SELECT quantite_stock/.test(sql)) return [[{ quantite_stock: 2 }]];
      return [{ affectedRows: 1 }];
    });
    const res = await request(app).post('/api/stock/sortie').set(auth()).send({ produit_id: 1, quantite: 3 });
    assert.equal(res.status, 201);
    assert.equal(res.body.data.alerte_stock_faible, true);
    assert.ok(calls.some((c) => c.sql === 'COMMIT'));
  });
});

describe('Images des produits', () => {
  const imageFile = (name) => {
    fs.mkdirSync(uploadDir, { recursive: true });
    const p = path.join(uploadDir, name);
    fs.writeFileSync(p, 'image');
    return p;
  };

  test("supprime le fichier image quand le produit est supprimé", async () => {
    const file = imageFile('produit-ancien.jpg');
    onQuery((sql) => {
      if (/SELECT image_url/.test(sql)) return [[{ image_url: '/uploads/products/produit-ancien.jpg' }]];
      return [{ affectedRows: 1 }];
    });
    const res = await request(app).delete('/api/products/1').set(auth());
    assert.equal(res.status, 200);
    assert.equal(fs.existsSync(file), false);
  });

  test("supprime l'ancienne image quand elle est remplacée", async () => {
    const file = imageFile('produit-remplace.jpg');
    const existing = { id: 1, nom: 'P', categorie_id: 1, prix_vente: 10, image_url: '/uploads/products/produit-remplace.jpg' };
    onQuery((sql) => (/SELECT \*/.test(sql) || /FROM produits p/.test(sql) ? [[existing]] : [{ affectedRows: 1 }]));

    const res = await request(app).put('/api/products/1').set(auth())
      .attach('image', Buffer.from([0xff, 0xd8, 0xff]), { filename: 'nouvelle.jpg', contentType: 'image/jpeg' });
    assert.equal(res.status, 200);
    assert.equal(fs.existsSync(file), false);
  });

  test("ne touche pas aux fichiers hors du dossier d'envoi", async () => {
    const outside = path.join(path.dirname(uploadDir), 'ne-pas-effacer.txt');
    fs.writeFileSync(outside, 'x');
    onQuery((sql) => (/SELECT image_url/.test(sql) ? [[{ image_url: '/uploads/products/../../ne-pas-effacer.txt' }]] : [{ affectedRows: 1 }]));

    await request(app).delete('/api/products/1').set(auth());
    assert.equal(fs.existsSync(outside), true);
    fs.unlinkSync(outside);
  });
});
