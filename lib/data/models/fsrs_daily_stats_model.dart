import 'package:hive/hive.dart';

part 'fsrs_daily_stats_model.g.dart';

/// Hive model for daily learning statistics
/// 
/// This stores aggregated statistics for each day to support
/// heatmaps, streak tracking, and progress visualization.
@HiveType(typeId: 42)
class FSRSDailyStatsModel extends HiveObject {
  /// User ID
  @HiveField(0)
  final String userId;

  /// Date (normalized to midnight UTC)
  @HiveField(1)
  final DateTime date;

  /// Number of new cards studied
  @HiveField(2)
  final int newCards;

  /// Number of learning cards reviewed
  @HiveField(3)
  final int learningCards;

  /// Number of review cards reviewed
  @HiveField(4)
  final int reviewCards;

  /// Number of relearning cards reviewed
  @HiveField(5)
  final int relearningCards;

  /// Total reviews done
  @HiveField(6)
  final int totalReviews;

  /// Number of "Again" ratings
  @HiveField(7)
  final int againCount;

  /// Number of "Hard" ratings
  @HiveField(8)
  final int hardCount;

  /// Number of "Good" ratings
  @HiveField(9)
  final int goodCount;

  /// Number of "Easy" ratings
  @HiveField(10)
  final int easyCount;

  /// Total study time in seconds
  @HiveField(11)
  final int studyTimeSeconds;

  /// Number of unique words studied
  @HiveField(12)
  final int uniqueWords;

  /// Number of unique senses studied
  @HiveField(13)
  final int uniqueSenses;

  /// Created timestamp
  @HiveField(14)
  final DateTime createdAt;

  /// Updated timestamp
  @HiveField(15)
  final DateTime updatedAt;

  FSRSDailyStatsModel({
    required this.userId,
    required this.date,
    required this.newCards,
    required this.learningCards,
    required this.reviewCards,
    required this.relearningCards,
    required this.totalReviews,
    required this.againCount,
    required this.hardCount,
    required this.goodCount,
    required this.easyCount,
    required this.studyTimeSeconds,
    required this.uniqueWords,
    required this.uniqueSenses,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create empty stats for a date
  factory FSRSDailyStatsModel.empty({
    required String userId,
    required DateTime date,
  }) {
    final normalizedDate = DateTime.utc(date.year, date.month, date.day);
    final now = DateTime.now();
    return FSRSDailyStatsModel(
      userId: userId,
      date: normalizedDate,
      newCards: 0,
      learningCards: 0,
      reviewCards: 0,
      relearningCards: 0,
      totalReviews: 0,
      againCount: 0,
      hardCount: 0,
      goodCount: 0,
      easyCount: 0,
      studyTimeSeconds: 0,
      uniqueWords: 0,
      uniqueSenses: 0,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Get accuracy rate (0.0 to 1.0)
  double get accuracy {
    if (totalReviews == 0) return 0.0;
    return (goodCount + easyCount) / totalReviews;
  }

  /// Get average study time per review (in seconds)
  double get avgTimePerReview {
    if (totalReviews == 0) return 0.0;
    return studyTimeSeconds / totalReviews;
  }

  /// Check if any studying was done on this day
  bool get hasActivity => totalReviews > 0;

  FSRSDailyStatsModel copyWith({
    String? userId,
    DateTime? date,
    int? newCards,
    int? learningCards,
    int? reviewCards,
    int? relearningCards,
    int? totalReviews,
    int? againCount,
    int? hardCount,
    int? goodCount,
    int? easyCount,
    int? studyTimeSeconds,
    int? uniqueWords,
    int? uniqueSenses,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FSRSDailyStatsModel(
      userId: userId ?? this.userId,
      date: date ?? this.date,
      newCards: newCards ?? this.newCards,
      learningCards: learningCards ?? this.learningCards,
      reviewCards: reviewCards ?? this.reviewCards,
      relearningCards: relearningCards ?? this.relearningCards,
      totalReviews: totalReviews ?? this.totalReviews,
      againCount: againCount ?? this.againCount,
      hardCount: hardCount ?? this.hardCount,
      goodCount: goodCount ?? this.goodCount,
      easyCount: easyCount ?? this.easyCount,
      studyTimeSeconds: studyTimeSeconds ?? this.studyTimeSeconds,
      uniqueWords: uniqueWords ?? this.uniqueWords,
      uniqueSenses: uniqueSenses ?? this.uniqueSenses,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'date': date.toIso8601String(),
      'newCards': newCards,
      'learningCards': learningCards,
      'reviewCards': reviewCards,
      'relearningCards': relearningCards,
      'totalReviews': totalReviews,
      'againCount': againCount,
      'hardCount': hardCount,
      'goodCount': goodCount,
      'easyCount': easyCount,
      'studyTimeSeconds': studyTimeSeconds,
      'uniqueWords': uniqueWords,
      'uniqueSenses': uniqueSenses,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory FSRSDailyStatsModel.fromJson(Map<String, dynamic> json) {
    return FSRSDailyStatsModel(
      userId: json['userId'] as String,
      date: DateTime.parse(json['date'] as String),
      newCards: json['newCards'] as int,
      learningCards: json['learningCards'] as int,
      reviewCards: json['reviewCards'] as int,
      relearningCards: json['relearningCards'] as int,
      totalReviews: json['totalReviews'] as int,
      againCount: json['againCount'] as int,
      hardCount: json['hardCount'] as int,
      goodCount: json['goodCount'] as int,
      easyCount: json['easyCount'] as int,
      studyTimeSeconds: json['studyTimeSeconds'] as int,
      uniqueWords: json['uniqueWords'] as int,
      uniqueSenses: json['uniqueSenses'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
