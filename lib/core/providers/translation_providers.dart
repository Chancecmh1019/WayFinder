import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../data/services/translation_service.dart';

/// Provider for Dio instance for translation
final translationDioProvider = Provider<Dio>((ref) {
  return Dio();
});

/// Provider for TranslationService
final translationServiceProvider = Provider<TranslationService>((ref) {
  final dio = ref.watch(translationDioProvider);
  final service = TranslationService(dio: dio);
  
  // Initialize on first access
  service.initialize();
  
  // Dispose when provider is disposed
  ref.onDispose(() {
    service.dispose();
  });
  
  return service;
});

/// Provider for translation state
final translationStateProvider = StateNotifierProvider.family<
    TranslationStateNotifier,
    AsyncValue<String>,
    String
>((ref, text) {
  final service = ref.watch(translationServiceProvider);
  return TranslationStateNotifier(service, text);
});

/// Translation State Notifier
class TranslationStateNotifier extends StateNotifier<AsyncValue<String>> {
  final TranslationService _service;
  final String _text;

  TranslationStateNotifier(this._service, this._text)
      : super(const AsyncValue.loading()) {
    _translate();
  }

  Future<void> _translate() async {
    try {
      final translation = await _service.translate(_text);
      state = AsyncValue.data(translation);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> retry() async {
    state = const AsyncValue.loading();
    await _translate();
  }
}

/// Provider for translation cache stats
final translationCacheStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final service = ref.watch(translationServiceProvider);
  return await service.getCacheStats();
});
