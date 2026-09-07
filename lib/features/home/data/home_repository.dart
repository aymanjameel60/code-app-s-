import '../../../core/network/api_client.dart';
import '../../../models/banner_item.dart';
import '../../../models/category.dart';
import '../../../models/collection.dart';
import '../../../models/product.dart';
import '../../../models/store.dart';

class HomeData {
  const HomeData({required this.categories, required this.products, required this.bestSellers, required this.stores, required this.banners, required this.collections});
  final List<CategoryModel> categories;
  final List<ProductModel> products;
  final List<ProductModel> bestSellers;
  final List<StoreModel> stores;
  final List<BannerItem> banners;
  final List<CollectionModel> collections;
}

class HomeRepository {
  HomeRepository(this._api);
  final ApiClient _api;

  Future<HomeData> load() async {
    final results = await Future.wait<Map<String, dynamic>>([
      _api.get('/categories'),
      _api.get('/products'),
      _api.get('/stores'),
      _api.get('/home-sections'),
      _api.get('/banners', query: {'placement': 'home'}),
    ]);
    Map<String, dynamic> bestSellersData = const {};
    try {
      bestSellersData = await _api.get('/best-sellers', query: {'limit': '12'});
    } catch (_) {
      // Keep home usable while older production deployments catch up.
    }
    final categoriesRaw = (results[0]['categories'] as List? ?? const []);
    final productsRaw = (results[1]['products'] as List? ?? const []);
    final storesRaw = (results[2]['stores'] as List? ?? const []);
    final home = results[3];
    final categories = categoriesRaw.whereType<Map>().map((e) => CategoryModel.fromJson(Map<String, dynamic>.from(e))).where((e) => e.enabled).toList()..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final products = productsRaw.whereType<Map>().map((e) => ProductModel.fromJson(Map<String, dynamic>.from(e))).toList();
    final bestSellers = (bestSellersData['products'] as List? ?? const []).whereType<Map>().map((e) => ProductModel.fromJson(Map<String, dynamic>.from(e))).toList();
    final stores = storesRaw.whereType<Map>().map((e) => StoreModel.fromJson(Map<String, dynamic>.from(e))).toList();
    final banners = (results[4]['banners'] as List? ?? const []).whereType<Map>().map((e) => BannerItem.fromJson(Map<String, dynamic>.from(e))).where((e) => e.imageUrl.isNotEmpty).toList();
    final collections = (home['spike_collections'] as List? ?? const []).whereType<Map>().where((e) => e['enabled'] != false).map((e) => CollectionModel.fromJson(Map<String, dynamic>.from(e))).toList()..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return HomeData(categories: categories, products: products, bestSellers: bestSellers, stores: stores, banners: banners, collections: collections);
  }
}
