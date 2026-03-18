import '../../core/errors/failures.dart';
import '../../core/utils/either.dart';
import '../entities/learning_progress_entity.dart';
import '../entities/vocabulary_entity.dart';
import '../repositories/review_scheduler_repository.dart';
import 'usecase.dart';

/// Use case for getting the next learning item
/// 
/// This use case prioritizes due reviews over new words,
/// following the spaced repetition principle.
class GetNextItemUseCase implements UseCase<LearningItem, GetNextItemParams> {
  final ReviewSchedulerRepository repository;

  const GetNextItemUseCase(this.repository);

  @override
  Future<Either<Failure, LearningItem>> call(GetNextItemParams params) async {
    // First, check if there are due reviews
    final dueReviewsResult = await repository.getDueReviews();

    return dueReviewsResult.fold(
      (failure) => Left(failure),
      (dueReviews) async {
        // If we have due reviews and haven't completed them all, return next review
        if (dueReviews.isNotEmpty &&
            params.completedReviews < dueReviews.length) {
          final nextReview = dueReviews[params.completedReviews];

          // Get the vocabulary for this review
          final vocabResult = await _getVocabularyForWord(nextReview.word);

          return vocabResult.fold(
            (failure) => Left(failure),
            (vocab) => Right(LearningItem.review(
              vocabulary: vocab,
              progress: nextReview,
            )),
          );
        }

        // All reviews completed, get new words
        final newWordsNeeded = params.dailyGoal - params.completedTotal;

        if (newWordsNeeded <= 0) {
          return Left(const ValidationFailure('Daily goal already met'));
        }

        final newWordsResult = await repository.getNewWords(1);

        return newWordsResult.fold(
          (failure) => Left(failure),
          (newWords) {
            if (newWords.isEmpty) {
              return Left(const NotFoundFailure('No more new words available'));
            }

            return Right(LearningItem.newWord(
              vocabulary: newWords.first,
            ));
          },
        );
      },
    );
  }

  /// Helper method to get vocabulary for a word
  Future<Either<Failure, VocabularyEntity>> _getVocabularyForWord(
    String word,
  ) async {
    // This would typically use VocabularyRepository
    // For now, we'll return a failure indicating this needs to be implemented
    // in the actual implementation with proper dependency injection
    return Left(const NotFoundFailure(
      'Vocabulary lookup not implemented in use case',
    ));
  }
}

/// Parameters for getting next learning item
class GetNextItemParams {
  final int completedReviews;
  final int completedTotal;
  final int dailyGoal;

  const GetNextItemParams({
    required this.completedReviews,
    required this.completedTotal,
    required this.dailyGoal,
  });
}

/// Learning item that can be either a review or a new word
class LearningItem {
  final VocabularyEntity vocabulary;
  final LearningProgressEntity? progress;
  final bool isReview;

  const LearningItem._({
    required this.vocabulary,
    this.progress,
    required this.isReview,
  });

  /// Create a review item
  factory LearningItem.review({
    required VocabularyEntity vocabulary,
    required LearningProgressEntity progress,
  }) {
    return LearningItem._(
      vocabulary: vocabulary,
      progress: progress,
      isReview: true,
    );
  }

  /// Create a new word item
  factory LearningItem.newWord({
    required VocabularyEntity vocabulary,
  }) {
    return LearningItem._(
      vocabulary: vocabulary,
      progress: null,
      isReview: false,
    );
  }

  /// Check if this is a new word
  bool get isNewWord => !isReview;
}
