import 'package:hive_flutter/hive_flutter.dart';
import 'package:logger/logger.dart';
import '../models/vocab_models_enhanced.dart';

/// 詞彙快取管理器
/// 
/// 使用 Hive 提供持久化快取功能，減少重複載入
/// 實作 LRU 清理策略和過期機制
class VocabCacheManager {
  final Logger _logger = Logger();
  
  // Hive box 名稱
  static const String wordCacheBoxName = 'word_cache';
  static const String phraseCacheBoxName = 'phrase_cache';
  static const String patternCacheBoxName = 'pattern_cache';
  static const String cacheMetadataBoxName = 'cache_metadata';
  
  // 快取大小限制（持久化）
  static const int maxWordCacheSize = 1000;
  static const int maxPhraseCacheSize = 500;
  static const int maxPatternCacheSize = 20;
  
  // 快取過期時間（30 天）
  static const Duration cacheExpiration = Duration(days: 30);
  
  late Box<WordEntryModel> _wordCacheBox;
  late Box<PhraseEntryModel> _phraseCacheBox;
  late Box<PatternEntryModel> _patternCacheBox;
  late Box<Map<dynamic, dynamic>> _metadataBox;
  
  bool _isInitialized = false;
  
  /// 初始化快取管理器
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _logger.i('初始化詞彙快取管理器...');
      
      // 註冊 Hive adapters（如果尚未註冊）
      _registerAdapters();
      
      // 開啟 Hive boxes
      _wordCacheBox = await Hive.openBox<WordEntryModel>(wordCacheBoxName);
      _phraseCacheBox = await Hive.openBox<PhraseEntryModel>(phraseCacheBoxName);
      _patternCacheBox = await Hive.openBox<PatternEntryModel>(patternCacheBoxName);
      _metadataBox = await Hive.openBox<Map>(cacheMetadataBoxName);
      
      _isInitialized = true;
      
      _logger.i('快取管理器初始化完成');
      _logger.i('  - 單字快取: ${_wordCacheBox.length} 項');
      _logger.i('  - 片語快取: ${_phraseCacheBox.length} 項');
      _logger.i('  - 句型快取: ${_patternCacheBox.length} 項');
      
      // 清理過期快取
      await _cleanupExpiredCache();
    } catch (e, stackTrace) {
      _logger.e('初始化快取管理器失敗: $e', stackTrace: stackTrace);
      rethrow;
    }
  }
  
  /// 註冊 Hive type adapters
  void _registerAdapters() {
    // 這些 adapters 應該已經在 HiveService.initialize() 中註冊
    // 這裡只是確保它們已註冊（使用新的 typeId）
    if (!Hive.isAdapterRegistered(50)) {
      Hive.registerAdapter(SourceInfoModelAdapter());
    }
    if (!Hive.isAdapterRegistered(51)) {
      Hive.registerAdapter(ExamExampleModelAdapter());
    }
    if (!Hive.isAdapterRegistered(52)) {
      Hive.registerAdapter(VocabSenseModelAdapter());
    }
    if (!Hive.isAdapterRegistered(53)) {
      Hive.registerAdapter(FrequencyDataModelAdapter());
    }
    if (!Hive.isAdapterRegistered(54)) {
      Hive.registerAdapter(ConfusionNoteModelAdapter());
    }
    if (!Hive.isAdapterRegistered(55)) {
      Hive.registerAdapter(RootInfoModelAdapter());
    }
    if (!Hive.isAdapterRegistered(58)) {
      Hive.registerAdapter(PatternSubtypeModelAdapter());
    }
    if (!Hive.isAdapterRegistered(59)) {
      Hive.registerAdapter(PatternEntryModelAdapter());
    }
    if (!Hive.isAdapterRegistered(60)) {
      Hive.registerAdapter(PhraseEntryModelAdapter());
    }
    if (!Hive.isAdapterRegistered(61)) {
      Hive.registerAdapter(WordEntryModelAdapter());
    }
  }
  
  /// 取得單字快取
  Future<WordEntryModel?> getWordCache(String lemma) async {
    _ensureInitialized();
    
    final word = _wordCacheBox.get(lemma);
    if (word != null) {
      // 更新存取時間
      await _updateAccessTime('word', lemma);
      _logger.d('從快取載入單字: $lemma');
    }
    
    return word;
  }
  
  /// 儲存單字快取
  Future<void> saveWordCache(WordEntryModel word) async {
    _ensureInitialized();
    
    // 檢查快取大小限制
    if (_wordCacheBox.length >= maxWordCacheSize) {
      await _cleanupLRUCache('word', _wordCacheBox, maxWordCacheSize);
    }
    
    await _wordCacheBox.put(word.lemma, word);
    await _updateAccessTime('word', word.lemma);
    
    _logger.d('儲存單字快取: ${word.lemma}');
  }
  
  /// 取得片語快取
  Future<PhraseEntryModel?> getPhraseCache(String lemma) async {
    _ensureInitialized();
    
    final phrase = _phraseCacheBox.get(lemma);
    if (phrase != null) {
      await _updateAccessTime('phrase', lemma);
      _logger.d('從快取載入片語: $lemma');
    }
    
    return phrase;
  }
  
  /// 儲存片語快取
  Future<void> savePhraseCache(PhraseEntryModel phrase) async {
    _ensureInitialized();
    
    if (_phraseCacheBox.length >= maxPhraseCacheSize) {
      await _cleanupLRUCache('phrase', _phraseCacheBox, maxPhraseCacheSize);
    }
    
    await _phraseCacheBox.put(phrase.lemma, phrase);
    await _updateAccessTime('phrase', phrase.lemma);
    
    _logger.d('儲存片語快取: ${phrase.lemma}');
  }
  
  /// 取得句型快取
  Future<PatternEntryModel?> getPatternCache(String lemma) async {
    _ensureInitialized();
    
    final pattern = _patternCacheBox.get(lemma);
    if (pattern != null) {
      await _updateAccessTime('pattern', lemma);
      _logger.d('從快取載入句型: $lemma');
    }
    
    return pattern;
  }
  
  /// 儲存句型快取
  Future<void> savePatternCache(PatternEntryModel pattern) async {
    _ensureInitialized();
    
    if (_patternCacheBox.length >= maxPatternCacheSize) {
      await _cleanupLRUCache('pattern', _patternCacheBox, maxPatternCacheSize);
    }
    
    await _patternCacheBox.put(pattern.lemma, pattern);
    await _updateAccessTime('pattern', pattern.lemma);
    
    _logger.d('儲存句型快取: ${pattern.lemma}');
  }
  
  /// 批次儲存單字快取
  Future<void> batchSaveWords(List<WordEntryModel> words) async {
    _ensureInitialized();
    
    _logger.i('批次儲存 ${words.length} 個單字...');
    
    final Map<String, WordEntryModel> entries = {};
    for (final word in words) {
      entries[word.lemma] = word;
    }
    
    await _wordCacheBox.putAll(entries);
    
    // 更新存取時間
    for (final lemma in entries.keys) {
      await _updateAccessTime('word', lemma);
    }
    
    _logger.i('批次儲存完成');
  }
  
  /// 清除所有快取
  Future<void> clearAllCache() async {
    _ensureInitialized();
    
    _logger.i('清除所有快取...');
    
    await _wordCacheBox.clear();
    await _phraseCacheBox.clear();
    await _patternCacheBox.clear();
    await _metadataBox.clear();
    
    _logger.i('快取已清除');
  }
  
  /// 取得快取統計資訊
  Future<Map<String, dynamic>> getCacheStatistics() async {
    _ensureInitialized();
    
    return {
      'word_cache_size': _wordCacheBox.length,
      'phrase_cache_size': _phraseCacheBox.length,
      'pattern_cache_size': _patternCacheBox.length,
      'total_cache_size': _wordCacheBox.length + _phraseCacheBox.length + _patternCacheBox.length,
      'max_word_cache_size': maxWordCacheSize,
      'max_phrase_cache_size': maxPhraseCacheSize,
      'max_pattern_cache_size': maxPatternCacheSize,
    };
  }
  
  /// 更新存取時間（用於 LRU）
  Future<void> _updateAccessTime(String type, String lemma) async {
    final key = '${type}_$lemma';
    await _metadataBox.put(key, {
      'last_accessed': DateTime.now().toIso8601String(),
      'type': type,
      'lemma': lemma,
    });
  }
  
  /// 清理 LRU 快取（移除最久未使用的項目）
  Future<void> _cleanupLRUCache(String type, Box box, int maxSize) async {
    _logger.i('清理 $type 快取 (當前: ${box.length}, 最大: $maxSize)');
    
    // 取得所有存取時間
    final List<MapEntry<String, DateTime>> accessTimes = [];
    
    for (final key in _metadataBox.keys) {
      if (key.toString().startsWith('${type}_')) {
        final metadata = _metadataBox.get(key);
        if (metadata != null && metadata['last_accessed'] != null) {
          final lemma = metadata['lemma'] as String;
          final lastAccessed = DateTime.parse(metadata['last_accessed'] as String);
          accessTimes.add(MapEntry(lemma, lastAccessed));
        }
      }
    }
    
    // 按存取時間排序（最舊的在前）
    accessTimes.sort((a, b) => a.value.compareTo(b.value));
    
    // 移除最舊的項目直到符合大小限制
    final removeCount = box.length - (maxSize * 0.8).toInt(); // 保留 80% 空間
    for (int i = 0; i < removeCount && i < accessTimes.length; i++) {
      final lemma = accessTimes[i].key;
      await box.delete(lemma);
      await _metadataBox.delete('${type}_$lemma');
      _logger.d('移除快取: $lemma');
    }
    
    _logger.i('清理完成，移除了 $removeCount 個項目');
  }
  
  /// 清理過期快取
  Future<void> _cleanupExpiredCache() async {
    _logger.i('清理過期快取...');
    
    final now = DateTime.now();
    int expiredCount = 0;
    
    for (final key in _metadataBox.keys) {
      final metadata = _metadataBox.get(key);
      if (metadata != null && metadata['last_accessed'] != null) {
        final lastAccessed = DateTime.parse(metadata['last_accessed'] as String);
        
        if (now.difference(lastAccessed) > cacheExpiration) {
          final type = metadata['type'] as String;
          final lemma = metadata['lemma'] as String;
          
          // 刪除過期項目
          switch (type) {
            case 'word':
              await _wordCacheBox.delete(lemma);
              break;
            case 'phrase':
              await _phraseCacheBox.delete(lemma);
              break;
            case 'pattern':
              await _patternCacheBox.delete(lemma);
              break;
          }
          
          await _metadataBox.delete(key);
          expiredCount++;
        }
      }
    }
    
    if (expiredCount > 0) {
      _logger.i('清理了 $expiredCount 個過期快取項目');
    }
  }
  
  /// 確保已初始化
  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError('VocabCacheManager 尚未初始化，請先呼叫 initialize()');
    }
  }
  
  /// 關閉快取管理器
  Future<void> close() async {
    if (!_isInitialized) return;
    
    await _wordCacheBox.close();
    await _phraseCacheBox.close();
    await _patternCacheBox.close();
    await _metadataBox.close();
    
    _isInitialized = false;
    _logger.i('快取管理器已關閉');
  }
}
