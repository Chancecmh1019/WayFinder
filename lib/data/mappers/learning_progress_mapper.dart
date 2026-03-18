import '../../domain/entities/learning_progress_entity.dart';
import '../../domain/entities/review_history.dart';
import '../models/learning_progress_model.dart';
import '../models/review_history_model.dart';

/// Mapper to convert between LearningProgressModel and LearningProgressEntity
/// NOTE: This is legacy SM2-based code. The app now uses FSRS algorithm.
/// This mapper is kept for backward compatibility with old data imports.
class LearningProgressMapper {
  /// Convert LearningProgressModel to LearningProgressEntity
  static LearningProgressEntity toEntity(LearningProgressModel model) {
    return LearningProgressEntity(
      userId: model.userId,
      word: model.word,
      repetitions: model.repetitions,
      interval: model.interval,
      easeFactor: model.easeFactor,
      nextReviewDate: model.nextReviewDate,
      lastReviewDate: model.lastReviewDate,
      proficiencyLevel: ProficiencyLevel.fromValue(model.proficiencyLevel),
      history: model.history.cast<Map<String, dynamic>>().map((h) => ReviewHistory(
        reviewDate: DateTime.parse(h['reviewDate'] as String),
        quality: h['quality'] as int,
        timeSpent: Duration(seconds: h['timeSpent'] as int),
        questionType: h['questionType'] as String,
        correct: h['correct'] as bool,
      )).toList(),
    );
  }

  /// Convert LearningProgressEntity to LearningProgressModel
  static LearningProgressModel toModel(LearningProgressEntity entity) {
    return LearningProgressModel(
      userId: entity.userId,
      word: entity.word,
      repetitions: entity.repetitions,
      interval: entity.interval,
      easeFactor: entity.easeFactor,
      nextReviewDate: entity.nextReviewDate,
      lastReviewDate: entity.lastReviewDate,
      proficiencyLevel: entity.proficiencyLevel.value,
      history: entity.history.map((h) => ReviewHistoryModel(
        reviewDate: h.reviewDate,
        quality: h.quality,
        timeSpentSeconds: h.timeSpent.inSeconds,
        questionType: h.questionType,
        correct: h.correct,
      )).toList(),
      updatedAt: DateTime.now(),
    );
  }
}
