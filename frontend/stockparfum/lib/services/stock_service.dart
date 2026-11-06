import '../core/network/api_client.dart';
import '../models/stock_movement.dart';

/// Service d'accès à l'API des mouvements de stock (entrées/sorties)
/// et de l'historique des sorties.
class StockService {
  final ApiClient _client = ApiClient();

  Future<int> enregistrerEntree(int produitId, int quantite, {String? motif}) async {
    final data = await _client.post('/stock/entree', {
      'produit_id': produitId,
      'quantite': quantite,
      if (motif != null) 'motif': motif,
    });
    return data['nouvelle_quantite'] as int;
  }

  /// Retourne un couple (nouvelle quantité, alerte stock faible).
  Future<Map<String, dynamic>> enregistrerSortie(int produitId, int quantite, {String? motif}) async {
    final data = await _client.post('/stock/sortie', {
      'produit_id': produitId,
      'quantite': quantite,
      if (motif != null) 'motif': motif,
    });
    return {
      'nouvelle_quantite': data['nouvelle_quantite'] as int,
      'alerte_stock_faible': data['alerte_stock_faible'] as bool,
    };
  }

  Future<List<StockMovement>> getHistoriqueSorties({
    String? dateDebut,
    String? dateFin,
    int? produitId,
  }) async {
    final data = await _client.get('/stock/historique-sorties', query: {
      if (dateDebut != null) 'date_debut': dateDebut,
      if (dateFin != null) 'date_fin': dateFin,
      if (produitId != null) 'produit_id': produitId,
    });
    return (data as List).map((e) => StockMovement.fromJson(e)).toList();
  }
}
