/// Base class for all failures in the application
abstract class Failure {
  final String message;
  final StackTrace? stackTrace;

  const Failure(this.message, [this.stackTrace]);

  @override
  String toString() => message;
}

/// Server-related failures
class ServerFailure extends Failure {
  const ServerFailure(super.message, [super.stackTrace]);
}

/// Cache-related failures
class CacheFailure extends Failure {
  const CacheFailure(super.message, [super.stackTrace]);
}

/// Network-related failures
class NetworkFailure extends Failure {
  const NetworkFailure(super.message, [super.stackTrace]);
}

/// Authentication-related failures
class AuthFailure extends Failure {
  const AuthFailure(super.message, [super.stackTrace]);
}

/// Database-related failures
class DatabaseFailure extends Failure {
  const DatabaseFailure(super.message, [super.stackTrace]);
}

/// Validation-related failures
class ValidationFailure extends Failure {
  const ValidationFailure(super.message, [super.stackTrace]);
}

/// Not found failures
class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message, [super.stackTrace]);
}

/// Sync-related failures
class SyncFailure extends Failure {
  const SyncFailure(super.message, [super.stackTrace]);
}
