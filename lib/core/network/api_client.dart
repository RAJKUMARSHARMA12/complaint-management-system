import 'dart:io' show Platform;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:major_project/core/storage/secure_storage_service.dart';

class AuthInterceptor extends Interceptor {
  final StorageService storageService;
  final VoidCallback? onUnauthorized;

  AuthInterceptor({
    required this.storageService,
    this.onUnauthorized,
  });

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    options.headers['Content-Type'] ??= 'application/json';

    try {
      final token = await storageService.getToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    } catch (_) {
      // Ignore storage read error during request interception
    }

    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      await storageService.clearAuth();
      onUnauthorized?.call();
    }
    return handler.next(err);
  }
}

class ApiClient {
  final Dio dio;
  final StorageService storageService;
  final VoidCallback? onUnauthorized;

  ApiClient({
    required this.storageService,
    String? baseUrl,
    this.onUnauthorized,
    Dio? customDio,
  }) : dio = customDio ?? Dio() {
    dio.options.baseUrl = baseUrl ?? defaultBaseUrl;
    dio.options.connectTimeout = const Duration(seconds: 15);
    dio.options.receiveTimeout = const Duration(seconds: 15);
    dio.options.headers['Content-Type'] = 'application/json';

    dio.interceptors.add(
      AuthInterceptor(
        storageService: storageService,
        onUnauthorized: onUnauthorized,
      ),
    );
  }

  static String get defaultBaseUrl {
    if (kIsWeb) {
      return 'http://localhost:5001/api';
    }
    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:5001/api';
      }
    } catch (_) {
      // Fallback for non-standard environments
    }
    return 'http://localhost:5001/api';
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) =>
      dio.get<T>(path, queryParameters: queryParameters, options: options);

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) =>
      dio.post<T>(path, data: data, queryParameters: queryParameters, options: options);

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) =>
      dio.put<T>(path, data: data, queryParameters: queryParameters, options: options);

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) =>
      dio.patch<T>(path, data: data, queryParameters: queryParameters, options: options);

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) =>
      dio.delete<T>(path, data: data, queryParameters: queryParameters, options: options);
}
