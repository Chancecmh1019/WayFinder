import 'dart:math';

/// FSRS v5 (Free Spaced Repetition Scheduler) — Dart 實作
///
/// 核心公式：
///   R(t,S) = (1 + FACTOR × t/S)^DECAY          記憶保留率
///   I(S,r) = S/FACTOR × (r^(1/DECAY) − 1)      下次間隔
///   D₀(G)  = w₄ − exp(w₅×(G−1)) + 1            初始難度
///   S₀(G)  = w[G−1]                              初始穩定度
class FSRSAlgorithm {
  static const double _decay  = -0.5;
  static const double _factor = 19.0 / 81.0;

  final FSRSParameters parameters;

  FSRSAlgorithm({FSRSParameters? parameters})
      : parameters = parameters ?? FSRSParameters.defaults();

  SchedulingInfo schedule(FSRSCard card, {DateTime? now}) {
    now ??= DateTime.now();
    return SchedulingInfo(
      again: _scheduleForRating(card, FSRSRating.again, now),
      hard:  _scheduleForRating(card, FSRSRating.hard,  now),
      good:  _scheduleForRating(card, FSRSRating.good,  now),
      easy:  _scheduleForRating(card, FSRSRating.easy,  now),
    );
  }

  FSRSCard next(FSRSCard card, FSRSRating rating, {DateTime? now}) {
    now ??= DateTime.now();
    return _scheduleForRating(card, rating, now);
  }

  FSRSCard _scheduleForRating(FSRSCard card, FSRSRating rating, DateTime now) {
    final elapsed = card.lastReview != null
        ? now.difference(card.lastReview!).inDays : 0;
    switch (card.state) {
      case CardState.newCard:
        return _handleNew(card, rating, now);
      case CardState.learning:
      case CardState.relearning:
        return _handleLearning(card, rating, now, elapsed);
      case CardState.review:
        return _handleReview(card, rating, now, elapsed);
    }
  }

  FSRSCard _handleNew(FSRSCard card, FSRSRating rating, DateTime now) {
    final s = _initStability(rating);
    final d = _initDifficulty(rating);
    switch (rating) {
      case FSRSRating.again:
        return card.copyWith(state: CardState.learning, scheduledDays: 0,
            due: now.add(Duration(minutes: parameters.againMinutes)),
            stability: s, difficulty: d, lastReview: now, reps: 0);
      case FSRSRating.hard:
        return card.copyWith(state: CardState.learning, scheduledDays: 0,
            due: now.add(Duration(minutes: parameters.hardMinutes)),
            stability: s, difficulty: d, lastReview: now, reps: 0);
      case FSRSRating.good:
        return card.copyWith(state: CardState.learning, scheduledDays: 0,
            due: now.add(Duration(minutes: parameters.goodMinutes)),
            stability: s, difficulty: d, lastReview: now, reps: 0);
      case FSRSRating.easy:
        final i = _nextInterval(s);
        return card.copyWith(state: CardState.review, scheduledDays: i,
            due: now.add(Duration(days: i)),
            stability: s, difficulty: d, lastReview: now, reps: 1);
    }
  }

  FSRSCard _handleLearning(FSRSCard card, FSRSRating rating, DateTime now, int elapsed) {
    final s = _nextStability(card, rating, elapsed);
    final d = _nextDifficulty(card, rating);
    switch (rating) {
      case FSRSRating.again:
        return card.copyWith(state: card.state, scheduledDays: 0,
            due: now.add(Duration(minutes: parameters.againMinutes)),
            stability: s, difficulty: d, lastReview: now, reps: 0);
      default:
        final i = _nextInterval(s);
        return card.copyWith(state: CardState.review, scheduledDays: i,
            due: now.add(Duration(days: i)),
            stability: s, difficulty: d, lastReview: now, reps: card.reps + 1);
    }
  }

  FSRSCard _handleReview(FSRSCard card, FSRSRating rating, DateTime now, int elapsed) {
    final s = _nextStability(card, rating, elapsed);
    final d = _nextDifficulty(card, rating);
    switch (rating) {
      case FSRSRating.again:
        return card.copyWith(state: CardState.relearning, scheduledDays: 0,
            due: now.add(Duration(minutes: parameters.againMinutes)),
            stability: s, difficulty: d, lastReview: now,
            lapses: card.lapses + 1, reps: 0);
      default:
        final i = _nextInterval(s);
        return card.copyWith(state: CardState.review, scheduledDays: i,
            due: now.add(Duration(days: i)),
            stability: s, difficulty: d, lastReview: now, reps: card.reps + 1);
    }
  }

  double _initStability(FSRSRating rating) =>
      parameters.w[rating.value - 1].clamp(0.1, 100.0);

  double _initDifficulty(FSRSRating rating) {
    final d = parameters.w[4] - exp(parameters.w[5] * (rating.value - 1)) + 1;
    return d.clamp(1.0, 10.0);
  }

  /// R(t,S) = (1 + FACTOR × t/S)^DECAY
  double _retrievability(FSRSCard card, int elapsed) {
    if (card.stability <= 0) return 0.0;
    return pow(1 + _factor * elapsed / card.stability, _decay).toDouble();
  }

  /// I = S/FACTOR × (r^(1/DECAY) − 1)
  int _nextInterval(double stability) {
    if (stability <= 0) return 1;
    final r   = parameters.requestRetention;
    final raw = stability / _factor * (pow(r, 1.0 / _decay) - 1);
    return raw.round().clamp(1, parameters.maximumInterval);
  }

  double _nextStability(FSRSCard card, FSRSRating rating, int elapsed) {
    if (rating == FSRSRating.again) {
      final r = _retrievability(card, elapsed);
      return (parameters.w[11] *
          pow(card.difficulty, -parameters.w[12]) *
          (pow(card.stability + 1, parameters.w[13]) - 1) *
          exp(parameters.w[14] * (1 - r))).clamp(0.1, 36500.0);
    }
    final r           = _retrievability(card, elapsed);
    final hardPenalty = (rating == FSRSRating.hard) ? parameters.w[15] : 1.0;
    final easyBonus   = (rating == FSRSRating.easy) ? parameters.w[16] : 1.0;
    return (card.stability *
        (exp(parameters.w[8]) *
            (11 - card.difficulty) *
            pow(card.stability, -parameters.w[9]) *
            (exp((1 - r) * parameters.w[10]) - 1) *
            hardPenalty * easyBonus +
            1)).clamp(0.1, 36500.0);
  }

  double _nextDifficulty(FSRSCard card, FSRSRating rating) {
    final delta   = parameters.w[6] * (rating.value - 3);
    final nextD   = card.difficulty - delta;
    final reverted = parameters.w[7] * parameters.w[4] + (1 - parameters.w[7]) * nextD;
    return reverted.clamp(1.0, 10.0);
  }

  double currentRetentionRate(FSRSCard card, {DateTime? now}) {
    now ??= DateTime.now();
    if (card.lastReview == null) return 1.0;
    final elapsed = now.difference(card.lastReview!).inDays;
    return _retrievability(card, elapsed).clamp(0.0, 1.0);
  }
}

// ──────────────────────────────────────────────────────────────

class FSRSParameters {
  final List<double> w;
  final double requestRetention;
  final int maximumInterval;
  final int againMinutes;
  final int hardMinutes;
  final int goodMinutes;

  const FSRSParameters({
    required this.w,
    this.requestRetention = 0.9,
    this.maximumInterval  = 36500,
    this.againMinutes     = 1,
    this.hardMinutes      = 5,
    this.goodMinutes      = 10,
  });

  factory FSRSParameters.defaults() => const FSRSParameters(w: [
    0.4072, 1.1829, 3.1262, 15.4722,
    7.2102, 0.5316, 1.0651, 0.0234,
    1.6160, 0.1544, 1.0824, 1.9813,
    0.0953, 0.2975, 2.2042, 0.2407,
    2.9466,
  ]);

  FSRSParameters copyWith({
    List<double>? w, double? requestRetention, int? maximumInterval,
    int? againMinutes, int? hardMinutes, int? goodMinutes,
  }) => FSRSParameters(
    w: w ?? this.w,
    requestRetention: requestRetention ?? this.requestRetention,
    maximumInterval: maximumInterval ?? this.maximumInterval,
    againMinutes: againMinutes ?? this.againMinutes,
    hardMinutes:  hardMinutes  ?? this.hardMinutes,
    goodMinutes:  goodMinutes  ?? this.goodMinutes,
  );
}

// ──────────────────────────────────────────────────────────────

enum CardState { newCard, learning, review, relearning }

enum FSRSRating { again, hard, good, easy }

extension FSRSRatingX on FSRSRating {
  int get value {
    switch (this) {
      case FSRSRating.again: return 1;
      case FSRSRating.hard:  return 2;
      case FSRSRating.good:  return 3;
      case FSRSRating.easy:  return 4;
    }
  }
  String get label {
    switch (this) {
      case FSRSRating.again: return '又忘了';
      case FSRSRating.hard:  return '困難';
      case FSRSRating.good:  return '良好';
      case FSRSRating.easy:  return '簡單';
    }
  }
}

// ──────────────────────────────────────────────────────────────

class FSRSCard {
  final CardState state;
  final int scheduledDays;
  final DateTime due;
  final double stability;
  final double difficulty;
  final int reps;
  final int lapses;
  final DateTime? lastReview;

  const FSRSCard({
    required this.state, required this.scheduledDays, required this.due,
    required this.stability, required this.difficulty,
    required this.reps, required this.lapses, this.lastReview,
  });

  factory FSRSCard.newCard({DateTime? now}) {
    now ??= DateTime.now();
    return FSRSCard(state: CardState.newCard, scheduledDays: 0, due: now,
        stability: 0, difficulty: 0, reps: 0, lapses: 0);
  }

  bool isDue({DateTime? now}) => !(now ?? DateTime.now()).isBefore(due);

  FSRSCard copyWith({
    CardState? state, int? scheduledDays, DateTime? due,
    double? stability, double? difficulty, int? reps, int? lapses, DateTime? lastReview,
  }) => FSRSCard(
    state: state ?? this.state, scheduledDays: scheduledDays ?? this.scheduledDays,
    due: due ?? this.due, stability: stability ?? this.stability,
    difficulty: difficulty ?? this.difficulty, reps: reps ?? this.reps,
    lapses: lapses ?? this.lapses, lastReview: lastReview ?? this.lastReview,
  );
}

class SchedulingInfo {
  final FSRSCard again, hard, good, easy;
  const SchedulingInfo({required this.again, required this.hard, required this.good, required this.easy});
  FSRSCard forRating(FSRSRating r) {
    switch (r) {
      case FSRSRating.again: return again;
      case FSRSRating.hard:  return hard;
      case FSRSRating.good:  return good;
      case FSRSRating.easy:  return easy;
    }
  }
}
