import '../../domain/entities/entities.dart';
import '../../domain/usecases/get_next_item_usecase.dart';

/// State for a learning session
class LearningSessionState {
  /// Queue of learning items (reviews + new words)
  final List<LearningItem> queue;

  /// Current item being studied
  final LearningItem? currentItem;

  /// Current question for the current item
  final QuizQuestion? currentQuestion;

  /// Number of items completed in this session
  final int completedCount;

  /// Total number of items in the session
  final int totalCount;

  /// Session statistics
  final SessionStatistics statistics;

  /// Whether the session is currently loading
  final bool isLoading;

  /// Error message if any
  final String? error;

  /// Session ID for tracking
  final String? sessionId;

  /// Session start time
  final DateTime? startTime;

  /// Session end time
  final DateTime? endTime;

  /// Whether the session is active
  final bool isActive;

  /// Daily goal for this session
  final int dailyGoal;

  const LearningSessionState({
    required this.queue,
    this.currentItem,
    this.currentQuestion,
    this.completedCount = 0,
    this.totalCount = 0,
    this.statistics = const SessionStatistics(
      totalReviews: 0,
      correctReviews: 0,
      newWordsCount: 0,
      totalTime: Duration.zero,
      questionTypeDistribution: {},
    ),
    this.isLoading = false,
    this.error,
    this.sessionId,
    this.startTime,
    this.endTime,
    this.isActive = false,
    this.dailyGoal = 30, // 修正預設值為 30
  });

  /// Check if session has items
  bool get hasItems => queue.isNotEmpty;

  /// Check if session is complete
  bool get isComplete => completedCount >= totalCount && totalCount > 0;

  /// Check if daily goal is met
  bool get isGoalMet => completedCount >= dailyGoal;

  /// Get progress percentage (0-100)
  double get progressPercentage {
    if (totalCount == 0) return 0.0;
    return (completedCount / totalCount) * 100;
  }

  /// Get remaining items count
  int get remainingCount => totalCount - completedCount;

  /// Check if there's a current item
  bool get hasCurrentItem => currentItem != null;

  /// Check if there's a current question
  bool get hasCurrentQuestion => currentQuestion != null;

  /// Initial state for a new session
  factory LearningSessionState.initial() {
    return const LearningSessionState(
      queue: [],
      currentItem: null,
      currentQuestion: null,
      completedCount: 0,
      totalCount: 0,
      statistics: SessionStatistics(
        totalReviews: 0,
        correctReviews: 0,
        newWordsCount: 0,
        totalTime: Duration.zero,
        questionTypeDistribution: {},
      ),
      isLoading: false,
      error: null,
      sessionId: null,
      startTime: null,
      endTime: null,
      isActive: false,
      dailyGoal: 20,
    );
  }

  /// Create a copy with updated fields
  LearningSessionState copyWith({
    List<LearningItem>? queue,
    LearningItem? currentItem,
    QuizQuestion? currentQuestion,
    int? completedCount,
    int? totalCount,
    SessionStatistics? statistics,
    bool? isLoading,
    String? error,
    String? sessionId,
    DateTime? startTime,
    DateTime? endTime,
    bool? isActive,
    int? dailyGoal,
  }) {
    return LearningSessionState(
      queue: queue ?? this.queue,
      currentItem: currentItem ?? this.currentItem,
      currentQuestion: currentQuestion ?? this.currentQuestion,
      completedCount: completedCount ?? this.completedCount,
      totalCount: totalCount ?? this.totalCount,
      statistics: statistics ?? this.statistics,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      sessionId: sessionId ?? this.sessionId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isActive: isActive ?? this.isActive,
      dailyGoal: dailyGoal ?? this.dailyGoal,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LearningSessionState &&
          runtimeType == other.runtimeType &&
          sessionId == other.sessionId &&
          completedCount == other.completedCount &&
          totalCount == other.totalCount &&
          isActive == other.isActive;

  @override
  int get hashCode => Object.hash(
        sessionId,
        completedCount,
        totalCount,
        isActive,
      );
}
