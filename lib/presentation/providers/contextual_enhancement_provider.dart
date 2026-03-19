import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/vocab_models_enhanced.dart';
import '../../core/providers/app_providers.dart';

/// 已學習單字 Provider（今日 + 過去所有）
/// 直接使用 LocalVocabService + FsrsService，避免走錯誤的 VocabularyRepository 路徑
final learnedWordsProvider = FutureProvider.autoDispose<List<WordEntryModel>>((ref) async {
  // 監聽刷新觸發器，確保完成學習後重新載入
  ref.watch(statsRefreshTriggerProvider);

  final fsrs  = ref.watch(fsrsServiceProvider);
  final vocab = ref.watch(localVocabServiceProvider);

  if (!fsrs.isInitialized()) return [];

  // 從 FSRS 取得所有曾複習過的單字 lemma
  final learnedLemmas = fsrs.getAllLearnedWords().toSet();
  if (learnedLemmas.isEmpty) return [];

  // 從詞庫取得完整 WordEntryModel
  final db = await vocab.loadDatabase();
  return db.words.where((w) => learnedLemmas.contains(w.lemma)).toList();
});

/// 今日學習的單字（只含今天）
final todayLearnedWordsProvider = FutureProvider.autoDispose<List<WordEntryModel>>((ref) async {
  ref.watch(statsRefreshTriggerProvider);

  final fsrs  = ref.watch(fsrsServiceProvider);
  final vocab = ref.watch(localVocabServiceProvider);

  if (!fsrs.isInitialized()) return [];

  final todayLemmas = fsrs.getTodayLearnedWords().toSet();
  if (todayLemmas.isEmpty) return [];

  final db = await vocab.loadDatabase();
  return db.words.where((w) => todayLemmas.contains(w.lemma)).toList();
});

/// 情境強化可用的單字數量（用於 StudyHub 顯示）
final contextualWordCountProvider = Provider.autoDispose<int>((ref) {
  final learnedWords = ref.watch(learnedWordsProvider);
  return learnedWords.maybeWhen(
    data: (words) => words.length,
    orElse: () => 0,
  );
});

/// 情境練習最低需求單字數
const int kMinContextualWords = 4;
