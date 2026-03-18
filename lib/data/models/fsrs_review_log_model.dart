import 'package:hive/hive.dart';
import '../../domain/services/fsrs_algorithm.dart';

part 'fsrs_review_log_model.g.dart';

/// Hive model for FSRS review log
/// 
/// This stores the history of all reviews for analytics and statistics.
@HiveType(typeId: 41)
class FSRSReviewLogModel extends HiveObject {
  /// User ID
  @HiveField(0)
  final String userId;

  /// Word lemma
  @HiveField(1)
  final String lemma;

  /// Sense ID
  @HiveField(2)
  final String senseId;

  /// Rating given (1=Again, 2=Hard, 3=Good, 4=Easy)
  @HiveField(3)
  final int rating;

  /// Card state before review (0=New, 1=Learning, 2=Review, 3=Relearning)
  @HiveField(4)
  final int stateBefore;

  /// Card state after review
  @HiveField(5)
  final int stateAfter;

  /// Scheduled days before review
  @HiveField(6)
  final int scheduledDaysBefore;

  /// Scheduled days after review
  @HiveField(7)
  final int scheduledDaysAfter;

  /// Stability before review
  @HiveField(8)
  final double stabilityBefore;

  /// Stability after review
  @HiveField(9)
  final double stabilityAfter;

  /// Difficulty before review
  @HiveField(10)
  final double difficultyBefore;

  /// Difficulty after review
  @HiveField(11)
  final double difficultyAfter;

  /// Days elapsed since last review
  @HiveField(12)
  final int elapsedDays;

  /// Review timestamp
  @HiveField(13)
  final DateTime reviewedAt;

  /// Time taken to review (in seconds)
  @HiveField(14)
  final int? reviewTimeSeconds;

  FSRSReviewLogModel({
    required this.userId,
    required this.lemma,
    required this.senseId,
    required this.rating,
    required this.stateBefore,
    required this.stateAfter,
    required this.scheduledDaysBefore,
    required this.scheduledDaysAfter,
    required this.stabilityBefore,
    required this.stabilityAfter,
    required this.difficultyBefore,
    required this.difficultyAfter,
    required this.elapsedDays,
    required this.reviewedAt,
    this.reviewTimeSeconds,
  });

  /// Create a review log from before/after card states
  factory FSRSReviewLogModel.fromReview({
    required String userId,
    required String lemma,
    required String senseId,
    required FSRSRating rating,
    required FSRSCard cardBefore,
    required FSRSCard cardAfter,
    required int elapsedDays,
    int? reviewTimeSeconds,
  }) {
    return FSRSReviewLogModel(
      userId: userId,
      lemma: lemma,
      senseId: senseId,
      rating: rating.value,
      stateBefore: cardBefore.state.index,
      stateAfter: cardAfter.state.index,
      scheduledDaysBefore: cardBefore.scheduledDays,
      scheduledDaysAfter: cardAfter.scheduledDays,
      stabilityBefore: cardBefore.stability,
      stabilityAfter: cardAfter.stability,
      difficultyBefore: cardBefore.difficulty,
      difficultyAfter: cardAfter.difficulty,
      elapsedDays: elapsedDays,
      reviewedAt: DateTime.now(),
      reviewTimeSeconds: reviewTimeSeconds,
    );
  }

  /// Get rating as enum
  FSRSRating get ratingEnum => FSRSRating.values[rating - 1];

  /// Get state before as enum
  CardState get stateBeforeEnum => CardState.values[stateBefore];

  /// Get state after as enum
  CardState get stateAfterEnum => CardState.values[stateAfter];

  /// Check if this was a successful review (Good or Easy)
  bool get isSuccess => rating >= 3;

  /// Check if this was a lapse (Again)
  bool get isLapse => rating == 1;

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'lemma': lemma,
      'senseId': senseId,
      'rating': rating,
      'stateBefore': stateBefore,
      'stateAfter': stateAfter,
      'scheduledDaysBefore': scheduledDaysBefore,
      'scheduledDaysAfter': scheduledDaysAfter,
      'stabilityBefore': stabilityBefore,
      'stabilityAfter': stabilityAfter,
      'difficultyBefore': difficultyBefore,
      'difficultyAfter': difficultyAfter,
      'elapsedDays': elapsedDays,
      'reviewedAt': reviewedAt.toIso8601String(),
      'reviewTimeSeconds': reviewTimeSeconds,
    };
  }

  factory FSRSReviewLogModel.fromJson(Map<String, dynamic> json) {
    return FSRSReviewLogModel(
      userId: json['userId'] as String,
      lemma: json['lemma'] as String,
      senseId: json['senseId'] as String,
      rating: json['rating'] as int,
      stateBefore: json['stateBefore'] as int,
      stateAfter: json['stateAfter'] as int,
      scheduledDaysBefore: json['scheduledDaysBefore'] as int,
      scheduledDaysAfter: json['scheduledDaysAfter'] as int,
      stabilityBefore: (json['stabilityBefore'] as num).toDouble(),
      stabilityAfter: (json['stabilityAfter'] as num).toDouble(),
      difficultyBefore: (json['difficultyBefore'] as num).toDouble(),
      difficultyAfter: (json['difficultyAfter'] as num).toDouble(),
      elapsedDays: json['elapsedDays'] as int,
      reviewedAt: DateTime.parse(json['reviewedAt'] as String),
      reviewTimeSeconds: json['reviewTimeSeconds'] as int?,
    );
  }
}
