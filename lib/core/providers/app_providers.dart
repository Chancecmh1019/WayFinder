import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/local_vocab_service.dart';
import '../../data/services/fsrs_service.dart';
import '../../data/services/tts_service.dart';
import '../../data/models/vocab_models_enhanced.dart';

// ── Core services ──────────────────────────────────────────

final localVocabServiceProvider = Provider<LocalVocabService>((_) => LocalVocabService());
final fsrsServiceProvider = Provider<FsrsService>((_) => FsrsService());
final ttsServiceProvider = Provider<TtsService>((ref) {
  final svc = TtsService();
  ref.onDispose(() => svc.dispose());
  return svc;
});

// ── Initialization ─────────────────────────────────────────

final appInitProvider = FutureProvider<bool>((ref) async {
  final fsrs = ref.watch(fsrsServiceProvider);
  final vocab = ref.watch(localVocabServiceProvider);
  await fsrs.initialize().timeout(const Duration(seconds: 15),
      onTimeout: () => throw Exception('FSRS 初始化超時'));
  await vocab.loadDatabase().timeout(const Duration(seconds: 45),
      onTimeout: () => throw Exception('字彙資料庫載入超時'));
  return true;
});

// ── Vocabulary data ────────────────────────────────────────

final vocabDatabaseProvider = FutureProvider<VocabDatabaseModel>((ref) async {
  return ref.watch(localVocabServiceProvider).loadDatabase();
});

final allWordsProvider = FutureProvider<List<WordEntryModel>>((ref) async {
  final db = await ref.watch(vocabDatabaseProvider.future);
  return db.words;
});

final allPhrasesProvider = FutureProvider<List<PhraseEntryModel>>((ref) async {
  final db = await ref.watch(vocabDatabaseProvider.future);
  return db.phrases;
});

final allPatternsProvider = FutureProvider<List<PatternEntryModel>>((ref) async {
  final db = await ref.watch(vocabDatabaseProvider.future);
  return db.patterns;
});

final wordDetailProvider = FutureProvider.family<WordEntryModel?, String>((ref, lemma) async {
  return ref.watch(localVocabServiceProvider).getWord(lemma);
});

final phraseDetailProvider = FutureProvider.family<PhraseEntryModel?, String>((ref, lemma) async {
  return ref.watch(localVocabServiceProvider).getPhrase(lemma);
});

// ── FSRS stats (for home screen & stats screen) ────────────

/// 刷新觸發器 - 每次學習完成後遞增此值以觸發所有相關provider重新計算
final statsRefreshTriggerProvider = StateProvider<int>((ref) => 0);

final streakProvider = Provider<int>((ref) {
  // 監聽刷新觸發器
  ref.watch(statsRefreshTriggerProvider);
  final fsrs = ref.watch(fsrsServiceProvider);
  return fsrs.isInitialized() ? fsrs.getCurrentStreak() : 0;
});

final dueCountProvider = Provider<int>((ref) {
  // 監聽刷新觸發器
  ref.watch(statsRefreshTriggerProvider);
  final fsrs = ref.watch(fsrsServiceProvider);
  return fsrs.isInitialized() ? fsrs.dueCount : 0;
});

final learnedCountProvider = Provider<int>((ref) {
  // 監聽刷新觸發器
  ref.watch(statsRefreshTriggerProvider);
  final fsrs = ref.watch(fsrsServiceProvider);
  return fsrs.isInitialized() ? fsrs.learnedCount : 0;
});

final todayStudiedProvider = Provider<int>((ref) {
  // 監聽刷新觸發器
  ref.watch(statsRefreshTriggerProvider);
  final fsrs = ref.watch(fsrsServiceProvider);
  return fsrs.isInitialized() ? fsrs.getTodayNewCardsCount() : 0;
});

final retentionRateProvider = Provider<double>((ref) {
  // 監聽刷新觸發器
  ref.watch(statsRefreshTriggerProvider);
  final fsrs = ref.watch(fsrsServiceProvider);
  return fsrs.isInitialized() ? fsrs.getRetentionRate() : 100.0;
});

final weakWordsProvider = Provider<List<String>>((ref) {
  // 監聽刷新觸發器
  ref.watch(statsRefreshTriggerProvider);
  final fsrs = ref.watch(fsrsServiceProvider);
  return fsrs.isInitialized() ? fsrs.getWeakWords(limit: 10) : [];
});

