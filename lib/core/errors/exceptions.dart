/// Base class for all exceptions in the application
class AppException implements Exception {
  final String message;
  final StackTrace? stackTrace;

  AppException(this.message, [this.stackTrace]);

  @override
  String toString() => 'AppException: $message';
}

/// Server-related exceptions
class ServerException extends AppException {
  final int? statusCode;
  
  ServerException(super.message, [super.stackTrace, this.statusCode]);
}

/// Cache-related exceptions
class CacheException extends AppException {
  CacheException(super.message, [super.stackTrace]);
}

/// Network-related exceptions
class NetworkException extends AppException {
  NetworkException(super.message, [super.stackTrace]);
}

/// Database-related exceptions
class DatabaseException extends AppException {
  DatabaseException(super.message, [super.stackTrace]);
}

/// Authentication-related exceptions
class AuthException extends AppException {
  AuthException(super.message, [super.stackTrace]);
}

/// Validation-related exceptions
class ValidationException extends AppException {
  ValidationException(super.message, [super.stackTrace]);
}

/// Not found exceptions
class NotFoundException extends AppException {
  NotFoundException(super.message, [super.stackTrace]);
}
