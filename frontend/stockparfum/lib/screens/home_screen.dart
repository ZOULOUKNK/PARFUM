import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dashboard/dashboard_screen.dart';
import 'products/product_list_screen.dart';
import 'stock/stock_screen.dart';
import 'history/history_screen.dart';
import 'suppliers/supplier_list_screen.dart';

/// Coquille principale de l'application : héberge les 5 sections via
/// une Bottom Navigation Bar Material 3, avec animation de transition
/// légère entre les onglets.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    ProductListScreen(),
    StockScreen(),
    HistoryScreen(),
    SupplierListScreen(),
  ];

  final List<NavigationDestination> _destinations = const [
    NavigationDestination(icon: FaIcon(FontAwesomeIcons.chartPie, size: 20), label: 'Accueil'),
    NavigationDestination(icon: FaIcon(FontAwesomeIcons.boxesStacked, size: 20), label: 'Produits'),
    NavigationDestination(icon: FaIcon(FontAwesomeIcons.rightLeft, size: 20), label: 'Stock'),
    NavigationDestination(icon: FaIcon(FontAwesomeIcons.clockRotateLeft, size: 20), label: 'Historique'),
    NavigationDestination(icon: FaIcon(FontAwesomeIcons.truck, size: 20), label: 'Fournisseurs'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: _destinations,
      ),
    );
  }
}
