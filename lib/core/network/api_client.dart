import 'package:dio/dio.dart';
import '../api_config.dart';
import '../storage/token_storage.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
  @override
  String toString() => message;
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

  Future<Map<String, dynamic>> get(String path, {bool auth = false, Map<String, dynamic>? query}) =>
      _request('GET', path, auth: auth, query: query);
  Future<Map<String, dynamic>> post(String path, {bool auth = false, Object? data}) =>
      _request('POST', path, auth: auth, data: data);
  Future<Map<String, dynamic>> put(String path, {bool auth = false, Object? data}) =>
      _request('PUT', path, auth: auth, data: data);
  Future<Map<String, dynamic>> delete(String path, {bool auth = false, Object? data}) =>
      _request('DELETE', path, auth: auth, data: data);

  Future<Map<String, dynamic>> uploadFile(String path, {required String filePath, bool auth = true}) async {
    try {
      final headers = <String, dynamic>{};
      if (auth) {
        final token = await _tokenStorage.readToken();
        if (token != null && token.isNotEmpty) headers['Authorization'] = 'Bearer $token';
      }
      final name = filePath.split(RegExp(r'[\\/]')).last;
      final form = FormData.fromMap({'file': await MultipartFile.fromFile(filePath, filename: name)});
      final response = await _dio.post<Object?>(
        path,
        data: form,
        options: Options(headers: headers, contentType: 'multipart/form-data'),
      );
      return _mapBody(response.data);
    } on DioException catch (e) {
      throw _dioError(e);
    }
  }

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    bool auth = false,
    Object? data,
    Map<String, dynamic>? query,
  }) async {
    final headers = <String, dynamic>{};
    if (auth) {
      final token = await _tokenStorage.readToken();
      if (token == null || token.isEmpty) throw const ApiException('سجّل الدخول أولاً للمتابعة', statusCode: 401);
      headers['Authorization'] = 'Bearer $token';
    }

    final maxAttempts = method == 'GET' ? 2 : 1;
    DioException? lastError;
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        final response = await _dio.request<Object?>(
          path,
          data: data,
          queryParameters: query,
          options: Options(method: method, headers: headers),
        );
        return _mapBody(response.data);
      } on DioException catch (e) {
        lastError = e;
        final transient = e.type == DioExceptionType.connectionError ||
            e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.sendTimeout;
        if (!transient || attempt + 1 >= maxAttempts) break;
        await Future<void>.delayed(const Duration(milliseconds: 650));
      }
    }
    throw _dioError(lastError!);
  }

  Map<String, dynamic> _mapBody(Object? body) {
    if (body is Map<String, dynamic>) return body;
    if (body is Map) return body.map((k, v) => MapEntry('$k', v));
    return <String, dynamic>{'data': body};
  }

  ApiException _dioError(DioException e) {
    final raw = e.response?.data;
    String message = 'تعذر الاتصال بالخادم، تحقق من الإنترنت وحاول مرة أخرى';
    if (raw is Map && raw['message'] != null) message = '${raw['message']}';
    if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
      message = 'انتهت مهلة الاتصال، حاول مرة أخرى';
    }
    return ApiException(message, statusCode: e.response?.statusCode);
  }
}
