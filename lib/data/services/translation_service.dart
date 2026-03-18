import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import '../../core/utils/logger.dart';

/// Translation error types
enum TranslationErrorType {
  rateLimitExceeded,
  networkError,
  timeout,
  apiError,
  unknown,
}

/// Translation exception with detailed error information
class TranslationException implements Exception {
  final TranslationErrorType type;
  final String message;
  final String userMessage;

  TranslationException({
    required this.type,
    required this.message,
    required this.userMessage,
  });

  @override
  String toString() => userMessage;

  bool get isRateLimitError => type == TranslationErrorType.rateLimitExceeded;
  bool get isNetworkError => type == TranslationErrorType.networkError;
  bool get isTimeout => type == TranslationErrorType.timeout;
}

/// Translation cache model
class TranslationCache {
  final String sourceText;
  final String translatedText;
  final String sourceLang;
  final String targetLang;
  final DateTime cachedAt;

  TranslationCache({
    required this.sourceText,
    required this.translatedText,
    required this.sourceLang,
    required this.targetLang,
    required this.cachedAt,
  });

  Map<String, dynamic> toJson() => {
        'sourceText': sourceText,
        'translatedText': translatedText,
        'sourceLang': sourceLang,
        'targetLang': targetLang,
        'cachedAt': cachedAt.toIso8601String(),
      };

  factory TranslationCache.fromJson(Map<String, dynamic> json) {
    return TranslationCache(
      sourceText: json['sourceText'] as String,
      translatedText: json['translatedText'] as String,
      sourceLang: json['sourceLang'] as String,
      targetLang: json['targetLang'] as String,
      cachedAt: DateTime.parse(json['cachedAt'] as String),
    );
  }
}

/// Translation Service using MyMemory API
/// Free API with no API key required
/// Limit: 1000 requests per day per IP
class TranslationService {
  static const String _apiUrl = 'https://api.mymemory.translated.net/get';
  static const String _cacheBoxName = 'translation_cache';
  static const Duration _cacheDuration = Duration(days: 30);

  final Dio _dio;
  Box<Map>? _cacheBox;
  bool _isInitialized = false;

  TranslationService({Dio? dio}) : _dio = dio ?? Dio();

  /// Initialize the translation service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _cacheBox = await Hive.openBox<Map>(_cacheBoxName);
      _isInitialized = true;
      AppLogger.info('TranslationService initialized');
    } catch (e) {
      AppLogger.error('Failed to initialize TranslationService: $e');
      rethrow;
    }
  }

  /// Translate text from source language to target language
  /// 
  /// [text] - Text to translate
  /// [from] - Source language code (default: 'en')
  /// [to] - Target language code (default: 'zh-TW')
  /// 
  /// Returns translated text or throws TranslationException
  Future<String> translate(
    String text, {
    String from = 'en',
    String to = 'zh-TW',
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    // Check cache first
    final cached = await _getFromCache(text, from, to);
    if (cached != null) {
      AppLogger.debug('Translation cache hit: $text');
      return cached;
    }

    try {
      // Call MyMemory API
      final response = await _dio.get(
        _apiUrl,
        queryParameters: {
          'q': text,
          'langpair': '$from|$to',
        },
        options: Options(
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final responseData = data['responseData'] as Map<String, dynamic>;
        final translatedText = responseData['translatedText'] as String;

        // Check for rate limit error in the response
        // MyMemory API returns "QUOTA EXCEEDED" or similar messages when rate limited
        if (translatedText.toUpperCase().contains('QUOTA') ||
            translatedText.toUpperCase().contains('LIMIT') ||
            translatedText.toUpperCase().contains('TOO MANY REQUESTS')) {
          AppLogger.warning('Translation API rate limit reached');
          throw TranslationException(
            type: TranslationErrorType.rateLimitExceeded,
            message: '已達到每日翻譯次數上限（1000次/天）',
            userMessage: '已達到每日翻譯次數上限（1000次/天）\n請明天再試，或使用已快取的翻譯',
          );
        }

        // Check if translation quality is good
        final matches = data['matches'] as List?;
        if (matches != null && matches.isNotEmpty) {
          // Use the best match if available
          final bestMatch = matches.first as Map<String, dynamic>;
          final quality = bestMatch['quality'] as int?;
          if (quality != null && quality > 70) {
            final betterTranslation = bestMatch['translation'] as String;
            await _saveToCache(text, betterTranslation, from, to);
            return betterTranslation;
          }
        }

        // Save to cache
        await _saveToCache(text, translatedText, from, to);
        return translatedText;
      } else if (response.statusCode == 429) {
        // HTTP 429 Too Many Requests
        AppLogger.warning('Translation API rate limit (429)');
        throw TranslationException(
          type: TranslationErrorType.rateLimitExceeded,
          message: '已達到每日翻譯次數上限（1000次/天）',
          userMessage: '已達到每日翻譯次數上限（1000次/天）\n請明天再試，或使用已快取的翻譯',
        );
      } else if (response.statusCode == 403) {
        // HTTP 403 Forbidden (sometimes used for rate limiting)
        AppLogger.warning('Translation API forbidden (403)');
        throw TranslationException(
          type: TranslationErrorType.rateLimitExceeded,
          message: '翻譯服務暫時無法使用',
          userMessage: '翻譯服務暫時無法使用\n可能已達到使用限制，請稍後再試',
        );
      } else {
        AppLogger.warning('Translation API returned status: ${response.statusCode}');
        throw TranslationException(
          type: TranslationErrorType.apiError,
          message: '翻譯失敗',
          userMessage: '翻譯失敗，請稍後再試',
        );
      }
    } on TranslationException {
      // Re-throw translation exceptions
      rethrow;
    } on DioException catch (e) {
      if (e.response?.statusCode == 429 || e.response?.statusCode == 403) {
        // Rate limit error
        AppLogger.warning('Translation API rate limit: ${e.response?.statusCode}');
        throw TranslationException(
          type: TranslationErrorType.rateLimitExceeded,
          message: '已達到每日翻譯次數上限（1000次/天）',
          userMessage: '已達到每日翻譯次數上限（1000次/天）\n請明天再試，或使用已快取的翻譯',
        );
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        AppLogger.warning('Translation timeout: $e');
        throw TranslationException(
          type: TranslationErrorType.timeout,
          message: '翻譯超時',
          userMessage: '翻譯超時，請檢查網路連線',
        );
      } else if (e.type == DioExceptionType.connectionError) {
        AppLogger.warning('Translation connection error: $e');
        throw TranslationException(
          type: TranslationErrorType.networkError,
          message: '無法連線到翻譯服務',
          userMessage: '無法連線到翻譯服務\n請檢查網路連線',
        );
      } else {
        AppLogger.error('Translation error: $e');
        throw TranslationException(
          type: TranslationErrorType.apiError,
          message: '翻譯失敗',
          userMessage: '翻譯失敗，請稍後再試',
        );
      }
    } catch (e) {
      AppLogger.error('Unexpected translation error: $e');
      throw TranslationException(
        type: TranslationErrorType.unknown,
        message: '翻譯失敗',
        userMessage: '翻譯失敗，請稍後再試',
      );
    }
  }

  /// Batch translate multiple texts
  Future<List<String>> translateBatch(
    List<String> texts, {
    String from = 'en',
    String to = 'zh-TW',
  }) async {
    final results = <String>[];
    for (final text in texts) {
      final translation = await translate(text, from: from, to: to);
      results.add(translation);
      // Add small delay to avoid rate limiting
      await Future.delayed(const Duration(milliseconds: 100));
    }
    return results;
  }

  /// Get translation from cache
  Future<String?> _getFromCache(
    String text,
    String from,
    String to,
  ) async {
    if (_cacheBox == null) return null;

    try {
      final key = _getCacheKey(text, from, to);
      final cached = _cacheBox!.get(key);
      
      if (cached != null) {
        final cacheData = TranslationCache.fromJson(
          Map<String, dynamic>.from(cached),
        );
        
        // Check if cache is still valid
        final age = DateTime.now().difference(cacheData.cachedAt);
        if (age < _cacheDuration) {
          return cacheData.translatedText;
        } else {
          // Remove expired cache
          await _cacheBox!.delete(key);
        }
      }
    } catch (e) {
      AppLogger.error('Failed to get from cache: $e');
    }

    return null;
  }

  /// Save translation to cache
  Future<void> _saveToCache(
    String text,
    String translation,
    String from,
    String to,
  ) async {
    if (_cacheBox == null) return;

    try {
      final key = _getCacheKey(text, from, to);
      final cache = TranslationCache(
        sourceText: text,
        translatedText: translation,
        sourceLang: from,
        targetLang: to,
        cachedAt: DateTime.now(),
      );
      
      await _cacheBox!.put(key, cache.toJson());
      AppLogger.debug('Translation cached: $text');
    } catch (e) {
      AppLogger.error('Failed to save to cache: $e');
    }
  }

  /// Generate cache key
  String _getCacheKey(String text, String from, String to) {
    return '${from}_${to}_${text.hashCode}';
  }

  /// Clear all translation cache
  Future<void> clearCache() async {
    if (_cacheBox == null) return;

    try {
      await _cacheBox!.clear();
      AppLogger.info('Translation cache cleared');
    } catch (e) {
      AppLogger.error('Failed to clear cache: $e');
    }
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    if (_cacheBox == null) {
      return {
        'totalEntries': 0,
        'cacheSize': 0,
      };
    }

    try {
      final totalEntries = _cacheBox!.length;
      return {
        'totalEntries': totalEntries,
        'cacheSize': totalEntries * 200, // Rough estimate in bytes
      };
    } catch (e) {
      AppLogger.error('Failed to get cache stats: $e');
      return {
        'totalEntries': 0,
        'cacheSize': 0,
      };
    }
  }

  /// Dispose resources
  Future<void> dispose() async {
    await _cacheBox?.close();
    _isInitialized = false;
  }
}
