import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:flutter/services.dart';
import '../models/vocab_models_enhanced.dart';

/// Loads and caches vocabulary from assets/GSAT-English.json.gz
class LocalVocabService {
  static const String assetPath = 'assets/GSAT-English.json.gz';

  // In-memory LRU caches
  final Map<String, WordEntryModel> _wordCache = {};
  final Map<String, PhraseEntryModel> _phraseCache = {};
  final Map<String, PatternEntryModel> _patternCache = {};
  static const int _maxCacheSize = 800;

  VocabDatabaseModel? _db;
  bool _loading = false;

  Future<VocabDatabaseModel> loadDatabase() async {
    if (_db != null) return _db!;
    
    // If already loading, wait for it to complete
    if (_loading) {
      int attempts = 0;
      const maxAttempts = 100; // 5 seconds max wait
      while (_loading && attempts < maxAttempts) {
        await Future.delayed(const Duration(milliseconds: 50));
        attempts++;
      }
      if (_db != null) return _db!;
      // If still loading after timeout, throw error
      if (_loading) {
        throw Exception('Database loading timeout');
      }
    }
    
    _loading = true;
    try {
      final data = await rootBundle.load(assetPath);
      final bytes = data.buffer.asUint8List();
      final decompressed = GZipDecoder().decodeBytes(bytes);
      final jsonString = utf8.decode(decompressed);
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      _db = VocabDatabaseModel.fromJson(json);
      return _db!;
    } catch (e) {
      _loading = false;
      rethrow;
    } finally {
      _loading = false;
    }
  }

  Future<List<WordEntryModel>> getAllWords() async {
    final db = await loadDatabase();
    return db.words;
  }

  Future<List<PhraseEntryModel>> getAllPhrases() async {
    final db = await loadDatabase();
    return db.phrases;
  }

  Future<List<PatternEntryModel>> getAllPatterns() async {
    final db = await loadDatabase();
    return db.patterns;
  }

  Future<WordEntryModel?> getWord(String lemma) async {
    if (_wordCache.containsKey(lemma)) return _wordCache[lemma];
    final db = await loadDatabase();
    final word = db.words.where((w) => w.lemma == lemma).firstOrNull;
    if (word != null) {
      _putWordCache(lemma, word);
    }
    return word;
  }

  Future<PhraseEntryModel?> getPhrase(String lemma) async {
    if (_phraseCache.containsKey(lemma)) return _phraseCache[lemma];
    final db = await loadDatabase();
    final phrase = db.phrases.where((p) => p.lemma == lemma).firstOrNull;
    if (phrase != null) {
      if (_phraseCache.length >= _maxCacheSize) {
        _phraseCache.remove(_phraseCache.keys.first);
      }
      _phraseCache[lemma] = phrase;
    }
    return phrase;
  }

  Future<PatternEntryModel?> getPattern(String lemma) async {
    if (_patternCache.containsKey(lemma)) return _patternCache[lemma];
    final db = await loadDatabase();
    final pattern = db.patterns.where((p) => p.lemma == lemma).firstOrNull;
    if (pattern != null) _patternCache[lemma] = pattern;
    return pattern;
  }

  void _putWordCache(String key, WordEntryModel value) {
    if (_wordCache.length >= _maxCacheSize) {
      _wordCache.remove(_wordCache.keys.first);
    }
    _wordCache[key] = value;
  }

  /// Get words with cloze examples (for cloze test mode)
  Future<List<MapEntry<WordEntryModel, ExamExampleModel>>> getClozeExamples({
    int limit = 50,
  }) async {
    final db = await loadDatabase();
    final result = <MapEntry<WordEntryModel, ExamExampleModel>>[];
    for (final word in db.words) {
      for (final sense in word.senses) {
        for (final ex in sense.examples) {
          final role = ex.source.sentenceRole ?? '';
          final section = ex.source.sectionType;
          if ((role == 'cloze' || role == 'correct_answer') &&
              (section == 'vocabulary' || section == 'cloze') &&
              ex.text.toLowerCase().contains(word.lemma.toLowerCase())) {
            result.add(MapEntry(word, ex));
            if (result.length >= limit * 3) break;
          }
        }
        if (result.length >= limit * 3) break;
      }
      if (result.length >= limit * 3) break;
    }
    result.shuffle();
    return result.take(limit).toList();
  }

  /// Get words that have confusion_notes (for confusion trainer)
  Future<List<WordEntryModel>> getWordsWithConfusion() async {
    final db = await loadDatabase();
    return db.words.where((w) => w.confusionNotes.isNotEmpty).toList();
  }

  /// Get words grouped by root prefix (for root explorer)
  Future<Map<String, List<WordEntryModel>>> getWordsByRoot() async {
    final db = await loadDatabase();
    final map = <String, List<WordEntryModel>>{};
    for (final word in db.words) {
      if (word.rootInfo != null) {
        final root = word.rootInfo!.rootBreakdown.split(' ').first;
        map.putIfAbsent(root, () => []).add(word);
      }
    }
    return Map.fromEntries(
      map.entries.where((e) => e.value.length >= 2).toList()
        ..sort((a, b) => b.value.length.compareTo(a.value.length)),
    );
  }

  bool get isLoaded => _db != null;

  /// Phrase examples for cloze fill-in mode
  Future<List<MapEntry<PhraseEntryModel, ExamExampleModel>>> getPhraseClozeExamples({
    int limit = 15,
  }) async {
    final db = await loadDatabase();
    final result = <MapEntry<PhraseEntryModel, ExamExampleModel>>[];
    for (final phrase in db.phrases) {
      for (final sense in phrase.senses) {
        for (final ex in sense.examples) {
          if (ex.text.toLowerCase().contains(phrase.lemma.toLowerCase())) {
            result.add(MapEntry(phrase, ex));
          }
        }
      }
    }
    result.shuffle();
    return result.take(limit).toList();
  }
}
