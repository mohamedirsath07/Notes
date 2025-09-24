import 'package:json_annotation/json_annotation.dart';

part 'api_response.g.dart';

@JsonSerializable(genericArgumentFactories: true)
class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final List<String>? errors;
  final Map<String, dynamic>? metadata;

  const ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.errors,
    this.metadata,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) => _$ApiResponseFromJson(json, fromJsonT);

  Map<String, dynamic> toJson(Object Function(T value) toJsonT) =>
      _$ApiResponseToJson(this, toJsonT);

  // Success response factory
  factory ApiResponse.success({
    required String message,
    T? data,
    Map<String, dynamic>? metadata,
  }) {
    return ApiResponse<T>(
      success: true,
      message: message,
      data: data,
      metadata: metadata,
    );
  }

  // Error response factory
  factory ApiResponse.error({
    required String message,
    List<String>? errors,
    Map<String, dynamic>? metadata,
  }) {
    return ApiResponse<T>(
      success: false,
      message: message,
      errors: errors,
      metadata: metadata,
    );
  }

  // Check if response has data
  bool get hasData => data != null;

  // Check if response has errors
  bool get hasErrors => errors != null && errors!.isNotEmpty;

  // Get first error message
  String? get firstError => hasErrors ? errors!.first : null;

  // Get error message or default
  String getErrorMessage([String defaultMessage = 'An error occurred']) {
    if (hasErrors) return errors!.join(', ');
    return success ? message : defaultMessage;
  }

  @override
  String toString() {
    return 'ApiResponse{success: $success, message: $message, hasData: $hasData, hasErrors: $hasErrors}';
  }
}

@JsonSerializable(explicitToJson: true, genericArgumentFactories: true)
class PaginatedResponse<T> {
  @JsonKey(name: 'items')
  final List<T> items;
  final int totalCount;
  final int page;
  final int pageSize;
  final int totalPages;
  final bool hasNext;
  final bool hasPrevious;

  const PaginatedResponse({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrevious,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) => _$PaginatedResponseFromJson(json, fromJsonT);

  Map<String, dynamic> toJson(Object Function(T value) toJsonT) =>
      _$PaginatedResponseToJson(this, toJsonT);

  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;
  int get length => items.length;

  // Create empty paginated response
  factory PaginatedResponse.empty() {
    return PaginatedResponse<T>(
      items: const [],
      totalCount: 0,
      page: 1,
      pageSize: 10,
      totalPages: 0,
      hasNext: false,
      hasPrevious: false,
    );
  }

  @override
  String toString() {
    return 'PaginatedResponse{items: ${items.length}, totalCount: $totalCount, page: $page, totalPages: $totalPages}';
  }
}

@JsonSerializable()
class ErrorDetails {
  final String code;
  final String message;
  final String? field;
  final Map<String, dynamic>? details;

  const ErrorDetails({
    required this.code,
    required this.message,
    this.field,
    this.details,
  });

  factory ErrorDetails.fromJson(Map<String, dynamic> json) =>
      _$ErrorDetailsFromJson(json);
  Map<String, dynamic> toJson() => _$ErrorDetailsToJson(this);

  @override
  String toString() {
    return 'ErrorDetails{code: $code, message: $message, field: $field}';
  }
}
