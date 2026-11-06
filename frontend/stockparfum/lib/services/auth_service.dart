import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/constants/app_constants.dart';
import '../core/network/api_client.dart';
import '../models/admin.dart';

/// Service responsable de l'authentification : connexion, déconnexion
/// et persistance sécurisée du token JWT sur l'appareil.
class AuthService {
  final ApiClient _client = ApiClient();
  final _storage = const FlutterSecureStorage();

  /// Connecte l'administrateur et stocke le token JWT reçu.
  Future<Admin> login(String email, String motDePasse) async {
    final data = await _client.post('/auth/login', {
      'email': email,
      'mot_de_passe': motDePasse,
    });

    final token = data['token'] as String;
    final adminJson = data['admin'] as Map<String, dynamic>;

    await _storage.write(key: AppConstants.tokenKey, value: token);
    await _storage.write(key: AppConstants.adminNameKey, value: adminJson['nom']);
    await _storage.write(key: AppConstants.adminEmailKey, value: adminJson['email']);

    return Admin.fromJson(adminJson);
  }

  /// Déconnecte l'administrateur : informe le backend puis supprime le
  /// token local, quel que soit le résultat de l'appel réseau.
  Future<void> logout() async {
    try {
      await _client.post('/auth/logout', {});
    } catch (_) {
      // Même en cas d'échec réseau, on supprime la session locale.
    } finally {
      await _storage.deleteAll();
    }
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: AppConstants.tokenKey);
    return token != null;
  }

  Future<String?> getAdminName() => _storage.read(key: AppConstants.adminNameKey);
}
