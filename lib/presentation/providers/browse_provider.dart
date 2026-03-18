import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/vocab_models_enhanced.dart';
import '../../core/providers/app_providers.dart';

// ── Tab ─────────────────────────────────────────────────────

enum BrowseTab { words, phrases }
enum BrowseSortMode { level, frequency, alphabetical }

// ── Filter state ─────────────────────────────────────────────

class BrowseFilter {
  final String query;
  final Set<int> levels;
  final bool officialOnly;
  final Set<String> posTags;
  final BrowseSortMode sort;
  final BrowseTab tab;

  const BrowseFilter({
    this.query = '',
    this.levels = const {},
    this.officialOnly = false,
    this.posTags = const {},
    this.sort = BrowseSortMode.level,
    this.tab = BrowseTab.words,
  });

  BrowseFilter copyWith({
    String? query,
    Set<int>? levels,
    bool? officialOnly,
    Set<String>? posTags,
    BrowseSortMode? sort,
    BrowseTab? tab,
  }) => BrowseFilter(
    query: query ?? this.query,
    levels: levels ?? this.levels,
    officialOnly: officialOnly ?? this.officialOnly,
    posTags: posTags ?? this.posTags,
    sort: sort ?? this.sort,
    tab: tab ?? this.tab,
  );
}

// ── Notifier ──────────────────────────────────────────────────

class BrowseNotifier extends StateNotifier<BrowseFilter> {
  BrowseNotifier() : super(const BrowseFilter());

  void setQuery(String q) => state = state.copyWith(query: q);
  void setTab(BrowseTab t) => state = state.copyWith(
      tab: t, query: '', levels: {}, posTags: {}, officialOnly: false);
  void setOfficialOnly(bool v) => state = state.copyWith(officialOnly: v);
  void setSort(BrowseSortMode s) => state = state.copyWith(sort: s);

  void toggleLevel(int level) {
    final lvls = Set<int>.from(state.levels);
    lvls.contains(level) ? lvls.remove(level) : lvls.add(level);
    state = state.copyWith(levels: lvls);
  }

  void togglePos(String pos) {
    final tags = Set<String>.from(state.posTags);
    tags.contains(pos) ? tags.remove(pos) : tags.add(pos);
    state = state.copyWith(posTags: tags);
  }

  void reset() => state = state.copyWith(
      query: '', levels: {}, posTags: {}, officialOnly: false);
}

final browseFilterProvider =
    StateNotifierProvider<BrowseNotifier, BrowseFilter>((_) => BrowseNotifier());

// ── Filtered words ────────────────────────────────────────────

final filteredWordsProvider =
    Provider<AsyncValue<List<WordEntryModel>>>((ref) {
  final filter = ref.watch(browseFilterProvider);
  return ref.watch(allWordsProvider).whenData((words) {
    var result = words.where((w) {
      if (filter.query.isNotEmpty) {
        final q = filter.query.toLowerCase();
        if (!w.lemma.toLowerCase().contains(q) &&
            !w.senses.any((s) => s.zhDef.contains(q))) {
          return false;
        }
      }
      if (filter.officialOnly && !w.inOfficialList) {
        return false;
      }
      if (filter.levels.isNotEmpty && !filter.levels.contains(w.level)) {
        return false;
      }
      if (filter.posTags.isNotEmpty &&
          !w.pos.any((p) => filter.posTags.contains(p))) {
        return false;
      }
      return true;
    }).toList();

    switch (filter.sort) {
      case BrowseSortMode.alphabetical:
        result.sort((a, b) => a.lemma.compareTo(b.lemma));
      case BrowseSortMode.frequency:
        result.sort((a, b) {
          final aS = a.frequency?.importanceScore ?? 0;
          final bS = b.frequency?.importanceScore ?? 0;
          return bS.compareTo(aS);
        });
      case BrowseSortMode.level:
        result.sort((a, b) {
          final al = a.level ?? 99;
          final bl = b.level ?? 99;
          return al != bl ? al.compareTo(bl) : a.lemma.compareTo(b.lemma);
        });
    }
    return result;
  });
});

// ── Filtered phrases ──────────────────────────────────────────

final filteredPhrasesProvider =
    Provider<AsyncValue<List<PhraseEntryModel>>>((ref) {
  final filter = ref.watch(browseFilterProvider);
  return ref.watch(allPhrasesProvider).whenData((phrases) {
    var result = phrases.where((p) {
      if (filter.query.isNotEmpty) {
        final q = filter.query.toLowerCase();
        if (!p.lemma.toLowerCase().contains(q) &&
            !p.senses.any((s) => s.zhDef.contains(q))) {
          return false;
        }
      }
      return true;
    }).toList();

    switch (filter.sort) {
      case BrowseSortMode.alphabetical:
        result.sort((a, b) => a.lemma.compareTo(b.lemma));
      case BrowseSortMode.frequency:
        result.sort((a, b) {
          final aS = a.frequency?.importanceScore ?? 0;
          final bS = b.frequency?.importanceScore ?? 0;
          return bS.compareTo(aS);
        });
      case BrowseSortMode.level:
        result.sort((a, b) => a.lemma.compareTo(b.lemma));
    }
    return result;
  });
});
