
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/vocabulary_entity.dart';
import '../../domain/repositories/vocabulary_repository.dart';
import '../../data/repositories/vocabulary_repository_impl.dart';
import '../../data/datasources/local/vocabulary_local_datasource.dart';

/// Provider for vocabulary local datasource
final vocabularyLocalDataSourceProvider = Provider<VocabularyLocalDataSource>((ref) {
  return VocabularyLocalDataSource();
});

/// Provider for vocabulary repository
final vocabularyRepositoryProvider = Provider<VocabularyRepository>((ref) {
  final localDataSource = ref.watch(vocabularyLocalDataSourceProvider);
  return VocabularyRepositoryImpl(localDataSource: localDataSource);
});

/// State for vocabulary browser
class VocabularyBrowserState {
  final List<VocabularyEntity> allWords;
  final List<VocabularyEntity> filteredWords;
  final String searchQuery;
  final Set<int> selectedLevels;
  final Set<String> selectedPartsOfSpeech;
  
  // New Filters
  final String? vocabType; // 'word', 'phrase', 'pattern'
  final bool officialOnly;
  final bool testedOnly;

  final bool isLoading;
  final String? error;

  const VocabularyBrowserState({
    this.allWords = const [],
    this.filteredWords = const [],
    this.searchQuery = '',
    this.selectedLevels = const {},
    this.selectedPartsOfSpeech = const {},
    this.vocabType,
    this.officialOnly = false,
    this.testedOnly = false,
    this.isLoading = false,
    this.error,
  });

  VocabularyBrowserState copyWith({
    List<VocabularyEntity>? allWords,
    List<VocabularyEntity>? filteredWords,
    String? searchQuery,
    Set<int>? selectedLevels,
    Set<String>? selectedPartsOfSpeech,
    String? vocabType,
    bool? officialOnly,
    bool? testedOnly,
    bool? isLoading,
    String? error,
  }) {
    return VocabularyBrowserState(
      allWords: allWords ?? this.allWords,
      filteredWords: filteredWords ?? this.filteredWords,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedLevels: selectedLevels ?? this.selectedLevels,
      selectedPartsOfSpeech: selectedPartsOfSpeech ?? this.selectedPartsOfSpeech,
      vocabType: vocabType ?? this.vocabType,
      officialOnly: officialOnly ?? this.officialOnly,
      testedOnly: testedOnly ?? this.testedOnly,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  /// Group words by CEFR level
  Map<int, List<VocabularyEntity>> get groupedWords {
    final grouped = <int, List<VocabularyEntity>>{};
    // CEFR levels: 1=A1, 2=A2, 3=B1, 4=B2, 5=C1, 6=C2
    for (final level in [1, 2, 3, 4, 5, 6]) {
      grouped[level] = [];
    }

    for (final word in filteredWords) {
      if (word.level != null) {
        grouped[word.level]?.add(word);
      }
    }

    return grouped;
  }
}

/// Provider for vocabulary browser
final vocabularyBrowserProvider =
    StateNotifierProvider<VocabularyBrowserNotifier, VocabularyBrowserState>(
  (ref) => VocabularyBrowserNotifier(ref),
);

class VocabularyBrowserNotifier extends StateNotifier<VocabularyBrowserState> {
  final Ref ref;

  VocabularyBrowserNotifier(this.ref) : super(const VocabularyBrowserState()) {
    loadVocabulary();
  }

  Future<void> loadVocabulary() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final repository = ref.read(vocabularyRepositoryProvider);
      final result = await repository.getAllVocabulary();

      result.fold(
        (failure) {
          state = state.copyWith(
            isLoading: false,
            error: failure.message,
          );
        },
        (words) {
          state = state.copyWith(
            isLoading: false,
            allWords: words,
            filteredWords: words,
          );
        },
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    _applyFilters();
  }

  void toggleLevel(int level) {
    final newLevels = Set<int>.from(state.selectedLevels);
    if (newLevels.contains(level)) {
      newLevels.remove(level);
    } else {
      newLevels.add(level);
    }
    state = state.copyWith(selectedLevels: newLevels);
    _applyFilters();
  }

  void togglePartOfSpeech(String pos) {
    // Basic multi-select logic
    final newPos = Set<String>.from(state.selectedPartsOfSpeech);
    if (newPos.contains(pos)) {
      newPos.remove(pos);
    } else {
      newPos.add(pos);
    }
    state = state.copyWith(selectedPartsOfSpeech: newPos);
    _applyFilters();
  }
  
  // Set explicit POS (Single Select) - For new FilterSheet logic if needed
  void setPosFilter(String? pos) {
      if (pos == null || pos == 'all') {
          state = state.copyWith(selectedPartsOfSpeech: {});
      } else {
          state = state.copyWith(selectedPartsOfSpeech: {pos});
      }
      _applyFilters();
  }

  void setVocabType(String? type) {
      if (type == 'all') type = null;
      state = state.copyWith(vocabType: type);
      _applyFilters();
  }

  void setOfficialOnly(bool value) {
      state = state.copyWith(officialOnly: value);
      _applyFilters();
  }

  void setTestedOnly(bool value) {
      state = state.copyWith(testedOnly: value);
      _applyFilters();
  }

  void clearFilters() {
    state = state.copyWith(
      searchQuery: '',
      selectedLevels: {},
      selectedPartsOfSpeech: {},
      vocabType: null,
      officialOnly: false,
      testedOnly: false,
      filteredWords: state.allWords,
    );
  }

  void _applyFilters() {
    var filtered = state.allWords;

    // Apply search query
    if (state.searchQuery.isNotEmpty) {
      final query = state.searchQuery.toLowerCase();
      filtered = filtered.where((word) {
        return word.lemma.toLowerCase().contains(query) ||
            [word].any((def) =>
                def.senses.first.zhDef.toLowerCase().contains(query) ||
                (def.senses.first.zhDef.toLowerCase().contains(query)));
      }).toList();
    }

    // Apply CEFR level filter
    if (state.selectedLevels.isNotEmpty) {
      filtered = filtered
          .where((word) => state.selectedLevels.contains(word.level))
          .toList();
    }

    // Apply part of speech filter
    if (state.selectedPartsOfSpeech.isNotEmpty) {
      filtered = filtered.where((word) {
        return word.pos
            .any((pos) => state.selectedPartsOfSpeech.contains(pos));
      }).toList();
    }
    
    // Apply Vocab Type
    if (state.vocabType != null) {
        if (state.vocabType == 'phrase') {
             // Heuristic: phrase contains spaces
             filtered = filtered.where((w) => w.lemma.contains(' ')).toList();
        } else if (state.vocabType == 'word') {
             filtered = filtered.where((w) => !w.lemma.contains(' ')).toList();
        }
        // 'pattern' might need specific metadata
    }
    
    // Apply Official Only
    if (state.officialOnly) {
         filtered = filtered.where((w) => w.inOfficialList).toList();
    }
    
    // Apply Tested Only
    if (state.testedOnly) {
         filtered = filtered.where((w) => [w].any((s) => [s].expand((s) => s.senses.first.examples).toList().isNotEmpty)).toList();
    }

    state = state.copyWith(filteredWords: filtered);
  }
}

/// Provider for available parts of speech
final availablePartsOfSpeechProvider = Provider<List<String>>((ref) {
  final browserState = ref.watch(vocabularyBrowserProvider);
  final allPos = <String>{};

  for (final word in browserState.allWords) {
    allPos.addAll(word.pos);
  }

  return allPos.toList()..sort();
});
