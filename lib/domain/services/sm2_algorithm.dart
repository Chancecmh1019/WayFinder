/// SM-2 (SuperMemo 2) spaced repetition algorithm implementation
/// 
/// This algorithm calculates optimal review intervals based on:
/// - Current interval (days between reviews)
/// - Number of consecutive correct repetitions
/// - Ease factor (difficulty multiplier, 1.3-2.5)
/// - Quality of recall (0-5 rating)
class SM2Algorithm {
  /// Calculate next review parameters using SM-2 algorithm
  /// 
  /// Parameters:
  /// - [currentInterval]: Current interval in days
  /// - [repetitions]: Number of consecutive correct reviews
  /// - [easeFactor]: Current ease factor (1.3-2.5)
  /// - [quality]: Quality of recall (0-5)
  ///   - 5: Perfect response
  ///   - 4: Correct after hesitation
  ///   - 3: Correct with difficulty
  ///   - 2: Incorrect but easy to recall
  ///   - 1: Incorrect but remembered
  ///   - 0: Complete blackout
  /// 
  /// Returns: [SM2Result] containing new interval, repetitions, and ease factor
  SM2Result calculate({
    required int currentInterval,
    required int repetitions,
    required double easeFactor,
    required int quality,
  }) {
    // Validate inputs
    if (quality < 0 || quality > 5) {
      throw ArgumentError('Quality must be between 0 and 5, got: $quality');
    }
    if (easeFactor < 1.3) {
      throw ArgumentError(
          'Ease factor must be >= 1.3, got: $easeFactor');
    }

    // Calculate new ease factor
    // Formula: EF' = EF + (0.1 - (5-q) × (0.08 + (5-q) × 0.02))
    double newEaseFactor = easeFactor +
        (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));

    // Ensure ease factor doesn't go below 1.3
    if (newEaseFactor < 1.3) {
      newEaseFactor = 1.3;
    }

    int newRepetitions;
    int newInterval;

    // If quality < 3, reset repetitions and interval
    if (quality < 3) {
      newRepetitions = 0;
      newInterval = 1;
    } else {
      // Increment repetitions
      newRepetitions = repetitions + 1;

      // Calculate new interval based on repetition number
      if (newRepetitions == 1) {
        newInterval = 1;
      } else if (newRepetitions == 2) {
        newInterval = 6;
      } else {
        // For n > 2: I(n) = I(n-1) × EF
        newInterval = (currentInterval * newEaseFactor).ceil();
      }
    }

    // Calculate next review date
    final nextReviewDate = DateTime.now().add(Duration(days: newInterval));

    return SM2Result(
      newInterval: newInterval,
      newRepetitions: newRepetitions,
      newEaseFactor: newEaseFactor,
      nextReviewDate: nextReviewDate,
    );
  }

  /// Get initial SM-2 parameters for a new word
  /// 
  /// Returns: [SM2Result] with default values:
  /// - interval: 1 day
  /// - repetitions: 0
  /// - easeFactor: 2.5
  SM2Result getInitialParameters() {
    return SM2Result(
      newInterval: 1,
      newRepetitions: 0,
      newEaseFactor: 2.5,
      nextReviewDate: DateTime.now().add(const Duration(days: 1)),
    );
  }
}

/// Result of SM-2 algorithm calculation
class SM2Result {
  /// New interval in days until next review
  final int newInterval;

  /// New number of consecutive correct repetitions
  final int newRepetitions;

  /// New ease factor (difficulty multiplier)
  final double newEaseFactor;

  /// Next review date
  final DateTime nextReviewDate;

  const SM2Result({
    required this.newInterval,
    required this.newRepetitions,
    required this.newEaseFactor,
    required this.nextReviewDate,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SM2Result &&
          runtimeType == other.runtimeType &&
          newInterval == other.newInterval &&
          newRepetitions == other.newRepetitions &&
          (newEaseFactor - other.newEaseFactor).abs() < 0.001 &&
          nextReviewDate.difference(other.nextReviewDate).inSeconds.abs() < 1;

  @override
  int get hashCode => Object.hash(
        newInterval,
        newRepetitions,
        newEaseFactor,
        nextReviewDate,
      );

  @override
  String toString() {
    return 'SM2Result(interval: $newInterval days, repetitions: $newRepetitions, '
        'easeFactor: ${newEaseFactor.toStringAsFixed(2)}, '
        'nextReview: ${nextReviewDate.toIso8601String()})';
  }
}
