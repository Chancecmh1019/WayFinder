import 'package:hive/hive.dart';
import '../../domain/services/fsrs_algorithm.dart';

part 'fsrs_card_model.g.dart';

/// Hive model for FSRS card state
/// 
/// This stores the learning progress for a specific sense of a word.
/// Each sense is tracked independently to support progressive unlocking.
@HiveType(typeId: 40)
class FSRSCardModel extends HiveObject {
  /// User ID
  @HiveField(0)
  final String userId;

  /// Word lemma
  @HiveField(1)
  final String lemma;

  /// Sense ID (e.g., "advanced.adj.dicta86c2ec1")
  @HiveField(2)
  final String senseId;

  /// Card state (0=New, 1=Learning, 2=Review, 3=Relearning)
  @HiveField(3)
  final int state;

  /// Scheduled interval in days
  @HiveField(4)
  final int scheduledDays;

  /// Next review date
  @HiveField(5)
  final DateTime due;

  /// Memory stability (in days)
  @HiveField(6)
  final double stability;

  /// Difficulty rating (1-10)
  @HiveField(7)
  final double difficulty;

  /// Number of consecutive successful reviews
  @HiveField(8)
  final int reps;

  /// Number of times the card was forgotten
  @HiveField(9)
  final int lapses;

  /// Last review timestamp
  @HiveField(10)
  final DateTime? lastReview;

  /// Whether this sense is unlocked for learning
  @HiveField(11)
  final bool isUnlocked;

  /// Created timestamp
  @HiveField(12)
  final DateTime createdAt;

  /// Updated timestamp
  @HiveField(13)
  final DateTime updatedAt;

  FSRSCardModel({
    required this.userId,
    required this.lemma,
    required this.senseId,
    required this.state,
    required this.scheduledDays,
    required this.due,
    required this.stability,
    required this.difficulty,
    required this.reps,
    required this.lapses,
    this.lastReview,
    required this.isUnlocked,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create a new card for a sense
  factory FSRSCardModel.newCard({
    required String userId,
    required String lemma,
    required String senseId,
    required bool isUnlocked,
  }) {
    final now = DateTime.now();
    return FSRSCardModel(
      userId: userId,
      lemma: lemma,
      senseId: senseId,
      state: CardState.newCard.index,
      scheduledDays: 0,
      due: now,
      stability: 0,
      difficulty: 0,
      reps: 0,
      lapses: 0,
      lastReview: null,
      isUnlocked: isUnlocked,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Convert to domain FSRSCard
  FSRSCard toFSRSCard() {
    return FSRSCard(
      state: CardState.values[state],
      scheduledDays: scheduledDays,
      due: due,
      stability: stability,
      difficulty: difficulty,
      reps: reps,
      lapses: lapses,
      lastReview: lastReview,
    );
  }

  /// Create from domain FSRSCard
  factory FSRSCardModel.fromFSRSCard({
    required String userId,
    required String lemma,
    required String senseId,
    required FSRSCard card,
    required bool isUnlocked,
    required DateTime createdAt,
  }) {
    return FSRSCardModel(
      userId: userId,
      lemma: lemma,
      senseId: senseId,
      state: card.state.index,
      scheduledDays: card.scheduledDays,
      due: card.due,
      stability: card.stability,
      difficulty: card.difficulty,
      reps: card.reps,
      lapses: card.lapses,
      lastReview: card.lastReview,
      isUnlocked: isUnlocked,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  /// Update from domain FSRSCard
  FSRSCardModel updateFromFSRSCard(FSRSCard card) {
    return FSRSCardModel(
      userId: userId,
      lemma: lemma,
      senseId: senseId,
      state: card.state.index,
      scheduledDays: card.scheduledDays,
      due: card.due,
      stability: card.stability,
      difficulty: card.difficulty,
      reps: card.reps,
      lapses: card.lapses,
      lastReview: card.lastReview,
      isUnlocked: isUnlocked,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  /// Check if the card is due for review
  bool isDue({DateTime? now}) {
    now ??= DateTime.now();
    return now.isAfter(due) || now.isAtSameMomentAs(due);
  }

  /// Get card state as enum
  CardState get cardState => CardState.values[state];

  /// Check if card is in review state (mastered)
  bool get isReview => state == CardState.review.index;

  /// Check if card is new
  bool get isNew => state == CardState.newCard.index;

  /// Check if card is learning
  bool get isLearning =>
      state == CardState.learning.index || state == CardState.relearning.index;

  FSRSCardModel copyWith({
    String? userId,
    String? lemma,
    String? senseId,
    int? state,
    int? scheduledDays,
    DateTime? due,
    double? stability,
    double? difficulty,
    int? reps,
    int? lapses,
    DateTime? lastReview,
    bool? isUnlocked,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FSRSCardModel(
      userId: userId ?? this.userId,
      lemma: lemma ?? this.lemma,
      senseId: senseId ?? this.senseId,
      state: state ?? this.state,
      scheduledDays: scheduledDays ?? this.scheduledDays,
      due: due ?? this.due,
      stability: stability ?? this.stability,
      difficulty: difficulty ?? this.difficulty,
      reps: reps ?? this.reps,
      lapses: lapses ?? this.lapses,
      lastReview: lastReview ?? this.lastReview,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'lemma': lemma,
      'senseId': senseId,
      'state': state,
      'scheduledDays': scheduledDays,
      'due': due.toIso8601String(),
      'stability': stability,
      'difficulty': difficulty,
      'reps': reps,
      'lapses': lapses,
      'lastReview': lastReview?.toIso8601String(),
      'isUnlocked': isUnlocked,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory FSRSCardModel.fromJson(Map<String, dynamic> json) {
    return FSRSCardModel(
      userId: json['userId'] as String,
      lemma: json['lemma'] as String,
      senseId: json['senseId'] as String,
      state: json['state'] as int,
      scheduledDays: json['scheduledDays'] as int,
      due: DateTime.parse(json['due'] as String),
      stability: (json['stability'] as num).toDouble(),
      difficulty: (json['difficulty'] as num).toDouble(),
      reps: json['reps'] as int,
      lapses: json['lapses'] as int,
      lastReview: json['lastReview'] != null
          ? DateTime.parse(json['lastReview'] as String)
          : null,
      isUnlocked: json['isUnlocked'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
