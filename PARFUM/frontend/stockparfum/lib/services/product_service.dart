import '../core/network/api_client.dart';
import '../models/product.dart';

/// Service d'accès à l'API des produits.
class ProductService {
  final ApiClient _client = ApiClient();

  Future<List<Product>> getAll({String? search, int? categorieId}) async {
    final data = await _client.get('/products', query: {
      if (search != null && search.isNotEmpty) 'search': search,
      if (categorieId != null) 'categorie_id': categorieId,
    });
    return (data as List).map((e) => Product.fromJson(e)).toList();
  }

  Future<Product> getById(int id) async {
    final data = await _client.get('/products/$id');
    return Product.fromJson(data);
  }

  Future<Product> create({
    required String nom,
    required int categorieId,
    String? marque,
    required double prixAchat,
    required double prixVente,
    required int quantiteStock,
    int seuilMinimum = 5,
    int? fournisseurId,
    String? imagePath,
  }) async {
    final fields = {
      'nom': nom,
      'categorie_id': categorieId.toString(),
      'marque': marque ?? '',
      'prix_achat': prixAchat.toString(),
      'prix_vente': prixVente.toString(),
      'quantite_stock': quantiteStock.toString(),
      'seuil_minimum': seuilMinimum.toString(),
      if (fournisseurId != null) 'fournisseur_id': fournisseurId.toString(),
    };
    final data = await _client.multipartRequest('POST', '/products', fields, imagePath: imagePath);
    return Product.fromJson(data);
  }

  Future<Product> update({
    required int id,
    required String nom,
    required int categorieId,
    String? marque,
    required double prixAchat,
    required double prixVente,
    required int quantiteStock,
    int seuilMinimum = 5,
    int? fournisseurId,
    String? imagePath,
  }) async {
    final fields = {
      'nom': nom,
      'categorie_id': categorieId.toString(),
      'marque': marque ?? '',
      'prix_achat': prixAchat.toString(),
      'prix_vente': prixVente.toString(),
      'quantite_stock': quantiteStock.toString(),
      'seuil_minimum': seuilMinimum.toString(),
      if (fournisseurId != null) 'fournisseur_id': fournisseurId.toString(),
    };
    final data = await _client.multipartRequest('PUT', '/products/$id', fields, imagePath: imagePath);
    return Product.fromJson(data);
  }

  Future<void> delete(int id) => _client.delete('/products/$id');
}
