// =====================================================================
// Configuration de Multer pour l'upload des images de produits.
// Les fichiers sont stockés sur disque dans UPLOAD_DIR avec un nom
// unique afin d'éviter les collisions et les écrasements accidentels.
// =====================================================================
const multer = require('multer');
const path = require('path');
const fs = require('fs');

// Chemin absolu : relatif au dossier backend, quel que soit le dossier
// depuis lequel le serveur est lancé (express.static utilise le même).
const uploadDir = path.resolve(__dirname, '../..', process.env.UPLOAD_DIR || 'uploads/products');
const PUBLIC_PREFIX = '/uploads/products/';

// Crée le dossier d'upload s'il n'existe pas encore
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true });
}

const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, uploadDir),
  filename: (req, file, cb) => {
    const uniqueSuffix = `${Date.now()}-${Math.round(Math.random() * 1e9)}`;
    const ext = path.extname(file.originalname).toLowerCase();
    cb(null, `produit-${uniqueSuffix}${ext}`);
  },
});

const allowedTypes = /jpeg|jpg|png|webp/;

function fileFilter(req, file, cb) {
  const isValidExt = allowedTypes.test(path.extname(file.originalname).toLowerCase());
  const isValidMime = allowedTypes.test(file.mimetype);
  if (isValidExt && isValidMime) {
    return cb(null, true);
  }
  const error = new Error("Format d'image non autorisé. Utilisez JPG, PNG ou WEBP.");
  error.statusCode = 400;
  cb(error);
}

const maxSizeMb = Number(process.env.MAX_UPLOAD_SIZE_MB) || 5;

const upload = multer({
  storage,
  fileFilter,
  limits: { fileSize: maxSizeMb * 1024 * 1024 },
});

// URL publique d'une image enregistrée (servie par app.js)
function publicUrl(filename) {
  return PUBLIC_PREFIX + filename;
}

// Supprime le fichier d'une image à partir de son URL publique. Seul le
// nom de fichier est conservé (path.basename) : une URL forgée du type
// « ../../fichier » ne peut pas faire effacer un fichier hors du dossier.
function deleteImage(imageUrl) {
  if (!imageUrl || !imageUrl.startsWith(PUBLIC_PREFIX)) return;
  const file = path.join(uploadDir, path.basename(imageUrl));
  fs.unlink(file, () => {}); // fichier déjà absent : rien à faire
}

// Supprime le fichier envoyé avec une requête refusée (validation, erreur)
function discardUpload(req) {
  if (req.file?.path) fs.unlink(req.file.path, () => {});
}

module.exports = upload;
module.exports.uploadDir = uploadDir;
module.exports.publicUrl = publicUrl;
module.exports.deleteImage = deleteImage;
module.exports.discardUpload = discardUpload;
