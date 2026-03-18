import '../../core/errors/failures.dart';
import '../../core/utils/either.dart';
import '../entities/vocabulary_entity.dart';
import '../repositories/vocabulary_repository.dart';
import '../../data/services/fsrs_service.dart';

/// Use case for getting words available for contextual enhancement
/// 
/// Returns words that have been learned (today + past) for practice exercises
/// Uses FSRS system to track learned words
class GetContextualWordsUseCase {
  final VocabularyRepository vocabRepository;
  final FsrsService fsrsService;

  GetContextualWordsUseCase({
    required this.vocabRepository,
    required this.fsrsService,
  });

  /// Get all words that have been learned (have FSRS cards)
  /// These are available for contextual enhancement exercises
  Future<Either<Failure, List<VocabularyEntity>>> call() async {
    try {
      if (!fsrsService.isInitialized()) {
        return const Right([]);
      }

      // 從 FSRS 獲取所有已學習的單字
      final learnedWords = fsrsService.getAllLearnedWords();
      
      if (learnedWords.isEmpty) {
        return const Right([]);
      }
      
      // 獲取這些單字的詳細資料
      final vocabResult = await vocabRepository.getVocabularyByWords(learnedWords);
      
      return vocabResult.fold(
        (failure) => Left(failure),
        (vocabList) => Right(vocabList),
      );
    } catch (e) {
      return Left(DatabaseFailure('Failed to get contextual words: $e'));
    }
  }

  /// Get words learned today only
  Future<Either<Failure, List<VocabularyEntity>>> getTodayWords() async {
    try {
      if (!fsrsService.isInitialized()) {
        return const Right([]);
      }

      // 從 FSRS 獲取今天學習的單字
      final todayWords = fsrsService.getTodayLearnedWords();
      
      if (todayWords.isEmpty) {
        return const Right([]);
      }
      
      final vocabResult = await vocabRepository.getVocabularyByWords(todayWords);
      
      return vocabResult.fold(
        (failure) => Left(failure),
        (vocabList) => Right(vocabList),
      );
    } catch (e) {
      return Left(DatabaseFailure('Failed to get today words: $e'));
    }
  }
}
