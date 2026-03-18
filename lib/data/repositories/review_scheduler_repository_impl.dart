import 'dart:async';
import '../mappers/vocabulary_mapper.dart';

import 'package:logger/logger.dart';
import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../core/utils/either.dart';
import '../../domain/entities/learning_progress_entity.dart';
import '../../domain/entities/vocabulary_entity.dart';
import '../../domain/repositories/review_scheduler_repository.dart';
import '../../domain/services/sm2_algorithm.dart';
import '../datasources/local/progress_local_datasource.dart';
import '../datasources/local/vocabulary_local_datasource.dart';
import '../mappers/learning_progress_mapper.dart';
import '../models/learning_progress_model.dart';
import '../models/review_history_model.dart';

/// Implementation of ReviewSchedulerRepository
class ReviewSchedulerRepositoryImpl implements ReviewSchedulerRepository {
  final ProgressLocalDataSource progressDataSource;
  final VocabularyLocalDataSource vocabularyDataSource;
  final SM2Algorithm sm2Algorithm;
  final Logger _logger = Logger();

  String? _currentUserId;

  ReviewSchedulerRepositoryImpl({
    required this.progressDataSource,
    required this.vocabularyDataSource,
    required this.sm2Algorithm,
  });

  /// Set the current user ID
  void setUserId(String userId) {
    _currentUserId = userId;
  }

  String get _userId {
    if (_currentUserId == null) {
      throw StateError('User ID not set. Call setUserId() first.');
    }
    return _currentUserId!;
  }

  @override
  Future<Either<Failure, List<LearningProgressEntity>>> getDueReviews() async {
    try {
      final models = await progressDataSource.getDueReviews(_userId);
      final entities = models.map(LearningProgressMapper.toEntity).toList();
      return Right(entities);
    } on DatabaseException catch (e) {
      _logger.e('Database error getting due reviews: $e');
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      _logger.e('Unexpected error getting due reviews: $e');
      return Left(DatabaseFailure('Failed to get due reviews: $e'));
    }
  }

  @override
  Future<Either<Failure, List<VocabularyEntity>>> getNewWords(int limit) async {
    try {
      // Get all vocabulary
      final allVocab = await vocabularyDataSource.getAllVocabulary();

      // Get all learned words
      final learnedProgress = await progressDataSource.getAllProgress(_userId);
      final learnedWords = learnedProgress.map((p) => p.word).toSet();

      // Filter out learned words
      final newWords = allVocab
          .where((vocab) => !learnedWords.contains(vocab.lemma))
          .take(limit)
          .toList();

      final entities = newWords.map(VocabularyMapper.toEntity).toList();
      return Right(entities);
    } on DatabaseException catch (e) {
      _logger.e('Database error getting new words: $e');
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      _logger.e('Unexpected error getting new words: $e');
      return Left(DatabaseFailure('Failed to get new words: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> recordReview({
    required String word,
    required int quality,
    required Duration timeSpent,
    String? questionType,
  }) async {
    try {
      // Validate quality
      if (quality < 0 || quality > 5) {
        return Left(
          ValidationFailure('Quality must be between 0 and 5'),
        );
      }

      // Get existing progress or create new
      LearningProgressModel progress =
          await progressDataSource.getProgress(_userId, word) ??
              LearningProgressModel.initial(userId: _userId, word: word);

      // Calculate new SM-2 parameters
      final sm2Result = sm2Algorithm.calculate(
        currentInterval: progress.interval,
        repetitions: progress.repetitions,
        easeFactor: progress.easeFactor,
        quality: quality,
      );

      // Create review history entry
      final reviewHistory = {
        'reviewDate': DateTime.now().toIso8601String(),
        'quality': quality,
        'timeSpent': timeSpent.inSeconds,
        'questionType': questionType ?? 'review',
        'correct': quality >= 3,
      };

      // Update proficiency level based on quality
      int newProficiency = progress.proficiencyLevel;
      if (quality >= 4) {
        newProficiency = (newProficiency + 1).clamp(0, 5);
      } else if (quality < 3) {
        newProficiency = (newProficiency - 1).clamp(0, 5);
      }

      // Update progress
      final updatedProgress = progress.copyWith(
        repetitions: sm2Result.newRepetitions,
        interval: sm2Result.newInterval,
        easeFactor: sm2Result.newEaseFactor,
        nextReviewDate: sm2Result.nextReviewDate,
        lastReviewDate: DateTime.now(),
        proficiencyLevel: newProficiency,
        history: [...progress.history, ReviewHistoryModel.fromJson(reviewHistory)],
        updatedAt: DateTime.now(),
      );

      // Save to database
      await progressDataSource.saveProgress(updatedProgress);

      _logger.i(
        'Recorded review for "$word": quality=$quality, '
        'newInterval=${sm2Result.newInterval} days, '
        'proficiency=$newProficiency',
      );

      return const Right(null);
    } on DatabaseException catch (e) {
      _logger.e('Database error recording review: $e');
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      _logger.e('Unexpected error recording review: $e');
      return Left(DatabaseFailure('Failed to record review: $e'));
    }
  }

  @override
  Future<Either<Failure, LearningProgressEntity>> getProgress(
    String word,
  ) async {
    try {
      final model = await progressDataSource.getProgress(_userId, word);
      if (model == null) {
        return Left(NotFoundFailure('Progress not found for word: $word'));
      }
      final entity = LearningProgressMapper.toEntity(model);
      return Right(entity);
    } on DatabaseException catch (e) {
      _logger.e('Database error getting progress: $e');
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      _logger.e('Unexpected error getting progress: $e');
      return Left(DatabaseFailure('Failed to get progress: $e'));
    }
  }

  @override
  Future<Either<Failure, List<LearningProgressEntity>>> getAllProgress() async {
    try {
      final models = await progressDataSource.getAllProgress(_userId);
      final entities = models.map(LearningProgressMapper.toEntity).toList();
      return Right(entities);
    } on DatabaseException catch (e) {
      _logger.e('Database error getting all progress: $e');
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      _logger.e('Unexpected error getting all progress: $e');
      return Left(DatabaseFailure('Failed to get all progress: $e'));
    }
  }

  @override
  Stream<int> get dueReviewCount {
    return progressDataSource.dueReviewCountStream;
  }

  @override
  Future<Either<Failure, int>> getLearnedWordsCount() async {
    try {
      final count = await progressDataSource.getLearnedWordsCount(_userId);
      return Right(count);
    } on DatabaseException catch (e) {
      _logger.e('Database error getting learned words count: $e');
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      _logger.e('Unexpected error getting learned words count: $e');
      return Left(
        DatabaseFailure('Failed to get learned words count: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, int>> getMasteredWordsCount() async {
    try {
      final count = await progressDataSource.getMasteredWordsCount(_userId);
      return Right(count);
    } on DatabaseException catch (e) {
      _logger.e('Database error getting mastered words count: $e');
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      _logger.e('Unexpected error getting mastered words count: $e');
      return Left(
        DatabaseFailure('Failed to get mastered words count: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, int>> getLearningStreak() async {
    try {
      final streak = await progressDataSource.getLearningStreak(_userId);
      return Right(streak);
    } on DatabaseException catch (e) {
      _logger.e('Database error getting learning streak: $e');
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      _logger.e('Unexpected error getting learning streak: $e');
      return Left(DatabaseFailure('Failed to get learning streak: $e'));
    }
  }
}
