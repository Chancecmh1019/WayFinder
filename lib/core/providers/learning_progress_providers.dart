import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

/// 學習進度 Provider
/// 
/// 追蹤使用者的學習進度，包括已學習的單字、複習次數等

/// 已學習單字 Box Provider
final learnedWordsBoxProvider = FutureProvider<Box<Map<dynamic, dynamic>>>((ref) async {
  return await Hive.openBox<Map<dynamic, dynamic>>('learned_words');
});

/// 獲取已學習單字列表 Provider
final learnedWordsProvider = FutureProvider.family<List<String>, String>((ref, userId) async {
  final box = await ref.watch(learnedWordsBoxProvider.future);
  
  final learnedWords = <String>[];
  for (final key in box.keys) {
    final data = box.get(key);
    if (data != null && data['userId'] == userId) {
      learnedWords.add(data['lemma'] as String);
    }
  }
  
  return learnedWords;
});

/// 獲取已學習單字數量 Provider
final learnedWordsCountProvider = FutureProvider.family<int, String>((ref, userId) async {
  final learnedWords = await ref.watch(learnedWordsProvider(userId).future);
  return learnedWords.length;
});

/// 檢查單字是否已學習 Provider
final isWordLearnedProvider = FutureProvider.family<bool, ({String userId, String lemma})>((ref, params) async {
  final learnedWords = await ref.watch(learnedWordsProvider(params.userId).future);
  return learnedWords.contains(params.lemma);
});

/// 標記單字為已學習 Provider
final markWordAsLearnedProvider = FutureProvider.family<void, ({String userId, String lemma})>((ref, params) async {
  final box = await ref.watch(learnedWordsBoxProvider.future);
  
  final key = '${params.userId}_${params.lemma}';
  await box.put(key, {
    'userId': params.userId,
    'lemma': params.lemma,
    'learnedAt': DateTime.now().toIso8601String(),
  });
  
  // 刷新相關 providers
  ref.invalidate(learnedWordsProvider(params.userId));
  ref.invalidate(learnedWordsCountProvider(params.userId));
});

/// 學習統計 Provider
/// 
/// 從 FSRS 每日統計中計算學習進度
final learningStatsProvider = FutureProvider.family<LearningStats, String>((ref, userId) async {
  final box = await ref.watch(learnedWordsBoxProvider.future);
  
  int totalLearned = 0;
  int learnedToday = 0;
  int learnedThisWeek = 0;
  int learnedThisMonth = 0;
  
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final weekAgo = today.subtract(const Duration(days: 7));
  final monthAgo = today.subtract(const Duration(days: 30));
  
  for (final key in box.keys) {
    final data = box.get(key);
    if (data != null && data['userId'] == userId) {
      totalLearned++;
      
      final learnedAt = DateTime.parse(data['learnedAt'] as String);
      final learnedDate = DateTime(learnedAt.year, learnedAt.month, learnedAt.day);
      
      // 今天學習的（包含今天）
      if (!learnedDate.isBefore(today)) {
        learnedToday++;
      }
      
      // 本週學習的（過去 7 天，包含今天）
      if (!learnedDate.isBefore(weekAgo)) {
        learnedThisWeek++;
      }
      
      // 本月學習的（過去 30 天，包含今天）
      if (!learnedDate.isBefore(monthAgo)) {
        learnedThisMonth++;
      }
    }
  }
  
  return LearningStats(
    totalLearned: totalLearned,
    learnedToday: learnedToday,
    learnedThisWeek: learnedThisWeek,
    learnedThisMonth: learnedThisMonth,
  );
});

/// 學習統計資料類別
class LearningStats {
  final int totalLearned;
  final int learnedToday;
  final int learnedThisWeek;
  final int learnedThisMonth;
  
  const LearningStats({
    required this.totalLearned,
    required this.learnedToday,
    required this.learnedThisWeek,
    required this.learnedThisMonth,
  });
}
