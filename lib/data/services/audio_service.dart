import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../core/utils/logger.dart';
import 'audio_cache_manager.dart';
import 'flutter_tts_service.dart';
import 'global_audio_controller.dart';

/// Audio pronunciation types
enum PronunciationType {
  us, // 美式發音
  uk, // 英式發音
}

/// Audio service for playing word pronunciations
/// 
/// Audio source priority:
/// 1. Local assets (from vocab.json.gz)
/// 2. Local cache (downloaded audio)
/// 3. TTS fallback (flutter_tts service - offline)
class AudioService {
  final AudioPlayer _audioPlayer;
  final AudioCacheManager _cacheManager;
  final FlutterTtsService _ttsService;
  final GlobalAudioController? _globalAudioController;

  AudioService({
    AudioPlayer? audioPlayer,
    AudioCacheManager? cacheManager,
    FlutterTtsService? ttsService,
    GlobalAudioController? globalAudioController,
  })  : _audioPlayer = audioPlayer ?? AudioPlayer(),
        _cacheManager = cacheManager ?? AudioCacheManager(),
        _ttsService = ttsService ?? FlutterTtsService(),
        _globalAudioController = globalAudioController;

  /// Initialize the audio service
  Future<void> initialize() async {
    await _cacheManager.initialize();
    await _ttsService.initialize();
    AppLogger.info('Audio service initialized');
  }

  /// Play pronunciation for a word
  /// 
  /// Priority:
  /// 1. Check if word has audioUrl in vocabulary database (local assets)
  /// 2. Check local cache for downloaded audio
  /// 3. Use TTS fallback (flutter_tts service - offline)
  Future<Either<Failure, void>> playPronunciation({
    required String word,
    String? audioUrl,
    PronunciationType type = PronunciationType.us,
  }) async {
    try {
      // Stop any currently playing audio first
      if (_globalAudioController != null) {
        await _globalAudioController.stopAll();
      }
      
      AppLogger.info('Playing pronunciation for word: $word');

      // Priority 1: Use provided audioUrl (from vocabulary database)
      if (audioUrl != null && audioUrl.isNotEmpty) {
        AppLogger.debug('Using audio URL from vocabulary database');
        final result = await _playFromUrl(audioUrl);
        if (result.isRight()) {
          return result;
        }
        AppLogger.warning('Failed to play from vocabulary URL, trying cache');
      }

      // Priority 2: Check local cache
      final cacheKey = _getCacheKey(word, type);
      final cacheEntry = _cacheManager.getEntry(cacheKey);
      
      if (cacheEntry != null) {
        AppLogger.debug('Playing from cache: $cacheKey');
        
        // Update access time
        await _cacheManager.updateAccess(cacheKey);
        
        final result = await _playFromFile(cacheEntry.filePath);
        if (result.isRight()) {
          return result;
        }
        AppLogger.warning('Failed to play from cache, falling back to TTS');
      }

      // Priority 3: Use TTS fallback with global audio controller
      AppLogger.debug('Using TTS fallback for word: $word');
      return await _playWithTts(word, type);
    } catch (e, stackTrace) {
      AppLogger.error('Error playing pronunciation', e, stackTrace);
      return Left(ServerFailure('Failed to play pronunciation: $e', stackTrace));
    }
  }

  /// Preload audio for multiple words
  /// 
  /// Downloads and caches audio files in the background
  /// Note: Without Wordnik API, this only validates cache entries
  Future<void> preloadAudio(List<String> words) async {
    AppLogger.info('Checking audio cache for ${words.length} words');

    for (final word in words) {
      try {
        // Check if already cached
        final cacheKey = _getCacheKey(word, PronunciationType.us);
        final cacheEntry = _cacheManager.getEntry(cacheKey);
        
        if (cacheEntry != null) {
          AppLogger.debug('Word already cached: $word');
          continue;
        }

        AppLogger.debug('No cached audio for word: $word (TTS will be used)');
      } catch (e) {
        AppLogger.warning('Failed to check cache for word: $word - $e');
        // Continue with next word
      }
    }

    AppLogger.info('Audio cache check complete');
  }

  /// Clear audio cache
  Future<void> clearCache() async {
    try {
      AppLogger.info('Clearing audio cache');
      await _cacheManager.clearAll();
      AppLogger.info('Audio cache cleared');
    } catch (e, stackTrace) {
      AppLogger.error('Error clearing cache', e, stackTrace);
    }
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    final stats = await _cacheManager.getStats();
    
    return {
      'entryCount': stats.entryCount,
      'sizeBytes': stats.totalSizeBytes,
      'sizeMB': stats.totalSizeMB.toStringAsFixed(2),
      'maxSizeMB': (AudioCacheManager.maxCacheSizeBytes / (1024 * 1024)).toStringAsFixed(0),
      'usagePercent': stats.getUsagePercentage(AudioCacheManager.maxCacheSizeBytes).toStringAsFixed(1),
      'expiredCount': stats.expiredCount,
    };
  }

  /// Dispose resources
  Future<void> dispose() async {
    await _audioPlayer.dispose();
    await _cacheManager.close();
    _ttsService.dispose();
  }

  // Private helper methods

  /// Play audio using TTS
  Future<Either<Failure, void>> _playWithTts(String word, PronunciationType type) async {
    try {
      // Set language based on pronunciation type
      final language = type == PronunciationType.us ? 'en-US' : 'en-GB';
      await _ttsService.setLanguage(language);
      
      // Use global audio controller if available, otherwise use TTS service directly
      bool success;
      if (_globalAudioController != null) {
        success = await _globalAudioController.playTts(_ttsService, word);
      } else {
        success = await _ttsService.speak(word);
      }
      
      if (success) {
        AppLogger.debug('TTS played successfully: $word ($language)');
        return const Right(null);
      } else {
        return Left(ServerFailure('TTS failed to play: $word'));
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error playing with TTS', e, stackTrace);
      return Left(ServerFailure('Failed to play with TTS: $e', stackTrace));
    }
  }

  /// Play audio from URL
  Future<Either<Failure, void>> _playFromUrl(String url) async {
    try {
      await _audioPlayer.play(UrlSource(url));
      return const Right(null);
    } catch (e, stackTrace) {
      AppLogger.error('Error playing from URL', e, stackTrace);
      return Left(ServerFailure('Failed to play from URL: $e', stackTrace));
    }
  }

  /// Play audio from local file
  Future<Either<Failure, void>> _playFromFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return Left(NotFoundFailure('Audio file not found: $filePath'));
      }

      await _audioPlayer.play(DeviceFileSource(filePath));
      return const Right(null);
    } catch (e, stackTrace) {
      AppLogger.error('Error playing from file', e, stackTrace);
      return Left(ServerFailure('Failed to play from file: $e', stackTrace));
    }
  }

  /// Generate cache key for word and pronunciation type
  String _getCacheKey(String word, PronunciationType type) {
    return '${word}_${type.name}';
  }
}
