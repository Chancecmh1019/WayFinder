import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/vocab_models_enhanced.dart';
import '../../core/providers/app_providers.dart';

/// 已學習單字 Provider（今日 + 過去所有）
/// 移除 autoDispose — 避免 StudyHub 重建時重新載入資料庫，
/// 改以 statsRefreshTriggerProvider 觸發刷新。
final learnedWordsProvider = FutureProvider<List<WordEntryModel>>((ref) async {
  ref.watch(statsRefreshTriggerProvider);

  final fsrs  = ref.watch(fsrsServiceProvider);
  final vocab = ref.watch(localVocabServiceProvider);

  if (!fsrs.isInitialized()) return [];

  final learnedLemmas = fsrs.getAllLearnedWords().toSet();
  if (learnedLemmas.isEmpty) return [];

  final db = await vocab.loadDatabase();
  return db.words.where((w) => learnedLemmas.contains(w.lemma)).toList();
});

/// 今日學習的單字（只含今天）
final todayLearnedWordsProvider = FutureProvider<List<WordEntryModel>>((ref) async {
  ref.watch(statsRefreshTriggerProvider);

  final fsrs  = ref.watch(fsrsServiceProvider);
  final vocab = ref.watch(localVocabServiceProvider);

  if (!fsrs.isInitialized()) return [];

  final todayLemmas = fsrs.getTodayLearnedWords().toSet();
  if (todayLemmas.isEmpty) return [];

  final db = await vocab.loadDatabase();
  return db.words.where((w) => todayLemmas.contains(w.lemma)).toList();
});

/// 情境強化可用的單字數量（移除 autoDispose）
final contextualWordCountProvider = Provider<int>((ref) {
  final learnedWords = ref.watch(learnedWordsProvider);
  return learnedWords.maybeWhen(
    data: (words) => words.length,
    orElse: () => 0,
  );
});

/// 情境練習最低需求單字數
const int kMinContextualWords = 4;
