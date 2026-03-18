import 'package:hive/hive.dart';

part 'review_history_model.g.dart';

@HiveType(typeId: 2)
class ReviewHistoryModel extends HiveObject {
  @HiveField(0)
  final DateTime reviewDate;

  @HiveField(1)
  final int quality; // 0-5

  @HiveField(2)
  final int timeSpentSeconds;

  @HiveField(3)
  final String questionType;

  @HiveField(4)
  final bool correct;

  ReviewHistoryModel({
    required this.reviewDate,
    required this.quality,
    required this.timeSpentSeconds,
    required this.questionType,
    required this.correct,
  });

  Duration get timeSpent => Duration(seconds: timeSpentSeconds);

  factory ReviewHistoryModel.fromDuration({
    required DateTime reviewDate,
    required int quality,
    required Duration timeSpent,
    required String questionType,
    required bool correct,
  }) {
    return ReviewHistoryModel(
      reviewDate: reviewDate,
      quality: quality,
      timeSpentSeconds: timeSpent.inSeconds,
      questionType: questionType,
      correct: correct,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reviewDate': reviewDate.toIso8601String(),
      'quality': quality,
      'timeSpentSeconds': timeSpentSeconds,
      'questionType': questionType,
      'correct': correct,
    };
  }

  factory ReviewHistoryModel.fromJson(Map<String, dynamic> json) {
    return ReviewHistoryModel(
      reviewDate: DateTime.parse(json['reviewDate'] as String),
      quality: json['quality'] as int,
      timeSpentSeconds: json['timeSpentSeconds'] as int,
      questionType: json['questionType'] as String,
      correct: json['correct'] as bool,
    );
  }
}
