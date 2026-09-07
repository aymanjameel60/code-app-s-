import '../../../core/network/api_client.dart';
import '../../../models/category.dart';
import '../../../models/product.dart';
import '../../../models/store.dart';

class CatalogRepository {
  CatalogRepository(this._api);
  final ApiClient _api;

  Future<List<ProductModel>> products({String? categoryId, String? collectionId}) async {
    final data = await _api.get('/products', query: {
      if (categoryId != null && categoryId.isNotEmpty) 'category_id': categoryId,
      if (collectionId != null && collectionId.isNotEmpty) 'collection_id': collectionId,
    });
    return (data['products'] as List? ?? const []).whereType<Map>().map((e) => ProductModel.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<ProductModel?> product(String id) async {
    final list = await products();
    for (final product in list) { if (product.id == id) return product; }
    return null;
  }

  Future<List<StoreModel>> stores() async {
    final data = await _api.get('/stores');
    return (data['stores'] as List? ?? const []).whereType<Map>().map((e) => StoreModel.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<List<CategoryModel>> categories() async {
    final data = await _api.get('/categories');
    return (data['categories'] as List? ?? const []).whereType<Map>().map((e) => CategoryModel.fromJson(Map<String, dynamic>.from(e))).where((e) => e.enabled).toList();
  }
}
