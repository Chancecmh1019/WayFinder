import 'package:dio/dio.dart';
import '../../core/utils/logger.dart';

/// Google Cloud TTS Service for online text-to-speech
/// This is a backup TTS solution requiring internet connection
/// Note: Requires Google Cloud TTS API key to be configured
class GoogleTtsService {
  static const String _apiEndpoint = 'https://texttospeech.googleapis.com/v1/text:synthesize';
  final String? _apiKey;
  final Dio _dio;
  bool _isInitialized = false;

  GoogleTtsService({String? apiKey, Dio? dio})
      : _apiKey = apiKey,
        _dio = dio ?? Dio();

  /// Initialize TTS service
  Future<void> initialize() async {
    if (_isInitialized) return;

    if (_apiKey == null || _apiKey.isEmpty) {
      AppLogger.warning('Google Cloud TTS API key not configured');
      return;
    }

    _isInitialized = true;
    AppLogger.info('Google Cloud TTS initialized successfully');
  }

  /// Synthesize speech from text
  /// Returns base64 encoded audio data (MP3 format)
  Future<String?> synthesize(String text, {String languageCode = 'en-US'}) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_apiKey == null || _apiKey.isEmpty) {
      AppLogger.error('Google Cloud TTS API key not configured');
      return null;
    }

    try {
      final response = await _dio.post(
        '$_apiEndpoint?key=$_apiKey',
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
        data: {
          'input': {'text': text},
          'voice': {
            'languageCode': languageCode,
            'name': _getVoiceName(languageCode),
            'ssmlGender': 'NEUTRAL',
          },
          'audioConfig': {
            'audioEncoding': 'MP3',
            'speakingRate': 0.9, // Slightly slower for learning
            'pitch': 0.0,
            'volumeGainDb': 0.0,
          },
        },
      );

      if (response.statusCode == 200) {
        final audioContent = response.data['audioContent'] as String?;
        
        if (audioContent != null) {
          AppLogger.debug('Google TTS synthesis successful');
          return audioContent;
        } else {
          AppLogger.error('No audio content in response');
          return null;
        }
      } else {
        AppLogger.error('Google TTS API error: ${response.statusCode} - ${response.data}');
        return null;
      }
    } catch (e) {
      AppLogger.error('Failed to synthesize speech: $e');
      return null;
    }
  }

  /// Get appropriate voice name based on language code
  String _getVoiceName(String languageCode) {
    switch (languageCode) {
      case 'en-US':
        return 'en-US-Neural2-J'; // High quality US English voice
      case 'en-GB':
        return 'en-GB-Neural2-B'; // High quality UK English voice
      default:
        return 'en-US-Neural2-J';
    }
  }

  /// Check if service is available (has API key)
  bool get isAvailable => _apiKey != null && _apiKey.isNotEmpty;

  /// Check if initialized
  bool get isInitialized => _isInitialized;

  /// Dispose resources
  void dispose() {
    _isInitialized = false;
  }
}
