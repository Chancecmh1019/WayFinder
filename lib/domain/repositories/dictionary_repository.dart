import 'package:dartz/dartz.dart';
import '../entities/dictionary_entry.dart';
import '../../core/errors/failures.dart';

/// Repository interface for dictionary operations
abstract class DictionaryRepository {
  /// Initialize the dictionary service
  /// Loads dictionary files from assets
  Future<Either<Failure, void>> initialize();

  /// Look up a single word in the dictionary
  /// Returns the dictionary entry or a failure
  Future<Either<Failure, DictionaryEntry>> lookup(String word);

  /// Batch lookup multiple words
  /// Returns a map of word to dictionary entry
  Future<Either<Failure, Map<String, DictionaryEntry>>> batchLookup(
    List<String> words,
  );

  /// Check if the dictionary is initialized
  bool get isInitialized;

  /// Get the list of available dictionary sources
  List<String> get availableSources;
}
