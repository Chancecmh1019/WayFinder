/// Record of a single review session for a word
class ReviewHistory {
  final DateTime reviewDate;
  final int quality; // SM-2 quality rating (0-5)
  final Duration timeSpent;
  final String questionType;
  final bool correct;

  const ReviewHistory({
    required this.reviewDate,
    required this.quality,
    required this.timeSpent,
    required this.questionType,
    required this.correct,
  });

  ReviewHistory copyWith({
    DateTime? reviewDate,
    int? quality,
    Duration? timeSpent,
    String? questionType,
    bool? correct,
  }) {
    return ReviewHistory(
      reviewDate: reviewDate ?? this.reviewDate,
      quality: quality ?? this.quality,
      timeSpent: timeSpent ?? this.timeSpent,
      questionType: questionType ?? this.questionType,
      correct: correct ?? this.correct,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReviewHistory &&
          runtimeType == other.runtimeType &&
          reviewDate == other.reviewDate &&
          quality == other.quality &&
          questionType == other.questionType;

  @override
  int get hashCode => Object.hash(reviewDate, quality, questionType);
}
