import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/api_config.dart';
import '../../../core/storage/token_storage.dart';
import '../../../models/product.dart';
import '../../../core/network/api_client.dart';

String? _absoluteImage(Object? value) {
  final raw = '${value ?? ''}'.trim();
  if (raw.isEmpty) return null;
  if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
  if (raw.startsWith('/uploads/')) return '${ApiConfig.assetBaseUrl}$raw';
  return raw;
}

class CartItemModel {
  const CartItemModel({required this.id, required this.variantId, required this.quantity, required this.productId, required this.productName, required this.storeId, required this.storeName, required this.variantTitle, required this.unitPrice, required this.originalPrice, required this.stock, this.imageUrl});
  final String id, variantId, productId, productName, storeId, storeName, variantTitle;
  final int quantity, stock;
  final double unitPrice, originalPrice;
  final String? imageUrl;
  factory CartItemModel.fromJson(Map<String,dynamic> j)=>CartItemModel(
    id:'${j['id']??''}', variantId:'${j['variant_id']??''}', quantity:int.tryParse('${j['quantity']??1}')??1,
    productId:'${j['product_id']??''}', productName:'${j['product_name']??''}', storeId:'${j['store_id']??''}', storeName:'${j['store_name']??''}', variantTitle:'${j['variant_title']??''}',
    unitPrice:double.tryParse('${j['current_price_usd']??j['price_usd']??0}')??0, originalPrice:double.tryParse('${j['price_usd']??0}')??0, stock:int.tryParse('${j['stock']??0}')??0,
    imageUrl:_absoluteImage(j['image_url']));
  Map<String,dynamic> toJson()=>{'id':id,'variant_id':variantId,'quantity':quantity,'product_id':productId,'product_name':productName,'store_id':storeId,'store_name':storeName,'variant_title':variantTitle,'current_price_usd':unitPrice,'price_usd':originalPrice,'stock':stock,'image_url':imageUrl};
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
  Map<String,dynamic> toJson()=>{'cart':{'currency_code':currencyCode,'coupon_code':couponCode},'items':items.map((e)=>e.toJson()).toList()};
}

class CartRepository {
  CartRepository(this._api,this._tokens);
  final ApiClient _api;
  final TokenStorage _tokens;
  static const _guestKey='spike_guest_cart_v1';

  Future<bool> get _guest async {
    final token=await _tokens.readToken();
    return token==null||token.isEmpty;
  }

  Future<CartSnapshot> _readGuest() async {
    final prefs=await SharedPreferences.getInstance();
    final raw=prefs.getString(_guestKey);
    if(raw==null||raw.isEmpty)return const CartSnapshot(items:[],currencyCode:'USD');
    return CartSnapshot.fromJson(Map<String,dynamic>.from(jsonDecode(raw) as Map));
  }

  Future<CartSnapshot> _saveGuest(CartSnapshot cart) async {
    final prefs=await SharedPreferences.getInstance();
    await prefs.setString(_guestKey,jsonEncode(cart.toJson()));
    return cart;
  }

  Future<CartSnapshot> load() async {
    if(await _guest)return _readGuest();
    return CartSnapshot.fromJson(await _api.get('/cart',auth:true));
  }

  Future<CartSnapshot> add({required String variantId,required ProductModel product,int quantity=1}) async {
    if(!await _guest)return CartSnapshot.fromJson(await _api.post('/cart/items',auth:true,data:{'variant_id':variantId,'quantity':quantity}));
    final old=await _readGuest();
    final items=[...old.items];
    final index=items.indexWhere((x)=>x.variantId==variantId);
    if(index>=0) {
      final x=items[index];
      items[index]=CartItemModel(id:x.id,variantId:x.variantId,quantity:x.quantity+quantity,productId:x.productId,productName:x.productName,storeId:x.storeId,storeName:x.storeName,variantTitle:x.variantTitle,unitPrice:x.unitPrice,originalPrice:x.originalPrice,stock:x.stock,imageUrl:x.imageUrl);
    } else {
      final variant=product.variants.firstWhere((x)=>x.id==variantId,orElse:()=>product.cheapestVariant!);
      items.add(CartItemModel(id:variantId,variantId:variantId,quantity:quantity,productId:product.id,productName:product.name,storeId:product.storeId??'',storeName:product.storeName,variantTitle:variant.title,unitPrice:variant.price,originalPrice:variant.originalPrice??variant.price,stock:variant.stock,imageUrl:product.imageUrl));
    }
    return _saveGuest(CartSnapshot(items:items,currencyCode:old.currencyCode,couponCode:old.couponCode));
  }

  Future<CartSnapshot> update({required String variantId,required int quantity}) async {
    if(!await _guest)return CartSnapshot.fromJson(await _api.put('/cart/items/'+variantId,auth:true,data:{'quantity':quantity}));
    final old=await _readGuest();
    final items=<CartItemModel>[];
    for(final x in old.items) {
      if(x.variantId!=variantId) {items.add(x);continue;}
      if(quantity>0)items.add(CartItemModel(id:x.id,variantId:x.variantId,quantity:quantity,productId:x.productId,productName:x.productName,storeId:x.storeId,storeName:x.storeName,variantTitle:x.variantTitle,unitPrice:x.unitPrice,originalPrice:x.originalPrice,stock:x.stock,imageUrl:x.imageUrl));
    }
    return _saveGuest(CartSnapshot(items:items,currencyCode:old.currencyCode,couponCode:old.couponCode));
  }

  Future<CartSnapshot> updateMeta({String? currencyCode,String? couponCode}) async {
    if(!await _guest)return CartSnapshot.fromJson(await _api.put('/cart/meta',auth:true,data:{if(currencyCode!=null)'currency_code':currencyCode,if(couponCode!=null)'coupon_code':couponCode}));
    final old=await _readGuest();
    return _saveGuest(CartSnapshot(items:old.items,currencyCode:currencyCode??old.currencyCode,couponCode:couponCode??old.couponCode));
  }

  Future<void> mergeGuestCart() async {
    final cart=await _readGuest();
    for(final item in cart.items){await _api.post('/cart/items',auth:true,data:{'variant_id':item.variantId,'quantity':item.quantity});}
    final prefs=await SharedPreferences.getInstance();
    await prefs.remove(_guestKey);
  }
}
