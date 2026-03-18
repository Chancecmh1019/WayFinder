import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/models/fsrs_card_model.dart';
import '../../data/models/fsrs_review_log_model.dart';
import '../../data/models/fsrs_daily_stats_model.dart';
import '../../data/models/vocab_models_enhanced.dart';
import '../../domain/services/fsrs_algorithm.dart';
import '../../domain/usecases/fsrs_learning_usecase.dart';
import '../../domain/usecases/sense_unlock_usecase.dart';
import '../../core/providers/learning_progress_providers.dart';

/// Provider for FSRS cards box
final fsrsCardsBoxProvider = FutureProvider<Box<FSRSCardModel>>((ref) async {
  return await Hive.openBox<FSRSCardModel>('fsrs_cards');
});

/// Provider for FSRS review logs box
final fsrsReviewLogsBoxProvider = FutureProvider<Box<FSRSReviewLogModel>>((ref) async {
  return await Hive.openBox<FSRSReviewLogModel>('fsrs_review_logs');
});

/// Provider for FSRS daily stats box
final fsrsDailyStatsBoxProvider = FutureProvider<Box<FSRSDailyStatsModel>>((ref) async {
  return await Hive.openBox<FSRSDailyStatsModel>('fsrs_daily_stats');
});

/// Provider for FSRS algorithm
final fsrsAlgorithmProvider = Provider<FSRSAlgorithm>((ref) {
  return FSRSAlgorithm();
});

/// Provider for FSRS learning use case
final fsrsLearningUseCaseProvider = Provider<FSRSLearningUseCase?>((ref) {
  final cardsBox = ref.watch(fsrsCardsBoxProvider).value;
  final reviewLogsBox = ref.watch(fsrsReviewLogsBoxProvider).value;
  final dailyStatsBox = ref.watch(fsrsDailyStatsBoxProvider).value;
  final algorithm = ref.watch(fsrsAlgorithmProvider);

  if (cardsBox == null || reviewLogsBox == null || dailyStatsBox == null) {
    return null;
  }

  return FSRSLearningUseCase(
    algorithm: algorithm,
    cardsBox: cardsBox,
    reviewLogsBox: reviewLogsBox,
    dailyStatsBox: dailyStatsBox,
  );
});

/// Provider for sense unlock use case
final senseUnlockUseCaseProvider = Provider<SenseUnlockUseCase>((ref) {
  return SenseUnlockUseCase();
});

/// State for FSRS learning session
class FSRSLearningState {
  final List<FSRSCardModel> queue;
  final int currentIndex;
  final bool isLoading;
  final String? error;
  final Map<String, int> statistics;
  final int todayReviews;
  final int todayNewCards;

  const FSRSLearningState({
    this.queue = const [],
    this.currentIndex = 0,
    this.isLoading = false,
    this.error,
    this.statistics = const {},
    this.todayReviews = 0,
    this.todayNewCards = 0,
  });

  FSRSCardModel? get currentCard =>
      currentIndex < queue.length ? queue[currentIndex] : null;

  bool get hasMore => currentIndex < queue.length;

  int get remaining => queue.length - currentIndex;

  double get progress =>
      queue.isEmpty ? 0.0 : currentIndex / queue.length;

  FSRSLearningState copyWith({
    List<FSRSCardModel>? queue,
    int? currentIndex,
    bool? isLoading,
    String? error,
    Map<String, int>? statistics,
    int? todayReviews,
    int? todayNewCards,
  }) {
    return FSRSLearningState(
      queue: queue ?? this.queue,
      currentIndex: currentIndex ?? this.currentIndex,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      statistics: statistics ?? this.statistics,
      todayReviews: todayReviews ?? this.todayReviews,
      todayNewCards: todayNewCards ?? this.todayNewCards,
    );
  }
}

/// Notifier for FSRS learning session
class FSRSLearningNotifier extends StateNotifier<FSRSLearningState> {
  final FSRSLearningUseCase _learningUseCase;
  final SenseUnlockUseCase _unlockUseCase;
  final String _userId;
  final Ref _ref;

  FSRSLearningNotifier({
    required FSRSLearningUseCase learningUseCase,
    required SenseUnlockUseCase unlockUseCase,
    required String userId,
    required Ref ref,
  })  : _learningUseCase = learningUseCase,
        _unlockUseCase = unlockUseCase,
        _userId = userId,
        _ref = ref,
        super(const FSRSLearningState());

  /// Initialize learning session
  Future<void> initialize({
    int newCardsLimit = 20,
    int reviewCardsLimit = 100,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Get learning queue
      final queue = _learningUseCase.getLearningQueue(
        userId: _userId,
        newCardsLimit: newCardsLimit,
        reviewCardsLimit: reviewCardsLimit,
      );

      final allCards = [...queue['new']!, ...queue['review']!];

      // Get statistics
      final stats = _learningUseCase.getCardStatistics(_userId);

      // Get today's stats
      final today = DateTime.now();
      final todayStats = _learningUseCase.getDailyStats(
        userId: _userId,
        startDate: today,
        endDate: today,
      );

      state = state.copyWith(
        queue: allCards,
        currentIndex: 0,
        isLoading: false,
        statistics: stats,
        todayReviews: todayStats.isNotEmpty ? todayStats.first.totalReviews : 0,
        todayNewCards: todayStats.isNotEmpty ? todayStats.first.newCards : 0,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Submit a review
  Future<void> submitReview({
    required FSRSRating rating,
    int? reviewTimeSeconds,
  }) async {
    final currentCard = state.currentCard;
    if (currentCard == null) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      // Submit review (本地儲存，無需同步)
      await _learningUseCase.submitReview(
        card: currentCard,
        rating: rating,
        reviewTimeSeconds: reviewTimeSeconds,
      );

      // Mark word as learned in learning progress tracking
      // This happens after a successful review
      try {
        await _ref.read(markWordAsLearnedProvider((
          userId: _userId,
          lemma: currentCard.lemma,
        )).future);
      } catch (e) {
        // Silently fail - learning progress tracking is not critical
        // Error: $e
      }

      // Move to next card
      state = state.copyWith(
        currentIndex: state.currentIndex + 1,
        isLoading: false,
        todayReviews: state.todayReviews + 1,
        todayNewCards: currentCard.isNew
            ? state.todayNewCards + 1
            : state.todayNewCards,
      );

      // Refresh statistics
      final stats = _learningUseCase.getCardStatistics(_userId);
      state = state.copyWith(statistics: stats);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Get scheduling info for current card
  SchedulingInfo? getSchedulingInfo() {
    final currentCard = state.currentCard;
    if (currentCard == null) return null;

    final fsrsCard = currentCard.toFSRSCard();
    final algorithm = FSRSAlgorithm();
    
    return algorithm.schedule(fsrsCard);
  }

  /// Skip current card
  void skipCard() {
    if (state.hasMore) {
      state = state.copyWith(currentIndex: state.currentIndex + 1);
    }
  }

  /// Reset session
  void reset() {
    state = const FSRSLearningState();
  }

  /// Get or create cards for a word entry
  Future<List<FSRSCardModel>> getOrCreateCardsForEntry(
    VocabEntryModel entry,
  ) async {
    final existingCards = _learningUseCase.getWordCards(_userId, entry.lemma);
    
    // Determine which senses should be unlocked
    final unlockedSenseIds = _unlockUseCase.determineUnlockedSenses(
      entry,
      existingCards,
    );

    final cards = <FSRSCardModel>[];

    for (final sense in entry.senses) {
      final isUnlocked = unlockedSenseIds.contains(sense.senseId);
      
      final card = await _learningUseCase.getOrCreateCard(
        userId: _userId,
        lemma: entry.lemma,
        senseId: sense.senseId,
        isUnlocked: isUnlocked,
      );

      cards.add(card);
    }

    return cards;
  }

  /// Check and unlock next sense if conditions are met
  Future<bool> checkAndUnlockNextSense(
    VocabEntryModel entry,
    String justReviewedSenseId,
  ) async {
    final cards = _learningUseCase.getWordCards(_userId, entry.lemma);
    
    final shouldUnlock = _unlockUseCase.shouldAutoUnlock(
      entry,
      cards,
      justReviewedSenseId,
    );

    if (shouldUnlock) {
      final nextSenseId = _unlockUseCase.getNextSenseToUnlock(entry, cards);
      
      if (nextSenseId != null) {
        // Unlock the next sense
        await _learningUseCase.getOrCreateCard(
          userId: _userId,
          lemma: entry.lemma,
          senseId: nextSenseId,
          isUnlocked: true,
        );
        
        return true;
      }
    }

    return false;
  }

  /// Get unlock progress for a word
  Map<String, dynamic> getUnlockProgress(
    VocabEntryModel entry,
  ) {
    final cards = _learningUseCase.getWordCards(_userId, entry.lemma);
    return _unlockUseCase.getUnlockProgress(entry, cards);
  }

  /// Get unlock hint for a word
  String getUnlockHint(VocabEntryModel entry) {
    final cards = _learningUseCase.getWordCards(_userId, entry.lemma);
    return _unlockUseCase.getUnlockHint(entry, cards);
  }
}

/// Provider for FSRS learning notifier
final fsrsLearningProvider = StateNotifierProvider.family<
    FSRSLearningNotifier,
    FSRSLearningState,
    String>((ref, userId) {
  final learningUseCase = ref.watch(fsrsLearningUseCaseProvider);
  final unlockUseCase = ref.watch(senseUnlockUseCaseProvider);

  if (learningUseCase == null) {
    throw Exception('FSRS learning use case not initialized');
  }

  return FSRSLearningNotifier(
    learningUseCase: learningUseCase,
    unlockUseCase: unlockUseCase,
    userId: userId,
    ref: ref,
  );
});

/// Provider for card statistics
final cardStatisticsProvider = Provider.family<Map<String, int>, String>((ref, userId) {
  final learningUseCase = ref.watch(fsrsLearningUseCaseProvider);
  
  if (learningUseCase == null) {
    return {};
  }

  return learningUseCase.getCardStatistics(userId);
});

/// Provider for current streak
final currentStreakProvider = Provider.family<int, String>((ref, userId) {
  final learningUseCase = ref.watch(fsrsLearningUseCaseProvider);
  
  if (learningUseCase == null) {
    return 0;
  }

  return learningUseCase.getCurrentStreak(userId);
});

/// Provider for longest streak
final longestStreakProvider = Provider.family<int, String>((ref, userId) {
  final learningUseCase = ref.watch(fsrsLearningUseCaseProvider);
  
  if (learningUseCase == null) {
    return 0;
  }

  return learningUseCase.getLongestStreak(userId);
});

/// Provider for daily stats in a date range
final dailyStatsRangeProvider = Provider.family<
    List<FSRSDailyStatsModel>,
    ({String userId, DateTime startDate, DateTime endDate})>((ref, params) {
  final learningUseCase = ref.watch(fsrsLearningUseCaseProvider);
  
  if (learningUseCase == null) {
    return [];
  }

  return learningUseCase.getDailyStats(
    userId: params.userId,
    startDate: params.startDate,
    endDate: params.endDate,
  );
});
