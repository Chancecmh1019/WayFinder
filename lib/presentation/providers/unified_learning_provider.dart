import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/models/fsrs_card_model.dart';
import '../../data/models/fsrs_daily_stats_model.dart';
import '../../data/models/fsrs_review_log_model.dart';
import '../../domain/services/fsrs_algorithm.dart';
import '../../domain/usecases/unified_learning_usecase.dart';
import 'settings_provider.dart';

// ═══════════════════════════════════════════════════════════
// Providers for Hive boxes
// ═══════════════════════════════════════════════════════════

final unifiedCardsBoxProvider = FutureProvider<Box<FSRSCardModel>>((ref) async {
  return await Hive.openBox<FSRSCardModel>('fsrs_cards');
});

final unifiedReviewLogsBoxProvider = FutureProvider<Box<FSRSReviewLogModel>>((ref) async {
  return await Hive.openBox<FSRSReviewLogModel>('fsrs_review_logs');
});

final unifiedDailyStatsBoxProvider = FutureProvider<Box<FSRSDailyStatsModel>>((ref) async {
  return await Hive.openBox<FSRSDailyStatsModel>('fsrs_daily_stats');
});

// ═══════════════════════════════════════════════════════════
// Unified Learning Use Case Provider
// ═══════════════════════════════════════════════════════════

final unifiedLearningUseCaseProvider = Provider<UnifiedLearningUseCase?>((ref) {
  final cardsBox = ref.watch(unifiedCardsBoxProvider).value;
  final reviewLogsBox = ref.watch(unifiedReviewLogsBoxProvider).value;
  final dailyStatsBox = ref.watch(unifiedDailyStatsBoxProvider).value;

  if (cardsBox == null || reviewLogsBox == null || dailyStatsBox == null) {
    return null;
  }

  return UnifiedLearningUseCase(
    cardsBox: cardsBox,
    reviewLogsBox: reviewLogsBox,
    dailyStatsBox: dailyStatsBox,
    algorithm: FSRSAlgorithm(),
  );
});

// ═══════════════════════════════════════════════════════════
// 首頁統計 Providers
// ═══════════════════════════════════════════════════════════

/// 刷新觸發器
final unifiedStatsRefreshProvider = StateProvider<int>((ref) => 0);

/// 今天剩餘可學習的新單字數量
final remainingNewCardsProvider = Provider<int>((ref) {
  // 監聽刷新觸發器
  ref.watch(unifiedStatsRefreshProvider);
  
  final useCase = ref.watch(unifiedLearningUseCaseProvider);
  final dailyGoal = ref.watch(dailyGoalProvider);
  
  if (useCase == null) {
    return dailyGoal;
  }
  
  return useCase.getRemainingNewCardsToday('local_user', dailyGoal);
});

/// 今天需要複習的卡片數量
final dueReviewsCountProvider = Provider<int>((ref) {
  // 監聽刷新觸發器
  ref.watch(unifiedStatsRefreshProvider);
  
  final useCase = ref.watch(unifiedLearningUseCaseProvider);
  
  if (useCase == null) {
    return 0;
  }
  
  return useCase.getDueReviewsCount('local_user');
});

/// 連續學習天數
final currentStreakProvider = Provider<int>((ref) {
  // 監聽刷新觸發器
  ref.watch(unifiedStatsRefreshProvider);
  
  final useCase = ref.watch(unifiedLearningUseCaseProvider);
  
  if (useCase == null) {
    return 0;
  }
  
  return useCase.getCurrentStreak('local_user');
});

/// 今天的統計數據
final todayStatsProvider = Provider<FSRSDailyStatsModel?>((ref) {
  // 監聽刷新觸發器
  ref.watch(unifiedStatsRefreshProvider);
  
  final useCase = ref.watch(unifiedLearningUseCaseProvider);
  
  if (useCase == null) {
    return null;
  }
  
  return useCase.getTodayStats('local_user');
});

// ═══════════════════════════════════════════════════════════
// 學習會話 State 和 Notifier
// ═══════════════════════════════════════════════════════════

/// 學習模式類型
enum LearningMode {
  flashcard,      // 翻卡模式（預設）
  recognition,    // 識別（看英文選中文）
  reverse,        // 反向（看中文選英文）
  fillBlank,      // 填空
  spelling,       // 拼寫
  distinguish,    // 辨析（相似詞辨析）
}

extension LearningModeExtension on LearningMode {
  String get displayName {
    switch (this) {
      case LearningMode.flashcard:
        return '翻卡複習';
      case LearningMode.recognition:
        return '識別測驗';
      case LearningMode.reverse:
        return '反向測驗';
      case LearningMode.fillBlank:
        return '填空練習';
      case LearningMode.spelling:
        return '拼寫練習';
      case LearningMode.distinguish:
        return '辨析練習';
    }
  }

  String get description {
    switch (this) {
      case LearningMode.flashcard:
        return '看單字，翻卡查看釋義';
      case LearningMode.recognition:
        return '看英文單字，選擇正確的中文釋義';
      case LearningMode.reverse:
        return '看中文釋義，選擇正確的英文單字';
      case LearningMode.fillBlank:
        return '根據例句和釋義，填入正確的單字';
      case LearningMode.spelling:
        return '聽發音或看釋義，拼寫出完整單字';
      case LearningMode.distinguish:
        return '辨析相似單字的差異';
    }
  }
}

/// 學習會話狀態
class UnifiedLearningState {
  final List<FSRSCardModel> queue;
  final int currentIndex;
  final bool isLoading;
  final String? error;
  final LearningMode mode;
  final int completedCount;
  final int correctCount;

  const UnifiedLearningState({
    this.queue = const [],
    this.currentIndex = 0,
    this.isLoading = false,
    this.error,
    this.mode = LearningMode.flashcard,
    this.completedCount = 0,
    this.correctCount = 0,
  });

  FSRSCardModel? get currentCard =>
      currentIndex < queue.length ? queue[currentIndex] : null;

  bool get hasMore => currentIndex < queue.length;

  int get remaining => queue.length - currentIndex;

  double get progress =>
      queue.isEmpty ? 0.0 : currentIndex / queue.length;

  double get accuracy =>
      completedCount > 0 ? correctCount / completedCount : 0.0;

  UnifiedLearningState copyWith({
    List<FSRSCardModel>? queue,
    int? currentIndex,
    bool? isLoading,
    String? error,
    LearningMode? mode,
    int? completedCount,
    int? correctCount,
  }) {
    return UnifiedLearningState(
      queue: queue ?? this.queue,
      currentIndex: currentIndex ?? this.currentIndex,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      mode: mode ?? this.mode,
      completedCount: completedCount ?? this.completedCount,
      correctCount: correctCount ?? this.correctCount,
    );
  }
}

/// 學習會話 Notifier
class UnifiedLearningNotifier extends StateNotifier<UnifiedLearningState> {
  final UnifiedLearningUseCase _useCase;
  final String _userId;
  final int _dailyGoal;
  final Ref _ref;

  UnifiedLearningNotifier({
    required UnifiedLearningUseCase useCase,
    required String userId,
    required int dailyGoal,
    required Ref ref,
  })  : _useCase = useCase,
        _userId = userId,
        _dailyGoal = dailyGoal,
        _ref = ref,
        super(const UnifiedLearningState());

  /// 初始化學習會話
  Future<void> initialize({LearningMode mode = LearningMode.flashcard}) async {
    state = state.copyWith(isLoading: true, error: null, mode: mode);

    try {
      // 獲取學習隊列
      final queue = _useCase.getLearningQueue(
        userId: _userId,
        dailyGoal: _dailyGoal,
      );

      state = state.copyWith(
        queue: queue,
        currentIndex: 0,
        isLoading: false,
        completedCount: 0,
        correctCount: 0,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// 提交複習結果
  Future<void> submitReview({
    required FSRSRating rating,
    bool isCorrect = true,
    int? reviewTimeSeconds,
  }) async {
    final currentCard = state.currentCard;
    if (currentCard == null) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      // 提交複習
      await _useCase.submitReview(
        card: currentCard,
        rating: rating,
        reviewTimeSeconds: reviewTimeSeconds,
      );

      // 更新統計
      state = state.copyWith(
        currentIndex: state.currentIndex + 1,
        isLoading: false,
        completedCount: state.completedCount + 1,
        correctCount: state.correctCount + (isCorrect ? 1 : 0),
      );

      // 如果完成所有卡片，觸發刷新
      if (!state.hasMore) {
        _ref.read(unifiedStatsRefreshProvider.notifier).state++;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// 跳過當前卡片
  void skipCard() {
    if (state.hasMore) {
      state = state.copyWith(currentIndex: state.currentIndex + 1);
    }
  }

  /// 重置會話
  void reset() {
    state = const UnifiedLearningState();
  }

  /// 切換學習模式
  Future<void> changeMode(LearningMode mode) async {
    await initialize(mode: mode);
  }
}

/// 學習會話 Provider
final unifiedLearningProvider = StateNotifierProvider.family<
    UnifiedLearningNotifier,
    UnifiedLearningState,
    String>((ref, userId) {
  final useCase = ref.watch(unifiedLearningUseCaseProvider);
  final dailyGoal = ref.watch(dailyGoalProvider);

  if (useCase == null) {
    throw Exception('Unified learning use case not initialized');
  }

  return UnifiedLearningNotifier(
    useCase: useCase,
    userId: userId,
    dailyGoal: dailyGoal,
    ref: ref,
  );
});
