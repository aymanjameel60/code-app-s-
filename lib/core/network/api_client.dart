import 'package:dio/dio.dart';
import '../api_config.dart';
import '../storage/token_storage.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
  @override String toString() => message;
}

class ApiClient {
  ApiClient({required TokenStorage tokenStorage})
      : _tokenStorage = tokenStorage,
        _dio = Dio(BaseOptions(
          baseUrl: ApiConfig.baseUrl,
          connectTimeout: ApiConfig.connectTimeout,
          receiveTimeout: ApiConfig.receiveTimeout,
          headers: const {'Accept': 'application/json'},
        ));

  final Dio _dio;
  final TokenStorage _tokenStorage;

  Future<Map<String, dynamic>> get(String path, {bool auth = false, Map<String, dynamic>? query}) async => _request('GET', path, auth: auth, query: query);
  Future<Map<String, dynamic>> post(String path, {bool auth = false, Object? data}) async => _request('POST', path, auth: auth, data: data);
  Future<Map<String, dynamic>> put(String path, {bool auth = false, Object? data}) async => _request('PUT', path, auth: auth, data: data);
  Future<Map<String, dynamic>> delete(String path, {bool auth = false, Object? data}) async => _request('DELETE', path, auth: auth, data: data);

  Future<Map<String, dynamic>> _request(String method, String path, {bool auth = false, Object? data, Map<String, dynamic>? query}) async {
    try {
      final headers = <String, dynamic>{};
      if (auth) {
        final token = await _tokenStorage.readToken();
        if (token != null && token.isNotEmpty) headers['Authorization'] = 'Bearer $token';
      }
      final response = await _dio.request<Object?>(path, data: data, queryParameters: query, options: Options(method: method, headers: headers));
      final body = response.data;
      if (body is Map<String, dynamic>) return body;
      if (body is Map) return body.map((key, value) => MapEntry('$key', value));
      return <String, dynamic>{'data': body};
    } on DioException catch (e) {
      final response = e.response;
      final raw = response?.data;
      String message = 'تعذر الاتصال بالخادم';
      if (raw is Map && raw['message'] != null) message = '${raw['message']}';
      if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) message = 'انتهت مهلة الاتصال، حاول مرة أخرى';
      throw ApiException(message, statusCode: response?.statusCode);
    }
  }
}
