import 'dart:convert';
import '../models/vocab_models_enhanced.dart';
import 'package:archive/archive.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:logger/logger.dart';
/// Service for loading vocabulary data from assets
class VocabularyLoaderService {
  final Logger _logger = Logger();
  static const String assetPath = 'assets/GSAT-English.json.gz';
  static const int batchSize = 100;

  /// Load vocabulary from gzipped JSON asset file
  Future<void> loadVocabularyFromAssets(LazyBox<VocabEntryModel> box) async {
    try {
      _logger.i('Starting vocabulary data load from $assetPath');

      // Check if already loaded
      if (box.isNotEmpty) {
        _logger.i('Vocabulary already loaded (${box.length} words). Skipping.');
        return;
      }

      // Load from vocab_original.json.gz
      await _loadFromOriginalFormat(box, assetPath);
    } catch (e, stackTrace) {
      _logger.e('Failed to load vocabulary data: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Load from original format (vocab_original.json.gz)
  Future<void> _loadFromOriginalFormat(LazyBox<VocabEntryModel> box, String path) async {
    final ByteData data = await rootBundle.load(path);
    final List<int> bytes = data.buffer.asUint8List();
    _logger.i('Loaded ${bytes.length} bytes from $path');

    final List<int> decompressed = GZipDecoder().decodeBytes(bytes);
    final String jsonString = utf8.decode(decompressed);
    _logger.i('Decompressed ${decompressed.length} bytes');

    final dynamic jsonData = json.decode(jsonString);
    
    // Original format has 'words', 'phrases', and 'patterns' keys
    int totalProcessed = 0;
    
    // Load words
    if (jsonData is Map<String, dynamic> && jsonData.containsKey('words')) {
      final List<dynamic> wordsList = jsonData['words'] as List<dynamic>;
      _logger.i('Found ${wordsList.length} words');
      totalProcessed += await _processVocabularyList(box, wordsList, 'word');
    }
    
    // Load phrases
    if (jsonData is Map<String, dynamic> && jsonData.containsKey('phrases')) {
      final List<dynamic> phrasesList = jsonData['phrases'] as List<dynamic>;
      _logger.i('Found ${phrasesList.length} phrases');
      totalProcessed += await _processVocabularyList(box, phrasesList, 'phrase');
    }
    
    // Load patterns (grammar patterns)
    if (jsonData is Map<String, dynamic> && jsonData.containsKey('patterns')) {
      final List<dynamic> patternsList = jsonData['patterns'] as List<dynamic>;
      _logger.i('Found ${patternsList.length} patterns');
      totalProcessed += await _processVocabularyList(box, patternsList, 'pattern');
    }

    _logger.i('Successfully loaded $totalProcessed total items (words + phrases + patterns)');
    await box.compact();
  }
  
  /// Process a list of vocabulary items
  Future<int> _processVocabularyList(
    LazyBox<VocabEntryModel> box,
    List<dynamic> vocabularyList,
    String type,
  ) async {
    int processedCount = 0;
    final List<MapEntry<String, VocabEntryModel>> batch = [];

    for (final item in vocabularyList) {
      try {
        final Map<String, dynamic> itemMap = item as Map<String, dynamic>;
        // Add type marker to the data
        itemMap['_type'] = type;
        
        final vocabModel = VocabEntryModel.fromJson(itemMap);
        batch.add(MapEntry(vocabModel.lemma, vocabModel));

        if (batch.length >= batchSize) {
          await _insertBatch(box, batch);
          processedCount += batch.length;
          _logger.d('Processed $processedCount $type items');
          batch.clear();
        }
      } catch (e) {
        _logger.w('Failed to parse $type item: $e');
      }
    }

    if (batch.isNotEmpty) {
      await _insertBatch(box, batch);
      processedCount += batch.length;
    }

    return processedCount;
  }

  /// Insert a batch of vocabulary entries
  Future<void> _insertBatch(
    LazyBox<VocabEntryModel> box,
    List<MapEntry<String, VocabEntryModel>> batch,
  ) async {
    final Map<String, VocabEntryModel> batchMap = Map.fromEntries(batch);
    await box.putAll(batchMap);
  }

  /// Build indexes for efficient querying
  Future<void> buildIndexes(LazyBox<VocabEntryModel> vocabularyBox) async {
    try {
      _logger.i('Building vocabulary indexes...');

      final cefrIndexBox = await Hive.openBox<List<String>>('vocab_cefr_index');
      final frequencyIndexBox = await Hive.openBox<List<String>>('vocab_frequency_index');
      final posIndexBox = await Hive.openBox<List<String>>('vocab_pos_index');

      await cefrIndexBox.clear();
      await frequencyIndexBox.clear();
      await posIndexBox.clear();

      final Map<String, List<String>> cefrIndex = {};
      final Map<String, List<String>> posIndex = {};

      for (final key in vocabularyBox.keys) {
        final vocab = await vocabularyBox.get(key);
        if (vocab != null) {
          final levelKey = vocab.level?.toString() ?? 'unknown';
          cefrIndex.putIfAbsent(levelKey, () => []).add(vocab.lemma);
          for (final pos in vocab.pos) {
            posIndex.putIfAbsent(pos, () => []).add(vocab.lemma);
          }
        }
      }

      await cefrIndexBox.putAll(cefrIndex);
      await posIndexBox.putAll(posIndex);

      _logger.i('Indexes built successfully');
      _logger.i('CEFR levels: ${cefrIndex.keys.join(", ")}');
      _logger.i('Parts of speech: ${posIndex.keys.join(", ")}');
    } catch (e, stackTrace) {
      _logger.e('Failed to build indexes: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Get vocabulary count
  Future<int> getVocabularyCount(LazyBox<VocabEntryModel> box) async {
    return box.length;
  }

  /// Check if vocabulary is loaded
  Future<bool> isVocabularyLoaded(LazyBox<VocabEntryModel> box) async {
    return box.isNotEmpty;
  }
}
