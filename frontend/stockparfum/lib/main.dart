import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/network/api_client.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/product_provider.dart';
import 'providers/supplier_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/splash_screen.dart';

/// Permet de naviguer hors d'un widget (session expirée).
final navigatorKey = GlobalKey<NavigatorState>();

void main() {
  // Session expirée : retour à l'écran de connexion avec un message,
  // au lieu d'afficher « Token invalide » sur chaque écran.
  // Plusieurs requêtes simultanées peuvent recevoir 401 : une seule
  // redirection.
  var redirecting = false;
  ApiClient.onSessionExpired = () {
    final navigator = navigatorKey.currentState;
    if (navigator == null || redirecting) return;
    redirecting = true;
    Future.delayed(const Duration(seconds: 2), () => redirecting = false);
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
    ScaffoldMessenger.maybeOf(navigator.context)?.showSnackBar(
      const SnackBar(content: Text('Session expirée. Veuillez vous reconnecter.')),
    );
  };

  runApp(const StockParfumApp());
}

/// Widget racine de l'application StockParfum.
/// Configure les providers de gestion d'état globale et le thème
/// Material Design 3 utilisé dans toute l'application.
class StockParfumApp extends StatelessWidget {
  const StockParfumApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => SupplierProvider()),
      ],
      child: MaterialApp(
        title: 'StockParfum',
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
      ),
    );
  }
}
