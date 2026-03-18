import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/audio_service.dart';
import '../../data/services/audio_cache_manager.dart';
import '../../data/services/flutter_tts_service.dart';
import '../../data/services/global_audio_controller.dart';

/// Provider for audio player
final audioPlayerProvider = Provider<AudioPlayer>((ref) {
  final player = AudioPlayer();
  ref.onDispose(() {
    player.dispose();
  });
  return player;
});

/// Provider for audio cache manager
final audioCacheManagerProvider = Provider<AudioCacheManager>((ref) {
  final manager = AudioCacheManager();
  ref.onDispose(() {
    manager.close();
  });
  return manager;
});

/// Provider for flutter TTS service (for audio service)
final audioTtsServiceProvider = Provider<FlutterTtsService>((ref) {
  final service = FlutterTtsService();
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});

/// Provider for audio service
final audioServiceProvider = Provider<AudioService>((ref) {
  final audioPlayer = ref.watch(audioPlayerProvider);
  final cacheManager = ref.watch(audioCacheManagerProvider);
  final ttsService = ref.watch(audioTtsServiceProvider);
  final globalAudioController = GlobalAudioController();

  final service = AudioService(
    audioPlayer: audioPlayer,
    cacheManager: cacheManager,
    ttsService: ttsService,
    globalAudioController: globalAudioController,
  );

  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

/// Provider for audio service initialization
final audioServiceInitializedProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(audioServiceProvider);
  try {
    await service.initialize();
    return true;
  } catch (e) {
    return false;
  }
});
