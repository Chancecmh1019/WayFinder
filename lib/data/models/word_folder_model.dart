import 'package:hive/hive.dart';
import 'package:equatable/equatable.dart';

part 'word_folder_model.g.dart';

/// 單字資料夾模型
/// 
/// 用戶可以創建自己的單字資料夾，收藏和組織單字
@HiveType(typeId: 60)
class WordFolderModel extends Equatable {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String? description;

  @HiveField(3)
  final List<String> wordLemmas; // 單字 lemma 列表

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  final DateTime updatedAt;

  @HiveField(6)
  final String? color; // 資料夾顏色標籤

  @HiveField(7)
  final String? icon; // 資料夾圖示

  @HiveField(8)
  final int sortOrder; // 排序順序

  @HiveField(9)
  final List<String> phraseLemmas; // 片語 lemma 列表

  const WordFolderModel({
    required this.id,
    required this.name,
    this.description,
    required this.wordLemmas,
    required this.createdAt,
    required this.updatedAt,
    this.color,
    this.icon,
    this.sortOrder = 0,
    this.phraseLemmas = const [],
  });

  factory WordFolderModel.create({
    required String id,
    required String name,
    String? description,
    String? color,
    String? icon,
  }) {
    final now = DateTime.now();
    return WordFolderModel(
      id: id,
      name: name,
      description: description,
      wordLemmas: [],
      phraseLemmas: [],
      createdAt: now,
      updatedAt: now,
      color: color,
      icon: icon,
    );
  }

  WordFolderModel copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? wordLemmas,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? color,
    String? icon,
    int? sortOrder,
    List<String>? phraseLemmas,
  }) {
    return WordFolderModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      wordLemmas: wordLemmas ?? this.wordLemmas,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      sortOrder: sortOrder ?? this.sortOrder,
      phraseLemmas: phraseLemmas ?? this.phraseLemmas,
    );
  }

  /// 添加單字
  WordFolderModel addWord(String lemma) {
    if (wordLemmas.contains(lemma)) {
      return this;
    }
    return copyWith(
      wordLemmas: [...wordLemmas, lemma],
      updatedAt: DateTime.now(),
    );
  }

  /// 移除單字
  WordFolderModel removeWord(String lemma) {
    return copyWith(
      wordLemmas: wordLemmas.where((w) => w != lemma).toList(),
      updatedAt: DateTime.now(),
    );
  }

  /// 是否包含單字
  bool containsWord(String lemma) {
    return wordLemmas.contains(lemma);
  }

  /// 添加片語
  WordFolderModel addPhrase(String lemma) {
    if (phraseLemmas.contains(lemma)) {
      return this;
    }
    return copyWith(
      phraseLemmas: [...phraseLemmas, lemma],
      updatedAt: DateTime.now(),
    );
  }

  /// 移除片語
  WordFolderModel removePhrase(String lemma) {
    return copyWith(
      phraseLemmas: phraseLemmas.where((p) => p != lemma).toList(),
      updatedAt: DateTime.now(),
    );
  }

  /// 是否包含片語
  bool containsPhrase(String lemma) {
    return phraseLemmas.contains(lemma);
  }

  /// 單字數量
  int get wordCount => wordLemmas.length;

  /// 片語數量
  int get phraseCount => phraseLemmas.length;

  /// 總詞彙數量
  int get totalCount => wordCount + phraseCount;

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        wordLemmas,
        createdAt,
        updatedAt,
        color,
        icon,
        sortOrder,
        phraseLemmas,
      ];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'wordLemmas': wordLemmas,
      'phraseLemmas': phraseLemmas,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'color': color,
      'icon': icon,
      'sortOrder': sortOrder,
    };
  }

  factory WordFolderModel.fromJson(Map<String, dynamic> json) {
    return WordFolderModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      wordLemmas: (json['wordLemmas'] as List<dynamic>).cast<String>(),
      phraseLemmas: (json['phraseLemmas'] as List<dynamic>?)?.cast<String>() ?? [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      color: json['color'] as String?,
      icon: json['icon'] as String?,
      sortOrder: json['sortOrder'] as int? ?? 0,
    );
  }
}
