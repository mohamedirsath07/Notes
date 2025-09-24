// Custom exceptions for the app
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  const AppException({required this.message, this.code, this.details});

  @override
  String toString() => 'AppException: $message (Code: $code)';
}

// Network related exceptions
class NetworkException extends AppException {
  const NetworkException({
    required super.message,
    super.code = 'NETWORK_ERROR',
    super.details,
  });
}

class TimeoutException extends AppException {
  const TimeoutException({
    required super.message,
    super.code = 'TIMEOUT_ERROR',
    super.details,
  });
}

class ConnectionException extends AppException {
  const ConnectionException({
    required super.message,
    super.code = 'CONNECTION_ERROR',
    super.details,
  });
}

// Authentication exceptions
class AuthenticationException extends AppException {
  const AuthenticationException({
    required super.message,
    super.code = 'AUTH_ERROR',
    super.details,
  });
}

class UnauthorizedException extends AppException {
  const UnauthorizedException({
    required super.message,
    super.code = 'UNAUTHORIZED',
    super.details,
  });
}

class ForbiddenException extends AppException {
  const ForbiddenException({
    required super.message,
    super.code = 'FORBIDDEN',
    super.details,
  });
}

// Validation exceptions
class ValidationException extends AppException {
  final Map<String, List<String>>? fieldErrors;

  const ValidationException({
    required super.message,
    super.code = 'VALIDATION_ERROR',
    this.fieldErrors,
    super.details,
  });

  bool hasFieldErrors() => fieldErrors != null && fieldErrors!.isNotEmpty;

  List<String>? getFieldErrors(String field) => fieldErrors?[field];

  String get allErrors {
    if (!hasFieldErrors()) return message;

    final buffer = StringBuffer(message);
    fieldErrors!.forEach((field, errors) {
      buffer.write('\n$field: ${errors.join(', ')}');
    });
    return buffer.toString();
  }
}

// Server exceptions
class ServerException extends AppException {
  final int? statusCode;

  const ServerException({
    required super.message,
    super.code = 'SERVER_ERROR',
    this.statusCode,
    super.details,
  });
}

class NotFoundException extends AppException {
  const NotFoundException({
    required super.message,
    super.code = 'NOT_FOUND',
    super.details,
  });
}

// Cache exceptions
class CacheException extends AppException {
  const CacheException({
    required super.message,
    super.code = 'CACHE_ERROR',
    super.details,
  });
}

// Parse exceptions
class ParseException extends AppException {
  const ParseException({
    required super.message,
    super.code = 'PARSE_ERROR',
    super.details,
  });
}

// Business logic exceptions
class BusinessLogicException extends AppException {
  const BusinessLogicException({
    required super.message,
    super.code,
    super.details,
  });
}

// Note specific exceptions
class NoteNotFoundException extends AppException {
  const NoteNotFoundException({
    super.message = 'Note not found',
    super.code = 'NOTE_NOT_FOUND',
    super.details,
  });
}

class NoteValidationException extends ValidationException {
  const NoteValidationException({
    required super.message,
    super.code = 'NOTE_VALIDATION_ERROR',
    super.fieldErrors,
    super.details,
  });
}

// User specific exceptions
class UserNotFoundException extends AppException {
  const UserNotFoundException({
    super.message = 'User not found',
    super.code = 'USER_NOT_FOUND',
    super.details,
  });
}

class EmailAlreadyExistsException extends AppException {
  const EmailAlreadyExistsException({
    super.message = 'Email already exists',
    super.code = 'EMAIL_EXISTS',
    super.details,
  });
}

class UsernameAlreadyExistsException extends AppException {
  const UsernameAlreadyExistsException({
    super.message = 'Username already exists',
    super.code = 'USERNAME_EXISTS',
    super.details,
  });
}

class InvalidCredentialsException extends AppException {
  const InvalidCredentialsException({
    super.message = 'Invalid credentials',
    super.code = 'INVALID_CREDENTIALS',
    super.details,
  });
}

// Rate limiting exception
class RateLimitException extends AppException {
  final int? retryAfter;

  const RateLimitException({
    super.message = 'Rate limit exceeded',
    super.code = 'RATE_LIMIT_EXCEEDED',
    this.retryAfter,
    super.details,
  });
}

// Maintenance exception
class MaintenanceException extends AppException {
  const MaintenanceException({
    super.message = 'Service is under maintenance',
    super.code = 'MAINTENANCE_MODE',
    super.details,
  });
}

// Helper class for creating exceptions from API responses
class ExceptionFactory {
  static AppException fromStatusCode(
    int statusCode, {
    String? message,
    dynamic details,
  }) {
    final errorMessage = message ?? _getDefaultMessageForStatusCode(statusCode);

    switch (statusCode) {
      case 400:
        return ValidationException(message: errorMessage, details: details);
      case 401:
        return UnauthorizedException(message: errorMessage, details: details);
      case 403:
        return ForbiddenException(message: errorMessage, details: details);
      case 404:
        return NotFoundException(message: errorMessage, details: details);
      case 422:
        return ValidationException(message: errorMessage, details: details);
      case 429:
        return RateLimitException(message: errorMessage, details: details);
      case 500:
      case 502:
      case 503:
      case 504:
        return ServerException(
          message: errorMessage,
          statusCode: statusCode,
          details: details,
        );
      default:
        return ServerException(
          message: errorMessage,
          statusCode: statusCode,
          details: details,
        );
    }
  }

  static AppException fromErrorCode(
    String code, {
    String? message,
    dynamic details,
  }) {
    switch (code.toUpperCase()) {
      case 'NETWORK_ERROR':
      case 'CONNECTION_ERROR':
        return NetworkException(
          message: message ?? 'Network connection failed',
          details: details,
        );
      case 'TIMEOUT_ERROR':
        return TimeoutException(
          message: message ?? 'Request timed out',
          details: details,
        );
      case 'UNAUTHORIZED':
      case 'AUTH_ERROR':
        return UnauthorizedException(
          message: message ?? 'Authentication required',
          details: details,
        );
      case 'VALIDATION_ERROR':
        return ValidationException(
          message: message ?? 'Validation failed',
          details: details,
        );
      case 'NOT_FOUND':
        return NotFoundException(
          message: message ?? 'Resource not found',
          details: details,
        );
      case 'CACHE_ERROR':
        return CacheException(
          message: message ?? 'Cache operation failed',
          details: details,
        );
      case 'PARSE_ERROR':
        return ParseException(
          message: message ?? 'Failed to parse data',
          details: details,
        );
      default:
        return BusinessLogicException(
          message: message ?? 'An unknown error occurred',
          code: code,
          details: details,
        );
    }
  }

  static String _getDefaultMessageForStatusCode(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Bad request. Please check your input.';
      case 401:
        return 'Authentication required. Please login.';
      case 403:
        return 'Access forbidden. You don\'t have permission.';
      case 404:
        return 'Resource not found.';
      case 422:
        return 'Validation failed. Please check your input.';
      case 429:
        return 'Too many requests. Please try again later.';
      case 500:
        return 'Internal server error. Please try again.';
      case 502:
        return 'Bad gateway. Please try again later.';
      case 503:
        return 'Service unavailable. Please try again later.';
      case 504:
        return 'Gateway timeout. Please try again later.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
}
