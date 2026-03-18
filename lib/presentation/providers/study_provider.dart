import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/vocab_models_enhanced.dart';
import '../../data/services/fsrs_service.dart';
import '../../data/services/local_vocab_service.dart';
import '../../domain/services/fsrs_algorithm.dart';
import '../../core/providers/app_providers.dart';
import 'settings_provider.dart';

// ── Study Mode ─────────────────────────────────────────────

enum StudyMode { flashcard, cloze, multipleChoice, spelling }

// ── Session Item ───────────────────────────────────────────

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

// ── Flashcard Session ──────────────────────────────────────

class FlashcardSessionState {
  final List<StudyItem> queue;
  final int currentIndex;
  final bool isFlipped;
  final bool isComplete;
  final int correctCount;
  final int totalSeen;
  final SchedulingInfo? nextIntervals;

  const FlashcardSessionState({
    this.queue = const [],
    this.currentIndex = 0,
    this.isFlipped = false,
    this.isComplete = false,
    this.correctCount = 0,
    this.totalSeen = 0,
    this.nextIntervals,
  });

  StudyItem? get currentItem =>
      queue.isNotEmpty && currentIndex < queue.length ? queue[currentIndex] : null;

  double get progress => queue.isEmpty ? 0.0 : currentIndex / queue.length;

  FlashcardSessionState copyWith({
    List<StudyItem>? queue, int? currentIndex, bool? isFlipped,
    bool? isComplete, int? correctCount, int? totalSeen, SchedulingInfo? nextIntervals,
  }) => FlashcardSessionState(
    queue: queue ?? this.queue, currentIndex: currentIndex ?? this.currentIndex,
    isFlipped: isFlipped ?? this.isFlipped, isComplete: isComplete ?? this.isComplete,
    correctCount: correctCount ?? this.correctCount, totalSeen: totalSeen ?? this.totalSeen,
    nextIntervals: nextIntervals ?? this.nextIntervals,
  );
}

class FlashcardSessionNotifier extends StateNotifier<FlashcardSessionState> {
  final FsrsService _fsrs;
  final LocalVocabService _vocab;
  final Ref _ref;

  FlashcardSessionNotifier(this._fsrs, this._vocab, this._ref)
      : super(const FlashcardSessionState());

  Future<void> startSession({int? newLimit, int? reviewLimit, List<String>? customList}) async {
    final dailyGoal = newLimit ?? _ref.read(dailyGoalProvider);
    final db = await _vocab.loadDatabase();

    if (customList != null && customList.isNotEmpty) {
      final queue = customList
          .expand((lemma) {
            final w = db.words.where((e) => e.lemma == lemma).firstOrNull;
            if (w == null || w.senses.isEmpty) return <StudyItem>[];
            return [StudyItem(lemma: w.lemma, senseId: w.senses.first.senseId, word: w, sense: w.senses.first)];
          })
          .toList()..shuffle();
      state = FlashcardSessionState(
        queue: queue, isComplete: queue.isEmpty,
        nextIntervals: queue.isNotEmpty ? _fsrs.getNextIntervals(queue.first.lemma, queue.first.senseId) : null,
      );
      return;
    }

    final dueCards = _fsrs.getDueCards(limit: reviewLimit ?? (dailyGoal! * 3));
    final queue = <StudyItem>[];

    for (final card in dueCards) {
      final w = db.words.where((e) => e.lemma == card.lemma).firstOrNull;
      if (w == null || w.senses.isEmpty) continue;
      final s = w.senses.where((e) => e.senseId == card.senseId).firstOrNull ?? w.senses.first;
      queue.add(StudyItem(lemma: w.lemma, senseId: s.senseId, word: w, sense: s));
    }

    final remaining = _fsrs.getRemainingNewCardsToday(dailyGoal!);
    if (remaining > 0) {
      final tracked = {...dueCards.map((c) => c.lemma), ..._fsrs.getNewCards(limit: 9999).map((c) => c.lemma)};
      final sorted = (db.words
          .where((w) => w.senses.isNotEmpty && !tracked.contains(w.lemma))
          .toList()
        ..sort((a, b) {
          double score(WordEntryModel w) =>
              (w.frequency?.importanceScore ?? 0) +
              (w.inOfficialList ? 0.5 : 0) +
              ((6 - (w.level ?? 6)) * 0.1);
          return score(b).compareTo(score(a));
        })).take(remaining);
      for (final w in sorted) {
        if (w.senses.isEmpty) continue;
        queue.add(StudyItem(lemma: w.lemma, senseId: w.senses.first.senseId, word: w, sense: w.senses.first, isNew: true));
      }
    }

    queue.shuffle();
    state = FlashcardSessionState(
      queue: queue, isComplete: queue.isEmpty,
      nextIntervals: queue.isNotEmpty ? _fsrs.getNextIntervals(queue.first.lemma, queue.first.senseId) : null,
    );
  }

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
      correctCount: state.correctCount + (rating == FSRSRating.good || rating == FSRSRating.easy ? 1 : 0),
      totalSeen: state.totalSeen + 1,
      nextIntervals: !isComplete
          ? _fsrs.getNextIntervals(state.queue[nextIndex].lemma, state.queue[nextIndex].senseId)
          : null,
    );
  }
}

// ── Cloze Session ──────────────────────────────────────────

class ClozeItem {
  final WordEntryModel word;
  final VocabSenseModel sense;
  final String sentence;
  final String answer;    // 正確單字（小寫）
  final String display;   // 原始句子（含答案位置提示）

  const ClozeItem({
    required this.word, required this.sense,
    required this.sentence, required this.answer, required this.display,
  });
}

class ClozeSessionState {
  final List<ClozeItem> items;
  final int currentIndex;
  final String? userInput;
  final bool? isCorrect;
  final bool isComplete;
  final int correctCount;

  const ClozeSessionState({
    this.items = const [], this.currentIndex = 0, this.userInput,
    this.isCorrect, this.isComplete = false, this.correctCount = 0,
  });

  ClozeItem? get current => items.isNotEmpty && currentIndex < items.length ? items[currentIndex] : null;
  double get progress => items.isEmpty ? 0.0 : currentIndex / items.length;

  ClozeSessionState copyWith({
    List<ClozeItem>? items, int? currentIndex, String? userInput,
    bool? isCorrect, bool? isComplete, int? correctCount,
  }) => ClozeSessionState(
    items: items ?? this.items, currentIndex: currentIndex ?? this.currentIndex,
    userInput: userInput, isCorrect: isCorrect ?? this.isCorrect,
    isComplete: isComplete ?? this.isComplete, correctCount: correctCount ?? this.correctCount,
  );
}

class ClozeSessionNotifier extends StateNotifier<ClozeSessionState> {
  final LocalVocabService _vocab;
  final FsrsService _fsrs;

  ClozeSessionNotifier(this._vocab, this._fsrs) : super(const ClozeSessionState());

  Future<void> start({List<String>? customWordList}) async {
    final db = await _vocab.loadDatabase();
    final items = <ClozeItem>[];
    final words = customWordList != null
        ? customWordList.map((l) => db.words.where((w) => w.lemma == l).firstOrNull).whereType<WordEntryModel>().toList()
        : (db.words..sort((a, b) => (b.frequency?.totalAppearances ?? 0).compareTo(a.frequency?.totalAppearances ?? 0))).take(200).toList();

    for (final word in words.take(20)) {
      for (final sense in word.senses) {
        for (final ex in sense.examples.take(2)) {
          final text = ex.text;
          final lower = text.toLowerCase();
          final lemma = word.lemma.toLowerCase();
          final idx = lower.indexOf(lemma);
          if (idx < 0) continue;
          final blanked = '${text.substring(0, idx)}___${text.substring(idx + lemma.length)}';
          items.add(ClozeItem(
            word: word, sense: sense,
            sentence: blanked, answer: lemma,
            display: text,
          ));
          break;
        }
        if (items.where((i) => i.word.lemma == word.lemma).isNotEmpty) break;
      }
    }
    items.shuffle();
    state = ClozeSessionState(items: items.take(15).toList(), isComplete: items.isEmpty);
  }

  void submit(String input) {
    final item = state.current;
    if (item == null) return;
    final correct = input.trim().toLowerCase() == item.answer.toLowerCase();
    state = state.copyWith(
      userInput: input, isCorrect: correct,
      correctCount: state.correctCount + (correct ? 1 : 0),
    );
  }

  Future<void> next() async {
    final item = state.current;
    if (item != null) {
      final rating = state.isCorrect == true ? FSRSRating.good : FSRSRating.again;
      await _fsrs.reviewCard(item.word.lemma, item.sense.senseId, rating);
    }
    final nextIndex = state.currentIndex + 1;
    state = state.copyWith(
      currentIndex: nextIndex,
      isCorrect: null,
      isComplete: nextIndex >= state.items.length,
    );
  }
}

// ── Multiple Choice Session ────────────────────────────────

class MCItem {
  final WordEntryModel word;
  final VocabSenseModel sense;
  final List<String> choices;   // 4 個選項的中文定義
  final int correctIndex;

  const MCItem({required this.word, required this.sense, required this.choices, required this.correctIndex});
}

class MCSessionState {
  final List<MCItem> items;
  final int currentIndex;
  final int? selectedIndex;
  final bool isComplete;
  final int correctCount;

  const MCSessionState({
    this.items = const [], this.currentIndex = 0, this.selectedIndex,
    this.isComplete = false, this.correctCount = 0,
  });

  MCItem? get current => items.isNotEmpty && currentIndex < items.length ? items[currentIndex] : null;
  double get progress => items.isEmpty ? 0.0 : currentIndex / items.length;

  MCSessionState copyWith({
    List<MCItem>? items, int? currentIndex, int? selectedIndex,
    bool? isComplete, int? correctCount,
  }) => MCSessionState(
    items: items ?? this.items, currentIndex: currentIndex ?? this.currentIndex,
    selectedIndex: selectedIndex, isComplete: isComplete ?? this.isComplete,
    correctCount: correctCount ?? this.correctCount,
  );
}

class MCSessionNotifier extends StateNotifier<MCSessionState> {
  final LocalVocabService _vocab;
  final FsrsService _fsrs;

  MCSessionNotifier(this._vocab, this._fsrs) : super(const MCSessionState());

  Future<void> start({List<String>? customWordList}) async {
    final db = await _vocab.loadDatabase();
    final pool = db.words.where((w) => w.senses.isNotEmpty).toList();

    final target = customWordList != null
        ? customWordList.map((l) => pool.where((w) => w.lemma == l).firstOrNull).whereType<WordEntryModel>().toList()
        : (List<WordEntryModel>.from(pool)..shuffle()).take(15).toList();

    final items = <MCItem>[];
    for (final word in target) {
      if (word.senses.isEmpty) continue;
      final sense = word.senses.first;
      final correct = sense.zhDef;
      if (correct.isEmpty) continue;

      // 干擾項：從同詞性的其他單字取
      final distractors = pool
          .where((w) => w.lemma != word.lemma &&
              w.senses.isNotEmpty &&
              w.senses.first.zhDef.isNotEmpty &&
              (w.senses.first.pos == sense.pos || true))
          .toList()
        ..shuffle();

      final choices = [correct, ...distractors.take(3).map((w) => w.senses.first.zhDef)];
      choices.shuffle();
      items.add(MCItem(
        word: word, sense: sense,
        choices: choices, correctIndex: choices.indexOf(correct),
      ));
    }

    state = MCSessionState(items: items, isComplete: items.isEmpty);
  }

  Future<void> select(int index) async {
    final item = state.current;
    if (item == null || state.selectedIndex != null) return;
    final isCorrect = index == item.correctIndex;
    final rating = isCorrect ? FSRSRating.good : FSRSRating.again;
    await _fsrs.reviewCard(item.word.lemma, item.sense.senseId, rating);
    state = state.copyWith(
      selectedIndex: index,
      correctCount: state.correctCount + (isCorrect ? 1 : 0),
    );
  }

  void next() {
    final nextIndex = state.currentIndex + 1;
    state = state.copyWith(
      currentIndex: nextIndex, selectedIndex: null,
      isComplete: nextIndex >= state.items.length,
    );
  }
}

// ── Spelling Session ──────────────────────────────────────

class SpellingItem {
  final WordEntryModel word;
  final VocabSenseModel sense;

  const SpellingItem({required this.word, required this.sense});
}

class SpellingSessionState {
  final List<SpellingItem> items;
  final int currentIndex;
  final String? userInput;
  final bool? isCorrect;
  final bool isComplete;
  final int correctCount;

  const SpellingSessionState({
    this.items = const [], this.currentIndex = 0, this.userInput,
    this.isCorrect, this.isComplete = false, this.correctCount = 0,
  });

  SpellingItem? get current => items.isNotEmpty && currentIndex < items.length ? items[currentIndex] : null;
  double get progress => items.isEmpty ? 0.0 : currentIndex / items.length;

  SpellingSessionState copyWith({
    List<SpellingItem>? items, int? currentIndex, String? userInput,
    bool? isCorrect, bool? isComplete, int? correctCount,
  }) => SpellingSessionState(
    items: items ?? this.items, currentIndex: currentIndex ?? this.currentIndex,
    userInput: userInput, isCorrect: isCorrect ?? this.isCorrect,
    isComplete: isComplete ?? this.isComplete, correctCount: correctCount ?? this.correctCount,
  );
}

class SpellingSessionNotifier extends StateNotifier<SpellingSessionState> {
  final LocalVocabService _vocab;
  final FsrsService _fsrs;

  SpellingSessionNotifier(this._vocab, this._fsrs) : super(const SpellingSessionState());

  Future<void> start({List<String>? customWordList}) async {
    final db = await _vocab.loadDatabase();
    final pool = db.words.where((w) => w.senses.isNotEmpty).toList();
    final words = customWordList != null
        ? customWordList.map((l) => pool.where((w) => w.lemma == l).firstOrNull).whereType<WordEntryModel>().toList()
        : (List<WordEntryModel>.from(pool)..shuffle()).take(12).toList();

    final items = words.map((w) => SpellingItem(word: w, sense: w.senses.first)).toList();
    state = SpellingSessionState(items: items, isComplete: items.isEmpty);
  }

  void submit(String input) {
    final item = state.current;
    if (item == null) return;
    final correct = input.trim().toLowerCase() == item.word.lemma.toLowerCase();
    state = state.copyWith(
      userInput: input, isCorrect: correct,
      correctCount: state.correctCount + (correct ? 1 : 0),
    );
  }

  Future<void> next() async {
    final item = state.current;
    if (item != null) {
      final rating = state.isCorrect == true ? FSRSRating.good : FSRSRating.again;
      await _fsrs.reviewCard(item.word.lemma, item.sense.senseId, rating);
    }
    final nextIndex = state.currentIndex + 1;
    state = state.copyWith(
      currentIndex: nextIndex, isCorrect: null,
      isComplete: nextIndex >= state.items.length,
    );
  }
}

// ── Providers ─────────────────────────────────────────────

final studySessionProvider = StateNotifierProvider<FlashcardSessionNotifier, FlashcardSessionState>((ref) {
  return FlashcardSessionNotifier(ref.watch(fsrsServiceProvider), ref.watch(localVocabServiceProvider), ref);
});

final clozeSessionProvider = StateNotifierProvider<ClozeSessionNotifier, ClozeSessionState>((ref) {
  return ClozeSessionNotifier(ref.watch(localVocabServiceProvider), ref.watch(fsrsServiceProvider));
});

final mcSessionProvider = StateNotifierProvider<MCSessionNotifier, MCSessionState>((ref) {
  return MCSessionNotifier(ref.watch(localVocabServiceProvider), ref.watch(fsrsServiceProvider));
});

final spellingSessionProvider = StateNotifierProvider<SpellingSessionNotifier, SpellingSessionState>((ref) {
  return SpellingSessionNotifier(ref.watch(localVocabServiceProvider), ref.watch(fsrsServiceProvider));
});
