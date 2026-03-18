import 'api_client_base.dart';
import '../../../core/errors/exceptions.dart';

/// Etymology information
class Etymology {
  final String text;
  final List<String> roots;

  Etymology({
    required this.text,
    required this.roots,
  });
}

/// Word form variation
class WordForm {
  final String form;
  final String type; // plural, past, gerund, etc.

  WordForm({
    required this.form,
    required this.type,
  });
}

/// Wiktionary API client for etymology and word forms
class WiktionaryAPIClient extends APIClientBase {
  WiktionaryAPIClient({super.dio})
      : super(
          baseUrl: 'https://en.wiktionary.org/api/rest_v1',
        );

  /// Get etymology information
  Future<Etymology?> getEtymology(String word) async {
    try {
      final response = await get<Map<String, dynamic>>(
        '/page/definition/$word',
      );

      return _parseEtymology(response);
    } on ServerException {
      return null; // Return null if not found
    } catch (e) {
      throw ServerException('Failed to fetch etymology: $e');
    }
  }

  /// Get word forms (inflections)
  Future<List<WordForm>> getWordForms(String word) async {
    try {
      final response = await get<Map<String, dynamic>>(
        '/page/definition/$word',
      );

      return _parseWordForms(response);
    } on ServerException {
      return []; // Return empty list if not found
    } catch (e) {
      throw ServerException('Failed to fetch word forms: $e');
    }
  }

  /// Get complete word information
  Future<Map<String, dynamic>> getWordInfo(String word) async {
    try {
      final response = await get<Map<String, dynamic>>(
        '/page/definition/$word',
      );

      return {
        'etymology': _parseEtymology(response),
        'wordForms': _parseWordForms(response),
        'definitions': _parseDefinitions(response),
      };
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to fetch word info: $e');
    }
  }

  Etymology? _parseEtymology(Map<String, dynamic> response) {
    try {
      // Wiktionary API structure varies, this is a simplified parser
      final definitions = response['en'] as List<dynamic>?;
      if (definitions == null || definitions.isEmpty) return null;

      // Look for etymology in the first definition section
      final firstDef = definitions[0] as Map<String, dynamic>;
      final etymologyText = firstDef['etymology'] as String?;

      if (etymologyText == null) return null;

      // Extract root words (simplified - looks for words in parentheses)
      final rootPattern = RegExp(r'\(([^)]+)\)');
      final matches = rootPattern.allMatches(etymologyText);
      final roots = matches.map((m) => m.group(1)!).toList();

      return Etymology(
        text: etymologyText,
        roots: roots,
      );
    } catch (e) {
      return null;
    }
  }

  List<WordForm> _parseWordForms(Map<String, dynamic> response) {
    try {
      final forms = <WordForm>[];
      final definitions = response['en'] as List<dynamic>?;

      if (definitions == null) return forms;

      for (final def in definitions) {
        final defMap = def as Map<String, dynamic>;

        // Look for inflection information
        final inflections = defMap['inflections'] as List<dynamic>?;
        if (inflections != null) {
          for (final inflection in inflections) {
            final inflMap = inflection as Map<String, dynamic>;
            forms.add(WordForm(
              form: inflMap['form'] as String,
              type: inflMap['type'] as String? ?? 'unknown',
            ));
          }
        }
      }

      return forms;
    } catch (e) {
      return [];
    }
  }

  List<Map<String, dynamic>> _parseDefinitions(Map<String, dynamic> response) {
    try {
      final definitions = <Map<String, dynamic>>[];
      final defList = response['en'] as List<dynamic>?;

      if (defList == null) return definitions;

      for (final def in defList) {
        final defMap = def as Map<String, dynamic>;
        final defTexts = defMap['definitions'] as List<dynamic>?;

        if (defTexts != null) {
          for (final defText in defTexts) {
            final defTextMap = defText as Map<String, dynamic>;
            definitions.add({
              'text': defTextMap['definition'] as String?,
              'partOfSpeech': defMap['partOfSpeech'] as String?,
              'examples': defTextMap['examples'] as List<dynamic>? ?? [],
            });
          }
        }
      }

      return definitions;
    } catch (e) {
      return [];
    }
  }

  /// Search for words by prefix
  Future<List<String>> searchByPrefix(
    String prefix, {
    int limit = 10,
  }) async {
    try {
      final response = await get<Map<String, dynamic>>(
        '/page/prefix/$prefix',
        queryParameters: {
          'limit': limit,
        },
      );

      final pages = response['pages'] as List<dynamic>? ?? [];
      return pages
          .map((page) => (page as Map<String, dynamic>)['title'] as String)
          .toList();
    } on ServerException {
      return [];
    } catch (e) {
      throw ServerException('Failed to search by prefix: $e');
    }
  }
}
