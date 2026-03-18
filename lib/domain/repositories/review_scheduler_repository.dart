import '../../core/errors/failures.dart';
import '../../core/utils/either.dart';
import '../entities/learning_progress_entity.dart';
import '../entities/vocabulary_entity.dart';

/// Repository interface for review scheduling and learning progress
abstract class ReviewSchedulerRepository {
  /// Get all words that are due for review
  /// Returns list of [LearningProgressEntity] sorted by due date (oldest first)
  Future<Either<Failure, List<LearningProgressEntity>>> getDueReviews();

  /// Get new words that haven't been learned yet
  /// [limit] specifies maximum number of words to return
  /// Returns list of [VocabularyEntity] on success or [DatabaseFailure] on failure
  Future<Either<Failure, List<VocabularyEntity>>> getNewWords(int limit);

  /// Record a review for a word and update SM-2 parameters
  /// [word] is the word being reviewed
  /// [quality] is the SM-2 quality rating (0-5)
  /// [timeSpent] is the duration spent on this review
  /// [questionType] is the type of question answered (optional)
  /// Returns void on success or [DatabaseFailure] on failure
  Future<Either<Failure, void>> recordReview({
    required String word,
    required int quality,
    required Duration timeSpent,
    String? questionType,
  });

  /// Get learning progress for a specific word
  /// Returns [LearningProgressEntity] on success or [NotFoundFailure] if not found
  Future<Either<Failure, LearningProgressEntity>> getProgress(String word);

  /// Get all learning progress for the current user
  /// Returns list of [LearningProgressEntity] on success or [DatabaseFailure] on failure
  Future<Either<Failure, List<LearningProgressEntity>>> getAllProgress();

  /// Stream of due review count
  /// Emits the number of words due for review whenever it changes
  Stream<int> get dueReviewCount;

  /// Get count of words learned (with at least one review)
  /// Returns count on success or [DatabaseFailure] on failure
  Future<Either<Failure, int>> getLearnedWordsCount();

  /// Get count of words mastered (proficiency level >= 4)
  /// Returns count on success or [DatabaseFailure] on failure
  Future<Either<Failure, int>> getMasteredWordsCount();

  /// Get learning streak (consecutive days with at least one review)
  /// Returns streak count on success or [DatabaseFailure] on failure
  Future<Either<Failure, int>> getLearningStreak();
}
