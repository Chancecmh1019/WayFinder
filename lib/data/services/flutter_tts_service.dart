import 'package:flutter_tts/flutter_tts.dart';
import '../../core/utils/logger.dart';

/// Flutter TTS Service for offline text-to-speech
/// This is the primary TTS solution for the app
class FlutterTtsService {
  final FlutterTts _flutterTts;
  bool _isInitialized = false;
  bool _isPlaying = false;
  
  /// Callback to notify when TTS completes
  void Function()? onComplete;

  FlutterTtsService({FlutterTts? flutterTts})
      : _flutterTts = flutterTts ?? FlutterTts();

  /// Initialize TTS with default settings
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _flutterTts.setLanguage("en-US");
      await _flutterTts.setSpeechRate(0.85); // Natural pace for learning
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      // Set up handlers
      _flutterTts.setStartHandler(() {
        _isPlaying = true;
        AppLogger.debug('TTS started');
      });

      _flutterTts.setCompletionHandler(() {
        _isPlaying = false;
        AppLogger.debug('TTS completed');
        onComplete?.call();
      });

      _flutterTts.setCancelHandler(() {
        _isPlaying = false;
        AppLogger.debug('TTS cancelled');
        onComplete?.call();
      });

      _flutterTts.setErrorHandler((msg) {
        _isPlaying = false;
        AppLogger.error('TTS error: $msg');
      });

      _isInitialized = true;
      AppLogger.info('FlutterTTS initialized successfully');
    } catch (e) {
      AppLogger.error('Failed to initialize TTS: $e');
      rethrow;
    }
  }

  /// Speak the given text
  Future<bool> speak(String text) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      if (_isPlaying) {
        await stop();
      }

      // Ensure speech rate is set before every speak call
      // This prevents system or other factors from changing the rate
      await _flutterTts.setSpeechRate(0.85);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      final result = await _flutterTts.speak(text);
      return result == 1; // 1 means success
    } catch (e) {
      AppLogger.error('Failed to speak: $e');
      return false;
    }
  }

  /// Stop current speech
  Future<void> stop() async {
    try {
      await _flutterTts.stop();
      _isPlaying = false;
    } catch (e) {
      AppLogger.error('Failed to stop TTS: $e');
    }
  }

  /// Pause current speech
  Future<void> pause() async {
    try {
      await _flutterTts.pause();
    } catch (e) {
      AppLogger.error('Failed to pause TTS: $e');
    }
  }

  /// Set speech rate (0.0 to 1.0)
  Future<void> setSpeechRate(double rate) async {
    try {
      await _flutterTts.setSpeechRate(rate);
    } catch (e) {
      AppLogger.error('Failed to set speech rate: $e');
    }
  }

  /// Set volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    try {
      await _flutterTts.setVolume(volume);
    } catch (e) {
      AppLogger.error('Failed to set volume: $e');
    }
  }

  /// Set pitch (0.5 to 2.0)
  Future<void> setPitch(double pitch) async {
    try {
      await _flutterTts.setPitch(pitch);
    } catch (e) {
      AppLogger.error('Failed to set pitch: $e');
    }
  }

  /// Set language and try to select appropriate voice
  Future<void> setLanguage(String language) async {
    try {
      await _flutterTts.setLanguage(language);
      
      // Try to set a specific voice for better quality
      final voices = await getVoices();
      
      // Filter voices by language
      final matchingVoices = voices.where((voice) {
        final voiceLang = voice['locale'] ?? voice['language'] ?? '';
        return voiceLang.toLowerCase().contains(language.toLowerCase().replaceAll('-', ''));
      }).toList();
      
      if (matchingVoices.isNotEmpty) {
        // Prefer first matching voice
        final voiceName = matchingVoices.first['name'];
        if (voiceName != null) {
          await _flutterTts.setVoice({'name': voiceName, 'locale': language});
          AppLogger.debug('Set voice: $voiceName for language: $language');
        }
      }
    } catch (e) {
      AppLogger.error('Failed to set language: $e');
    }
  }

  /// Get available languages
  Future<List<String>> getLanguages() async {
    try {
      final languages = await _flutterTts.getLanguages;
      return List<String>.from(languages);
    } catch (e) {
      AppLogger.error('Failed to get languages: $e');
      return [];
    }
  }

  /// Get available voices
  Future<List<Map<String, String>>> getVoices() async {
    try {
      final voices = await _flutterTts.getVoices;
      return List<Map<String, String>>.from(
        voices.map((voice) => Map<String, String>.from(voice)),
      );
    } catch (e) {
      AppLogger.error('Failed to get voices: $e');
      return [];
    }
  }

  /// Check if currently playing
  bool get isPlaying => _isPlaying;

  /// Check if initialized
  bool get isInitialized => _isInitialized;

  /// Dispose resources
  void dispose() {
    _flutterTts.stop();
    _isInitialized = false;
    _isPlaying = false;
  }
}
