import 'dart:math';
import '../entities/entities.dart';

/// Strategy for interleaving practice to avoid mechanical memorization
class InterleavingStrategy {
  final Random _random;
  static const int _maxConsecutiveSameCategory = 3;

  InterleavingStrategy({Random? random}) : _random = random ?? Random();

  /// Interleave a list of words to mix different categories
  List<VocabularyEntity> interleaveWords(List<VocabularyEntity> words) {
    if (words.length <= 3) {
      // Too few words to interleave meaningfully
      return words;
    }

    // Group words by category
    final categories = _categorizeWords(words);

    // Build interleaved list
    final interleaved = <VocabularyEntity>[];
    final categoryKeys = categories.keys.toList()..shuffle(_random);
    final categoryIterators = <String, int>{};

    // Initialize iterators
    for (final key in categoryKeys) {
      categoryIterators[key] = 0;
    }

    int consecutiveSameCategory = 0;
    String? lastCategory;

    while (interleaved.length < words.length) {
      // Find next category to use
      String? nextCategory;

      // Try to avoid using the same category consecutively
      if (consecutiveSameCategory >= _maxConsecutiveSameCategory &&
          lastCategory != null) {
        // Force switch to a different category
        nextCategory = _findDifferentCategory(
          categoryKeys,
          lastCategory,
          categoryIterators,
          categories,
        );
      }

      // If no forced switch, pick the next available category
      nextCategory ??= _findNextAvailableCategory(
        categoryKeys,
        categoryIterators,
        categories,
      );

      if (nextCategory == null) {
        // No more words available
        break;
      }

      // Add word from selected category
      final categoryWords = categories[nextCategory]!;
      final index = categoryIterators[nextCategory]!;
      interleaved.add(categoryWords[index]);
      categoryIterators[nextCategory] = index + 1;

      // Update consecutive counter
      if (nextCategory == lastCategory) {
        consecutiveSameCategory++;
      } else {
        consecutiveSameCategory = 1;
        lastCategory = nextCategory;
      }
    }

    return interleaved;
  }

  /// Categorize words by CEFR level, part of speech, and word family
  Map<String, List<VocabularyEntity>> _categorizeWords(
    List<VocabularyEntity> words,
  ) {
    final categories = <String, List<VocabularyEntity>>{};

    for (final word in words) {
      // Create category key based on CEFR level and primary part of speech
      final cefrLevel = word.level?.toString() ?? "unknown";
      final partOfSpeech = word.pos.isNotEmpty
          ? word.pos.first
          : 'unknown';
      final categoryKey = '$cefrLevel-$partOfSpeech';

      categories.putIfAbsent(categoryKey, () => []).add(word);
    }

    return categories;
  }

  /// Find a different category from the last one
  String? _findDifferentCategory(
    List<String> categoryKeys,
    String lastCategory,
    Map<String, int> categoryIterators,
    Map<String, List<VocabularyEntity>> categories,
  ) {
    for (final key in categoryKeys) {
      if (key != lastCategory) {
        final index = categoryIterators[key]!;
        final categoryWords = categories[key]!;
        if (index < categoryWords.length) {
          return key;
        }
      }
    }
    return null;
  }

  /// Find the next available category with remaining words
  String? _findNextAvailableCategory(
    List<String> categoryKeys,
    Map<String, int> categoryIterators,
    Map<String, List<VocabularyEntity>> categories,
  ) {
    for (final key in categoryKeys) {
      final index = categoryIterators[key]!;
      final categoryWords = categories[key]!;
      if (index < categoryWords.length) {
        return key;
      }
    }
    return null;
  }

  /// Identify confusing word pairs from a list
  List<ConfusingPair> identifyConfusingPairs(List<VocabularyEntity> words) {
    final pairs = <ConfusingPair>[];

    for (int i = 0; i < words.length; i++) {
      for (int j = i + 1; j < words.length; j++) {
        final word1 = words[i];
        final word2 = words[j];

        if (_areWordsConfusing(word1, word2)) {
          pairs.add(ConfusingPair(word1: word1, word2: word2));
        }
      }
    }

    return pairs;
  }

  /// Check if two words are potentially confusing
  bool _areWordsConfusing(VocabularyEntity word1, VocabularyEntity word2) {
    // Similar spelling (edit distance)
    if (_calculateEditDistance(word1.lemma, word2.lemma) <= 2) {
      return true;
    }

    // Similar pronunciation (simplified check)
    if (_arePhoneticallySimila(word1.lemma, word2.lemma)) {
      return true;
    }

    // Same part of speech but different meanings
    if (word1.pos.any((pos) => word2.pos.contains(pos))) {
      return true;
    }

    return false;
  }

  /// Calculate Levenshtein edit distance between two strings
  int _calculateEditDistance(String s1, String s2) {
    final len1 = s1.length;
    final len2 = s2.length;

    // Create a matrix to store distances
    final matrix = List.generate(
      len1 + 1,
      (i) => List.filled(len2 + 1, 0),
    );

    // Initialize first row and column
    for (int i = 0; i <= len1; i++) {
      matrix[i][0] = i;
    }
    for (int j = 0; j <= len2; j++) {
      matrix[0][j] = j;
    }

    // Calculate distances
    for (int i = 1; i <= len1; i++) {
      for (int j = 1; j <= len2; j++) {
        final cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1, // deletion
          matrix[i][j - 1] + 1, // insertion
          matrix[i - 1][j - 1] + cost, // substitution
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    return matrix[len1][len2];
  }

  /// Check if two phonetic representations are similar (simplified)
  bool _arePhoneticallySimila(String phonetic1, String phonetic2) {
    if (phonetic1.isEmpty || phonetic2.isEmpty) {
      return false;
    }

    // Simple similarity check based on edit distance
    return _calculateEditDistance(phonetic1, phonetic2) <= 3;
  }

  /// Mix confusing pairs into a session
  List<VocabularyEntity> mixConfusingPairs({
    required List<VocabularyEntity> words,
    required List<ConfusingPair> confusingPairs,
  }) {
    final mixed = <VocabularyEntity>[];
    final usedPairs = <ConfusingPair>{};

    for (final word in words) {
      mixed.add(word);

      // Check if this word is part of a confusing pair
      final pair = confusingPairs.firstWhere(
        (p) => (p.word1.lemma == word.lemma || p.word2.lemma == word.lemma) &&
            !usedPairs.contains(p),
        orElse: () => ConfusingPair(
          word1: word,
          word2: word,
        ), // Dummy pair
      );

      // If found a valid pair and not already used
      if (pair.word1.lemma != pair.word2.lemma && !usedPairs.contains(pair)) {
        // Add the confusing pair word nearby (within next 3-5 words)
        final insertPosition = mixed.length + _random.nextInt(3) + 1;
        final pairWord =
            pair.word1.lemma == word.lemma ? pair.word2 : pair.word1;

        // Mark as used
        usedPairs.add(pair);

        // Insert the pair word if not already in the list
        if (!mixed.any((w) => w.lemma == pairWord.lemma)) {
          if (insertPosition < words.length) {
            mixed.insert(
              insertPosition.clamp(0, mixed.length),
              pairWord,
            );
          }
        }
      }
    }

    return mixed;
  }

  /// Ensure no more than 3 consecutive words from the same category
  bool validateInterleaving(List<VocabularyEntity> words) {
    if (words.length <= 3) {
      return true;
    }

    String? lastCategory;
    int consecutiveCount = 0;

    for (final word in words) {
      final category = '${word.level?.toString() ?? "unknown"}-${word.pos.isNotEmpty ? word.pos.first : "unknown"}';

      if (category == lastCategory) {
        consecutiveCount++;
        if (consecutiveCount > _maxConsecutiveSameCategory) {
          return false;
        }
      } else {
        consecutiveCount = 1;
        lastCategory = category;
      }
    }

    return true;
  }
}

/// Represents a pair of potentially confusing words
class ConfusingPair {
  final VocabularyEntity word1;
  final VocabularyEntity word2;

  const ConfusingPair({
    required this.word1,
    required this.word2,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConfusingPair &&
          runtimeType == other.runtimeType &&
          ((word1 == other.word1 && word2 == other.word2) ||
              (word1 == other.word2 && word2 == other.word1));

  @override
  int get hashCode => word1.hashCode ^ word2.hashCode;
}
