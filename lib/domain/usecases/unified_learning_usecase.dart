import 'package:hive_flutter/hive_flutter.dart';
import '../../data/models/fsrs_card_model.dart';
import '../../data/models/fsrs_daily_stats_model.dart';
import '../../data/models/fsrs_review_log_model.dart';
import '../services/fsrs_algorithm.dart';

/// 統一學習用例
/// 
/// 整合所有學習相關功能：
/// - 新單字學習
/// - 複習
/// - 測驗模式（識別、反向、填空、拼寫、辨析）
/// - 每日統計
class UnifiedLearningUseCase {
  final Box<FSRSCardModel> _cardsBox;
  final Box<FSRSReviewLogModel> _reviewLogsBox;
  final Box<FSRSDailyStatsModel> _dailyStatsBox;
  final FSRSAlgorithm _algorithm;

  UnifiedLearningUseCase({
    required Box<FSRSCardModel> cardsBox,
    required Box<FSRSReviewLogModel> reviewLogsBox,
    required Box<FSRSDailyStatsModel> dailyStatsBox,
    FSRSAlgorithm? algorithm,
  })  : _cardsBox = cardsBox,
        _reviewLogsBox = reviewLogsBox,
        _dailyStatsBox = dailyStatsBox,
        _algorithm = algorithm ?? FSRSAlgorithm();

  // ═══════════════════════════════════════════════════════════
  // 每日統計相關
  // ═══════════════════════════════════════════════════════════

  /// 獲取今天的統計數據
  FSRSDailyStatsModel getTodayStats(String userId) {
    final today = _normalizeDate(DateTime.now());
    final key = _getDailyStatsKey(userId, today);
    return _dailyStatsBox.get(key) ?? FSRSDailyStatsModel.empty(
      userId: userId,
      date: today,
    );
  }

  /// 獲取今天已學習的新單字數量
  int getTodayNewCardsCount(String userId) {
    return getTodayStats(userId).newCards;
  }

  /// 獲取今天剩餘可學習的新單字數量
  int getRemainingNewCardsToday(String userId, int dailyGoal) {
    final learned = getTodayNewCardsCount(userId);
    final remaining = dailyGoal - learned;
    return remaining > 0 ? remaining : 0;
  }

  /// 獲取今天需要複習的卡片數量
  int getDueReviewsCount(String userId) {
    final now = DateTime.now();
    return _cardsBox.values
        .where((card) =>
            card.userId == userId &&
            !card.isNew &&
            card.isDue(now: now))
        .length;
  }

  // ═══════════════════════════════════════════════════════════
  // 學習隊列相關
  // ═══════════════════════════════════════════════════════════

  /// 獲取學習隊列
  /// 
  /// 返回今天可以學習的卡片列表
  /// 優先順序：複習卡片 > 新卡片
  List<FSRSCardModel> getLearningQueue({
    required String userId,
    required int dailyGoal,
  }) {
    final queue = <FSRSCardModel>[];
    
    // 1. 獲取需要複習的卡片
    final reviewCards = _getReviewCards(userId);
    queue.addAll(reviewCards);
    
    // 2. 獲取新卡片（根據今日配額）
    final remainingNewCards = getRemainingNewCardsToday(userId, dailyGoal);
    if (remainingNewCards > 0) {
      final newCards = _getNewCards(userId, limit: remainingNewCards);
      queue.addAll(newCards);
    }
    
    return queue;
  }

  /// 獲取需要複習的卡片
  List<FSRSCardModel> _getReviewCards(String userId) {
    final now = DateTime.now();
    final reviewCards = _cardsBox.values
        .where((card) =>
            card.userId == userId &&
            !card.isNew &&
            card.isDue(now: now))
        .toList();
    
    // 按到期時間排序（最早到期的優先）
    reviewCards.sort((a, b) => a.due.compareTo(b.due));
    
    return reviewCards;
  }

  /// 獲取新卡片
  List<FSRSCardModel> _getNewCards(String userId, {required int limit}) {
    final newCards = _cardsBox.values
        .where((card) =>
            card.userId == userId &&
            card.isUnlocked &&
            card.isNew)
        .toList();
    
    // 【重要】按照 createdAt 排序，確保每天學習最早解鎖的單字
    newCards.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    
    return newCards.take(limit).toList();
  }

  // ═══════════════════════════════════════════════════════════
  // 卡片操作相關
  // ═══════════════════════════════════════════════════════════

  /// 獲取或創建卡片
  Future<FSRSCardModel> getOrCreateCard({
    required String userId,
    required String lemma,
    required String senseId,
    bool isUnlocked = true,
  }) async {
    final key = _getCardKey(userId, lemma, senseId);
    
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

  /// 提交複習結果
  Future<FSRSCardModel> submitReview({
    required FSRSCardModel card,
    required FSRSRating rating,
    int? reviewTimeSeconds,
  }) async {
    final now = DateTime.now();
    
    // 記錄原始狀態
    final wasNew = card.isNew;
    
    // 計算經過的天數
    final elapsed = card.lastReview != null
        ? now.difference(card.lastReview!).inDays
        : 0;

    // 使用 FSRS 算法計算下次複習時間
    final fsrsCard = card.toFSRSCard();
    final nextCard = _algorithm.next(fsrsCard, rating, now: now);
    final updatedCard = card.updateFromFSRSCard(nextCard);

    // 保存卡片
    final key = _getCardKey(card.userId, card.lemma, card.senseId);
    await _cardsBox.put(key, updatedCard);

    // 創建複習日誌
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
    await _reviewLogsBox.add(reviewLog);

    // 更新每日統計
    await _updateDailyStats(
      userId: card.userId,
      wasNew: wasNew,
      newState: updatedCard.state,
      rating: rating,
      reviewTimeSeconds: reviewTimeSeconds,
    );

    return updatedCard;
  }

  /// 更新每日統計
  Future<void> _updateDailyStats({
    required String userId,
    required bool wasNew,
    required int newState,
    required FSRSRating rating,
    int? reviewTimeSeconds,
  }) async {
    final today = _normalizeDate(DateTime.now());
    final key = _getDailyStatsKey(userId, today);
    
    var stats = _dailyStatsBox.get(key) ?? FSRSDailyStatsModel.empty(
      userId: userId,
      date: today,
    );

    // 更新統計數據
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

  // ═══════════════════════════════════════════════════════════
  // 統計相關
  // ═══════════════════════════════════════════════════════════

  /// 獲取連續學習天數
  int getCurrentStreak(String userId) {
    final today = _normalizeDate(DateTime.now());
    int streak = 0;
    var currentDate = today;

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

  /// 獲取卡片統計
  Map<String, int> getCardStatistics(String userId) {
    final cards = _cardsBox.values
        .where((card) => card.userId == userId)
        .toList();

    return {
      'total': cards.length,
      'new': cards.where((c) => c.isNew).length,
      'learning': cards.where((c) => c.isLearning).length,
      'review': cards.where((c) => c.isReview).length,
      'due': cards.where((c) => c.isDue()).length,
    };
  }

  // ═══════════════════════════════════════════════════════════
  // 輔助方法
  // ═══════════════════════════════════════════════════════════

  /// 標準化日期（UTC 午夜）
  DateTime _normalizeDate(DateTime date) {
    return DateTime.utc(date.year, date.month, date.day);
  }

  /// 生成卡片鍵
  String _getCardKey(String userId, String lemma, String senseId) {
    return '$userId:$lemma:$senseId';
  }

  /// 生成每日統計鍵
  String _getDailyStatsKey(String userId, DateTime date) {
    return '$userId:${date.toIso8601String()}';
  }

  /// 獲取指定日期的統計數據
  FSRSDailyStatsModel? _getDailyStatsForDate(String userId, DateTime date) {
    final key = _getDailyStatsKey(userId, date);
    return _dailyStatsBox.get(key);
  }

  /// 獲取所有單字的卡片
  List<FSRSCardModel> getWordCards(String userId, String lemma) {
    return _cardsBox.values
        .where((card) => card.userId == userId && card.lemma == lemma)
        .toList();
  }

  /// 獲取日期範圍內的統計數據
  List<FSRSDailyStatsModel> getDailyStats({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final normalizedStart = _normalizeDate(startDate);
    final normalizedEnd = _normalizeDate(endDate);

    return _dailyStatsBox.values
        .where((stats) =>
            stats.userId == userId &&
            !stats.date.isBefore(normalizedStart) &&
            !stats.date.isAfter(normalizedEnd))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }
}
