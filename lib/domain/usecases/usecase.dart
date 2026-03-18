import '../../core/errors/failures.dart';
import '../../core/utils/either.dart';

/// Base class for all use cases
/// 
/// [T] is the return type of the use case
/// [P] is the parameter type for the use case
abstract class UseCase<T, P> {
  /// Execute the use case with given parameters
  Future<Either<Failure, T>> call(P params);
}

/// Use case with no parameters
abstract class NoParamsUseCase<T> {
  /// Execute the use case
  Future<Either<Failure, T>> call();
}

/// Marker class for use cases that don't require parameters
class NoParams {
  const NoParams();
}
