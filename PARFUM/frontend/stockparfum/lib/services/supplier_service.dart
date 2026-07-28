import '../core/network/api_client.dart';
import '../models/supplier.dart';

/// Service d'accès à l'API des fournisseurs (CRUD + recherche).
class SupplierService {
  final ApiClient _client = ApiClient();

  Future<List<Supplier>> getAll({String? search}) async {
    final data = await _client.get('/suppliers', query: {
      if (search != null && search.isNotEmpty) 'search': search,
    });
    return (data as List).map((e) => Supplier.fromJson(e)).toList();
  }

  Future<Supplier> create(Supplier supplier) async {
    final data = await _client.post('/suppliers', supplier.toJson());
    return Supplier.fromJson(data);
  }

  Future<Supplier> update(int id, Supplier supplier) async {
    final data = await _client.put('/suppliers/$id', supplier.toJson());
    return Supplier.fromJson(data);
  }

  Future<void> delete(int id) => _client.delete('/suppliers/$id');
}
