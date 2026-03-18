import 'package:logger/logger.dart';
import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../core/utils/either.dart';
import '../../domain/entities/vocabulary_entity.dart';
import '../../domain/repositories/vocabulary_repository.dart';
import '../datasources/local/vocabulary_local_datasource.dart';
import '../mappers/vocabulary_mapper.dart';
/// Implementation of VocabularyRepository using local Hive database
class VocabularyRepositoryImpl implements VocabularyRepository {
  final VocabularyLocalDataSource localDataSource;
  final Logger _logger = Logger();

  VocabularyRepositoryImpl({
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, List<VocabularyEntity>>> getAllVocabulary() async {
    try {
      final models = await localDataSource.getAllVocabulary();
      final entities = models.map(VocabularyMapper.toEntity).toList();
      return Right(entities);
    } on DatabaseException catch (e) {
      _logger.e('Database error getting all vocabulary: $e');
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      _logger.e('Unexpected error getting all vocabulary: $e');
      return Left(DatabaseFailure('Failed to get vocabulary: $e'));
    }
  }

  @override
  Future<Either<Failure, VocabularyEntity>> getVocabularyByWord(
    String word,
  ) async {
    try {
      final model = await localDataSource.getVocabularyByWord(word);
      if (model == null) {
        return Left(NotFoundFailure('Word not found: $word'));
      }
      final entity = VocabularyMapper.toEntity(model);
      return Right(entity);
    } on DatabaseException catch (e) {
      _logger.e('Database error getting vocabulary by word: $e');
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      _logger.e('Unexpected error getting vocabulary by word: $e');
      return Left(DatabaseFailure('Failed to get word: $e'));
    }
  }

  @override
  Future<Either<Failure, List<VocabularyEntity>>> getVocabularyByLevel(
    int level,
  ) async {
    try {
      final models = await localDataSource.getVocabularyByLevel(level.toString());
      final entities = models.map(VocabularyMapper.toEntity).toList();
      return Right(entities);
    } on DatabaseException catch (e) {
      _logger.e('Database error getting vocabulary by level: $e');
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      _logger.e('Unexpected error getting vocabulary by level: $e');
      return Left(DatabaseFailure('Failed to get vocabulary by level: $e'));
    }
  }

  @override
  Future<Either<Failure, List<VocabularyEntity>>> searchVocabulary(
    String query,
  ) async {
    try {
      if (query.isEmpty) {
        return const Right([]);
      }
      final models = await localDataSource.searchVocabulary(query);
      final entities = models.map(VocabularyMapper.toEntity).toList();
      return Right(entities);
    } on DatabaseException catch (e) {
      _logger.e('Database error searching vocabulary: $e');
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      _logger.e('Unexpected error searching vocabulary: $e');
      return Left(DatabaseFailure('Failed to search vocabulary: $e'));
    }
  }

  @override
  Future<Either<Failure, List<VocabularyEntity>>> getVocabularyByPartOfSpeech(
    String partOfSpeech,
  ) async {
    try {
      final models = await localDataSource.getVocabularyByPartOfSpeech(partOfSpeech);
      final entities = models.map(VocabularyMapper.toEntity).toList();
      return Right(entities);
    } on DatabaseException catch (e) {
      _logger.e('Database error getting vocabulary by part of speech: $e');
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      _logger.e('Unexpected error getting vocabulary by part of speech: $e');
      return Left(
        DatabaseFailure('Failed to get vocabulary by part of speech: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, List<VocabularyEntity>>> getVocabularyByFrequency({
    required int minFrequency,
    required int maxFrequency,
  }) async {
    try {
      // Get all vocabulary and filter by frequency
      final models = await localDataSource.getAllVocabulary();
      final filtered = models.where((model) {
        final freq = model.frequency?.importanceScore ?? 0.0;
        return freq >= minFrequency && freq <= maxFrequency;
      }).toList();
      final entities = filtered.map(VocabularyMapper.toEntity).toList();
      return Right(entities);
    } on DatabaseException catch (e) {
      _logger.e('Database error getting vocabulary by frequency: $e');
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      _logger.e('Unexpected error getting vocabulary by frequency: $e');
      return Left(
        DatabaseFailure('Failed to get vocabulary by frequency: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, int>> getVocabularyCount() async {
    try {
      final count = await localDataSource.getVocabularyCount();
      return Right(count);
    } on DatabaseException catch (e) {
      _logger.e('Database error getting vocabulary count: $e');
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      _logger.e('Unexpected error getting vocabulary count: $e');
      return Left(DatabaseFailure('Failed to get vocabulary count: $e'));
    }
  }

  @override
  Future<Either<Failure, List<VocabularyEntity>>> getVocabularyByWords(
    List<String> words,
  ) async {
    try {
      if (words.isEmpty) {
        return const Right([]);
      }
      
      final entities = <VocabularyEntity>[];
      for (final word in words) {
        final model = await localDataSource.getVocabularyByWord(word);
        if (model != null) {
          entities.add(VocabularyMapper.toEntity(model));
        }
      }
      
      return Right(entities);
    } on DatabaseException catch (e) {
      _logger.e('Database error getting vocabulary by words: $e');
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      _logger.e('Unexpected error getting vocabulary by words: $e');
      return Left(DatabaseFailure('Failed to get vocabulary by words: $e'));
    }
  }
}
