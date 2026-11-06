import '../core/network/api_client.dart';
import '../models/category.dart';

/// Service d'accès à l'API des catégories.
class CategoryService {
  final ApiClient _client = ApiClient();

  Future<List<Category>> getAll() async {
    final data = await _client.get('/categories');
    return (data as List).map((e) => Category.fromJson(e)).toList();
  }
}
