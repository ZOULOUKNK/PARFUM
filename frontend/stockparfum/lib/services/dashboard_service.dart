import '../core/network/api_client.dart';
import '../models/product.dart';

/// Regroupe les statistiques affichées sur le tableau de bord.
class DashboardStats {
  final int totalProduits;
  final int totalStock;
  final int stockFaible;
  final List<Product> derniersProduits;

  DashboardStats({
    required this.totalProduits,
    required this.totalStock,
    required this.stockFaible,
    required this.derniersProduits,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalProduits: json['total_produits'] as int,
      totalStock: json['total_stock'] as int,
      stockFaible: json['stock_faible'] as int,
      derniersProduits: (json['derniers_produits'] as List)
          .map((e) => Product.fromJson({
                ...e as Map<String, dynamic>,
                // Le endpoint dashboard renvoie un objet allégé : on
                // complète les champs non fournis avec des valeurs par
                // défaut pour rester compatible avec le modèle Product.
                'categorie_id': e['categorie_id'] ?? 0,
                'prix_achat': e['prix_achat'] ?? 0,
                'seuil_minimum': e['seuil_minimum'] ?? 5,
              }))
          .toList(),
    );
  }
}

class DashboardService {
  final ApiClient _client = ApiClient();

  Future<DashboardStats> getStats() async {
    final data = await _client.get('/dashboard');
    return DashboardStats.fromJson(data as Map<String, dynamic>);
  }
}
