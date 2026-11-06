// =====================================================================
// Configuration de Multer pour l'upload des images de produits.
// Les fichiers sont stockés sur disque dans UPLOAD_DIR avec un nom
// unique afin d'éviter les collisions et les écrasements accidentels.
// =====================================================================
const multer = require('multer');
const path = require('path');
const fs = require('fs');

const uploadDir = process.env.UPLOAD_DIR || 'uploads/products';

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
  cb(new Error('Format d\'image non autorisé. Utilisez JPG, PNG ou WEBP.'));
}

const maxSizeMb = Number(process.env.MAX_UPLOAD_SIZE_MB) || 5;

const upload = multer({
  storage,
  fileFilter,
  limits: { fileSize: maxSizeMb * 1024 * 1024 },
});

module.exports = upload;
