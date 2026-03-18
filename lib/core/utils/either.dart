/// Functional Either type for error handling
/// Represents a value of one of two possible types (a disjoint union)
sealed class Either<L, R> {
  const Either();

  /// Fold the Either into a single value
  T fold<T>(T Function(L left) onLeft, T Function(R right) onRight);

  /// Check if this is a Left value
  bool get isLeft;

  /// Check if this is a Right value
  bool get isRight;

  /// Get the left value or null
  L? get leftOrNull;

  /// Get the right value or null
  R? get rightOrNull;
}

/// Left side of Either (typically represents failure/error)
class Left<L, R> extends Either<L, R> {
  final L value;

  const Left(this.value);

  @override
  T fold<T>(T Function(L left) onLeft, T Function(R right) onRight) {
    return onLeft(value);
  }

  @override
  bool get isLeft => true;

  @override
  bool get isRight => false;

  @override
  L? get leftOrNull => value;

  @override
  R? get rightOrNull => null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Left && runtimeType == other.runtimeType && value == other.value;

  @override
  int get hashCode => value.hashCode;
}

/// Right side of Either (typically represents success/value)
class Right<L, R> extends Either<L, R> {
  final R value;

  const Right(this.value);

  @override
  T fold<T>(T Function(L left) onLeft, T Function(R right) onRight) {
    return onRight(value);
  }

  @override
  bool get isLeft => false;

  @override
  bool get isRight => true;

  @override
  L? get leftOrNull => null;

  @override
  R? get rightOrNull => value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Right &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;
}
