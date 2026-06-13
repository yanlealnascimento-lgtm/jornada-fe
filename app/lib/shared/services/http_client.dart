import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../core/config/app_config.dart';

class HttpClient {
  static HttpClient? _instance;
  late final Dio _dio;

  HttpClient._() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: AppConfig.connectTimeout,
      receiveTimeout: AppConfig.receiveTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _dio.interceptors.add(_RetryInterceptor(dio: _dio));

    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) => debugPrint('[HTTP] $obj'),
      ));
    }
  }

  static HttpClient get instance {
    _instance ??= HttpClient._();
    return _instance!;
  }

  Dio get dio => _dio;

  /// Injeta o token JWT em todas as requisições autenticadas.
  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  void clearAuthToken() {
    _dio.options.headers.remove('Authorization');
  }

  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? queryParams}) =>
      _dio.get<T>(path, queryParameters: queryParams);

  Future<Response<T>> post<T>(String path, {dynamic data}) =>
      _dio.post<T>(path, data: data);

  Future<Response<T>> put<T>(String path, {dynamic data}) =>
      _dio.put<T>(path, data: data);

  Future<Response<T>> patch<T>(String path, {dynamic data}) =>
      _dio.patch<T>(path, data: data);

  Future<Response<T>> delete<T>(String path) =>
      _dio.delete<T>(path);
}

class _RetryInterceptor extends Interceptor {
  final Dio dio;
  _RetryInterceptor({required this.dio});

  /// Rotas de auth falham rápido — sem retry para login/register.
  static const _noRetryPaths = ['/auth/login', '/auth/register', '/auth/me'];

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final path = err.requestOptions.path;

    // Não faz retry em rotas de auth — falha rápida
    if (_noRetryPaths.any(path.contains)) {
      handler.next(err);
      return;
    }

    if (_shouldRetry(err)) {
      final opts = err.requestOptions;
      final retryCount = (opts.extra['retryCount'] as int?) ?? 0;
      if (retryCount < 1) {
        opts.extra['retryCount'] = retryCount + 1;
        await Future.delayed(const Duration(milliseconds: 800));
        try {
          handler.resolve(await dio.fetch(opts));
          return;
        } catch (_) {}
      }
    }
    handler.next(err);
  }

  bool _shouldRetry(DioException e) =>
      e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.receiveTimeout ||
      e.type == DioExceptionType.connectionError;
}
