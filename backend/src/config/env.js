// =====================================================================
// Vérification de la configuration au démarrage.
// Sans JWT_SECRET, le serveur démarrait mais chaque connexion échouait
// en erreur 500 : on préfère refuser de démarrer avec un message clair.
// =====================================================================
const MIN_SECRET_LENGTH = 32;

function validateEnv(env = process.env) {
  const problems = [];

  if (!env.JWT_SECRET) {
    problems.push('JWT_SECRET est vide : renseignez-le dans backend/.env.');
  } else if (env.JWT_SECRET.length < MIN_SECRET_LENGTH) {
    problems.push(`JWT_SECRET doit contenir au moins ${MIN_SECRET_LENGTH} caractères.`);
  }

  if (problems.length) {
    throw new Error(
      `Configuration invalide :\n - ${problems.join('\n - ')}\n` +
        'Astuce : node -e "console.log(require(\'crypto\').randomBytes(48).toString(\'hex\'))"'
    );
  }
}

module.exports = { validateEnv, MIN_SECRET_LENGTH };
