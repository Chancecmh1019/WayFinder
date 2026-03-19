import 'package:hive/hive.dart';
import '../models/fsrs_card_model.dart';
import '../models/fsrs_daily_stats_model.dart';
import '../models/fsrs_review_log_model.dart';
import '../services/hive_service.dart';
import '../../domain/services/fsrs_algorithm.dart';

class FsrsService {
  static const String _user = 'local_user';
  late Box<FSRSCardModel>      _cards;
  late Box<FSRSReviewLogModel> _logs;
  late Box<FSRSDailyStatsModel> _stats;
  bool _initialized = false;
  final FSRSAlgorithm _algo = FSRSAlgorithm();

  Future<void> initialize() async {
    if (_initialized) return;
    await HiveService.initialize();
    _cards = await HiveService.openFsrsCardsBox();
    _logs  = await HiveService.openFsrsReviewLogsBox();
    _stats = await HiveService.openFsrsDailyStatsBox();
    _initialized = true;
  }

  bool isInitialized() => _initialized;

  String _key(String lemma, String senseId) => '$_user:$lemma:$senseId';

  String _todayKey() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  // ── Card CRUD ────────────────────────────────────────────

  FSRSCardModel getOrCreateCard(String lemma, String senseId) {
    final key = _key(lemma, senseId);
    final now = DateTime.now();
    return _cards.get(key) ?? FSRSCardModel(
      userId: _user, lemma: lemma, senseId: senseId,
      state: CardState.newCard.index, scheduledDays: 0, due: now,
      stability: 0, difficulty: 0, reps: 0, lapses: 0, lastReview: null,
      isUnlocked: true, createdAt: now, updatedAt: now,
    );
  }

  Future<void> reviewCard(String lemma, String senseId, FSRSRating rating) async {
    final model = getOrCreateCard(lemma, senseId);
    final now   = DateTime.now();
    final stateBefore = model.state;
    final before = FSRSCard(
      state: CardState.values[model.state.clamp(0, 3)],
      due: model.due, stability: model.stability, difficulty: model.difficulty,
      reps: model.reps, lapses: model.lapses,
      lastReview: model.lastReview, scheduledDays: model.scheduledDays,
    );
    final after = _algo.next(before, rating);
    final updatedModel = model.copyWith(
      state: after.state.index, due: after.due, stability: after.stability,
      difficulty: after.difficulty, reps: after.reps, lapses: after.lapses,
      lastReview: now, scheduledDays: after.scheduledDays, updatedAt: now,
    );
    await _cards.put(_key(lemma, senseId), updatedModel);
    final elapsed = model.lastReview != null
        ? now.difference(model.lastReview!).inDays : 0;
    await _logs.add(FSRSReviewLogModel.fromReview(
      userId: _user, lemma: lemma, senseId: senseId,
      rating: rating, cardBefore: before, cardAfter: after, elapsedDays: elapsed,
    ));
    await _updateStats(rating, stateBefore);
    // 若此 sense 剛升入 Review 狀態，解鎖同字下一個 sense
    if (stateBefore != CardState.review.index &&
        updatedModel.state == CardState.review.index) {
      await _tryUnlockNextSense(lemma, senseId);
    }
  }

  /// 解鎖下一個 sense（第一譯掌握後解鎖第二譯，依此類推）
  Future<void> _tryUnlockNextSense(String lemma, String currentSenseId) async {
    final allCards = _cards.values
        .where((c) => c.lemma == lemma)
        .toList()
      ..sort((a, b) => a.senseId.compareTo(b.senseId));
    if (allCards.length < 2) return;
    final idx = allCards.indexWhere((c) => c.senseId == currentSenseId);
    if (idx == -1 || idx >= allCards.length - 1) return;
    final next = allCards[idx + 1];
    if (!next.isUnlocked) {
      await _cards.put(
        _key(lemma, next.senseId),
        next.copyWith(isUnlocked: true, updatedAt: DateTime.now()),
      );
    }
  }

  Future<void> _updateStats(FSRSRating rating, int stateBefore) async {
    final key = _todayKey();
    final now = DateTime.now();
    final isNew = stateBefore == CardState.newCard.index;
    final existing = _stats.get(key);
    if (existing != null) {
      await _stats.put(key, existing.copyWith(
        totalReviews: existing.totalReviews + 1,
        newCards:     existing.newCards + (isNew ? 1 : 0),
        againCount:   existing.againCount + (rating == FSRSRating.again ? 1 : 0),
        hardCount:    existing.hardCount  + (rating == FSRSRating.hard  ? 1 : 0),
        goodCount:    existing.goodCount  + (rating == FSRSRating.good  ? 1 : 0),
        easyCount:    existing.easyCount  + (rating == FSRSRating.easy  ? 1 : 0),
        updatedAt: now,
      ));
    } else {
      final today = DateTime(now.year, now.month, now.day);
      await _stats.put(key, FSRSDailyStatsModel(
        userId: _user, date: today,
        newCards: isNew ? 1 : 0, learningCards: 0, reviewCards: 0, relearningCards: 0,
        totalReviews: 1,
        againCount: rating == FSRSRating.again ? 1 : 0,
        hardCount:  rating == FSRSRating.hard  ? 1 : 0,
        goodCount:  rating == FSRSRating.good  ? 1 : 0,
        easyCount:  rating == FSRSRating.easy  ? 1 : 0,
        studyTimeSeconds: 0, uniqueWords: 0, uniqueSenses: 0,
        createdAt: now, updatedAt: now,
      ));
    }
  }

  // ── Query ─────────────────────────────────────────────────

  /// 到期待複習的卡片（修正：toList() 後再 take）
  List<FSRSCardModel> getDueCards({int limit = 50}) {
    final now = DateTime.now();
    final all = _cards.values
        .where((c) =>
            c.state != CardState.newCard.index &&
            !c.due.isAfter(now))
        .toList()
      ..sort((a, b) => a.due.compareTo(b.due));
    return all.take(limit).toList();
  }

  List<FSRSCardModel> getNewCards({int limit = 20}) =>
      _cards.values
          .where((c) => c.state == CardState.newCard.index)
          .take(limit)
          .toList();

  int get dueCount => getDueCards(limit: 9999).length;
  int get learnedCount =>
      _cards.values.where((c) => c.state == CardState.review.index).length;

  FSRSDailyStatsModel? getTodayStats() => _stats.get(_todayKey());
  int getTodayNewCardsCount()           => getTodayStats()?.newCards ?? 0;
  int getTodayReviewCount()             => getTodayStats()?.totalReviews ?? 0;

  int getRemainingNewCardsToday(int dailyGoal) =>
      (dailyGoal - getTodayNewCardsCount()).clamp(0, dailyGoal);

  // ── Stats ─────────────────────────────────────────────────

  int getCurrentStreak() {
    int streak = 0;
    final now = DateTime.now();
    for (int i = 0; i < 365; i++) {
      final d = now.subtract(Duration(days: i));
      final key = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      final s = _stats.get(key);
      if (s != null && s.totalReviews > 0) {
        streak++;
      } else if (i > 0) {
        break;
      }
    }
    return streak;
  }

  double getRetentionRate() {
    if (_logs.isEmpty) return 100.0;
    final total = _logs.length;
    final good  = _logs.values.where((l) => l.rating >= FSRSRating.good.value).length;
    return (good / total * 100).clamp(0, 100).roundToDouble();
  }

  List<String> getWeakWords({int limit = 10}) {
    final counts = <String, int>{};
    for (final c in _cards.values) {
      if (c.lapses > 0) counts[c.lemma] = (counts[c.lemma] ?? 0) + c.lapses;
    }
    return (counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))
        .take(limit)
        .map((e) => e.key)
        .toList();
  }

  Map<String, int> getHeatmapData(int days) {
    final map = <String, int>{};
    final now = DateTime.now();
    for (int i = 0; i < days; i++) {
      final d = now.subtract(Duration(days: i));
      final key = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      map[key] = _stats.get(key)?.totalReviews ?? 0;
    }
    return map;
  }

  Map<String, int> getMasteryDistribution() {
    final dist = {'new': 0, 'learning': 0, 'review': 0, 'relearning': 0};
    for (final c in _cards.values) {
      switch (CardState.values[c.state.clamp(0, 3)]) {
        case CardState.newCard:    dist['new']        = dist['new']! + 1;
        case CardState.learning:   dist['learning']   = dist['learning']! + 1;
        case CardState.review:     dist['review']     = dist['review']! + 1;
        case CardState.relearning: dist['relearning'] = dist['relearning']! + 1;
      }
    }
    return dist;
  }

  SchedulingInfo getNextIntervals(String lemma, String senseId) {
    final model = getOrCreateCard(lemma, senseId);
    return _algo.schedule(FSRSCard(
      state: CardState.values[model.state.clamp(0, 3)], due: model.due,
      stability: model.stability, difficulty: model.difficulty,
      reps: model.reps, lapses: model.lapses, lastReview: model.lastReview,
      scheduledDays: model.scheduledDays,
    ));
  }

  /// 取得單字的記憶保留率（0–1）
  double getRetentionForCard(String lemma, String senseId) {
    final model = getOrCreateCard(lemma, senseId);
    if (model.lastReview == null) return 1.0;
    final card = FSRSCard(
      state: CardState.values[model.state.clamp(0, 3)], due: model.due,
      stability: model.stability, difficulty: model.difficulty,
      reps: model.reps, lapses: model.lapses, lastReview: model.lastReview,
      scheduledDays: model.scheduledDays,
    );
    return _algo.currentRetentionRate(card);
  }

  /// 獲取所有已學習的單字（至少複習過一次）
  List<String> getAllLearnedWords() {
    return _cards.values
        .where((card) => card.lastReview != null)
        .map((card) => card.lemma)
        .toSet()
        .toList();
  }

  /// 獲取今天學習的單字
  List<String> getTodayLearnedWords() {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    
    return _cards.values
        .where((card) => 
            card.lastReview != null && 
            card.lastReview!.isAfter(todayStart))
        .map((card) => card.lemma)
        .toSet()
        .toList();
  }
}
