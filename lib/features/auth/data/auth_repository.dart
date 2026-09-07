import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';

class AuthRepository {
  AuthRepository(this._api, this._tokens);
  final ApiClient _api;
  final TokenStorage _tokens;

  Future<Map<String, dynamic>> login({required String email, required String password}) async {
    final data = await _api.post('/auth/login', data: {'email': email.trim(), 'password': password});
    final token = '${data['token'] ?? ''}';
    if (token.isEmpty) throw const ApiException('تعذر حفظ جلسة تسجيل الدخول');
    await _tokens.writeToken(token);
    return Map<String, dynamic>.from(data['user'] as Map? ?? const {});
  }

  Future<Map<String, dynamic>> register({required String name, required String email, required String password, String? phone}) async {
    final data = await _api.post('/auth/register', data: {
      'name': name.trim(),
      'email': email.trim(),
      'password': password,
      if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
    });
    final token = '${data['token'] ?? ''}';
    if (token.isEmpty) throw const ApiException('تعذر حفظ جلسة الحساب');
    await _tokens.writeToken(token);
    return Map<String, dynamic>.from(data['user'] as Map? ?? const {});
  }

  Future<Map<String, dynamic>?> me() async {
    final token = await _tokens.readToken();
    if (token == null || token.isEmpty) return null;
    try {
      final data = await _api.get('/me', auth: true);
      final user = data['user'];
      return user is Map ? Map<String, dynamic>.from(user) : null;
    } on ApiException catch (e) {
      if (e.statusCode == 401) await _tokens.clearToken();
      return null;
    }
  }

  Future<void> logout() => _tokens.clearToken();
}
