import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/dashboard_service.dart';
import '../../widgets/error_view.dart';
import '../../widgets/product_card.dart';
import '../../widgets/stat_card.dart';
import '../auth/login_screen.dart';

/// Tableau de bord : vue d'ensemble des statistiques de la boutique.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _service = DashboardService();
  DashboardStats? _stats;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final stats = await _service.getStats();
      setState(() => _stats = stats);
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'Impossible de charger le tableau de bord.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Déconnexion')),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<AuthProvider>().logout();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminName = context.watch<AuthProvider>().currentAdmin?.nom;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de bord'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Déconnexion',
            onPressed: _confirmLogout,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? ErrorView(message: _errorMessage!, onRetry: _load)
                : _buildContent(adminName),
      ),
    );
  }

  Widget _buildContent(String? adminName) {
    final stats = _stats!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (adminName != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'Bienvenue, $adminName 👋',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
            ),
          ),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.35,
          children: [
            StatCard(
              icon: FontAwesomeIcons.boxesStacked,
              label: 'Produits référencés',
              value: '${stats.totalProduits}',
              color: AppColors.primary,
            ),
            StatCard(
              icon: FontAwesomeIcons.warehouse,
              label: 'Quantité totale en stock',
              value: '${stats.totalStock}',
              color: AppColors.secondary,
            ),
            StatCard(
              icon: FontAwesomeIcons.triangleExclamation,
              label: 'Produits en stock faible',
              value: '${stats.stockFaible}',
              color: AppColors.danger,
            ),
            StatCard(
              icon: FontAwesomeIcons.clockRotateLeft,
              label: 'Derniers ajouts',
              value: '${stats.derniersProduits.length}',
              color: AppColors.success,
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text(
          'Derniers produits ajoutés',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 12),
        if (stats.derniersProduits.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text('Aucun produit ajouté pour le moment.', style: TextStyle(color: AppColors.textSecondary)),
            ),
          )
        else
          ...stats.derniersProduits.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ProductCard(product: p),
            ),
          ),
      ],
    );
  }
}
