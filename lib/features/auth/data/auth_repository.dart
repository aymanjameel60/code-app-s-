import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';

class AuthRepository{
  AuthRepository(this._api,this._tokens);final ApiClient _api;final TokenStorage _tokens;
  Future<Map<String,dynamic>> login({required String email,required String password})async{final d=await _api.post('/auth/login',data:{'email':email.trim(),'password':password});final token='${d['token']??''}';if(token.isEmpty)throw const ApiException('تعذر حفظ جلسة تسجيل الدخول');await _tokens.writeToken(token);return Map<String,dynamic>.from(d['user'] as Map? ?? const {});}
  Future<Map<String,dynamic>> register({required String name,required String email,required String password,String? phone})async{final d=await _api.post('/auth/register',data:{'name':name.trim(),'email':email.trim(),'password':password,if(phone!=null&&phone.trim().isNotEmpty)'phone':phone.trim()});final token='${d['token']??''}';if(token.isEmpty)throw const ApiException('تعذر حفظ جلسة الحساب');await _tokens.writeToken(token);return Map<String,dynamic>.from(d['user'] as Map? ?? const {});}
  Future<Map<String,dynamic>?> me()async{final token=await _tokens.readToken();if(token==null||token.isEmpty)return null;try{final d=await _api.get('/me',auth:true),u=d['user'];return u is Map?Map<String,dynamic>.from(u):null;}on ApiException catch(e){if(e.statusCode==401)await _tokens.clearToken();return null;}}
  Future<Map<String,dynamic>> updateProfile({required String name})async{final d=await _api.put('/profile',auth:true,data:{'name':name.trim()});return Map<String,dynamic>.from(d['user'] as Map? ?? const {});}
  Future<Map<String,dynamic>> uploadAvatar(String filePath)async{final uploaded=await _api.uploadFile('/uploads/avatar',filePath:filePath),url='${uploaded['url']??''}';if(url.isEmpty)throw const ApiException('تعذر رفع الصورة');final d=await _api.put('/customer-media/profile/avatar',auth:true,data:{'avatar_url':url});return Map<String,dynamic>.from(d['user'] as Map? ?? const {});}
  Future<void> requestPhoneChange(String phone)async{await _api.post('/profile/phone/request',auth:true,data:{'phone':phone.trim()});}
  Future<Map<String,dynamic>> verifyPhoneChange(String code)async{final d=await _api.post('/profile/phone/verify',auth:true,data:{'code':code});return Map<String,dynamic>.from(d['user'] as Map? ?? const {});}
  Future<void> requestPasswordReset(String email)async{await _api.post('/auth/password-reset/request',data:{'email':email.trim()});}
  Future<void> confirmPasswordReset({required String email,required String code,required String password})async{await _api.post('/auth/password-reset/confirm',data:{'email':email.trim(),'code':code.trim(),'password':password});}
  Future<void> logout()=>_tokens.clearToken();
}
