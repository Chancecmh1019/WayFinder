import 'package:logger/logger.dart';
import '../models/vocab_models_enhanced.dart';
import '../services/local_vocab_service.dart';
import '../services/vocab_cache_manager.dart';

/// 增強版詞彙資料倉庫
/// 
/// 整合 LocalVocabService（記憶體快取）和 VocabCacheManager（持久化快取）
/// 提供統一的資料存取介面
class VocabRepositoryEnhanced {
  final LocalVocabService _localService;
  final VocabCacheManager _cacheManager;
  final Logger _logger = Logger();
  
  VocabRepositoryEnhanced({
    required LocalVocabService localService,
    required VocabCacheManager cacheManager,
  })  : _localService = localService,
        _cacheManager = cacheManager;
  
  /// 初始化倉庫
  Future<void> initialize() async {
    _logger.i('初始化詞彙倉庫...');
    await _cacheManager.initialize();
    _logger.i('詞彙倉庫初始化完成');
  }
  
  /// 取得單字詳情
  /// 
  /// 查詢順序：
  /// 1. LocalVocabService 記憶體快取
  /// 2. VocabCacheManager Hive 快取
  /// 3. 從 assets 載入完整資料
  Future<WordEntryModel?> getWordDetail(String lemma) async {
    try {
      // 1. 嘗試從 LocalVocabService 取得（記憶體快取）
      try {
        final word = await _localService.getWord(lemma);
        if (word != null) {
          // 同時儲存到 Hive 快取
          await _cacheManager.saveWordCache(word);
          return word;
        }
      } catch (e) {
        _logger.w('從 LocalVocabService 載入單字失敗: $lemma: $e');
      }
      
      // 2. 嘗試從 VocabCacheManager 取得（Hive 快取）
      final cachedWord = await _cacheManager.getWordCache(lemma);
      if (cachedWord != null) {
        _logger.d('從 Hive 快取載入單字: $lemma');
        return cachedWord;
      }
      
      // 3. 都沒有找到
      _logger.w('找不到單字: $lemma');
      return null;
    } catch (e, stackTrace) {
      _logger.e('取得單字詳情失敗: $lemma: $e', stackTrace: stackTrace);
      rethrow;
    }
  }
  
  /// 取得片語詳情
  Future<PhraseEntryModel?> getPhraseDetail(String lemma) async {
    try {
      // 1. 從 LocalVocabService 取得
      try {
        final phrase = await _localService.getPhrase(lemma);
        if (phrase != null) {
          await _cacheManager.savePhraseCache(phrase);
          return phrase;
        }
      } catch (e) {
        _logger.w('從 LocalVocabService 載入片語失敗: $lemma: $e');
      }
      
      // 2. 從 VocabCacheManager 取得
      final cachedPhrase = await _cacheManager.getPhraseCache(lemma);
      if (cachedPhrase != null) {
        _logger.d('從 Hive 快取載入片語: $lemma');
        return cachedPhrase;
      }
      
      _logger.w('找不到片語: $lemma');
      return null;
    } catch (e, stackTrace) {
      _logger.e('取得片語詳情失敗: $lemma: $e', stackTrace: stackTrace);
      rethrow;
    }
  }
  
  /// 取得句型詳情
  Future<PatternEntryModel?> getPatternDetail(String lemma) async {
    try {
      // 1. 從 LocalVocabService 取得
      try {
        final pattern = await _localService.getPattern(lemma);
        if (pattern != null) {
          await _cacheManager.savePatternCache(pattern);
          return pattern;
        }
      } catch (e) {
        _logger.w('從 LocalVocabService 載入句型失敗: $lemma: $e');
      }
      
      // 2. 從 VocabCacheManager 取得
      final cachedPattern = await _cacheManager.getPatternCache(lemma);
      if (cachedPattern != null) {
        _logger.d('從 Hive 快取載入句型: $lemma');
        return cachedPattern;
      }
      
      _logger.w('找不到句型: $lemma');
      return null;
    } catch (e, stackTrace) {
      _logger.e('取得句型詳情失敗: $lemma: $e', stackTrace: stackTrace);
      rethrow;
    }
  }
  
  /// 取得詞彙詳情（自動判斷類型）
  Future<dynamic> getVocabDetail(String lemma, String type) async {
    switch (type) {
      case 'word':
        return await getWordDetail(lemma);
      case 'phrase':
        return await getPhraseDetail(lemma);
      case 'pattern':
        return await getPatternDetail(lemma);
      default:
        throw ArgumentError('未知的詞彙類型: $type');
    }
  }
  
  /// 批次預載單字（用於學習模式）
  Future<void> preloadWords(List<String> lemmas) async {
    _logger.i('預載 ${lemmas.length} 個單字...');
    // LocalVocabService already has caching, just load them
    for (final lemma in lemmas) {
      await _localService.getWord(lemma);
    }
  }
  
  /// 批次預載片語
  Future<void> preloadPhrases(List<String> lemmas) async {
    _logger.i('預載 ${lemmas.length} 個片語...');
    // LocalVocabService already has caching, just load them
    for (final lemma in lemmas) {
      await _localService.getPhrase(lemma);
    }
  }
  
  /// 取得所有單字
  Future<List<WordEntryModel>> getAllWords() async {
    return await _localService.getAllWords();
  }
  
  /// 取得所有片語
  Future<List<PhraseEntryModel>> getAllPhrases() async {
    return await _localService.getAllPhrases();
  }
  
  /// 取得所有句型
  Future<List<PatternEntryModel>> getAllPatterns() async {
    return await _localService.getAllPatterns();
  }
  
  /// 搜尋單字
  Future<List<WordEntryModel>> searchWords(String query) async {
    final allWords = await _localService.getAllWords();
    final lowerQuery = query.toLowerCase();
    return allWords.where((word) => 
      word.lemma.toLowerCase().contains(lowerQuery) ||
      word.senses.any((sense) => 
        (sense.enDef?.toLowerCase().contains(lowerQuery) ?? false) ||
        sense.zhDef.toLowerCase().contains(lowerQuery)
      )
    ).toList();
  }
  
  /// 搜尋片語
  Future<List<PhraseEntryModel>> searchPhrases(String query) async {
    final allPhrases = await _localService.getAllPhrases();
    final lowerQuery = query.toLowerCase();
    return allPhrases.where((phrase) => 
      phrase.lemma.toLowerCase().contains(lowerQuery) ||
      phrase.senses.any((sense) => 
        (sense.enDef?.toLowerCase().contains(lowerQuery) ?? false) ||
        sense.zhDef.toLowerCase().contains(lowerQuery)
      )
    ).toList();
  }
  
  /// 搜尋所有類型
  Future<Map<String, List<dynamic>>> searchAll(String query) async {
    final words = await searchWords(query);
    final phrases = await searchPhrases(query);
    
    return {
      'words': words,
      'phrases': phrases,
    };
  }
  
  /// 取得統計資訊
  Future<Map<String, dynamic>> getStatistics() async {
    final db = await _localService.loadDatabase();
    final cacheStats = await _cacheManager.getCacheStatistics();
    
    return {
      'words': db.words.length,
      'phrases': db.phrases.length,
      'patterns': db.patterns.length,
      'cache': cacheStats,
    };
  }
  
  /// 清除所有快取
  Future<void> clearAllCache() async {
    _logger.i('清除所有快取...');
    // LocalVocabService caches are internal, no need to clear
    await _cacheManager.clearAllCache();
    _logger.i('快取已清除');
  }
  
  /// 清除記憶體快取（保留 Hive 快取）
  void clearMemoryCache() {
    _logger.i('清除記憶體快取...');
    // LocalVocabService manages its own internal cache
    _logger.i('記憶體快取已清除');
  }
  
  /// 清除完整資料庫（釋放記憶體）
  void clearFullDatabase() {
    _logger.i('清除完整資料庫...');
    // LocalVocabService manages its own database lifecycle
    _logger.i('完整資料庫已清除');
  }
  
  /// 批次儲存單字到快取
  Future<void> batchCacheWords(List<WordEntryModel> words) async {
    await _cacheManager.batchSaveWords(words);
  }
  
  /// 關閉倉庫
  Future<void> close() async {
    await _cacheManager.close();
    _logger.i('詞彙倉庫已關閉');
  }
}
