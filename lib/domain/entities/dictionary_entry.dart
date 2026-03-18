/// Dictionary entry entity representing a word definition from MDX dictionary
class DictionaryEntry {
  /// The word being defined
  final String word;

  /// Words that are commonly confused with this word
  final List<String> confusedWith;

  /// HTML content from the MDX dictionary
  final String htmlContent;

  /// Source dictionary name
  final String source;

  /// Timestamp when this entry was retrieved
  final DateTime retrievedAt;

  const DictionaryEntry({
    required this.word,
    this.confusedWith = const [],
    required this.htmlContent,
    required this.source,
    required this.retrievedAt,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DictionaryEntry &&
          runtimeType == other.runtimeType &&
          word == other.word &&
          htmlContent == other.htmlContent &&
          source == other.source;

  @override
  int get hashCode =>
      word.hashCode ^ htmlContent.hashCode ^ source.hashCode;

  @override
  String toString() =>
      'DictionaryEntry(word: $word, source: $source, contentLength: ${htmlContent.length})';
}
