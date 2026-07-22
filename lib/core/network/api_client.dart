import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../storage/token_storage.dart';
import 'api_exception.dart';

class ApiClient {
  ApiClient({
    TokenStorage? tokenStorage,
    this.onUnauthorized,
  })  : _tokenStorage = tokenStorage ?? TokenStorage(),
        _dio = Dio(
          BaseOptions(
            baseUrl: _normalizeBaseUrl(AppConfig.apiBaseUrl),
            connectTimeout: AppConfig.connectTimeout,
            receiveTimeout: AppConfig.receiveTimeout,
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
          ),
        ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokenStorage.readToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final isUnauthorized = error.response?.statusCode == 401;
          final alreadyRetried = error.requestOptions.extra['auth_retry'] == true;

          if (isUnauthorized && !alreadyRetried) {
            await _tokenStorage.readToken();
            final token = await _tokenStorage.readToken();
            if (token != null && token.isNotEmpty) {
              final options = error.requestOptions;
              options.extra['auth_retry'] = true;
              options.headers['Authorization'] = 'Bearer $token';
              try {
                final response = await _dio.fetch<Map<String, dynamic>>(options);
                return handler.resolve(response);
              } on DioException catch (retryError) {
                if (retryError.response?.statusCode == 401) {
                  await _tokenStorage.clearToken();
                  onUnauthorized?.call();
                }
                return handler.next(retryError);
              }
            }
          }

          if (isUnauthorized) {
            await _tokenStorage.clearToken();
            onUnauthorized?.call();
          }

          handler.next(error);
        },
      ),
    );
  }

  final Dio _dio;
  final TokenStorage _tokenStorage;
  final void Function()? onUnauthorized;

  static String _normalizeBaseUrl(String baseUrl) {
    return baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
  }

  static String _normalizePath(String path) {
    return path.startsWith('/') ? path.substring(1) : path;
  }

  Future<void> warmAuthHeader() => _tokenStorage.readToken();

  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? query}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(_normalizePath(path), queryParameters: query);
      return _unwrap(response.data);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<Map<String, dynamic>> post(String path, {Map<String, dynamic>? body}) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(_normalizePath(path), data: body);
      return _unwrap(response.data);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<Map<String, dynamic>> patch(String path, {Map<String, dynamic>? body}) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(_normalizePath(path), data: body);
      return _unwrap(response.data);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<void> delete(String path) async {
    try {
      await _dio.delete<void>(_normalizePath(path));
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Map<String, dynamic> _unwrap(Map<String, dynamic>? data) {
    if (data == null) {
      return {};
    }
    if (data['data'] is Map<String, dynamic>) {
      return data['data'] as Map<String, dynamic>;
    }
    return data;
  }

  ApiException _mapError(DioException error) {
    final response = error.response;
    final data = response?.data;
    var message = 'Something went wrong. Please try again.';
    Map<String, List<String>>? fieldErrors;

    if (data is Map<String, dynamic>) {
      if (data['message'] is String) {
        message = data['message'] as String;
      }
      if (data['errors'] is Map) {
        fieldErrors = (data['errors'] as Map).map(
          (key, value) => MapEntry(
            key.toString(),
            (value as List).map((e) => e.toString()).toList(),
          ),
        );
        if (fieldErrors.isNotEmpty) {
          message = fieldErrors.values.first.first;
        }
      }
    } else if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      message = 'Connection timed out. Check your network.';
    } else if (error.type == DioExceptionType.connectionError) {
      message = 'Cannot reach VMFS Cloud. Check your connection.';
    }

    return ApiException(
      message,
      statusCode: response?.statusCode,
      errors: fieldErrors,
    );
  }
}
