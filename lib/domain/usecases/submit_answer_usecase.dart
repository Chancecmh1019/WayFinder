import '../../core/errors/failures.dart';
import '../../core/utils/either.dart';
import '../entities/learning_progress_entity.dart';
import '../repositories/review_scheduler_repository.dart';
import '../services/sm2_algorithm.dart';
import 'usecase.dart';

/// Use case for submitting an answer and updating learning progress
/// 
/// This use case records the review, calculates new SM-2 parameters,
/// and updates the learning progress.
class SubmitAnswerUseCase implements UseCase<AnswerResult, SubmitAnswerParams> {
  final ReviewSchedulerRepository repository;
  final SM2Algorithm sm2Algorithm;

  const SubmitAnswerUseCase({
    required this.repository,
    required this.sm2Algorithm,
  });

  @override
  Future<Either<Failure, AnswerResult>> call(
    SubmitAnswerParams params,
  ) async {
    // Validate quality rating
    if (params.quality < 0 || params.quality > 5) {
      return Left(ValidationFailure(
        'Quality must be between 0 and 5, got: ${params.quality}',
      ));
    }

    // Record the review
    final recordResult = await repository.recordReview(
      word: params.word,
      quality: params.quality,
      timeSpent: params.timeSpent,
    );

    return recordResult.fold(
      (failure) => Left(failure),
      (_) async {
        // Get updated progress to return
        final progressResult = await repository.getProgress(params.word);

        return progressResult.fold(
          (failure) => Left(failure),
          (progress) {
            // Determine if answer was correct (quality >= 3)
            final isCorrect = params.quality >= 3;

            // Calculate proficiency change
            final proficiencyChange = _calculateProficiencyChange(
              currentProficiency: progress.proficiencyLevel,
              quality: params.quality,
            );

            return Right(AnswerResult(
              isCorrect: isCorrect,
              quality: params.quality,
              updatedProgress: progress,
              proficiencyChange: proficiencyChange,
            ));
          },
        );
      },
    );
  }

  /// Calculate proficiency level change based on quality
  ProficiencyLevel _calculateProficiencyChange({
    required ProficiencyLevel currentProficiency,
    required int quality,
  }) {
    final currentValue = currentProficiency.value;

    // Increase proficiency for quality >= 4
    if (quality >= 4 && currentValue < 5) {
      return ProficiencyLevel.fromValue(currentValue + 1);
    }

    // Decrease proficiency for quality < 3
    if (quality < 3 && currentValue > 0) {
      return ProficiencyLevel.fromValue(currentValue - 1);
    }

    // No change for quality == 3 or at boundaries
    return currentProficiency;
  }
}

/// Parameters for submitting an answer
class SubmitAnswerParams {
  final String word;
  final int quality; // SM-2 quality rating (0-5)
  final Duration timeSpent;
  final String? userAnswer; // Optional: the actual answer provided
  final String questionType; // Type of question answered

  const SubmitAnswerParams({
    required this.word,
    required this.quality,
    required this.timeSpent,
    this.userAnswer,
    required this.questionType,
  });
}

/// Result of submitting an answer
class AnswerResult {
  final bool isCorrect;
  final int quality;
  final LearningProgressEntity updatedProgress;
  final ProficiencyLevel proficiencyChange;

  const AnswerResult({
    required this.isCorrect,
    required this.quality,
    required this.updatedProgress,
    required this.proficiencyChange,
  });

  /// Check if proficiency increased
  bool get proficiencyIncreased =>
      proficiencyChange.value > updatedProgress.proficiencyLevel.value;

  /// Check if proficiency decreased
  bool get proficiencyDecreased =>
      proficiencyChange.value < updatedProgress.proficiencyLevel.value;

  /// Get next review date
  DateTime get nextReviewDate => updatedProgress.nextReviewDate;

  /// Get interval until next review
  int get intervalDays => updatedProgress.interval;
}
