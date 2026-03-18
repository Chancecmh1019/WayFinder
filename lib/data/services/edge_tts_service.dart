import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import '../../core/utils/logger.dart';
import '../../domain/entities/user_settings.dart';

/// Edge TTS Service
/// 
/// 使用 Microsoft Edge TTS API 提供高品質多國口音語音合成
class EdgeTtsService {
  final AudioPlayer _audioPlayer;
  final Dio _dio;
  String _currentVoice = 'en-US-GuyNeural';
  bool _isInitialized = false;
  VoidCallback? onComplete;

  EdgeTtsService({AudioPlayer? audioPlayer, Dio? dio})
      : _audioPlayer = audioPlayer ?? AudioPlayer(),
        _dio = dio ?? Dio();

  /// Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Setup audio player completion handler
      _audioPlayer.onPlayerComplete.listen((_) {
        AppLogger.debug('Edge TTS audio playback completed');
        onComplete?.call();
      });

      _isInitialized = true;
      AppLogger.info('Edge TTS service initialized');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to initialize Edge TTS service', e, stackTrace);
      rethrow;
    }
  }

  /// Set voice based on pronunciation type
  Future<void> setVoice(PronunciationType type) async {
    _currentVoice = type.edgeTtsVoice;
    AppLogger.debug('Edge TTS voice set to: $_currentVoice');
  }

  /// Speak text using Edge TTS
  Future<bool> speak(String text, {PronunciationType? pronunciationType}) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      // Set voice if pronunciation type provided
      if (pronunciationType != null) {
        await setVoice(pronunciationType);
      }

      AppLogger.info('Edge TTS speaking: $text with voice: $_currentVoice');

      // Generate SSML
      final ssml = _generateSsml(text, _currentVoice);
      
      // Call Edge TTS API
      final audioBytes = await _synthesizeSpeech(ssml);

      if (audioBytes == null || audioBytes.isEmpty) {
        AppLogger.error('Edge TTS returned empty audio data');
        return false;
      }

      // Save to temporary file
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/edge_tts_${DateTime.now().millisecondsSinceEpoch}.mp3');
      await tempFile.writeAsBytes(audioBytes);

      // Play the audio
      await _audioPlayer.play(DeviceFileSource(tempFile.path));

      // Clean up temp file after a delay
      Future.delayed(const Duration(seconds: 10), () {
        if (tempFile.existsSync()) {
          tempFile.deleteSync();
        }
      });

      return true;
    } catch (e, stackTrace) {
      AppLogger.error('Edge TTS speak error', e, stackTrace);
      return false;
    }
  }

  /// Generate SSML for Edge TTS
  String _generateSsml(String text, String voice) {
    return '''
<speak version='1.0' xmlns='http://www.w3.org/2001/10/synthesis' xml:lang='en-US'>
  <voice name='$voice'>
    <prosody rate='0%' pitch='0%'>
      $text
    </prosody>
  </voice>
</speak>
''';
  }

  /// Synthesize speech using Edge TTS API
  Future<List<int>?> _synthesizeSpeech(String ssml) async {
    try {
      // Edge TTS endpoint
      const endpoint = 'https://speech.platform.bing.com/consumer/speech/synthesize/readaloud/edge/v1';
      
      final response = await _dio.post(
        endpoint,
        data: ssml,
        options: Options(
          headers: {
            'Content-Type': 'application/ssml+xml',
            'X-Microsoft-OutputFormat': 'audio-24khz-48kbitrate-mono-mp3',
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          },
          responseType: ResponseType.bytes,
        ),
      );

      return response.data as List<int>;
    } catch (e, stackTrace) {
      AppLogger.error('Error synthesizing speech', e, stackTrace);
      return null;
    }
  }

  /// Stop current playback
  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
      AppLogger.debug('Edge TTS playback stopped');
    } catch (e, stackTrace) {
      AppLogger.error('Error stopping Edge TTS playback', e, stackTrace);
    }
  }

  /// Check if currently playing
  Future<bool> isPlaying() async {
    try {
      final state = _audioPlayer.state;
      return state == PlayerState.playing;
    } catch (e) {
      return false;
    }
  }

  /// Dispose resources
  Future<void> dispose() async {
    try {
      await _audioPlayer.dispose();
      _dio.close();
      _isInitialized = false;
      AppLogger.info('Edge TTS service disposed');
    } catch (e, stackTrace) {
      AppLogger.error('Error disposing Edge TTS service', e, stackTrace);
    }
  }
}
