import 'package:hive/hive.dart';
import '../../models/vocab_models_enhanced.dart';
import 'package:logger/logger.dart';
import '../../services/hive_service.dart';
import '../../services/vocabulary_loader_service.dart';

/// Local data source for vocabulary using Hive
class VocabularyLocalDataSource {
  final Logger _logger = Logger();
  LazyBox<VocabEntryModel>? _vocabularyBox;
  Box<List<String>>? _cefrIndexBox;
  Box<List<String>>? _posIndexBox;
  final VocabularyLoaderService _loaderService = VocabularyLoaderService();

  /// Initialize the data source
  Future<void> initialize() async {
    try {
      _logger.i('[VocabularyLocalDataSource] 開始初始化...');
      
      _vocabularyBox = await HiveService.openVocabularyBox();
      _logger.i('[VocabularyLocalDataSource] 單字 Box 已打開，當前數量: ${_vocabularyBox!.length}');
      
      // Check if index boxes are already open
      if (!Hive.isBoxOpen('vocab_cefr_index')) {
        _cefrIndexBox = await Hive.openBox<List<String>>('vocab_cefr_index');
      } else {
        _cefrIndexBox = Hive.box<List<String>>('vocab_cefr_index');
      }
      
      if (!Hive.isBoxOpen('vocab_pos_index')) {
        _posIndexBox = await Hive.openBox<List<String>>('vocab_pos_index');
      } else {
        _posIndexBox = Hive.box<List<String>>('vocab_pos_index');
      }

      // Load vocabulary if not already loaded
      if (_vocabularyBox!.isEmpty) {
        _logger.i('[VocabularyLocalDataSource] 單字 Box 為空，開始加載單字...');
        await _loaderService.loadVocabularyFromAssets(_vocabularyBox!);
        _logger.i('[VocabularyLocalDataSource] 單字加載完成，數量: ${_vocabularyBox!.length}');
        
        // Only build indexes if vocabulary was loaded successfully
        if (_vocabularyBox!.isNotEmpty) {
          await _loaderService.buildIndexes(_vocabularyBox!);
          _logger.i('[VocabularyLocalDataSource] 索引建立完成');
        }
      } else {
        _logger.i('[VocabularyLocalDataSource] 單字已存在，跳過加載');
      }
    } catch (e, stackTrace) {
      _logger.e('[VocabularyLocalDataSource] 初始化失敗: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Get all vocabulary words
  Future<List<VocabEntryModel>> getAllVocabulary() async {
    await _ensureInitialized();
    final List<VocabEntryModel> result = [];
    for (final key in _vocabularyBox!.keys) {
      final vocab = await _vocabularyBox!.get(key);
      if (vocab != null) {
        result.add(vocab);
      }
    }
    return result;
  }

  /// Get vocabulary by word
  Future<VocabEntryModel?> getVocabularyByWord(String word) async {
    await _ensureInitialized();
    return await _vocabularyBox!.get(word);
  }

  /// Get vocabulary by CEFR level
  Future<List<VocabEntryModel>> getVocabularyByLevel(String cefrLevel) async {
    await _ensureInitialized();
    final words = _cefrIndexBox!.get(cefrLevel) ?? [];
    final List<VocabEntryModel> result = [];
    for (final word in words) {
      final vocab = await _vocabularyBox!.get(word);
      if (vocab != null) {
        result.add(vocab);
      }
    }
    return result;
  }

  /// Get vocabulary by part of speech
  Future<List<VocabEntryModel>> getVocabularyByPartOfSpeech(String pos) async {
    await _ensureInitialized();
    final words = _posIndexBox!.get(pos) ?? [];
    final List<VocabEntryModel> result = [];
    for (final word in words) {
      final vocab = await _vocabularyBox!.get(word);
      if (vocab != null) {
        result.add(vocab);
      }
    }
    return result;
  }

  /// Search vocabulary by query (word starts with query)
  Future<List<VocabEntryModel>> searchVocabulary(String query) async {
    await _ensureInitialized();
    final lowerQuery = query.toLowerCase();
    final List<VocabEntryModel> result = [];

    for (final key in _vocabularyBox!.keys) {
      final word = key as String;
      if (word.toLowerCase().startsWith(lowerQuery)) {
        final vocab = await _vocabularyBox!.get(key);
        if (vocab != null) {
          result.add(vocab);
        }
      }
    }

    return result;
  }

  /// Get vocabulary count
  Future<int> getVocabularyCount() async {
    await _ensureInitialized();
    return _vocabularyBox!.length;
  }

  /// Get all CEFR levels
  Future<List<String>> getAllCEFRLevels() async {
    await _ensureInitialized();
    return _cefrIndexBox!.keys.cast<String>().toList();
  }

  /// Get all parts of speech
  Future<List<String>> getAllPartsOfSpeech() async {
    await _ensureInitialized();
    return _posIndexBox!.keys.cast<String>().toList();
  }

  /// Ensure the data source is initialized
  Future<void> _ensureInitialized() async {
    if (_vocabularyBox == null) {
      await initialize();
    }
  }

  /// Close the data source
  Future<void> close() async {
    await _vocabularyBox?.close();
    await _cefrIndexBox?.close();
    await _posIndexBox?.close();
  }
}
