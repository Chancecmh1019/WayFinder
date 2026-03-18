import 'package:hive/hive.dart';

part 'example_model.g.dart';

@HiveType(typeId: 4)
class ExampleModel extends HiveObject {
  @HiveField(0)
  final String sentence;

  @HiveField(1)
  final String? translation;

  @HiveField(2)
  final String? source;

  ExampleModel({
    required this.sentence,
    this.translation,
    this.source,
  });

  factory ExampleModel.fromJson(Map<String, dynamic> json) {
    return ExampleModel(
      sentence: json['sentence'] as String,
      translation: json['translation'] as String?,
      source: json['source'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sentence': sentence,
      'translation': translation,
      'source': source,
    };
  }
}
