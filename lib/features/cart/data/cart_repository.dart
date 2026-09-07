import '../../../core/network/api_client.dart';

class CartRepository {
  CartRepository(this._api);
  final ApiClient _api;

  Future<Map<String, dynamic>> load() => _api.get('/cart', auth: true);
  Future<Map<String, dynamic>> add({required String variantId, int quantity = 1}) => _api.post('/cart/items', auth: true, data: {'variant_id': variantId, 'quantity': quantity});
  Future<Map<String, dynamic>> update({required String variantId, required int quantity}) => _api.put('/cart/items/$variantId', auth: true, data: {'quantity': quantity});
  Future<Map<String, dynamic>> updateMeta({String? currencyCode, String? couponCode}) => _api.put('/cart/meta', auth: true, data: {if (currencyCode != null) 'currency_code': currencyCode, if (couponCode != null) 'coupon_code': couponCode});
}
