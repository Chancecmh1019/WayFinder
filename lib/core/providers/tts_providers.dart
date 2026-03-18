import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../data/services/flutter_tts_service.dart';
import '../../data/services/edge_tts_service.dart';
import '../../data/services/google_tts_service.dart';
import '../../data/services/global_audio_controller.dart';
import '../../data/services/audio_preloader.dart';
import '../../presentation/providers/settings_provider.dart';
import '../../domain/entities/user_settings.dart';

/// Provider for FlutterTts instance
final flutterTtsProvider = Provider<FlutterTts>((ref) {
  return FlutterTts();
});

/// Provider for FlutterTtsService
final flutterTtsServiceProvider = Provider<FlutterTtsService>((ref) {
  final flutterTts = ref.watch(flutterTtsProvider);
  final service = FlutterTtsService(flutterTts: flutterTts);
  
  // Connect completion callback to global audio controller
  final audioController = ref.read(globalAudioControllerProvider);
  service.onComplete = () {
    audioController.markCompleted();
  };
  
  // Initialize on first access
  service.initialize();
  
  // Dispose when provider is disposed
  ref.onDispose(() {
    service.dispose();
  });
  
  return service;
});

/// Provider for EdgeTtsService
final edgeTtsServiceProvider = Provider<EdgeTtsService>((ref) {
  final service = EdgeTtsService();
  
  // Connect completion callback to global audio controller
  final audioController = ref.read(globalAudioControllerProvider);
  service.onComplete = () {
    audioController.markCompleted();
  };
  
  // Initialize on first access
  service.initialize();
  
  // Dispose when provider is disposed
  ref.onDispose(() {
    service.dispose();
  });
  
  return service;
});

/// Provider for GoogleTtsService
/// 
/// Note: Google Cloud TTS requires an API key. 
/// For production use, add the API key to environment variables or secure storage.
/// Currently disabled (apiKey: null) - the app uses FlutterTtsService instead.
final googleTtsServiceProvider = Provider<GoogleTtsService>((ref) {
  // Google Cloud TTS API key should be stored securely
  // Options:
  // 1. Environment variable: const apiKey = String.fromEnvironment('GOOGLE_TTS_API_KEY');
  // 2. Secure storage: Load from flutter_secure_storage
  // 3. Firebase Remote Config: Load from remote config
  // 
  // For now, we use null which disables Google TTS (app uses FlutterTtsService)
  const String? apiKey = null;
  
  final service = GoogleTtsService(apiKey: apiKey);
  
  // Initialize on first access
  service.initialize();
  
  // Dispose when provider is disposed
  ref.onDispose(() {
    service.dispose();
  });
  
  return service;
});

/// Provider for active TTS service based on user settings
/// Returns the appropriate TTS service based on user preference
final activeTtsServiceProvider = Provider<dynamic>((ref) {
  final ttsEngine = ref.watch(ttsEngineTypeProvider);
  
  switch (ttsEngine) {
    case TtsEngineType.edgeTts:
      return ref.watch(edgeTtsServiceProvider);
    case TtsEngineType.flutterTts:
      return ref.watch(flutterTtsServiceProvider);
  }
});


/// Provider for Global Audio Controller
final globalAudioControllerProvider = ChangeNotifierProvider<GlobalAudioController>((ref) {
  return GlobalAudioController();
});

/// Provider for Audio Preloader
final audioPreloaderProvider = Provider<AudioPreloader>((ref) {
  final ttsService = ref.watch(flutterTtsServiceProvider);
  final preloader = AudioPreloader(ttsService: ttsService);
  
  // Dispose when provider is disposed
  ref.onDispose(() {
    preloader.dispose();
  });
  
  return preloader;
});

/// Provider for TTS playing state
final ttsPlayingStateProvider = StateProvider<bool>((ref) => false);

/// Provider for TTS settings
final ttsSettingsProvider = StateNotifierProvider<TtsSettingsNotifier, TtsSettings>((ref) {
  return TtsSettingsNotifier();
});

/// TTS Settings model
class TtsSettings {
  final double speechRate;
  final double volume;
  final double pitch;
  final String language;

  const TtsSettings({
    this.speechRate = 0.5,
    this.volume = 1.0,
    this.pitch = 1.0,
    this.language = 'en-US',
  });

  TtsSettings copyWith({
    double? speechRate,
    double? volume,
    double? pitch,
    String? language,
  }) {
    return TtsSettings(
      speechRate: speechRate ?? this.speechRate,
      volume: volume ?? this.volume,
      pitch: pitch ?? this.pitch,
      language: language ?? this.language,
    );
  }
}

/// TTS Settings Notifier
class TtsSettingsNotifier extends StateNotifier<TtsSettings> {
  TtsSettingsNotifier() : super(const TtsSettings());

  void setSpeechRate(double rate) {
    state = state.copyWith(speechRate: rate);
  }

  void setVolume(double volume) {
    state = state.copyWith(volume: volume);
  }

  void setPitch(double pitch) {
    state = state.copyWith(pitch: pitch);
  }

  void setLanguage(String language) {
    state = state.copyWith(language: language);
  }

  void reset() {
    state = const TtsSettings();
  }
}
