/// Constantes globales de l'application StockParfum.
class AppConstants {
  AppConstants._();

  /// Adresse de base de l'API backend.
  /// - Émulateur Android : 10.0.2.2 redirige vers le "localhost" de la
  ///   machine hôte.
  /// - Appareil physique : remplacez par l'adresse IP locale de votre
  ///   machine (ex : http://192.168.1.10:3000/api) ou l'URL de
  ///   production une fois déployée.
  /// Modifiable sans toucher au code :
  ///   flutter run --dart-define=API_URL=http://192.168.1.10:3000/api
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://10.0.2.2:3000/api',
  );

  /// Adresse du serveur sans le suffixe « /api » (pour les images).
  /// replaceAll('/api', '') abîmait les domaines du type
  /// https://api.exemple.mg/api.
  static String get serverUrl => baseUrl.endsWith('/api')
      ? baseUrl.substring(0, baseUrl.length - '/api'.length)
      : baseUrl;

  /// Délai maximal d'attente d'une réponse du serveur.
  static const Duration requestTimeout = Duration(seconds: 15);

  static const String appName = 'StockParfum';

  // Clés utilisées pour le stockage sécurisé (flutter_secure_storage)
  static const String tokenKey = 'auth_token';
  static const String adminNameKey = 'admin_name';
  static const String adminEmailKey = 'admin_email';

  // Catégories (doivent correspondre aux données de la table "categories")
  static const List<String> categoryNames = [
    'Parfums',
    'Antares',
    'Déodorants',
    'Crèmes pour le visage',
  ];
}
