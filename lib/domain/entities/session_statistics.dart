/// Statistics for a learning session
class SessionStatistics {
  final int totalReviews;
  final int correctReviews;
  final int newWordsCount;
  final Duration totalTime;
  final Map<String, int> questionTypeDistribution;

  const SessionStatistics({
    required this.totalReviews,
    required this.correctReviews,
    required this.newWordsCount,
    required this.totalTime,
    required this.questionTypeDistribution,
  });

  /// Calculate accuracy percentage
  double get accuracy {
    if (totalReviews == 0) return 0.0;
    return (correctReviews / totalReviews) * 100;
  }

  /// Calculate average time per review
  Duration get averageTimePerReview {
    if (totalReviews == 0) return Duration.zero;
    return Duration(
      milliseconds: totalTime.inMilliseconds ~/ totalReviews,
    );
  }

  /// Empty statistics for initialization
  factory SessionStatistics.empty() {
    return const SessionStatistics(
      totalReviews: 0,
      correctReviews: 0,
      newWordsCount: 0,
      totalTime: Duration.zero,
      questionTypeDistribution: {},
    );
  }

  SessionStatistics copyWith({
    int? totalReviews,
    int? correctReviews,
    int? newWordsCount,
    Duration? totalTime,
    Map<String, int>? questionTypeDistribution,
  }) {
    return SessionStatistics(
      totalReviews: totalReviews ?? this.totalReviews,
      correctReviews: correctReviews ?? this.correctReviews,
      newWordsCount: newWordsCount ?? this.newWordsCount,
      totalTime: totalTime ?? this.totalTime,
      questionTypeDistribution:
          questionTypeDistribution ?? this.questionTypeDistribution,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SessionStatistics &&
          runtimeType == other.runtimeType &&
          totalReviews == other.totalReviews &&
          correctReviews == other.correctReviews &&
          newWordsCount == other.newWordsCount &&
          totalTime == other.totalTime;

  @override
  int get hashCode => Object.hash(
        totalReviews,
        correctReviews,
        newWordsCount,
        totalTime,
      );
}
