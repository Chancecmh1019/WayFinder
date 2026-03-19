import '../../data/models/fsrs_card_model.dart';
import '../../data/models/fsrs_review_log_model.dart';
import '../../data/models/fsrs_daily_stats_model.dart';
import '../services/fsrs_algorithm.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Use case for FSRS learning operations
/// 
/// This handles all FSRS-related business logic including:
/// - Card scheduling and review
/// - Review log creation
/// - Daily statistics tracking
/// - Learning queue management
class FSRSLearningUseCase {
  final FSRSAlgorithm _algorithm;
  final Box<FSRSCardModel> _cardsBox;
  final Box<FSRSReviewLogModel> _reviewLogsBox;
  final Box<FSRSDailyStatsModel> _dailyStatsBox;

  FSRSLearningUseCase({
    FSRSAlgorithm? algorithm,
    required Box<FSRSCardModel> cardsBox,
    required Box<FSRSReviewLogModel> reviewLogsBox,
    required Box<FSRSDailyStatsModel> dailyStatsBox,
  })  : _algorithm = algorithm ?? FSRSAlgorithm(),
        _cardsBox = cardsBox,
        _reviewLogsBox = reviewLogsBox,
        _dailyStatsBox = dailyStatsBox;

  /// Submit a review for a card
  /// 
  /// [card]: The card being reviewed
  /// [rating]: The rating given by the user
  /// [reviewTimeSeconds]: Time taken to review (optional)
  /// 
  /// Returns: Updated card model
  Future<FSRSCardModel> submitReview({
    required FSRSCardModel card,
    required FSRSRating rating,
    int? reviewTimeSeconds,
  }) async {
    final now = DateTime.now();
    
    // 記錄卡片原始狀態（在更新之前）
    final wasNew = card.isNew;
    
    // Calculate elapsed days
    final elapsed = card.lastReview != null
        ? now.difference(card.lastReview!).inDays
        : 0;

    // Get current card state as FSRSCard
    final fsrsCard = card.toFSRSCard();

    // Schedule next review
    final nextCard = _algorithm.next(fsrsCard, rating, now: now);

    // Update card model
    final updatedCard = card.updateFromFSRSCard(nextCard);

    // Save card
    await _cardsBox.put(_getCardKey(card), updatedCard);

    // Create review log
    final reviewLog = FSRSReviewLogModel.fromReview(
      userId: card.userId,
      lemma: card.lemma,
      senseId: card.senseId,
      rating: rating,
      cardBefore: fsrsCard,
      cardAfter: nextCard,
      elapsedDays: elapsed,
      reviewTimeSeconds: reviewTimeSeconds,
    );

    // Save review log
    await _reviewLogsBox.add(reviewLog);

    // Update daily statistics（使用原始狀態）
    await _updateDailyStats(
      userId: card.userId,
      date: now,
      wasNew: wasNew,
      newState: updatedCard.state,
      rating: rating,
      reviewTimeSeconds: reviewTimeSeconds,
    );

    // 本地儲存，無需同步

    return updatedCard;
  }

  /// Get or create a card for a sense
  Future<FSRSCardModel> getOrCreateCard({
    required String userId,
    required String lemma,
    required String senseId,
    required bool isUnlocked,
  }) async {
    final key = _getCardKeyFromParts(userId, lemma, senseId);
    
    var card = _cardsBox.get(key);
    
    if (card == null) {
      card = FSRSCardModel.newCard(
        userId: userId,
        lemma: lemma,
        senseId: senseId,
        isUnlocked: isUnlocked,
      );
      await _cardsBox.put(key, card);
    }

    return card;
  }

  /// Get all cards for a user
  List<FSRSCardModel> getUserCards(String userId) {
    return _cardsBox.values
        .where((card) => card.userId == userId)
        .toList();
  }

  /// Get all cards for a specific word
  List<FSRSCardModel> getWordCards(String userId, String lemma) {
    return _cardsBox.values
        .where((card) => card.userId == userId && card.lemma == lemma)
        .toList();
  }

  /// Get due cards for review
  /// 
  /// [userId]: User ID
  /// [limit]: Maximum number of cards to return
  /// [includeNew]: Whether to include new cards
  /// 
  /// Returns: List of due cards sorted by priority
  List<FSRSCardModel> getDueCards({
    required String userId,
    int? limit,
    bool includeNew = true,
  }) {
    final now = DateTime.now();
    
    var dueCards = _cardsBox.values
        .where((card) =>
            card.userId == userId &&
            card.isUnlocked &&
            (includeNew || !card.isNew) &&
            card.isDue(now: now))
        .toList();

    // Sort by priority:
    // 1. Review cards (by due date, oldest first)
    // 2. Learning/Relearning cards (by due date)
    // 3. New cards
    dueCards.sort((a, b) {
      // Review cards have highest priority
      if (a.isReview && !b.isReview) return -1;
      if (!a.isReview && b.isReview) return 1;

      // Learning cards have medium priority
      if (a.isLearning && b.isNew) return -1;
      if (a.isNew && b.isLearning) return 1;

      // Within same state, sort by due date
      return a.due.compareTo(b.due);
    });

    if (limit != null && dueCards.length > limit) {
      dueCards = dueCards.sublist(0, limit);
    }

    return dueCards;
  }

  /// Get learning queue (cards to study today)
  /// 
  /// [userId]: User ID
  /// [newCardsLimit]: Maximum new cards per day (daily goal)
  /// [reviewCardsLimit]: Maximum review cards per day
  /// 
  /// Returns: Map with 'new' and 'review' card lists
  /// 
  /// 【重點】遵循每日配額邏輯：
  /// - 先獲取需要複習的卡片（根據 FSRS 間隔重複算法）
  /// - 檢查今天已經學習了多少新單字
  /// - 只有當今天的新單字配額還有剩餘時，才添加新單字
  Map<String, List<FSRSCardModel>> getLearningQueue({
    required String userId,
    int newCardsLimit = 20,
    int reviewCardsLimit = 100,
  }) {
    // Get all due cards (excluding new cards initially)
    final allDueCards = getDueCards(userId: userId, includeNew: false);

    // Get review cards (cards that need review based on FSRS algorithm)
    final reviewCards = allDueCards
        .take(reviewCardsLimit)
        .toList();

    // 檢查今天已經學習了多少新單字
    final today = DateTime.now();
    final normalizedToday = DateTime.utc(today.year, today.month, today.day);
    final todayStats = _getDailyStatsForDate(userId, normalizedToday);
    final todayNewCardsCount = todayStats?.newCards ?? 0;
    
    // 計算今天還可以學習多少新單字
    final remainingNewCards = newCardsLimit - todayNewCardsCount;
    
    // 只有當還有配額時才添加新單字
    List<FSRSCardModel> newCards = [];
    if (remainingNewCards > 0) {
      // Get new cards (cards that haven't been studied yet)
      final allNewCards = _cardsBox.values
          .where((card) =>
              card.userId == userId &&
              card.isUnlocked &&
              card.isNew)
          .toList();
      
      // 【重要】按照 createdAt 排序，確保每天學習最早解鎖的單字
      // 這樣可以確保：
      // - 第1天：學習最早的 N 個單字
      // - 第2天：學習接下來的 N 個單字（因為第1天的已經不是 isNew 狀態了）
      // - 以此類推
      allNewCards.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      
      newCards = allNewCards
          .take(remainingNewCards)
          .toList();
    }

    return {
      'new': newCards,
      'review': reviewCards,
    };
  }

  /// Get card statistics for a user
  Map<String, int> getCardStatistics(String userId) {
    final cards = getUserCards(userId);

    return {
      'total': cards.length,
      'new': cards.where((c) => c.isNew).length,
      'learning': cards.where((c) => c.isLearning).length,
      'review': cards.where((c) => c.isReview).length,
      'due': cards.where((c) => c.isDue()).length,
    };
  }

  /// Get daily statistics for a date range
  List<FSRSDailyStatsModel> getDailyStats({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final normalizedStart = DateTime.utc(
      startDate.year,
      startDate.month,
      startDate.day,
    );
    final normalizedEnd = DateTime.utc(
      endDate.year,
      endDate.month,
      endDate.day,
    );

    return _dailyStatsBox.values
        .where((stats) =>
            stats.userId == userId &&
            !stats.date.isBefore(normalizedStart) &&
            !stats.date.isAfter(normalizedEnd))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  /// Get current streak (consecutive days of study)
  int getCurrentStreak(String userId) {
    final today = DateTime.now();
    final normalizedToday = DateTime.utc(today.year, today.month, today.day);
    
    int streak = 0;
    var currentDate = normalizedToday;

    while (true) {
      final stats = _getDailyStatsForDate(userId, currentDate);
      
      if (stats == null || !stats.hasActivity) {
        break;
      }

      streak++;
      currentDate = currentDate.subtract(const Duration(days: 1));
    }

    return streak;
  }

  /// Get longest streak
  int getLongestStreak(String userId) {
    final allStats = _dailyStatsBox.values
        .where((stats) => stats.userId == userId && stats.hasActivity)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    if (allStats.isEmpty) return 0;

    int longestStreak = 1;
    int currentStreak = 1;

    for (int i = 1; i < allStats.length; i++) {
      final daysDiff = allStats[i].date.difference(allStats[i - 1].date).inDays;
      
      if (daysDiff == 1) {
        currentStreak++;
        longestStreak = currentStreak > longestStreak ? currentStreak : longestStreak;
      } else {
        currentStreak = 1;
      }
    }

    return longestStreak;
  }

  /// Update daily statistics
  Future<void> _updateDailyStats({
    required String userId,
    required DateTime date,
    required bool wasNew,
    required int newState,
    required FSRSRating rating,
    int? reviewTimeSeconds,
  }) async {
    final normalizedDate = DateTime.utc(date.year, date.month, date.day);
    final key = _getDailyStatsKey(userId, normalizedDate);
    
    var stats = _dailyStatsBox.get(key) ?? FSRSDailyStatsModel.empty(
      userId: userId,
      date: normalizedDate,
    );

    // Update counters based on card state
    // 使用原始狀態（wasNew）來判斷是否為新卡片
    final updatedStats = stats.copyWith(
      newCards: wasNew ? stats.newCards + 1 : stats.newCards,
      learningCards: newState == CardState.learning.index
          ? stats.learningCards + 1
          : stats.learningCards,
      reviewCards: newState == CardState.review.index
          ? stats.reviewCards + 1
          : stats.reviewCards,
      relearningCards: newState == CardState.relearning.index
          ? stats.relearningCards + 1
          : stats.relearningCards,
      totalReviews: stats.totalReviews + 1,
      againCount: rating == FSRSRating.again ? stats.againCount + 1 : stats.againCount,
      hardCount: rating == FSRSRating.hard ? stats.hardCount + 1 : stats.hardCount,
      goodCount: rating == FSRSRating.good ? stats.goodCount + 1 : stats.goodCount,
      easyCount: rating == FSRSRating.easy ? stats.easyCount + 1 : stats.easyCount,
      studyTimeSeconds: stats.studyTimeSeconds + (reviewTimeSeconds ?? 0),
      updatedAt: DateTime.now(),
    );

    await _dailyStatsBox.put(key, updatedStats);
  }

  /// Get daily stats for a specific date
  FSRSDailyStatsModel? _getDailyStatsForDate(String userId, DateTime date) {
    final key = _getDailyStatsKey(userId, date);
    return _dailyStatsBox.get(key);
  }

  /// Generate card key
  String _getCardKey(FSRSCardModel card) {
    return _getCardKeyFromParts(card.userId, card.lemma, card.senseId);
  }

  /// Generate card key from parts
  String _getCardKeyFromParts(String userId, String lemma, String senseId) {
    return '$userId:$lemma:$senseId';
  }

  /// Generate daily stats key
  String _getDailyStatsKey(String userId, DateTime date) {
    return '$userId:${date.toIso8601String()}';
  }
}
