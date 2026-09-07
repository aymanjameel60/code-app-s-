import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';

class EngagementRepository {
  EngagementRepository(this._api, this._tokens); final ApiClient _api; final TokenStorage _tokens;
  static const _guestKey = 'spike_guest_wishlist_v1';
  Future<bool> get _guest async { final token = await _tokens.readToken(); return token == null || token.isEmpty; }
  Future<Set<String>> _guestIds() async { final p = await SharedPreferences.getInstance(); return (p.getStringList(_guestKey) ?? const <String>[]).toSet(); }
  Future<void> _saveGuestIds(Set<String> ids) async { final p = await SharedPreferences.getInstance(); await p.setStringList(_guestKey, ids.toList()); }
  Future<List<String>> wishlistIds() async { if (await _guest) return (await _guestIds()).toList(); final d=await _api.get('/wishlist',auth:true);return (d['products'] as List? ?? const []).whereType<Map>().map((e)=>'${e['id']??''}').where((e)=>e.isNotEmpty).toList();}
  Future<void> addWishlist(String productId) async { if (await _guest) { final ids = await _guestIds(); ids.add(productId); return _saveGuestIds(ids); } await _api.post('/wishlist/$productId',auth:true); }
  Future<void> removeWishlist(String productId) async { if (await _guest) { final ids = await _guestIds(); ids.remove(productId); return _saveGuestIds(ids); } await _api.delete('/wishlist/$productId',auth:true); }

  Future<Map<String,dynamic>> notifications() => _api.get('/notifications',auth:true);
  Future<void> readNotification(String id) async{await _api.post('/notifications/$id/read',auth:true);}
  Future<void> readAllNotifications() async{await _api.post('/notifications/read-all',auth:true);}

  Future<List<Map<String,dynamic>>> announcements() async{final d=await _api.get('/announcements',auth:true);return (d['announcements'] as List? ?? const []).whereType<Map>().map((e)=>Map<String,dynamic>.from(e)).toList();}
  Future<void> dismissAnnouncement(String id) async{await _api.post('/announcements/$id/dismiss',auth:true);}

  Future<List<Map<String,dynamic>>> productReviews(String productId) async{final d=await _api.get('/products/$productId/reviews');return (d['reviews'] as List? ?? const []).whereType<Map>().map((e)=>Map<String,dynamic>.from(e)).toList();}
  Future<Map<String,dynamic>> storeReviews(String storeId) => _api.get('/stores/$storeId/reviews');
  Future<List<Map<String,dynamic>>> reviewable() async{final d=await _api.get('/reviews/reviewable',auth:true);return (d['items'] as List? ?? const []).whereType<Map>().map((e)=>Map<String,dynamic>.from(e)).toList();}
  Future<void> reviewProduct({required String orderItemId,required int rating,String? comment}) async{await _api.post('/reviews/product',auth:true,data:{'order_item_id':orderItemId,'rating':rating,'comment':comment});}
  Future<void> reviewStore({required String suborderId,required int rating,String? comment}) async{await _api.post('/reviews/store',auth:true,data:{'suborder_id':suborderId,'rating':rating,'comment':comment});}

  Future<Map<String,dynamic>> publicSettings() async => await _api.get('/settings/public');

  Future<String> ensureSupportThread() async{final d=await _api.post('/support/threads',auth:true,data:{'subject':'محادثة مع الإدارة'});return '${(d['thread'] as Map?)?['id']??''}';}
  Future<List<Map<String,dynamic>>> supportMessages(String threadId) async{final d=await _api.get('/support/threads/$threadId/messages',auth:true);return (d['messages'] as List? ?? const []).whereType<Map>().map((e)=>Map<String,dynamic>.from(e)).toList();}
  Future<void> sendSupportMessage(String threadId,String body) async{await _api.post('/support/threads/$threadId/messages',auth:true,data:{'body':body});}
}
