import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/errors/exceptions.dart';

/// Sentence pair from Tatoeba database
class SentencePair {
  final String english;
  final String chinese;
  final int difficulty;

  SentencePair({
    required this.english,
    required this.chinese,
    required this.difficulty,
  });

  factory SentencePair.fromJson(Map<String, dynamic> json) {
    return SentencePair(
      english: json['english'] as String,
      chinese: json['chinese'] as String,
      difficulty: json['difficulty'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'english': english,
      'chinese': chinese,
      'difficulty': difficulty,
    };
  }
}

/// Service for managing Tatoeba sentence database
class TatoebaService {
  static const String _sentencesFile = 'tatoeba_sentences.json';
  List<SentencePair>? _sentences;
  bool _isInitialized = false;

  /// Initialize the service by loading sentences
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Try to load from local storage first
      final localFile = await _getLocalFile();
      if (await localFile.exists()) {
        await _loadFromFile(localFile);
      } else {
        // Load from assets if not in local storage
        await _loadFromAssets();
      }

      _isInitialized = true;
    } catch (e) {
      throw CacheException('Failed to initialize Tatoeba service: $e');
    }
  }

  /// Search for sentences containing the target word
  Future<List<SentencePair>> searchSentences({
    required String word,
    String? maxCEFRLevel,
    int limit = 10,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_sentences == null || _sentences!.isEmpty) {
      return [];
    }

    final wordLower = word.toLowerCase();
    final maxDifficulty = _cefrToMaxDifficulty(maxCEFRLevel);

    // Find sentences containing the word
    final matches = _sentences!.where((sentence) {
      final englishLower = sentence.english.toLowerCase();

      // Check if word appears in sentence
      final containsWord = _containsWord(englishLower, wordLower);

      // Check difficulty level
      final withinDifficulty =
          maxDifficulty == null || sentence.difficulty <= maxDifficulty;

      return containsWord && withinDifficulty;
    }).toList();

    // Sort by difficulty (easier first) and take limit
    matches.sort((a, b) => a.difficulty.compareTo(b.difficulty));

    return matches.take(limit).toList();
  }

  /// Check if word appears as a whole word in text
  bool _containsWord(String text, String word) {
    // Use word boundaries to match whole words
    final pattern = RegExp(r'\b' + RegExp.escape(word) + r'\b');
    return pattern.hasMatch(text);
  }

  /// Convert CEFR level to max difficulty score
  int? _cefrToMaxDifficulty(String? cefrLevel) {
    if (cefrLevel == null) return null;

    switch (cefrLevel.toUpperCase()) {
      case 'A1':
        return 1;
      case 'A2':
        return 2;
      case 'B1':
        return 3;
      case 'B2':
        return 4;
      case 'C1':
        return 5;
      case 'C2':
        return 6;
      default:
        return null;
    }
  }

  /// Load sentences from local file
  Future<void> _loadFromFile(File file) async {
    try {
      final contents = await file.readAsString();
      final jsonData = json.decode(contents) as List<dynamic>;

      _sentences = jsonData
          .map((item) => SentencePair.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw CacheException('Failed to load sentences from file: $e');
    }
  }

  /// Load sentences from assets
  Future<void> _loadFromAssets() async {
    try {
      // Try to load from assets
      final String data =
          await rootBundle.loadString('assets/tatoeba_sentences.json');
      final jsonData = json.decode(data) as List<dynamic>;

      _sentences = jsonData
          .map((item) => SentencePair.fromJson(item as Map<String, dynamic>))
          .toList();

      // Save to local storage for faster loading next time
      await _saveToLocalStorage();
    } catch (e) {
      // If assets don't exist, initialize with empty list
      _sentences = [];
    }
  }

  /// Save sentences to local storage
  Future<void> _saveToLocalStorage() async {
    if (_sentences == null) return;

    try {
      final file = await _getLocalFile();
      final jsonData = _sentences!.map((s) => s.toJson()).toList();
      await file.writeAsString(json.encode(jsonData));
    } catch (e) {
      // Non-critical error, silently ignore
      // In production, use proper logging instead of print
    }
  }

  /// Get local file path
  Future<File> _getLocalFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_sentencesFile');
  }

  /// Get total sentence count
  int get sentenceCount => _sentences?.length ?? 0;

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;

  /// Clear cached sentences
  Future<void> clearCache() async {
    _sentences = null;
    _isInitialized = false;

    final file = await _getLocalFile();
    if (await file.exists()) {
      await file.delete();
    }
  }
}
