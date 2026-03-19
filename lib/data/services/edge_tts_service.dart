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
  double _speechRate = 0.45; // Default speech rate
  bool _isInitialized = false;
  VoidCallback? onComplete;

  EdgeTtsService({AudioPlayer? audioPlayer, Dio? dio})
      : _audioPlayer = audioPlayer ?? AudioPlayer(),
        _dio = dio ?? Dio();

  /// Initialize the service
  Future<void> initialize({double speechRate = 0.45}) async {
    if (_isInitialized) return;

    try {
      _speechRate = speechRate; // Store speech rate
      
      // Setup audio player completion handler
      _audioPlayer.onPlayerComplete.listen((_) {
        AppLogger.debug('Edge TTS audio playback completed');
        onComplete?.call();
      });

      _isInitialized = true;
      AppLogger.info('Edge TTS service initialized with speech rate: $speechRate');
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
  Future<bool> speak(String text, {PronunciationType? pronunciationType, double? speechRate}) async {
    try {
      if (!_isInitialized) {
        await initialize(speechRate: speechRate ?? 0.45);
      }

      // Update speech rate if provided
      if (speechRate != null) {
        _speechRate = speechRate;
      }

      // Set voice if pronunciation type provided
      if (pronunciationType != null) {
        await setVoice(pronunciationType);
      }

      AppLogger.info('Edge TTS speaking: $text with voice: $_currentVoice at rate: $_speechRate');

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
    // Convert speech rate (0.1-1.0) to percentage (-90% to 0%)
    // 0.45 -> -55%, 0.5 -> -50%, 1.0 -> 0%
    final ratePercent = ((_speechRate - 1.0) * 100).round();
    
    return '''
<speak version='1.0' xmlns='http://www.w3.org/2001/10/synthesis' xml:lang='en-US'>
  <voice name='$voice'>
    <prosody rate='$ratePercent%' pitch='0%'>
      $text
    </prosody>
  </voice>
</speak>
''';
  }

  /// Synthesize speech using Edge TTS API
  Future<List<int>?> _synthesizeSpeech(String ssml) async {
    try {
      // Edge TTS endpoint - using the correct WebSocket-based API endpoint
      const endpoint = 'https://speech.platform.bing.com/consumer/speech/synthesize/readaloud/edge/v1';
      
      final response = await _dio.post(
        endpoint,
        data: ssml,
        options: Options(
          headers: {
            'Content-Type': 'application/ssml+xml',
            'X-Microsoft-OutputFormat': 'audio-24khz-48kbitrate-mono-mp3',
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36 Edg/120.0.0.0',
          },
          responseType: ResponseType.bytes,
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode != 200) {
        AppLogger.error('Edge TTS API returned status ${response.statusCode}');
        throw Exception('Edge TTS API 回應錯誤: HTTP ${response.statusCode}');
      }

      final data = response.data;
      if (data == null || (data is List && data.isEmpty)) {
        throw Exception('Edge TTS API 回應為空');
      }

      return data as List<int>;
    } catch (e, stackTrace) {
      AppLogger.error('Error synthesizing speech with Edge TTS', e, stackTrace);
      // Provide more user-friendly error message
      if (e.toString().contains('SocketException') || e.toString().contains('Connection')) {
        throw Exception('無法連接到 Edge TTS 服務，請檢查網路連線');
      }
      rethrow;
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
