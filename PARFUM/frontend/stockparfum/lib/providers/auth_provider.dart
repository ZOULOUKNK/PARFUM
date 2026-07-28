import 'package:flutter/foundation.dart';
import '../core/network/api_client.dart';
import '../models/admin.dart';
import '../services/auth_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

/// Provider gérant l'état d'authentification global : statut de
/// connexion, administrateur courant, et actions login/logout.
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthStatus status = AuthStatus.unknown;
  Admin? currentAdmin;
  String? errorMessage;
  bool isLoading = false;

  Future<void> checkAuthStatus() async {
    final loggedIn = await _authService.isLoggedIn();
    status = loggedIn ? AuthStatus.authenticated : AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<bool> login(String email, String motDePasse) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final admin = await _authService.login(email, motDePasse);
      currentAdmin = admin;
      status = AuthStatus.authenticated;
      isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      errorMessage = 'Une erreur inattendue est survenue.';
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    currentAdmin = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
