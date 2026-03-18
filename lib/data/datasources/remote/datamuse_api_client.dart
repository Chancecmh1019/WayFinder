import 'api_client_base.dart';
import '../../../core/errors/exceptions.dart';

/// Datamuse API client for word associations and similarity
class DatamuseAPIClient extends APIClientBase {
  DatamuseAPIClient({super.dio})
      : super(
          baseUrl: 'https://api.datamuse.com',
        );

  /// Find words with similar meaning
  Future<List<String>> findSimilarMeaning(
    String word, {
    int limit = 10,
  }) async {
    try {
      final response = await get<List<dynamic>>(
        '/words',
        queryParameters: {
          'ml': word, // means like
          'max': limit,
        },
      );

      return response.map((item) => item['word'] as String).toList();
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to find similar meaning words: $e');
    }
  }

  /// Find words with similar spelling
  Future<List<String>> findSimilarSpelling(
    String word, {
    int limit = 10,
  }) async {
    try {
      final response = await get<List<dynamic>>(
        '/words',
        queryParameters: {
          'sp': word, // spelled like
          'max': limit,
        },
      );

      return response.map((item) => item['word'] as String).toList();
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to find similar spelling words: $e');
    }
  }

  /// Find words with similar pronunciation
  Future<List<String>> findSimilarSound(
    String word, {
    int limit = 10,
  }) async {
    try {
      final response = await get<List<dynamic>>(
        '/words',
        queryParameters: {
          'sl': word, // sounds like
          'max': limit,
        },
      );

      return response.map((item) => item['word'] as String).toList();
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to find similar sound words: $e');
    }
  }

  /// Find rhyming words
  Future<List<String>> findRhymes(
    String word, {
    int limit = 10,
  }) async {
    try {
      final response = await get<List<dynamic>>(
        '/words',
        queryParameters: {
          'rel_rhy': word, // rhymes with
          'max': limit,
        },
      );

      return response.map((item) => item['word'] as String).toList();
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to find rhymes: $e');
    }
  }

  /// Find words that frequently follow the given word
  Future<List<String>> findFollowers(
    String word, {
    int limit = 10,
  }) async {
    try {
      final response = await get<List<dynamic>>(
        '/words',
        queryParameters: {
          'lc': word, // left context
          'max': limit,
        },
      );

      return response.map((item) => item['word'] as String).toList();
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to find followers: $e');
    }
  }

  /// Find words that frequently precede the given word
  Future<List<String>> findPreceders(
    String word, {
    int limit = 10,
  }) async {
    try {
      final response = await get<List<dynamic>>(
        '/words',
        queryParameters: {
          'rc': word, // right context
          'max': limit,
        },
      );

      return response.map((item) => item['word'] as String).toList();
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to find preceders: $e');
    }
  }

  /// Find words related by topic
  Future<List<String>> findRelatedByTopic(
    String word, {
    int limit = 10,
  }) async {
    try {
      final response = await get<List<dynamic>>(
        '/words',
        queryParameters: {
          'rel_trg': word, // related trigger words
          'max': limit,
        },
      );

      return response.map((item) => item['word'] as String).toList();
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to find related words: $e');
    }
  }

  /// Get comprehensive word associations
  Future<Map<String, List<String>>> getWordAssociations(
    String word, {
    int limitPerType = 5,
  }) async {
    try {
      final results = await Future.wait([
        findSimilarMeaning(word, limit: limitPerType),
        findSimilarSpelling(word, limit: limitPerType),
        findSimilarSound(word, limit: limitPerType),
        findRelatedByTopic(word, limit: limitPerType),
      ]);

      return {
        'similarMeaning': results[0],
        'similarSpelling': results[1],
        'similarSound': results[2],
        'relatedTopic': results[3],
      };
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to get word associations: $e');
    }
  }

  /// Find confusing words (similar spelling or sound)
  Future<List<String>> findConfusingWords(
    String word, {
    int limit = 10,
  }) async {
    try {
      // Get both similar spelling and similar sound words
      final results = await Future.wait([
        findSimilarSpelling(word, limit: limit ~/ 2),
        findSimilarSound(word, limit: limit ~/ 2),
      ]);

      // Combine and deduplicate
      final confusingWords = <String>{
        ...results[0],
        ...results[1],
      }.toList();

      return confusingWords.take(limit).toList();
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to find confusing words: $e');
    }
  }
}
