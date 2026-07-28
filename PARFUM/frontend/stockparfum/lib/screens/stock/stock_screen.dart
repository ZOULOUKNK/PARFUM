import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../models/product.dart';
import '../../services/product_service.dart';
import '../../services/stock_service.dart';
import '../../widgets/error_view.dart';
import '../../widgets/product_card.dart';

/// Écran de gestion des stocks : sélection d'un produit puis
/// enregistrement d'une entrée ou d'une sortie, avec alerte visuelle
/// pour les produits déjà en stock faible.
class StockScreen extends StatefulWidget {
  const StockScreen({super.key});

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  final _productService = ProductService();
  final _stockService = StockService();
  final _searchController = TextEditingController();

  List<Product> _products = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts({String? search}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final products = await _productService.getAll(search: search);
      setState(() => _products = products);
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'Impossible de charger les produits.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _openMovementDialog(Product product, {required bool isEntree}) async {
    final quantiteController = TextEditingController();
    final motifController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isEntree ? FontAwesomeIcons.arrowDown : FontAwesomeIcons.arrowUp,
                      color: isEntree ? AppColors.success : AppColors.danger,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isEntree ? 'Entrée de stock' : 'Sortie de stock',
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(product.nom, style: const TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 18),
                TextFormField(
                  controller: quantiteController,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Quantité *'),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'La quantité est requise.';
                    final n = int.tryParse(v);
                    if (n == null || n <= 0) return 'Quantité invalide.';
                    if (!isEntree && n > product.quantiteStock) {
                      return 'Stock disponible : ${product.quantiteStock}';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: motifController,
                  decoration: const InputDecoration(labelText: 'Motif (optionnel)'),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isEntree ? AppColors.success : AppColors.danger,
                  ),
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      Navigator.pop(ctx, true);
                    }
                  },
                  child: Text(isEntree ? 'Valider l\'entrée' : 'Valider la sortie'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirmed != true) return;

    final quantite = int.parse(quantiteController.text);
    final motif = motifController.text.trim();

    try {
      if (isEntree) {
        await _stockService.enregistrerEntree(product.id, quantite, motif: motif.isEmpty ? null : motif);
      } else {
        final result = await _stockService.enregistrerSortie(product.id, quantite, motif: motif.isEmpty ? null : motif);
        if (result['alerte_stock_faible'] == true && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('⚠️ Attention : "${product.nom}" atteint le seuil de stock faible.'),
              backgroundColor: AppColors.warning,
            ),
          );
        }
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEntree ? 'Entrée enregistrée avec succès.' : 'Sortie enregistrée avec succès.'),
          backgroundColor: AppColors.success,
        ),
      );
      _loadProducts(search: _searchController.text);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: AppColors.danger));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mouvements de stock')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Rechercher un produit…',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => _loadProducts(search: value),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? ErrorView(message: _errorMessage!, onRetry: () => _loadProducts())
                    : _products.isEmpty
                        ? const Center(child: Text('Aucun produit trouvé.', style: TextStyle(color: AppColors.textSecondary)))
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                            itemCount: _products.length,
                            itemBuilder: (context, index) {
                              final product = _products[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: ProductCard(
                                  product: product,
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        tooltip: 'Enregistrer une entrée',
                                        icon: const Icon(FontAwesomeIcons.circlePlus, color: AppColors.success, size: 22),
                                        onPressed: () => _openMovementDialog(product, isEntree: true),
                                      ),
                                      IconButton(
                                        tooltip: 'Enregistrer une sortie',
                                        icon: const Icon(FontAwesomeIcons.circleMinus, color: AppColors.danger, size: 22),
                                        onPressed: () => _openMovementDialog(product, isEntree: false),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
