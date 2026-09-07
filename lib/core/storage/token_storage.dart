import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  TokenStorage(this._storage);

  final FlutterSecureStorage _storage;
  static const _tokenKey = 'spike_customer_token';
  static const _userCacheKey = 'spike_customer_profile_cache';

  Future<String?> readToken() => _storage.read(key: _tokenKey);

  Future<void> writeToken(String token) => _storage.write(key: _tokenKey, value: token);

  Future<Map<String, dynamic>?> readCachedUser() async {
    final raw = await _storage.read(key: _userCacheKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
    } catch (_) {
      await _storage.delete(key: _userCacheKey);
      return null;
    }
  }

  Future<void> writeCachedUser(Map<String, dynamic> user) =>
      _storage.write(key: _userCacheKey, value: jsonEncode(user));

  Future<void> clearToken() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userCacheKey);
  }
}
