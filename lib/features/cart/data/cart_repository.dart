import '../../../core/network/api_client.dart';

class CartItemModel {
  const CartItemModel({required this.id, required this.variantId, required this.quantity, required this.productId, required this.productName, required this.storeId, required this.storeName, required this.variantTitle, required this.unitPrice, required this.originalPrice, required this.stock});
  final String id, variantId, productId, productName, storeId, storeName, variantTitle;
  final int quantity, stock;
  final double unitPrice, originalPrice;
  factory CartItemModel.fromJson(Map<String,dynamic> j)=>CartItemModel(
    id:'${j['id']??''}', variantId:'${j['variant_id']??''}', quantity:int.tryParse('${j['quantity']??1}')??1,
    productId:'${j['product_id']??''}', productName:'${j['product_name']??''}', storeId:'${j['store_id']??''}', storeName:'${j['store_name']??''}', variantTitle:'${j['variant_title']??''}',
    unitPrice:double.tryParse('${j['current_price_usd']??j['price_usd']??0}')??0, originalPrice:double.tryParse('${j['price_usd']??0}')??0, stock:int.tryParse('${j['stock']??0}')??0);
}

class CartSnapshot {
  const CartSnapshot({required this.items, required this.currencyCode, this.couponCode});
  final List<CartItemModel> items;
  final String currencyCode;
  final String? couponCode;
  double get subtotal=>items.fold(0,(s,i)=>s+i.unitPrice*i.quantity);
  double get originalSubtotal=>items.fold(0,(s,i)=>s+i.originalPrice*i.quantity);
  double get saving=>originalSubtotal-subtotal;
  factory CartSnapshot.fromJson(Map<String,dynamic> j){final cart=Map<String,dynamic>.from(j['cart'] as Map? ?? const {});return CartSnapshot(items:(j['items'] as List? ?? const []).whereType<Map>().map((e)=>CartItemModel.fromJson(Map<String,dynamic>.from(e))).toList(),currencyCode:'${cart['currency_code']??'USD'}',couponCode:cart['coupon_code']?.toString());}
}

class CartRepository {
  CartRepository(this._api); final ApiClient _api;
  Future<CartSnapshot> load() async=>CartSnapshot.fromJson(await _api.get('/cart',auth:true));
  Future<CartSnapshot> add({required String variantId,int quantity=1}) async=>CartSnapshot.fromJson(await _api.post('/cart/items',auth:true,data:{'variant_id':variantId,'quantity':quantity}));
  Future<CartSnapshot> update({required String variantId,required int quantity}) async=>CartSnapshot.fromJson(await _api.put('/cart/items/$variantId',auth:true,data:{'quantity':quantity}));
  Future<CartSnapshot> updateMeta({String? currencyCode,String? couponCode}) async=>CartSnapshot.fromJson(await _api.put('/cart/meta',auth:true,data:{if(currencyCode!=null)'currency_code':currencyCode,if(couponCode!=null)'coupon_code':couponCode}));
}
