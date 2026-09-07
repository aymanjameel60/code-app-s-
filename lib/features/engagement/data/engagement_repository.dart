import '../../../core/network/api_client.dart';

class EngagementRepository {
  EngagementRepository(this._api);
  final ApiClient _api;

  Future<List<String>> wishlistIds() async {
    final data = await _api.get('/wishlist', auth: true);
    return (data['products'] as List? ?? const []).whereType<Map>().map((e) => '${e['id'] ?? ''}').where((e) => e.isNotEmpty).toList();
  }
  Future<void> addWishlist(String productId) async { await _api.post('/wishlist/$productId', auth: true); }
  Future<void> removeWishlist(String productId) async { await _api.delete('/wishlist/$productId', auth: true); }
}
