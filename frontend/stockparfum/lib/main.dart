import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/product_provider.dart';
import 'providers/supplier_provider.dart';
import 'screens/splash_screen.dart';

void main() {
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
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
      ),
    );
  }
}
