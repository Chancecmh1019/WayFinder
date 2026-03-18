import '../../core/errors/failures.dart';
import '../../core/utils/either.dart';
import '../entities/learning_progress_entity.dart';
import '../entities/vocabulary_entity.dart';
import '../repositories/review_scheduler_repository.dart';
import 'usecase.dart';

/// Use case for starting a new learning session
/// 
/// This use case retrieves due reviews and new words to create
/// a learning session queue.
class StartLearningSessionUseCase
    implements UseCase<LearningSession, StartLearningSessionParams> {
  final ReviewSchedulerRepository repository;

  const StartLearningSessionUseCase(this.repository);

  @override
  Future<Either<Failure, LearningSession>> call(
    StartLearningSessionParams params,
  ) async {
    // Get due reviews first (priority)
    final dueReviewsResult = await repository.getDueReviews();

    return dueReviewsResult.fold(
      (failure) => Left(failure),
      (dueReviews) async {
        // Calculate how many new words we need
        final newWordsNeeded = params.dailyGoal - dueReviews.length;

        if (newWordsNeeded <= 0) {
          // We have enough due reviews, no need for new words
          return Right(LearningSession(
            dueReviews: dueReviews,
            newWords: [],
            dailyGoal: params.dailyGoal,
          ));
        }

        // Get new words to fill the daily goal
        final newWordsResult = await repository.getNewWords(newWordsNeeded);

        return newWordsResult.fold(
          (failure) => Left(failure),
          (newWords) => Right(LearningSession(
            dueReviews: dueReviews,
            newWords: newWords,
            dailyGoal: params.dailyGoal,
          )),
        );
      },
    );
  }
}

/// Parameters for starting a learning session
class StartLearningSessionParams {
  final int dailyGoal;

  const StartLearningSessionParams({
    required this.dailyGoal,
  });
}

/// Learning session containing due reviews and new words
class LearningSession {
  final List<LearningProgressEntity> dueReviews;
  final List<VocabularyEntity> newWords;
  final int dailyGoal;

  const LearningSession({
    required this.dueReviews,
    required this.newWords,
    required this.dailyGoal,
  });

  /// Get total number of items in the session
  int get totalItems => dueReviews.length + newWords.length;

  /// Check if session has any items
  bool get hasItems => totalItems > 0;

  /// Check if daily goal is met
  bool get isGoalMet => totalItems >= dailyGoal;
}
