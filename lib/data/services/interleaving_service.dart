import '../../domain/entities/entities.dart';
import '../../domain/services/interleaving_strategy.dart';
import '../datasources/remote/datamuse_api_client.dart';
import '../../domain/repositories/vocabulary_repository.dart';

/// Enhanced interleaving service with API integration
class InterleavingService {
  final InterleavingStrategy _strategy;
  final DatamuseAPIClient _datamuseClient;
  final VocabularyRepository _vocabularyRepository;

  InterleavingService({
    required InterleavingStrategy strategy,
    required DatamuseAPIClient datamuseClient,
    required VocabularyRepository vocabularyRepository,
  })  : _strategy = strategy,
        _datamuseClient = datamuseClient,
        _vocabularyRepository = vocabularyRepository;

  /// Interleave words with API-enhanced confusing pair detection
  Future<List<VocabularyEntity>> interleaveWithConfusingPairs(
    List<VocabularyEntity> words,
  ) async {
    // First, apply basic interleaving
    final interleaved = _strategy.interleaveWords(words);

    // Identify confusing pairs using local algorithm
    final localPairs = _strategy.identifyConfusingPairs(words);

    // Enhance with API-based confusing pairs
    final apiPairs = await _identifyConfusingPairsWithAPI(words);

    // Combine both sources
    final allPairs = {...localPairs, ...apiPairs}.toList();

    // Mix confusing pairs into the session
    final mixed = _strategy.mixConfusingPairs(
      words: interleaved,
      confusingPairs: allPairs,
    );

    return mixed;
  }

  /// Identify confusing pairs using Datamuse API
  Future<List<ConfusingPair>> _identifyConfusingPairsWithAPI(
    List<VocabularyEntity> words,
  ) async {
    final pairs = <ConfusingPair>[];

    for (final word in words) {
      try {
        // Get confusing words from API
        final confusingWords = await _datamuseClient.findConfusingWords(
          word.lemma,
        );

        // Find matching words in our vocabulary
        for (final confusingWord in confusingWords) {
          final matchingWord = words.firstWhere(
            (w) => w.lemma.toLowerCase() == confusingWord.toLowerCase(),
            orElse: () => word, // Return dummy if not found
          );

          if (matchingWord != word) {
            pairs.add(ConfusingPair(word1: word, word2: matchingWord));
          }
        }
      } catch (e) {
        // API failed, continue with next word
        continue;
      }
    }

    return pairs;
  }

  /// Get confusing pairs for a specific word
  Future<List<VocabularyEntity>> getConfusingPairsForWord(
    VocabularyEntity word,
  ) async {
    final confusingPairs = <VocabularyEntity>[];

    try {
      // Get confusing words from API
      final confusingWords = await _datamuseClient.findConfusingWords(
        word.lemma,
      );

      // Convert to VocabularyEntity
      for (final confusingWord in confusingWords) {
        final result = await _vocabularyRepository.getVocabularyByWord(
          confusingWord,
        );

        result.fold(
          (failure) {
            // Word not found, skip
          },
          (vocabEntity) {
            if (vocabEntity.lemma != word.lemma) {
              confusingPairs.add(vocabEntity);
            }
          },
        );
      }
    } catch (e) {
      // API failed, return empty list
    }

    return confusingPairs;
  }

  /// Validate that interleaving meets the requirements
  bool validateInterleaving(List<VocabularyEntity> words) {
    return _strategy.validateInterleaving(words);
  }

  /// Apply interleaving to a learning session
  Future<List<VocabularyEntity>> applyInterleavingToSession({
    required List<VocabularyEntity> dueReviews,
    required List<VocabularyEntity> newWords,
  }) async {
    // Combine due reviews and new words
    final allWords = [...dueReviews, ...newWords];

    // Apply interleaving with confusing pairs
    return await interleaveWithConfusingPairs(allWords);
  }
}
