import '../../core/errors/failures.dart';
import '../../core/utils/either.dart';
import '../entities/vocabulary_entity.dart';

/// Repository interface for vocabulary data operations
abstract class VocabularyRepository {
  /// Get all vocabulary words from the database
  /// Returns list of [VocabularyEntity] on success or [DatabaseFailure] on failure
  Future<Either<Failure, List<VocabularyEntity>>> getAllVocabulary();

  /// Get a specific vocabulary word by its word string
  /// Returns [VocabularyEntity] on success or [NotFoundFailure] if not found
  Future<Either<Failure, VocabularyEntity>> getVocabularyByWord(String word);

  /// Get vocabulary words filtered by CEFR level
  /// Returns list of [VocabularyEntity] on success or [DatabaseFailure] on failure
  Future<Either<Failure, List<VocabularyEntity>>> getVocabularyByLevel(
    int level,
  );

  /// Search vocabulary words by query string
  /// Searches in word, definitions, and examples
  /// Returns list of matching [VocabularyEntity] on success or [DatabaseFailure] on failure
  Future<Either<Failure, List<VocabularyEntity>>> searchVocabulary(
    String query,
  );

  /// Get vocabulary words by part of speech
  /// Returns list of [VocabularyEntity] on success or [DatabaseFailure] on failure
  Future<Either<Failure, List<VocabularyEntity>>> getVocabularyByPartOfSpeech(
    String partOfSpeech,
  );

  /// Get vocabulary words by frequency range
  /// Returns list of [VocabularyEntity] on success or [DatabaseFailure] on failure
  Future<Either<Failure, List<VocabularyEntity>>> getVocabularyByFrequency({
    required int minFrequency,
    required int maxFrequency,
  });

  /// Get total count of vocabulary words
  /// Returns count on success or [DatabaseFailure] on failure
  Future<Either<Failure, int>> getVocabularyCount();

  /// Get vocabulary words by a list of word strings
  /// Returns list of [VocabularyEntity] on success or [DatabaseFailure] on failure
  Future<Either<Failure, List<VocabularyEntity>>> getVocabularyByWords(
    List<String> words,
  );
}
