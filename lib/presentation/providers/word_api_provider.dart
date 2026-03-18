import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/remote/wiktionary_api_client.dart';
import '../../core/providers/repository_providers.dart';
import 'package:dio/dio.dart';

/// Provider for Wiktionary API client
final wiktionaryApiClientProvider = Provider<WiktionaryAPIClient>((ref) {
  return WiktionaryAPIClient(
    dio: Dio(),
  );
});

/// State for related words
/// Note: Related words functionality removed with Wordnik API
/// This can be re-implemented using local data or alternative APIs
class RelatedWordsState {
  final bool isLoading;
  final Map<String, List<String>>? relatedWords;
  final String? error;

  const RelatedWordsState({
    this.isLoading = false,
    this.relatedWords,
    this.error,
  });

  RelatedWordsState copyWith({
    bool? isLoading,
    Map<String, List<String>>? relatedWords,
    String? error,
  }) {
    return RelatedWordsState(
      isLoading: isLoading ?? this.isLoading,
      relatedWords: relatedWords ?? this.relatedWords,
      error: error ?? this.error,
    );
  }
}

/// Provider for related words
/// Note: Wordnik API removed - this now returns empty state
/// Related words should come from local vocabulary data instead
final relatedWordsProvider =
    StateNotifierProvider.family<RelatedWordsNotifier, RelatedWordsState, String>(
  (ref, word) => RelatedWordsNotifier(ref, word),
);

class RelatedWordsNotifier extends StateNotifier<RelatedWordsState> {
  final Ref ref;
  final String word;

  RelatedWordsNotifier(this.ref, this.word)
      : super(const RelatedWordsState());

  Future<void> loadRelatedWords() async {
    if (state.relatedWords != null) return; // Already loaded

    state = state.copyWith(isLoading: true, error: null);

    try {
      // Load related words from local vocabulary data
      // This uses the vocabulary repository to find synonyms and antonyms
      final vocabularyRepo = ref.read(vocabularyRepositoryProvider);
      
      // Get the vocabulary entity for this word
      final result = await vocabularyRepo.getVocabularyByWord(word);
      
      result.fold(
        (failure) {
          // If word not found, return empty lists
          state = state.copyWith(
            isLoading: false,
            relatedWords: {
              'synonyms': [],
              'antonyms': [],
              'equivalent': [],
              'cross-reference': [],
            },
          );
        },
        (vocabulary) {
          // Extract synonyms and antonyms from vocabulary entity
          final synonyms = vocabulary.synonyms;
          final antonyms = vocabulary.antonyms;
          
          state = state.copyWith(
            isLoading: false,
            relatedWords: {
              'synonyms': synonyms,
              'antonyms': antonyms,
              'equivalent': [], // Not available in local data
              'cross-reference': [], // Not available in local data
            },
          );
        },
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        relatedWords: {
          'synonyms': [],
          'antonyms': [],
          'equivalent': [],
          'cross-reference': [],
        },
      );
    }
  }
}

/// State for etymology
class EtymologyState {
  final bool isLoading;
  final Etymology? etymology;
  final String? error;

  const EtymologyState({
    this.isLoading = false,
    this.etymology,
    this.error,
  });

  EtymologyState copyWith({
    bool? isLoading,
    Etymology? etymology,
    String? error,
  }) {
    return EtymologyState(
      isLoading: isLoading ?? this.isLoading,
      etymology: etymology ?? this.etymology,
      error: error ?? this.error,
    );
  }
}

/// Provider for etymology
final etymologyProvider =
    StateNotifierProvider.family<EtymologyNotifier, EtymologyState, String>(
  (ref, word) => EtymologyNotifier(ref, word),
);

class EtymologyNotifier extends StateNotifier<EtymologyState> {
  final Ref ref;
  final String word;

  EtymologyNotifier(this.ref, this.word) : super(const EtymologyState());

  Future<void> loadEtymology() async {
    if (state.etymology != null) return; // Already loaded

    state = state.copyWith(isLoading: true, error: null);

    try {
      final client = ref.read(wiktionaryApiClientProvider);
      final etymology = await client.getEtymology(word);

      state = state.copyWith(
        isLoading: false,
        etymology: etymology,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
}
