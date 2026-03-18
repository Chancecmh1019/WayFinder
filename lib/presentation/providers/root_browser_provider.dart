
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/vocabulary_entity.dart';
import 'vocabulary_browser_provider.dart';

class RootGroup {
  final String root;
  final String meaning;
  final List<VocabularyEntity> words;

  const RootGroup({
    required this.root,
    required this.meaning,
    required this.words,
  });
  
  int get count => words.length;
}

class RootBrowserState {
  final List<RootGroup> rootGroups;
  final bool isLoading;

  const RootBrowserState({
    this.rootGroups = const [],
    this.isLoading = false,
  });
}

final rootBrowserProvider = StateNotifierProvider<RootBrowserNotifier, RootBrowserState>((ref) {
  return RootBrowserNotifier(ref);
});

class RootBrowserNotifier extends StateNotifier<RootBrowserState> {
  final Ref ref;

  RootBrowserNotifier(this.ref) : super(const RootBrowserState()) {
    _init();
  }

  void _init() {
    // Listen to vocabulary updates
    ref.listen(vocabularyBrowserProvider, (previous, next) {
      if (next.allWords.isNotEmpty && !next.isLoading) {
        _processRoots(next.allWords);
      }
    });

    // Initial load check
    final vocabState = ref.read(vocabularyBrowserProvider);
    if (vocabState.allWords.isNotEmpty) {
      _processRoots(vocabState.allWords);
    }
  }

  void _processRoots(List<VocabularyEntity> words) {
     final Map<String, RootGroup> groupMap = {};
     
     for (var word in words) {
         if (word.rootInfo != null && word.rootInfo!.rootBreakdown.isNotEmpty) {
             final root = word.rootInfo!.rootBreakdown;
             final meaning = word.rootInfo!.memoryStrategy;
             
             if (!groupMap.containsKey(root)) {
                 groupMap[root] = RootGroup(root: root, meaning: meaning, words: []);
             }
             
             groupMap[root]!.words.add(word);
         }
     }
     
     // Sort by count descending
     final sortedGroups = groupMap.values.toList()
        ..sort((a, b) => b.count.compareTo(a.count)); // Popular roots first? Or A-Z?
        // Let's sort alphabetically for dictionary style
        // ..sort((a, b) => a.root.compareTo(b.root));
     
     // Sort alphabetically actually better for dictionary
     sortedGroups.sort((a, b) => a.root.compareTo(b.root));

     state = RootBrowserState(rootGroups: sortedGroups);
  }
}
