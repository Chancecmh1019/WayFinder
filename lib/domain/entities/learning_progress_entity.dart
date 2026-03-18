import 'review_history.dart';

/// Learning progress for a specific word using SM-2 algorithm
class LearningProgressEntity {
  final String userId;
  final String word;
  final int repetitions; // Number of consecutive correct reviews
  final int interval; // Days until next review
  final double easeFactor; // SM-2 ease factor (1.3 - 2.5)
  final DateTime nextReviewDate;
  final DateTime lastReviewDate;
  final ProficiencyLevel proficiencyLevel; // 0-5 scale
  final List<ReviewHistory> history;

  const LearningProgressEntity({
    required this.userId,
    required this.word,
    required this.repetitions,
    required this.interval,
    required this.easeFactor,
    required this.nextReviewDate,
    required this.lastReviewDate,
    required this.proficiencyLevel,
    required this.history,
  });

  /// Check if this word is due for review
  bool get isDue => DateTime.now().isAfter(nextReviewDate);

  /// Check if this is a new word (never reviewed)
  bool get isNew => repetitions == 0 && history.isEmpty;

  LearningProgressEntity copyWith({
    String? userId,
    String? word,
    int? repetitions,
    int? interval,
    double? easeFactor,
    DateTime? nextReviewDate,
    DateTime? lastReviewDate,
    ProficiencyLevel? proficiencyLevel,
    List<ReviewHistory>? history,
  }) {
    return LearningProgressEntity(
      userId: userId ?? this.userId,
      word: word ?? this.word,
      repetitions: repetitions ?? this.repetitions,
      interval: interval ?? this.interval,
      easeFactor: easeFactor ?? this.easeFactor,
      nextReviewDate: nextReviewDate ?? this.nextReviewDate,
      lastReviewDate: lastReviewDate ?? this.lastReviewDate,
      proficiencyLevel: proficiencyLevel ?? this.proficiencyLevel,
      history: history ?? this.history,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LearningProgressEntity &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          word == other.word;

  @override
  int get hashCode => Object.hash(userId, word);
}

/// Proficiency level for a word (0-5 scale)
enum ProficiencyLevel {
  beginner(0), // Just learned
  learning(1), // Seen a few times
  familiar(2), // Can recall with effort
  proficient(3), // Can recall easily
  mastered(4), // Fully mastered
  expert(5); // Expert level

  final int value;

  const ProficiencyLevel(this.value);

  static ProficiencyLevel fromValue(int value) {
    return ProficiencyLevel.values.firstWhere(
      (level) => level.value == value,
      orElse: () => ProficiencyLevel.beginner,
    );
  }

  String get displayName {
    switch (this) {
      case ProficiencyLevel.beginner:
        return '初學';
      case ProficiencyLevel.learning:
        return '學習中';
      case ProficiencyLevel.familiar:
        return '熟悉';
      case ProficiencyLevel.proficient:
        return '精通';
      case ProficiencyLevel.mastered:
        return '掌握';
      case ProficiencyLevel.expert:
        return '專家';
    }
  }
}
