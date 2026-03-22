import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/vocab_models_enhanced.dart';
import '../../data/services/fsrs_service.dart';
import '../../data/services/local_vocab_service.dart';
import '../../domain/services/fsrs_algorithm.dart';
import '../../core/providers/app_providers.dart';
import 'settings_provider.dart';

// ── Session Mode ────────────────────────────────────────────

enum SessionMode {
  daily,     // 每日必做：FSRS 到期複習 + 今日新詞
  weakWords, // 弱點攻克：多次忘記的單字集中強化
  custom,    // 自訂清單
}

// ── Study Mode (quiz type) ──────────────────────────────────

enum StudyMode { flashcard, cloze, multipleChoice, spelling }

// ── Study Item ─────────────────────────────────────────────

class StudyItem {
  final String lemma;
  final String senseId;
  final WordEntryModel word;
  final VocabSenseModel sense;
  final bool isNew;
  final bool isPhrase;

  const StudyItem({
    required this.lemma,
    required this.senseId,
    required this.word,
    required this.sense,
    this.isNew = false,
    this.isPhrase = false,
  });
}

// ── Flashcard Session State ─────────────────────────────────

class FlashcardSessionState {
  final List<StudyItem> queue;
  final int currentIndex;
  final bool isFlipped;
  final bool isComplete;
  final bool isLoading;
  final int correctCount;
  final int totalSeen;
  final SchedulingInfo? nextIntervals;
  final SessionMode mode;

  const FlashcardSessionState({
    this.queue = const [],
    this.currentIndex = 0,
    this.isFlipped = false,
    this.isComplete = false,
    this.isLoading = false,
    this.correctCount = 0,
    this.totalSeen = 0,
    this.nextIntervals,
    this.mode = SessionMode.daily,
  });

  StudyItem? get currentItem =>
      queue.isNotEmpty && currentIndex < queue.length ? queue[currentIndex] : null;

  double get progress =>
      queue.isEmpty ? 0.0 : currentIndex / queue.length;

  int get newCount => queue.where((i) => i.isNew).length;
  int get reviewCount => queue.where((i) => !i.isNew).length;

  FlashcardSessionState copyWith({
    List<StudyItem>? queue,
    int? currentIndex,
    bool? isFlipped,
    bool? isComplete,
    bool? isLoading,
    int? correctCount,
    int? totalSeen,
    SchedulingInfo? nextIntervals,
    SessionMode? mode,
  }) =>
      FlashcardSessionState(
        queue: queue ?? this.queue,
        currentIndex: currentIndex ?? this.currentIndex,
        isFlipped: isFlipped ?? this.isFlipped,
        isComplete: isComplete ?? this.isComplete,
        isLoading: isLoading ?? this.isLoading,
        correctCount: correctCount ?? this.correctCount,
        totalSeen: totalSeen ?? this.totalSeen,
        nextIntervals: nextIntervals ?? this.nextIntervals,
        mode: mode ?? this.mode,
      );
}

// ── Flashcard Session Notifier ──────────────────────────────

class FlashcardSessionNotifier extends StateNotifier<FlashcardSessionState> {
  final FsrsService _fsrs;
  final LocalVocabService _vocab;
  final Ref _ref;

  FlashcardSessionNotifier(this._fsrs, this._vocab, this._ref)
      : super(const FlashcardSessionState());

  /// 統一入口：僅由 FlashcardScreen.initState() 呼叫
  Future<void> startSession({
    SessionMode mode = SessionMode.daily,
    List<String>? customList,
  }) async {
    if (state.isLoading) return;
    state = FlashcardSessionState(isLoading: true, mode: mode);

    try {
      final db = await _vocab.loadDatabase();
      List<StudyItem> queue;

      switch (mode) {
        case SessionMode.custom:
          queue = _buildCustomQueue(db, customList ?? []);
        case SessionMode.weakWords:
          final weak = _fsrs.getWeakWords(limit: 20);
          queue = _buildCustomQueue(db, weak);
        case SessionMode.daily:
          queue = await _buildDailyQueue(db);
      }

      queue.shuffle();

      state = FlashcardSessionState(
        queue: queue,
        isComplete: queue.isEmpty,
        mode: mode,
        nextIntervals: queue.isNotEmpty
            ? _fsrs.getNextIntervals(queue.first.lemma, queue.first.senseId)
            : null,
      );
    } catch (_) {
      state = const FlashcardSessionState(isComplete: true);
    }
  }

  Future<List<StudyItem>> _buildDailyQueue(VocabDatabaseModel db) async {
    final dailyGoal = _ref.read(dailyGoalProvider);
    final queue = <StudyItem>[];

    // 1. 到期複習卡片（優先）
    final dueCards = _fsrs.getDueCards(limit: dailyGoal * 3);
    for (final card in dueCards) {
      final w = db.words.where((e) => e.lemma == card.lemma).firstOrNull;
      if (w != null && w.senses.isNotEmpty) {
        final s = w.senses.where((e) => e.senseId == card.senseId).firstOrNull
            ?? w.senses.first;
        queue.add(StudyItem(
            lemma: w.lemma, senseId: s.senseId,
            word: w, sense: s, isNew: false));
        continue;
      }
      final p = db.phrases.where((e) => e.lemma == card.lemma).firstOrNull;
      if (p != null && p.senses.isNotEmpty) {
        queue.add(StudyItem(
            lemma: p.lemma, senseId: p.senses.first.senseId,
            word: _phraseToWord(p), sense: p.senses.first,
            isNew: false, isPhrase: true));
      }
    }

    // 2. 今日新詞配額
    final remaining = _fsrs.getRemainingNewCardsToday(dailyGoal);
    if (remaining > 0) {
      final reviewedLemmas = <String>{
        ...dueCards.map((c) => c.lemma),
        ..._fsrs.getAllLearnedWords(),
      };

      int added = 0;

      // 單字（按頻率排序）
      final sortedWords = db.words
          .where((w) => w.senses.isNotEmpty && !reviewedLemmas.contains(w.lemma))
          .toList()
        ..sort((a, b) => (b.frequency?.importanceScore ?? 0).compareTo(a.frequency?.importanceScore ?? 0));

      for (final w in sortedWords) {
        if (added >= remaining) break;
        queue.add(StudyItem(
            lemma: w.lemma, senseId: w.senses.first.senseId,
            word: w, sense: w.senses.first, isNew: true));
        added++;
      }

      // 片語補足
      if (added < remaining) {
        final sortedPhrases = db.phrases
            .where((p) => p.senses.isNotEmpty && !reviewedLemmas.contains(p.lemma))
            .toList()
          ..sort((a, b) => (b.frequency?.importanceScore ?? 0).compareTo(a.frequency?.importanceScore ?? 0));

        for (final p in sortedPhrases) {
          if (added >= remaining) break;
          queue.add(StudyItem(
              lemma: p.lemma, senseId: p.senses.first.senseId,
              word: _phraseToWord(p), sense: p.senses.first,
              isNew: true, isPhrase: true));
          added++;
        }
      }
    }

    return queue;
  }

  List<StudyItem> _buildCustomQueue(VocabDatabaseModel db, List<String> lemmas) {
    final result = <StudyItem>[];
    for (final lemma in lemmas) {
      final w = db.words.where((e) => e.lemma == lemma).firstOrNull;
      if (w != null && w.senses.isNotEmpty) {
        result.add(StudyItem(
            lemma: w.lemma, senseId: w.senses.first.senseId,
            word: w, sense: w.senses.first));
        continue;
      }
      final p = db.phrases.where((e) => e.lemma == lemma).firstOrNull;
      if (p != null && p.senses.isNotEmpty) {
        result.add(StudyItem(
            lemma: p.lemma, senseId: p.senses.first.senseId,
            word: _phraseToWord(p), sense: p.senses.first,
            isPhrase: true));
      }
    }
    return result;
  }

  WordEntryModel _phraseToWord(PhraseEntryModel p) => WordEntryModel(
        lemma: p.lemma, pos: ['phrase'], level: null,
        inOfficialList: false, frequency: p.frequency,
        senses: p.senses, rootInfo: null,
        confusionNotes: const [], synonyms: const [],
        antonyms: const [], derivedForms: const [],
        lastUpdated: p.lastUpdated, collocations: const [],
      );

  void flip() => state = state.copyWith(isFlipped: true);

  Future<void> rate(FSRSRating rating) async {
    final item = state.currentItem;
    if (item == null) return;

    await _fsrs.reviewCard(item.lemma, item.senseId, rating);

    final nextIndex = state.currentIndex + 1;
    final isComplete = nextIndex >= state.queue.length;

    state = state.copyWith(
      currentIndex: nextIndex,
      isFlipped: false,
      isComplete: isComplete,
      correctCount: state.correctCount +
          (rating == FSRSRating.good || rating == FSRSRating.easy ? 1 : 0),
      totalSeen: state.totalSeen + 1,
      nextIntervals: !isComplete
          ? _fsrs.getNextIntervals(
              state.queue[nextIndex].lemma, state.queue[nextIndex].senseId)
          : null,
    );

    // ★ 即時刷新所有統計
    _ref.read(statsRefreshTriggerProvider.notifier).state++;
  }
}

final studySessionProvider =
    StateNotifierProvider<FlashcardSessionNotifier, FlashcardSessionState>((ref) {
  final fsrs = ref.watch(fsrsServiceProvider);
  final vocab = ref.watch(localVocabServiceProvider);
  return FlashcardSessionNotifier(fsrs, vocab, ref);
});

// ── Cloze Session ──────────────────────────────────────────

class ClozeItem {
  final WordEntryModel word;
  final VocabSenseModel sense;
  final String sentence;
  final String answer;
  final String display;

  const ClozeItem({
    required this.word, required this.sense,
    required this.sentence, required this.answer, required this.display,
  });
}

class ClozeSessionState {
  final List<ClozeItem> items;
  final int currentIndex;
  final String? userAnswer;
  final bool isAnswered;
  final bool isComplete;
  final int correctCount;

  const ClozeSessionState({
    this.items = const [], this.currentIndex = 0,
    this.userAnswer, this.isAnswered = false,
    this.isComplete = false, this.correctCount = 0,
  });

  ClozeItem? get current =>
      items.isNotEmpty && currentIndex < items.length ? items[currentIndex] : null;

  double get progress => items.isEmpty ? 0.0 : currentIndex / items.length;

  bool get isCorrect =>
      userAnswer?.toLowerCase().trim() == current?.answer.toLowerCase();

  ClozeSessionState copyWith({
    List<ClozeItem>? items, int? currentIndex, String? userAnswer,
    bool? isAnswered, bool? isComplete, int? correctCount,
  }) =>
      ClozeSessionState(
        items: items ?? this.items, currentIndex: currentIndex ?? this.currentIndex,
        userAnswer: userAnswer ?? this.userAnswer, isAnswered: isAnswered ?? this.isAnswered,
        isComplete: isComplete ?? this.isComplete, correctCount: correctCount ?? this.correctCount,
      );
}

class ClozeSessionNotifier extends StateNotifier<ClozeSessionState> {
  final LocalVocabService _vocab;
  final FsrsService _fsrs;
  final Ref _ref;

  ClozeSessionNotifier(this._vocab, this._fsrs, this._ref)
      : super(const ClozeSessionState());

  Future<void> start({List<String>? customWordList}) async {
    final db = await _vocab.loadDatabase();
    final learnedLemmas = customWordList?.toSet() ?? _fsrs.getAllLearnedWords().toSet();
    if (learnedLemmas.isEmpty) {
      state = const ClozeSessionState(isComplete: true);
      return;
    }
    final eligible = db.words
        .where((w) =>
            learnedLemmas.contains(w.lemma) &&
            w.senses.isNotEmpty &&
            w.senses.first.examples.isNotEmpty)
        .toList()
      ..shuffle();

    final items = <ClozeItem>[];
    for (final w in eligible.take(10)) {
      final s = w.senses.first;
      final ex = s.examples.first;
      final sentence = ex.text;
      if (!sentence.toLowerCase().contains(w.lemma.toLowerCase())) continue;
      final blank = sentence.replaceAll(
          RegExp(w.lemma, caseSensitive: false), '______');
      items.add(ClozeItem(
        word: w, sense: s, sentence: blank, answer: w.lemma, display: sentence,
      ));
    }
    state = ClozeSessionState(items: items, isComplete: items.isEmpty);
  }

  void submit(String answer) {
    if (state.isAnswered) return;
    state = state.copyWith(userAnswer: answer, isAnswered: true);
  }

  Future<void> next() async {
    final nextIndex = state.currentIndex + 1;
    final isComplete = nextIndex >= state.items.length;
    state = state.copyWith(
      currentIndex: nextIndex, userAnswer: null,
      isAnswered: false, isComplete: isComplete,
      correctCount: state.correctCount + (state.isCorrect ? 1 : 0),
    );
    if (isComplete) _ref.read(statsRefreshTriggerProvider.notifier).state++;
  }
}

final clozeSessionProvider =
    StateNotifierProvider<ClozeSessionNotifier, ClozeSessionState>((ref) {
  final vocab = ref.watch(localVocabServiceProvider);
  final fsrs = ref.watch(fsrsServiceProvider);
  return ClozeSessionNotifier(vocab, fsrs, ref);
});


// ── Multiple Choice Session ─────────────────────────────────

class MultipleChoiceItem {
  final StudyItem item;
  final List<String> choices;
  final int correctIndex;

  const MultipleChoiceItem({
    required this.item,
    required this.choices,
    required this.correctIndex,
  });
}

class MultipleChoiceSessionState {
  final List<MultipleChoiceItem> items;
  final int currentIndex;
  final int? selectedOption;
  final bool isAnswered;
  final bool isComplete;
  final int correctCount;

  const MultipleChoiceSessionState({
    this.items = const [],
    this.currentIndex = 0,
    this.selectedOption,
    this.isAnswered = false,
    this.isComplete = false,
    this.correctCount = 0,
  });

  MultipleChoiceItem? get current => currentIndex < items.length ? items[currentIndex] : null;
  bool get isCorrect => selectedOption == current?.correctIndex;
  int? get selectedIndex => selectedOption;
  double get progress => items.isEmpty ? 0.0 : (currentIndex + 1) / items.length;

  MultipleChoiceSessionState copyWith({
    List<MultipleChoiceItem>? items,
    int? currentIndex,
    int? selectedOption,
    bool? isAnswered,
    bool? isComplete,
    int? correctCount,
  }) {
    return MultipleChoiceSessionState(
      items: items ?? this.items,
      currentIndex: currentIndex ?? this.currentIndex,
      selectedOption: selectedOption,
      isAnswered: isAnswered ?? this.isAnswered,
      isComplete: isComplete ?? this.isComplete,
      correctCount: correctCount ?? this.correctCount,
    );
  }
}

class MultipleChoiceSessionNotifier extends StateNotifier<MultipleChoiceSessionState> {
  final LocalVocabService _vocab;
  final FsrsService _fsrs;
  final Ref _ref;

  MultipleChoiceSessionNotifier(this._vocab, this._fsrs, this._ref)
      : super(const MultipleChoiceSessionState());

  Future<void> start({List<String>? customWordList}) async {
    final db = await _vocab.loadDatabase();
    final learnedLemmas = customWordList?.toSet() ?? _fsrs.getAllLearnedWords().toSet();
    if (learnedLemmas.isEmpty) {
      state = const MultipleChoiceSessionState(isComplete: true);
      return;
    }
    final eligible = db.words
        .where((w) => learnedLemmas.contains(w.lemma) && w.senses.isNotEmpty)
        .toList()
      ..shuffle();

    final items = <MultipleChoiceItem>[];
    for (final w in eligible.take(10)) {
      final studyItem = StudyItem(
        lemma: w.lemma,
        senseId: w.senses.first.senseId,
        word: w,
        sense: w.senses.first,
      );
      
      // 生成選項
      final choices = <String>[w.senses.first.zhDef];
      final otherWords = db.words.where((other) => other.lemma != w.lemma).toList()..shuffle();
      for (var i = 0; i < 3 && i < otherWords.length; i++) {
        if (otherWords[i].senses.isNotEmpty) {
          choices.add(otherWords[i].senses.first.zhDef);
        }
      }
      choices.shuffle();
      final correctIndex = choices.indexOf(w.senses.first.zhDef);
      
      items.add(MultipleChoiceItem(
        item: studyItem,
        choices: choices,
        correctIndex: correctIndex,
      ));
    }

    state = MultipleChoiceSessionState(items: items, isComplete: items.isEmpty);
  }

  void select(int option) {
    if (state.isAnswered) return;
    state = state.copyWith(selectedOption: option, isAnswered: true);
  }

  void next() {
    final nextIndex = state.currentIndex + 1;
    final isComplete = nextIndex >= state.items.length;
    state = state.copyWith(
      currentIndex: nextIndex,
      selectedOption: null,
      isAnswered: false,
      isComplete: isComplete,
      correctCount: state.correctCount + (state.isCorrect ? 1 : 0),
    );
    if (isComplete) _ref.read(statsRefreshTriggerProvider.notifier).state++;
  }
}

final mcSessionProvider =
    StateNotifierProvider<MultipleChoiceSessionNotifier, MultipleChoiceSessionState>((ref) {
  final vocab = ref.watch(localVocabServiceProvider);
  final fsrs = ref.watch(fsrsServiceProvider);
  return MultipleChoiceSessionNotifier(vocab, fsrs, ref);
});

// ── Spelling Session ────────────────────────────────────────

class SpellingSessionState {
  final List<StudyItem> items;
  final int currentIndex;
  final String? userAnswer;
  final bool isAnswered;
  final bool isComplete;
  final int correctCount;

  const SpellingSessionState({
    this.items = const [],
    this.currentIndex = 0,
    this.userAnswer,
    this.isAnswered = false,
    this.isComplete = false,
    this.correctCount = 0,
  });

  StudyItem? get current => currentIndex < items.length ? items[currentIndex] : null;
  bool get isCorrect => userAnswer?.toLowerCase().trim() == current?.lemma.toLowerCase();
  String? get userInput => userAnswer;
  double get progress => items.isEmpty ? 0.0 : (currentIndex + 1) / items.length;

  SpellingSessionState copyWith({
    List<StudyItem>? items,
    int? currentIndex,
    String? userAnswer,
    bool? isAnswered,
    bool? isComplete,
    int? correctCount,
  }) {
    return SpellingSessionState(
      items: items ?? this.items,
      currentIndex: currentIndex ?? this.currentIndex,
      userAnswer: userAnswer,
      isAnswered: isAnswered ?? this.isAnswered,
      isComplete: isComplete ?? this.isComplete,
      correctCount: correctCount ?? this.correctCount,
    );
  }
}

class SpellingSessionNotifier extends StateNotifier<SpellingSessionState> {
  final LocalVocabService _vocab;
  final FsrsService _fsrs;
  final Ref _ref;

  SpellingSessionNotifier(this._vocab, this._fsrs, this._ref)
      : super(const SpellingSessionState());

  Future<void> start({List<String>? customWordList}) async {
    final db = await _vocab.loadDatabase();
    final learnedLemmas = customWordList?.toSet() ?? _fsrs.getAllLearnedWords().toSet();
    if (learnedLemmas.isEmpty) {
      state = const SpellingSessionState(isComplete: true);
      return;
    }
    final eligible = db.words
        .where((w) => learnedLemmas.contains(w.lemma) && w.senses.isNotEmpty)
        .toList()
      ..shuffle();

    final items = eligible.take(10).map((w) {
      return StudyItem(
        lemma: w.lemma,
        senseId: w.senses.first.senseId,
        word: w,
        sense: w.senses.first,
      );
    }).toList();

    state = SpellingSessionState(items: items, isComplete: items.isEmpty);
  }

  void submit(String answer) {
    if (state.isAnswered) return;
    state = state.copyWith(userAnswer: answer, isAnswered: true);
  }

  Future<void> next() async {
    final nextIndex = state.currentIndex + 1;
    final isComplete = nextIndex >= state.items.length;
    state = state.copyWith(
      currentIndex: nextIndex,
      userAnswer: null,
      isAnswered: false,
      isComplete: isComplete,
      correctCount: state.correctCount + (state.isCorrect ? 1 : 0),
    );
    if (isComplete) _ref.read(statsRefreshTriggerProvider.notifier).state++;
  }
}

final spellingSessionProvider =
    StateNotifierProvider<SpellingSessionNotifier, SpellingSessionState>((ref) {
  final vocab = ref.watch(localVocabServiceProvider);
  final fsrs = ref.watch(fsrsServiceProvider);
  return SpellingSessionNotifier(vocab, fsrs, ref);
});
