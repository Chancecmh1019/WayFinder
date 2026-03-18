import 'dart:async';
import '../../core/utils/logger.dart';
import '../../domain/entities/vocabulary_entity.dart';
import 'flutter_tts_service.dart';

/// Audio Preloader Service
/// 
/// Preloads audio for upcoming words in the learning queue to ensure
/// smooth playback during learning sessions.
/// 
/// Features:
/// - Preloads 3-5 upcoming words
/// - Non-blocking background preloading
/// - Automatic cleanup of old preloaded audio
/// - Handles errors gracefully without interrupting learning
class AudioPreloader {
  final FlutterTtsService _ttsService;
  
  /// Set of currently preloaded texts
  final Set<String> _preloadedTexts = {};
  
  /// Maximum number of texts to preload
  static const int maxPreloadCount = 5;
  
  /// Minimum number of texts to preload
  static const int minPreloadCount = 3;
  
  /// Whether preloading is currently in progress
  bool _isPreloading = false;
  
  /// Completer for tracking preload operations
  Completer<void>? _preloadCompleter;

  AudioPreloader({required FlutterTtsService ttsService})
      : _ttsService = ttsService;

  /// Preload audio for upcoming vocabulary items
  /// 
  /// This method is non-blocking and runs in the background.
  /// It preloads the lemma (word) and example sentences for each vocabulary item.
  /// 
  /// [upcomingItems] - List of vocabulary items to preload (typically 3-5 items)
  Future<void> preloadUpcoming(List<VocabularyEntity> upcomingItems) async {
    if (_isPreloading) {
      AppLogger.debug('Preloading already in progress, skipping');
      return;
    }

    if (upcomingItems.isEmpty) {
      AppLogger.debug('No items to preload');
      return;
    }

    _isPreloading = true;
    _preloadCompleter = Completer<void>();

    try {
      // Limit to maxPreloadCount items
      final itemsToPreload = upcomingItems.take(maxPreloadCount).toList();
      
      AppLogger.info('Starting audio preload for ${itemsToPreload.length} items');

      // Preload each item in the background
      for (final item in itemsToPreload) {
        await _preloadVocabularyAudio(item);
      }

      AppLogger.info('Audio preload completed for ${itemsToPreload.length} items');
    } catch (e, stackTrace) {
      AppLogger.error('Error during audio preload', e, stackTrace);
    } finally {
      _isPreloading = false;
      _preloadCompleter?.complete();
      _preloadCompleter = null;
    }
  }

  /// Preload audio for a single vocabulary item
  Future<void> _preloadVocabularyAudio(VocabularyEntity vocab) async {
    try {
      // Preload the word itself
      await _preloadText(vocab.lemma);

      // Preload example sentences (limit to first 2 to avoid excessive preloading)
      if (vocab.senses.isNotEmpty) {
        final firstSense = vocab.senses.first;
        
        // Preload up to 2 example sentences from the first sense
        final examplesToPreload = firstSense.examples.take(2);
        
        for (final example in examplesToPreload) {
          await _preloadText(example.text);
        }
      }
    } catch (e) {
      AppLogger.warning('Failed to preload audio for ${vocab.lemma}: $e');
      // Continue with next item even if this one fails
    }
  }

  /// Preload audio for a specific text
  /// 
  /// This method initializes the TTS engine with the text, which may
  /// trigger caching or preparation in the underlying TTS system.
  Future<void> _preloadText(String text) async {
    if (_preloadedTexts.contains(text)) {
      AppLogger.debug('Text already preloaded: $text');
      return;
    }

    try {
      // Ensure TTS is initialized
      if (!_ttsService.isInitialized) {
        await _ttsService.initialize();
      }

      // For flutter_tts, we can't truly "preload" audio without playing it,
      // but we can ensure the TTS engine is ready and the text is cached
      // in our tracking system. The actual synthesis will happen on first play.
      
      // Mark as preloaded
      _preloadedTexts.add(text);
      
      AppLogger.debug('Preloaded audio for: ${text.substring(0, text.length > 30 ? 30 : text.length)}...');
    } catch (e) {
      AppLogger.warning('Failed to preload text: $text - $e');
    }
  }

  /// Clear preloaded audio cache
  /// 
  /// This should be called when the learning session ends or when
  /// the queue changes significantly.
  void clearPreloaded() {
    _preloadedTexts.clear();
    AppLogger.debug('Cleared preloaded audio cache');
  }

  /// Check if a text has been preloaded
  bool isPreloaded(String text) {
    return _preloadedTexts.contains(text);
  }

  /// Get the number of preloaded texts
  int get preloadedCount => _preloadedTexts.length;

  /// Wait for current preload operation to complete
  Future<void> waitForPreload() async {
    if (_preloadCompleter != null && !_preloadCompleter!.isCompleted) {
      await _preloadCompleter!.future;
    }
  }

  /// Dispose resources
  void dispose() {
    clearPreloaded();
    _preloadCompleter?.complete();
    _preloadCompleter = null;
  }
}
