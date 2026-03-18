import 'package:hive/hive.dart';
import 'review_history_model.dart';

part 'learning_progress_model.g.dart';

@HiveType(typeId: 1)
class LearningProgressModel extends HiveObject {
  @HiveField(0)
  final String userId;

  @HiveField(1)
  final String word;

  @HiveField(2)
  final int repetitions;

  @HiveField(3)
  final int interval;

  @HiveField(4)
  final double easeFactor;

  @HiveField(5)
  final DateTime nextReviewDate;

  @HiveField(6)
  final DateTime lastReviewDate;

  @HiveField(7)
  final int proficiencyLevel; // 0-5

  @HiveField(8)
  final List<ReviewHistoryModel> history;

  @HiveField(9)
  final DateTime updatedAt;

  LearningProgressModel({
    required this.userId,
    required this.word,
    required this.repetitions,
    required this.interval,
    required this.easeFactor,
    required this.nextReviewDate,
    required this.lastReviewDate,
    required this.proficiencyLevel,
    required this.history,
    required this.updatedAt,
  });

  /// Create initial progress for a new word
  factory LearningProgressModel.initial({
    required String userId,
    required String word,
  }) {
    final now = DateTime.now();
    return LearningProgressModel(
      userId: userId,
      word: word,
      repetitions: 0,
      interval: 1,
      easeFactor: 2.5,
      nextReviewDate: now.add(const Duration(days: 1)),
      lastReviewDate: now,
      proficiencyLevel: 0,
      history: [],
      updatedAt: now,
    );
  }

  /// Create updated progress after a review
  LearningProgressModel copyWith({
    String? userId,
    String? word,
    int? repetitions,
    int? interval,
    double? easeFactor,
    DateTime? nextReviewDate,
    DateTime? lastReviewDate,
    int? proficiencyLevel,
    List<ReviewHistoryModel>? history,
    DateTime? updatedAt,
  }) {
    return LearningProgressModel(
      userId: userId ?? this.userId,
      word: word ?? this.word,
      repetitions: repetitions ?? this.repetitions,
      interval: interval ?? this.interval,
      easeFactor: easeFactor ?? this.easeFactor,
      nextReviewDate: nextReviewDate ?? this.nextReviewDate,
      lastReviewDate: lastReviewDate ?? this.lastReviewDate,
      proficiencyLevel: proficiencyLevel ?? this.proficiencyLevel,
      history: history ?? this.history,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isDue => DateTime.now().isAfter(nextReviewDate);

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'word': word,
      'repetitions': repetitions,
      'interval': interval,
      'easeFactor': easeFactor,
      'nextReviewDate': nextReviewDate.toIso8601String(),
      'lastReviewDate': lastReviewDate.toIso8601String(),
      'proficiencyLevel': proficiencyLevel,
      'history': history.map((e) => e.toJson()).toList(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory LearningProgressModel.fromJson(Map<String, dynamic> json) {
    return LearningProgressModel(
      userId: json['userId'] as String,
      word: json['word'] as String,
      repetitions: json['repetitions'] as int,
      interval: json['interval'] as int,
      easeFactor: (json['easeFactor'] as num).toDouble(),
      nextReviewDate: DateTime.parse(json['nextReviewDate'] as String),
      lastReviewDate: DateTime.parse(json['lastReviewDate'] as String),
      proficiencyLevel: json['proficiencyLevel'] as int,
      history: (json['history'] as List<dynamic>)
          .map((e) => ReviewHistoryModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
