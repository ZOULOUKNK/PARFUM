import 'package:flutter/foundation.dart';
import '../core/network/api_client.dart';
import '../models/supplier.dart';
import '../services/supplier_service.dart';

/// Provider gérant la liste des fournisseurs, la recherche et les
/// opérations de création / modification / suppression.
class SupplierProvider extends ChangeNotifier {
  final SupplierService _service = SupplierService();

  List<Supplier> suppliers = [];
  bool isLoading = false;
  String? errorMessage;
  String searchQuery = '';

  Future<void> loadSuppliers() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      suppliers = await _service.getAll(search: searchQuery);
    } on ApiException catch (e) {
      errorMessage = e.message;
    } catch (e) {
      errorMessage = 'Impossible de charger les fournisseurs.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void search(String query) {
    searchQuery = query;
    loadSuppliers();
  }

  Future<bool> createSupplier(Supplier supplier) async {
    try {
      await _service.create(supplier);
      await loadSuppliers();
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateSupplier(int id, Supplier supplier) async {
    try {
      await _service.update(id, supplier);
      await loadSuppliers();
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteSupplier(int id) async {
    try {
      await _service.delete(id);
      await loadSuppliers();
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }
}
