import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';

class AuthRepository{
  AuthRepository(this._api,this._tokens);final ApiClient _api;final TokenStorage _tokens;

  String _normalizePhone(String value)=>value.replaceAll(RegExp(r'\D'),'');

  Future<Map<String,dynamic>> login({required String phone,required String password})async{
    final normalized=_normalizePhone(phone);
    if(normalized.isEmpty)throw const ApiException('أدخل رقم الجوال');
    final d=await _api.post('/auth/login-phone',data:{'phone':normalized,'password':password});
    final token='${d['token']??''}';
    if(token.isEmpty)throw const ApiException('تعذر حفظ جلسة تسجيل الدخول');
    final user=Map<String,dynamic>.from(d['user'] as Map? ?? const {});
    if(user['role']!=null&&'${user['role']}'!='customer')throw const ApiException('هذا الحساب ليس حساب عميل');
    await _tokens.writeToken(token);
    if(user.isNotEmpty)await _tokens.writeCachedUser(user);
    return user;
  }

  Future<Map<String,dynamic>> register({required String name,required String phone,required String password})async{
    final normalized=_normalizePhone(phone);
    if(name.trim().isEmpty)throw const ApiException('أدخل اسمك');
    if(normalized.isEmpty)throw const ApiException('أدخل رقم الجوال');
    if(password.length<8)throw const ApiException('يجب أن لا تقل كلمة المرور عن 8 أحرف');
    final d=await _api.post('/auth/register-phone',data:{'name':name.trim(),'phone':normalized,'password':password});
    final token='${d['token']??''}';
    if(token.isEmpty)throw const ApiException('تعذر حفظ جلسة الحساب');
    final user=Map<String,dynamic>.from(d['user'] as Map? ?? const {});
    if(user['role']!=null&&'${user['role']}'!='customer')throw const ApiException('تعذر إنشاء حساب العميل');
    await _tokens.writeToken(token);
    if(user.isNotEmpty)await _tokens.writeCachedUser(user);
    return user;
  }

  Future<Map<String,dynamic>?> me()async{
    final token=await _tokens.readToken();
    if(token==null||token.isEmpty)return null;
    try{
      final d=await _api.get('/me',auth:true),u=d['user'];
      final user=u is Map?Map<String,dynamic>.from(u):null;
      if(user!=null&&user.isNotEmpty)await _tokens.writeCachedUser(user);
      return user;
    }on ApiException catch(e){
      if(e.statusCode==401){await _tokens.clearToken();return null;}
      return _tokens.readCachedUser();
    }
  }

  Future<Map<String,dynamic>> updateProfile({required String name})async{
    final d=await _api.put('/profile',auth:true,data:{'name':name.trim()});
    final user=Map<String,dynamic>.from(d['user'] as Map? ?? const {});
    if(user.isNotEmpty)await _tokens.writeCachedUser(user);
    return user;
  }

  Future<Map<String,dynamic>> uploadAvatar(String filePath)async{
    final uploaded=await _api.uploadFile('/uploads/avatar',filePath:filePath),url='${uploaded['url']??''}';
    if(url.isEmpty)throw const ApiException('تعذر رفع الصورة');
    final d=await _api.put('/customer-media/profile/avatar',auth:true,data:{'avatar_url':url});
    final user=Map<String,dynamic>.from(d['user'] as Map? ?? const {});
    if(user.isNotEmpty)await _tokens.writeCachedUser(user);
    return user;
  }

  Future<void> requestPhoneChange(String phone)async{await _api.post('/profile/phone/request',auth:true,data:{'phone':phone.trim()});}

  Future<Map<String,dynamic>> verifyPhoneChange(String code)async{
    final d=await _api.post('/profile/phone/verify',auth:true,data:{'code':code});
    final user=Map<String,dynamic>.from(d['user'] as Map? ?? const {});
    if(user.isNotEmpty)await _tokens.writeCachedUser(user);
    return user;
  }

  Future<void> requestPasswordReset(String email)async{await _api.post('/auth/password-reset/request',data:{'email':email.trim()});}
  Future<void> confirmPasswordReset({required String email,required String code,required String password})async{await _api.post('/auth/password-reset/confirm',data:{'email':email.trim(),'code':code.trim(),'password':password});}
  Future<void> logout()=>_tokens.clearToken();
}
