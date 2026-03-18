import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../data/models/vocab_models_enhanced.dart';
import '../../data/services/local_vocab_service.dart';
import '../../data/services/vocab_cache_manager.dart';
import '../../data/repositories/vocab_repository_enhanced.dart';

/// Dio Provider
final dioProvider = Provider<Dio>((ref) {
  return Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));
});

/// LocalVocabService Provider
final localVocabServiceProvider = Provider<LocalVocabService>((ref) {
  return LocalVocabService();
});

/// VocabCacheManager Provider
final vocabCacheManagerProvider = Provider<VocabCacheManager>((ref) {
  final manager = VocabCacheManager();
  return manager;
});

/// VocabCacheManager 初始化 Provider
final vocabCacheManagerInitProvider = FutureProvider<VocabCacheManager>((ref) async {
  final manager = ref.watch(vocabCacheManagerProvider);
  await manager.initialize();
  return manager;
});

/// VocabRepositoryEnhanced Provider
final vocabRepositoryProvider = Provider<VocabRepositoryEnhanced>((ref) {
  final localService = ref.watch(localVocabServiceProvider);
  final cacheManager = ref.watch(vocabCacheManagerProvider);
  
  return VocabRepositoryEnhanced(
    localService: localService,
    cacheManager: cacheManager,
  );
});

/// 初始化狀態 Provider
final vocabInitializationProvider = FutureProvider<void>((ref) async {
  // 先初始化 VocabCacheManager
  await ref.watch(vocabCacheManagerInitProvider.future);
  
  // 再初始化 repository
  final repository = ref.watch(vocabRepositoryProvider);
  await repository.initialize();
});

/// 完整資料庫 Provider
final vocabDatabaseProvider = FutureProvider<VocabDatabaseModel>((ref) async {
  final localService = ref.watch(localVocabServiceProvider);
  return await localService.loadDatabase();
});

/// 所有單字 Provider
final allWordsProvider = FutureProvider<List<WordEntryModel>>((ref) async {
  final repository = ref.watch(vocabRepositoryProvider);
  return await repository.getAllWords();
});

/// 所有片語 Provider
final allPhrasesProvider = FutureProvider<List<PhraseEntryModel>>((ref) async {
  final repository = ref.watch(vocabRepositoryProvider);
  return await repository.getAllPhrases();
});

/// 所有句型 Provider
final allPatternsProvider = FutureProvider<List<PatternEntryModel>>((ref) async {
  final repository = ref.watch(vocabRepositoryProvider);
  return await repository.getAllPatterns();
});

/// 單字詳情 Provider（帶參數）
final wordDetailProvider = FutureProvider.family<WordEntryModel?, String>((ref, lemma) async {
  final repository = ref.watch(vocabRepositoryProvider);
  return await repository.getWordDetail(lemma);
});

/// 片語詳情 Provider（帶參數）
final phraseDetailProvider = FutureProvider.family<PhraseEntryModel?, String>((ref, lemma) async {
  final repository = ref.watch(vocabRepositoryProvider);
  return await repository.getPhraseDetail(lemma);
});

/// 句型詳情 Provider（帶參數）
final patternDetailProvider = FutureProvider.family<PatternEntryModel?, String>((ref, lemma) async {
  final repository = ref.watch(vocabRepositoryProvider);
  return await repository.getPatternDetail(lemma);
});

/// 搜尋單字 Provider
final searchWordsProvider = FutureProvider.family<List<WordEntryModel>, String>((ref, query) async {
  if (query.isEmpty) return [];
  
  final repository = ref.watch(vocabRepositoryProvider);
  return await repository.searchWords(query);
});

/// 搜尋片語 Provider
final searchPhrasesProvider = FutureProvider.family<List<PhraseEntryModel>, String>((ref, query) async {
  if (query.isEmpty) return [];
  
  final repository = ref.watch(vocabRepositoryProvider);
  return await repository.searchPhrases(query);
});

/// 搜尋所有類型 Provider
final searchAllProvider = FutureProvider.family<Map<String, List<dynamic>>, String>((ref, query) async {
  if (query.isEmpty) return {'words': [], 'phrases': []};
  
  final repository = ref.watch(vocabRepositoryProvider);
  return await repository.searchAll(query);
});

/// 統計資訊 Provider
final vocabStatisticsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repository = ref.watch(vocabRepositoryProvider);
  return await repository.getStatistics();
});

/// 按等級篩選單字 Provider
final wordsByLevelProvider = FutureProvider.family<List<WordEntryModel>, int>((ref, level) async {
  final allWords = await ref.watch(allWordsProvider.future);
  return allWords.where((word) => word.level == level).toList();
});

/// 按詞性篩選單字 Provider
final wordsByPosProvider = FutureProvider.family<List<WordEntryModel>, String>((ref, pos) async {
  final allWords = await ref.watch(allWordsProvider.future);
  return allWords.where((word) => word.pos.contains(pos)).toList();
});

/// 官方單字列表 Provider
final officialWordsProvider = FutureProvider<List<WordEntryModel>>((ref) async {
  final allWords = await ref.watch(allWordsProvider.future);
  return allWords.where((word) => word.inOfficialList).toList();
});

/// 高頻單字 Provider（按 importance_score 排序）
final highFrequencyWordsProvider = FutureProvider.family<List<WordEntryModel>, int>((ref, limit) async {
  final allWords = await ref.watch(allWordsProvider.future);
  
  // 按 importance_score 排序
  final sortedWords = List<WordEntryModel>.from(allWords);
  sortedWords.sort((a, b) {
    final scoreA = a.frequency?.importanceScore ?? 0.0;
    final scoreB = b.frequency?.importanceScore ?? 0.0;
    return scoreB.compareTo(scoreA);
  });
  
  return sortedWords.take(limit).toList();
});

/// 有詞根資訊的單字 Provider
final wordsWithRootInfoProvider = FutureProvider<List<WordEntryModel>>((ref) async {
  final allWords = await ref.watch(allWordsProvider.future);
  return allWords.where((word) => word.rootInfo != null).toList();
});

/// 有易混淆詞的單字 Provider
final wordsWithConfusionNotesProvider = FutureProvider<List<WordEntryModel>>((ref) async {
  final allWords = await ref.watch(allWordsProvider.future);
  return allWords.where((word) => word.confusionNotes.isNotEmpty).toList();
});

/// 按考試年份篩選單字 Provider
final wordsByYearProvider = FutureProvider.family<List<WordEntryModel>, int>((ref, year) async {
  final allWords = await ref.watch(allWordsProvider.future);
  return allWords.where((word) {
    return word.frequency?.years.contains(year) ?? false;
  }).toList();
});

/// 按考試類型篩選單字 Provider
final wordsByExamTypeProvider = FutureProvider.family<List<WordEntryModel>, String>((ref, examType) async {
  final allWords = await ref.watch(allWordsProvider.future);
  return allWords.where((word) {
    return word.frequency?.byExamType.containsKey(examType) ?? false;
  }).toList();
});

/// 隨機單字 Provider
final randomWordsProvider = FutureProvider.family<List<WordEntryModel>, int>((ref, count) async {
  final allWords = await ref.watch(allWordsProvider.future);
  final shuffled = List<WordEntryModel>.from(allWords)..shuffle();
  return shuffled.take(count).toList();
});

/// 清除快取 Action Provider
final clearCacheActionProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    final repository = ref.read(vocabRepositoryProvider);
    await repository.clearAllCache();
    
    // 刷新所有相關 providers
    ref.invalidate(allWordsProvider);
    ref.invalidate(allPhrasesProvider);
    ref.invalidate(allPatternsProvider);
    ref.invalidate(vocabStatisticsProvider);
  };
});

/// 清除記憶體快取 Action Provider
final clearMemoryCacheActionProvider = Provider<void Function()>((ref) {
  return () {
    final repository = ref.read(vocabRepositoryProvider);
    repository.clearMemoryCache();
  };
});

/// 預載單字 Action Provider
final preloadWordsActionProvider = Provider<Future<void> Function(List<String>)>((ref) {
  return (lemmas) async {
    final repository = ref.read(vocabRepositoryProvider);
    await repository.preloadWords(lemmas);
  };
});

/// 預載片語 Action Provider
final preloadPhrasesActionProvider = Provider<Future<void> Function(List<String>)>((ref) {
  return (lemmas) async {
    final repository = ref.read(vocabRepositoryProvider);
    await repository.preloadPhrases(lemmas);
  };
});
