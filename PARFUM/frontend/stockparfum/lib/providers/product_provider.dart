import 'package:flutter/foundation.dart';
import '../core/network/api_client.dart';
import '../models/product.dart';
import '../services/product_service.dart';

/// Provider gérant la liste des produits, la recherche, le filtre par
/// catégorie et les opérations de création / modification / suppression.
class ProductProvider extends ChangeNotifier {
  final ProductService _service = ProductService();

  List<Product> products = [];
  bool isLoading = false;
  String? errorMessage;
  String searchQuery = '';
  int? selectedCategoryId;

  Future<void> loadProducts() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      products = await _service.getAll(
        search: searchQuery,
        categorieId: selectedCategoryId,
      );
    } on ApiException catch (e) {
      errorMessage = e.message;
    } catch (e) {
      errorMessage = 'Impossible de charger les produits.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void search(String query) {
    searchQuery = query;
    loadProducts();
  }

  void filterByCategory(int? categoryId) {
    selectedCategoryId = categoryId;
    loadProducts();
  }

  Future<bool> createProduct({
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
    try {
      await _service.create(
        nom: nom,
        categorieId: categorieId,
        marque: marque,
        prixAchat: prixAchat,
        prixVente: prixVente,
        quantiteStock: quantiteStock,
        seuilMinimum: seuilMinimum,
        fournisseurId: fournisseurId,
        imagePath: imagePath,
      );
      await loadProducts();
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProduct({
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
    try {
      await _service.update(
        id: id,
        nom: nom,
        categorieId: categorieId,
        marque: marque,
        prixAchat: prixAchat,
        prixVente: prixVente,
        quantiteStock: quantiteStock,
        seuilMinimum: seuilMinimum,
        fournisseurId: fournisseurId,
        imagePath: imagePath,
      );
      await loadProducts();
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteProduct(int id) async {
    try {
      await _service.delete(id);
      await loadProducts();
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }
}
