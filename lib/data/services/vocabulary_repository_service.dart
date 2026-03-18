import 'package:hive/hive.dart';
import '../models/vocab_models_enhanced.dart';
import 'package:logger/logger.dart';

/// 詞彙資料庫服務
/// 
/// 提供分類查詢功能：
/// - 單字 (words)
/// - 片語 (phrases)
/// - 文法句型 (patterns)
class VocabularyRepositoryService {
  final Logger _logger = Logger();
  
  /// 取得所有單字
  Future<List<VocabEntryModel>> getAllWords(
    LazyBox<VocabEntryModel> box,
  ) async {
    try {
      final words = <VocabEntryModel>[];
      
      for (final key in box.keys) {
        final entry = await box.get(key);
        if (entry != null && entry.type == 'word') {
          words.add(entry);
        }
      }
      
      _logger.i('[VocabRepository] 找到 ${words.length} 個單字');
      return words;
    } catch (e, stackTrace) {
      _logger.e('[VocabRepository] 取得單字失敗: $e', stackTrace: stackTrace);
      return [];
    }
  }
  
  /// 取得所有片語
  Future<List<VocabEntryModel>> getAllPhrases(
    LazyBox<VocabEntryModel> box,
  ) async {
    try {
      final phrases = <VocabEntryModel>[];
      
      for (final key in box.keys) {
        final entry = await box.get(key);
        if (entry != null && entry.type == 'phrase') {
          phrases.add(entry);
        }
      }
      
      _logger.i('[VocabRepository] 找到 ${phrases.length} 個片語');
      return phrases;
    } catch (e, stackTrace) {
      _logger.e('[VocabRepository] 取得片語失敗: $e', stackTrace: stackTrace);
      return [];
    }
  }
  
  /// 取得所有文法句型
  Future<List<VocabEntryModel>> getAllPatterns(
    LazyBox<VocabEntryModel> box,
  ) async {
    try {
      final patterns = <VocabEntryModel>[];
      
      for (final key in box.keys) {
        final entry = await box.get(key);
        if (entry != null && entry.type == 'pattern') {
          patterns.add(entry);
        }
      }
      
      _logger.i('[VocabRepository] 找到 ${patterns.length} 個文法句型');
      return patterns;
    } catch (e, stackTrace) {
      _logger.e('[VocabRepository] 取得文法句型失敗: $e', stackTrace: stackTrace);
      return [];
    }
  }
  
  /// 依級別取得單字
  Future<List<VocabEntryModel>> getWordsByLevel(
    LazyBox<VocabEntryModel> box,
    int level,
  ) async {
    try {
      final words = <VocabEntryModel>[];
      
      for (final key in box.keys) {
        final entry = await box.get(key);
        if (entry != null && 
            entry.type == 'word' && 
            entry.level == level) {
          words.add(entry);
        }
      }
      
      _logger.i('[VocabRepository] Level $level: ${words.length} 個單字');
      return words;
    } catch (e, stackTrace) {
      _logger.e('[VocabRepository] 取得 Level $level 單字失敗: $e', stackTrace: stackTrace);
      return [];
    }
  }
  
  /// 取得官方字彙表單字
  Future<List<VocabEntryModel>> getOfficialWords(
    LazyBox<VocabEntryModel> box,
  ) async {
    try {
      final words = <VocabEntryModel>[];
      
      for (final key in box.keys) {
        final entry = await box.get(key);
        if (entry != null && 
            entry.type == 'word' && 
            entry.inOfficialList) {
          words.add(entry);
        }
      }
      
      _logger.i('[VocabRepository] 官方字彙表: ${words.length} 個單字');
      return words;
    } catch (e, stackTrace) {
      _logger.e('[VocabRepository] 取得官方字彙表失敗: $e', stackTrace: stackTrace);
      return [];
    }
  }
  
  /// 依重要性分數排序單字
  Future<List<VocabEntryModel>> getWordsByImportance(
    LazyBox<VocabEntryModel> box, {
    int? limit,
    int? minLevel,
    int? maxLevel,
  }) async {
    try {
      final words = <VocabEntryModel>[];
      
      for (final key in box.keys) {
        final entry = await box.get(key);
        if (entry != null && entry.type == 'word') {
          // 篩選級別
          if (minLevel != null && (entry.level ?? 0) < minLevel) continue;
          if (maxLevel != null && (entry.level ?? 999) > maxLevel) continue;
          
          words.add(entry);
        }
      }
      
      // 依重要性分數排序
      words.sort((a, b) {
        final scoreA = a.frequency?.importanceScore ?? 0.0;
        final scoreB = b.frequency?.importanceScore ?? 0.0;
        return scoreB.compareTo(scoreA);
      });
      
      // 限制數量
      if (limit != null && words.length > limit) {
        return words.sublist(0, limit);
      }
      
      _logger.i('[VocabRepository] 依重要性排序: ${words.length} 個單字');
      return words;
    } catch (e, stackTrace) {
      _logger.e('[VocabRepository] 依重要性排序失敗: $e', stackTrace: stackTrace);
      return [];
    }
  }
  
  /// 搜尋單字、片語或文法
  Future<List<VocabEntryModel>> search(
    LazyBox<VocabEntryModel> box,
    String query, {
    String? type, // 'word', 'phrase', 'pattern' 或 null (全部)
  }) async {
    try {
      final results = <VocabEntryModel>[];
      final lowerQuery = query.toLowerCase();
      
      for (final key in box.keys) {
        final entry = await box.get(key);
        if (entry != null) {
          // 篩選類型
          if (type != null && entry.type != type) continue;
          
          // 搜尋 lemma 或中文定義
          if (entry.lemma.toLowerCase().contains(lowerQuery)) {
            results.add(entry);
            continue;
          }
          
          // 搜尋中文定義
          for (final sense in entry.senses) {
            if (sense.zhDef.contains(query)) {
              results.add(entry);
              break;
            }
          }
        }
      }
      
      _logger.i('[VocabRepository] 搜尋 "$query": ${results.length} 個結果');
      return results;
    } catch (e, stackTrace) {
      _logger.e('[VocabRepository] 搜尋失敗: $e', stackTrace: stackTrace);
      return [];
    }
  }
  
  /// 取得統計資訊
  Future<Map<String, dynamic>> getStatistics(
    LazyBox<VocabEntryModel> box,
  ) async {
    try {
      int wordCount = 0;
      int phraseCount = 0;
      int patternCount = 0;
      final levelCounts = <int, int>{};
      int officialCount = 0;
      
      for (final key in box.keys) {
        final entry = await box.get(key);
        if (entry != null) {
          switch (entry.type) {
            case 'word':
              wordCount++;
              if (entry.level != null) {
                levelCounts[entry.level!] = (levelCounts[entry.level!] ?? 0) + 1;
              }
              if (entry.inOfficialList) {
                officialCount++;
              }
              break;
            case 'phrase':
              phraseCount++;
              break;
            case 'pattern':
              patternCount++;
              break;
          }
        }
      }
      
      final stats = {
        'total': box.length,
        'words': wordCount,
        'phrases': phraseCount,
        'patterns': patternCount,
        'byLevel': levelCounts,
        'official': officialCount,
      };
      
      _logger.i('[VocabRepository] 統計: $stats');
      return stats;
    } catch (e, stackTrace) {
      _logger.e('[VocabRepository] 取得統計失敗: $e', stackTrace: stackTrace);
      return {};
    }
  }
}
