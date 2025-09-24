import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/api_response.dart';
import '../utils/constants.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal() {
    // Auto-initialize when created
    initialize();
  }

  // Mock mode for testing (should match AuthService._mockMode)
  static const bool _mockMode = true;

  late Dio _dio;

  void initialize({String? baseUrl}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? ApiConstants.baseUrl,
        connectTimeout: const Duration(milliseconds: 30000),
        receiveTimeout: const Duration(milliseconds: 30000),
        sendTimeout: const Duration(milliseconds: 30000),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _setupInterceptors();
  }

  void _setupInterceptors() {
    // Skip complex auth interceptors in mock mode
    if (_mockMode) {
      // Simple logging interceptor for mock mode
      _dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (kDebugMode) {
              debugPrint('🚀 MOCK REQUEST: ${options.method} ${options.uri}');
            }
            handler.next(options);
          },
          onResponse: (response, handler) {
            if (kDebugMode) {
              debugPrint('✅ MOCK RESPONSE: ${response.statusCode}');
            }
            handler.next(response);
          },
          onError: (error, handler) {
            if (kDebugMode) {
              debugPrint('❌ MOCK ERROR: ${error.message}');
            }
            handler.next(error);
          },
        ),
      );
      return;
    }

    // Full interceptors would go here for production mode
    // But since we're in mock mode, this section won't be reached
  }

  // Generic GET request
  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      return _handleError<T>(e);
    }
  }

  // Generic POST request
  Future<ApiResponse<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      return _handleError<T>(e);
    }
  }

  // Generic PUT request
  Future<ApiResponse<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      return _handleError<T>(e);
    }
  }

  // Generic DELETE request
  Future<ApiResponse<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      return _handleError<T>(e);
    }
  }

  // File upload
  Future<ApiResponse<T>> uploadFile<T>(
    String path,
    File file, {
    String fieldName = 'file',
    Map<String, dynamic>? additionalData,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final formData = FormData();
      formData.files.add(
        MapEntry(fieldName, await MultipartFile.fromFile(file.path)),
      );

      if (additionalData != null) {
        additionalData.forEach((key, value) {
          formData.fields.add(MapEntry(key, value.toString()));
        });
      }

      final response = await _dio.post(path, data: formData);
      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      return _handleError<T>(e);
    }
  }

  // Handle successful response
  ApiResponse<T> _handleResponse<T>(
    Response response,
    T Function(dynamic)? fromJson,
  ) {
    try {
      final responseData = response.data;

      // If response is already wrapped in ApiResponse format
      if (responseData is Map<String, dynamic> &&
          responseData.containsKey('success') &&
          responseData.containsKey('message')) {
        final success = responseData['success'] as bool;
        final message = responseData['message'] as String;
        final data = responseData['data'];

        T? parsedData;
        if (data != null && fromJson != null) {
          parsedData = fromJson(data);
        } else if (data != null) {
          parsedData = data as T?;
        }

        return ApiResponse<T>(
          success: success,
          message: message,
          data: parsedData,
          errors: responseData['errors'] != null
              ? List<String>.from(responseData['errors'])
              : null,
          metadata: responseData['metadata'] as Map<String, dynamic>?,
        );
      }

      // If response is direct data
      T? parsedData;
      if (responseData != null && fromJson != null) {
        parsedData = fromJson(responseData);
      } else if (responseData != null) {
        parsedData = responseData as T?;
      }

      return ApiResponse<T>.success(
        message: 'Request successful',
        data: parsedData,
      );
    } catch (e) {
      return ApiResponse<T>.error(
        message: 'Failed to parse response: ${e.toString()}',
        errors: [e.toString()],
      );
    }
  }

  // Handle errors
  ApiResponse<T> _handleError<T>(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return ApiResponse<T>.error(
            message:
                'Connection timeout. Please check your internet connection.',
            errors: ['TIMEOUT_ERROR'],
          );

        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          final responseData = error.response?.data;

          // Try to parse error response
          if (responseData is Map<String, dynamic>) {
            final message =
                responseData['message'] as String? ??
                responseData['detail'] as String? ??
                'Server error occurred';
            final errors = responseData['errors'] != null
                ? List<String>.from(responseData['errors'])
                : null;

            return ApiResponse<T>.error(
              message: message,
              errors: errors ?? ['HTTP_${statusCode}_ERROR'],
            );
          }

          return ApiResponse<T>.error(
            message: _getErrorMessageForStatusCode(statusCode),
            errors: ['HTTP_${statusCode}_ERROR'],
          );

        case DioExceptionType.cancel:
          return ApiResponse<T>.error(
            message: 'Request was cancelled',
            errors: ['REQUEST_CANCELLED'],
          );

        case DioExceptionType.connectionError:
          return ApiResponse<T>.error(
            message: 'No internet connection. Please check your network.',
            errors: ['NETWORK_ERROR'],
          );

        case DioExceptionType.badCertificate:
          return ApiResponse<T>.error(
            message: 'Security certificate error',
            errors: ['CERTIFICATE_ERROR'],
          );

        case DioExceptionType.unknown:
          return ApiResponse<T>.error(
            message: 'An unexpected error occurred',
            errors: ['UNKNOWN_ERROR'],
          );
      }
    }

    return ApiResponse<T>.error(
      message: error.toString(),
      errors: ['GENERAL_ERROR'],
    );
  }

  String _getErrorMessageForStatusCode(int? statusCode) {
    switch (statusCode) {
      case 400:
        return 'Bad request. Please check your input.';
      case 401:
        return 'Authentication failed. Please login again.';
      case 403:
        return 'Access forbidden. You don\'t have permission.';
      case 404:
        return 'Resource not found.';
      case 422:
        return 'Validation error. Please check your input.';
      case 429:
        return 'Too many requests. Please try again later.';
      case 500:
        return 'Internal server error. Please try again later.';
      case 502:
        return 'Bad gateway. Server is temporarily unavailable.';
      case 503:
        return 'Service unavailable. Please try again later.';
      default:
        return 'Server error occurred. Please try again.';
    }
  }

  // Cancel all ongoing requests
  void cancelRequests() {
    _dio.close();
  }

  // Get current Dio instance for custom requests
  Dio get dio => _dio;
}
