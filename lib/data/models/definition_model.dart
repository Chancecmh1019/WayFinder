import 'package:hive/hive.dart';

part 'definition_model.g.dart';

@HiveType(typeId: 3)
class DefinitionModel extends HiveObject {
  @HiveField(0)
  final String definition;

  @HiveField(1)
  final String? partOfSpeech;

  @HiveField(2)
  final String? translation;

  @HiveField(3)
  final List<String>? synonyms;

  @HiveField(4)
  final List<String>? antonyms;

  DefinitionModel({
    required this.definition,
    this.partOfSpeech,
    this.translation,
    this.synonyms,
    this.antonyms,
  });

  factory DefinitionModel.fromJson(Map<String, dynamic> json) {
    return DefinitionModel(
      definition: json['definition'] as String,
      partOfSpeech: json['partOfSpeech'] as String?,
      translation: json['translation'] as String?,
      synonyms: (json['synonyms'] as List<dynamic>?)?.cast<String>(),
      antonyms: (json['antonyms'] as List<dynamic>?)?.cast<String>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'definition': definition,
      'partOfSpeech': partOfSpeech,
      'translation': translation,
      'synonyms': synonyms,
      'antonyms': antonyms,
    };
  }
}
