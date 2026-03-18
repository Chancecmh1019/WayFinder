import 'package:hive/hive.dart';

part 'learning_session_model.g.dart';

/// Hive model for persisting learning session state
@HiveType(typeId: 20)
class LearningSessionModel extends HiveObject {
  /// Session ID for tracking
  @HiveField(0)
  final String sessionId;

  /// Session start time
  @HiveField(1)
  final DateTime startTime;

  /// Session end time (null if session is active)
  @HiveField(2)
  final DateTime? endTime;

  /// Whether the session is active
  @HiveField(3)
  final bool isActive;

  /// Daily goal for this session
  @HiveField(4)
  final int dailyGoal;

  /// Number of items completed in this session
  @HiveField(5)
  final int completedCount;

  /// Total number of items in the session
  @HiveField(6)
  final int totalCount;

  /// Queue of learning items (stored as word IDs and types)
  @HiveField(7)
  final List<LearningItemModel> queue;

  /// Current item index in the queue
  @HiveField(8)
  final int? currentItemIndex;

  /// Session statistics
  @HiveField(9)
  final SessionStatisticsModel statistics;

  /// Time spent on current item (in milliseconds)
  @HiveField(10)
  final int currentItemTimeMs;

  LearningSessionModel({
    required this.sessionId,
    required this.startTime,
    this.endTime,
    required this.isActive,
    required this.dailyGoal,
    required this.completedCount,
    required this.totalCount,
    required this.queue,
    this.currentItemIndex,
    required this.statistics,
    this.currentItemTimeMs = 0,
  });

  /// Create a copy with updated fields
  LearningSessionModel copyWith({
    String? sessionId,
    DateTime? startTime,
    DateTime? endTime,
    bool? isActive,
    int? dailyGoal,
    int? completedCount,
    int? totalCount,
    List<LearningItemModel>? queue,
    int? currentItemIndex,
    SessionStatisticsModel? statistics,
    int? currentItemTimeMs,
  }) {
    return LearningSessionModel(
      sessionId: sessionId ?? this.sessionId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isActive: isActive ?? this.isActive,
      dailyGoal: dailyGoal ?? this.dailyGoal,
      completedCount: completedCount ?? this.completedCount,
      totalCount: totalCount ?? this.totalCount,
      queue: queue ?? this.queue,
      currentItemIndex: currentItemIndex ?? this.currentItemIndex,
      statistics: statistics ?? this.statistics,
      currentItemTimeMs: currentItemTimeMs ?? this.currentItemTimeMs,
    );
  }
}

/// Model for a learning item in the queue
@HiveType(typeId: 21)
class LearningItemModel {
  /// Word being learned
  @HiveField(0)
  final String word;

  /// Whether this is a new word (true) or a review (false)
  @HiveField(1)
  final bool isNewWord;

  LearningItemModel({
    required this.word,
    required this.isNewWord,
  });
}

/// Model for session statistics
@HiveType(typeId: 22)
class SessionStatisticsModel {
  /// Total number of reviews in this session
  @HiveField(0)
  final int totalReviews;

  /// Number of correct reviews
  @HiveField(1)
  final int correctReviews;

  /// Number of new words learned
  @HiveField(2)
  final int newWordsCount;

  /// Total time spent (in milliseconds)
  @HiveField(3)
  final int totalTimeMs;

  /// Distribution of question types (question type -> count)
  @HiveField(4)
  final Map<String, int> questionTypeDistribution;

  SessionStatisticsModel({
    required this.totalReviews,
    required this.correctReviews,
    required this.newWordsCount,
    required this.totalTimeMs,
    required this.questionTypeDistribution,
  });

  /// Create an empty statistics model
  factory SessionStatisticsModel.empty() {
    return SessionStatisticsModel(
      totalReviews: 0,
      correctReviews: 0,
      newWordsCount: 0,
      totalTimeMs: 0,
      questionTypeDistribution: {},
    );
  }

  /// Create a copy with updated fields
  SessionStatisticsModel copyWith({
    int? totalReviews,
    int? correctReviews,
    int? newWordsCount,
    int? totalTimeMs,
    Map<String, int>? questionTypeDistribution,
  }) {
    return SessionStatisticsModel(
      totalReviews: totalReviews ?? this.totalReviews,
      correctReviews: correctReviews ?? this.correctReviews,
      newWordsCount: newWordsCount ?? this.newWordsCount,
      totalTimeMs: totalTimeMs ?? this.totalTimeMs,
      questionTypeDistribution: questionTypeDistribution ?? this.questionTypeDistribution,
    );
  }
}
