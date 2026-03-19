import 'package:flutter/foundation.dart';
import '../../core/utils/logger.dart';

/// Global Audio Controller
/// Ensures only one audio plays at a time across the app
class GlobalAudioController extends ChangeNotifier {
  static final GlobalAudioController _instance = GlobalAudioController._internal();
  
  factory GlobalAudioController() => _instance;
  
  GlobalAudioController._internal();

  dynamic _currentTtsService; // Can be FlutterTtsService or EdgeTtsService
  String? _currentPlayingText;
  bool _isPlaying = false;

  /// Get current playing text
  String? get currentPlayingText => _currentPlayingText;

  /// Check if audio is currently playing
  bool get isPlaying => _isPlaying;

  /// Play audio using TTS
  /// Automatically stops any currently playing audio
  /// Supports both FlutterTtsService and EdgeTtsService
  Future<bool> playTts(dynamic ttsService, String text) async {
    // Stop any currently playing audio first
    await stopAll();

    _currentTtsService = ttsService;
    _currentPlayingText = text;
    _isPlaying = true;
    notifyListeners();

    try {
      final success = await ttsService.speak(text);
      
      if (success) {
        AppLogger.debug('TTS started playing: ${text.length > 50 ? "${text.substring(0, 50)}..." : text}');
        
        // Schedule automatic completion after a reasonable time
        // This ensures the UI updates even if completion handler doesn't fire
        _scheduleAutoCompletion(text);
        
        return true;
      } else {
        AppLogger.warning('TTS failed to start');
        _isPlaying = false;
        _currentPlayingText = null;
        _currentTtsService = null;
        notifyListeners();
        return false;
      }
    } catch (e) {
      AppLogger.error('Failed to play TTS: $e');
      _isPlaying = false;
      _currentPlayingText = null;
      _currentTtsService = null;
      notifyListeners();
      return false;
    }
  }

  /// Schedule automatic completion after estimated duration
  void _scheduleAutoCompletion(String text) {
    // Estimate duration: ~120 words per minute at 0.45 speech rate (slower for learning)
    // That's ~2 words per second, or ~0.5 seconds per word
    final wordCount = text.split(' ').length;
    final estimatedSeconds = (wordCount * 0.5).ceil() + 2; // Add 2 second buffer
    
    Future.delayed(Duration(seconds: estimatedSeconds), () {
      // Only mark as completed if this text is still the current one
      if (_currentPlayingText == text && _isPlaying) {
        AppLogger.debug('Auto-completing TTS playback');
        markCompleted();
      }
    });
  }

  /// Stop all currently playing audio
  Future<void> stopAll() async {
    if (_currentTtsService != null) {
      try {
        await _currentTtsService!.stop();
        AppLogger.debug('Stopped TTS: $_currentPlayingText');
      } catch (e) {
        AppLogger.error('Error stopping TTS: $e');
      }
    }

    _currentTtsService = null;
    _currentPlayingText = null;
    _isPlaying = false;
    notifyListeners();
  }

  /// Pause current audio
  Future<void> pause() async {
    if (_currentTtsService != null) {
      try {
        // Check if service has pause method (FlutterTtsService does, EdgeTtsService doesn't)
        if (_currentTtsService.runtimeType.toString().contains('FlutterTts')) {
          await _currentTtsService!.pause();
        } else {
          // For services without pause, just stop
          await _currentTtsService!.stop();
        }
        _isPlaying = false;
        notifyListeners();
      } catch (e) {
        AppLogger.error('Error pausing TTS: $e');
      }
    }
  }

  /// Mark audio as completed (called by TTS completion handler)
  void markCompleted() {
    _isPlaying = false;
    _currentPlayingText = null;
    _currentTtsService = null;
    notifyListeners();
  }

  /// Check if specific text is currently playing
  bool isPlayingText(String text) {
    return _isPlaying && _currentPlayingText == text;
  }
}
