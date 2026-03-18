import 'package:hive/hive.dart';
import 'definition_model.dart';
import 'example_model.dart';

part 'vocabulary_model.g.dart';

@HiveType(typeId: 0)
class VocabularyModel extends HiveObject {
  @HiveField(0)
  final String word;

  @HiveField(1)
  final String phonetic;

  @HiveField(2)
  final List<DefinitionModel> definitions;

  @HiveField(3)
  final List<ExampleModel> examples;

  @HiveField(4)
  final List<String> partsOfSpeech;

  @HiveField(5)
  final String? audioUrl;

  @HiveField(6)
  final String cefrLevel;

  @HiveField(7)
  final int frequency;

  @HiveField(8)
  final Map<String, dynamic> originalData;

  // 新增欄位：完整資料支援
  @HiveField(9)
  final bool inOfficialList;

  @HiveField(10)
  final int totalAppearances;

  @HiveField(11)
  final int testedCount;

  @HiveField(12)
  final int yearSpread;

  @HiveField(13)
  final List<int> examYears;

  @HiveField(14)
  final Map<String, int> byRole;

  @HiveField(15)
  final Map<String, int> bySection;

  @HiveField(16)
  final Map<String, int> byExamType;

  @HiveField(17)
  final String? rootBreakdown;

  @HiveField(18)
  final String? memoryStrategy;

  @HiveField(19)
  final List<String> synonyms;

  @HiveField(20)
  final List<String> derivedForms;
  
  @HiveField(21)
  final String? itemType; // 'word', 'phrase', 'pattern'

  VocabularyModel({
    required this.word,
    required this.phonetic,
    required this.definitions,
    required this.examples,
    required this.partsOfSpeech,
    this.audioUrl,
    required this.cefrLevel,
    required this.frequency,
    required this.originalData,
    required this.inOfficialList,
    required this.totalAppearances,
    required this.testedCount,
    required this.yearSpread,
    required this.examYears,
    required this.byRole,
    required this.bySection,
    required this.byExamType,
    this.rootBreakdown,
    this.memoryStrategy,
    required this.synonyms,
    required this.derivedForms,
    this.itemType,
  });

  factory VocabularyModel.fromJson(Map<String, dynamic> json) {
    // 檢查類型標記
    final itemType = json['_type'] as String?;
    
    // 檢查是否為 original 格式（有 lemma 欄位）
    final isOriginalFormat = json.containsKey('lemma');
    
    if (isOriginalFormat) {
      return VocabularyModel._fromOriginalFormat(json, itemType);
    } else {
      return VocabularyModel._fromSimpleFormat(json);
    }
  }

  /// 從 original 格式載入（vocab_original.json.gz）
  factory VocabularyModel._fromOriginalFormat(Map<String, dynamic> json, String? itemType) {
    final lemma = json['lemma'] as String;
    final posList = (json['pos'] as List<dynamic>?)?.cast<String>() ?? [];
    final level = json['level'] as int? ?? 3;
    final inOfficialList = json['in_official_list'] as bool? ?? false;
    
    // 頻率資料
    final frequencyData = json['frequency'] as Map<String, dynamic>?;
    final totalAppearances = frequencyData?['total_appearances'] as int? ?? 0;
    final testedCount = frequencyData?['tested_count'] as int? ?? 0;
    final yearSpread = frequencyData?['year_spread'] as int? ?? 0;
    final examYears = (frequencyData?['years'] as List<dynamic>?)?.cast<int>() ?? [];
    final byRole = Map<String, int>.from(frequencyData?['by_role'] as Map? ?? {});
    final bySection = Map<String, int>.from(frequencyData?['by_section'] as Map? ?? {});
    final byExamType = Map<String, int>.from(frequencyData?['by_exam_type'] as Map? ?? {});
    
    // Senses 資料
    final sensesList = json['senses'] as List<dynamic>?;
    final definitions = <DefinitionModel>[];
    final examples = <ExampleModel>[];

    if (sensesList != null) {
      for (final sense in sensesList) {
        final senseMap = sense as Map<String, dynamic>;
        final pos = senseMap['pos'] as String? ?? '';
        final zhDef = senseMap['zh_def'] as String? ?? '';
        final enDef = senseMap['en_def'] as String? ?? '';
        
        // 添加定義
        definitions.add(DefinitionModel(
          definition: enDef,
          partOfSpeech: pos,
          translation: zhDef,
        ));

        // 添加例句
        final examplesList = senseMap['examples'] as List<dynamic>?;
        if (examplesList != null) {
          for (final ex in examplesList) {
            final exMap = ex as Map<String, dynamic>;
            final text = exMap['text'] as String? ?? '';
            final source = exMap['source'] as Map<String, dynamic>?;
            
            if (text.isNotEmpty) {
              // 建立來源資訊字串
              String? sourceInfo;
              if (source != null) {
                final year = source['year'] as int?;
                final examType = source['exam_type'] as String?;
                final sectionType = source['section_type'] as String?;
                sourceInfo = '${year ?? ''} ${examType ?? ''} · ${sectionType ?? ''}';
              }
              
              examples.add(ExampleModel(
                sentence: text,
                translation: sourceInfo,
              ));
            }
          }
        }

        // 添加生成的例句
        final generatedExample = senseMap['generated_example'] as String?;
        if (generatedExample != null && generatedExample.isNotEmpty) {
          examples.add(ExampleModel(
            sentence: generatedExample,
            translation: null,
          ));
        }
      }
    }

    // 詞根資訊
    final rootInfo = json['root_info'] as Map<String, dynamic>?;
    final rootBreakdown = rootInfo?['root_breakdown'] as String?;
    final memoryStrategy = rootInfo?['memory_strategy'] as String?;

    // 同義詞和衍生詞
    final synonyms = (json['synonyms'] as List<dynamic>?)?.cast<String>() ?? [];
    final derivedForms = (json['derived_forms'] as List<dynamic>?)?.cast<String>() ?? [];

    return VocabularyModel(
      word: lemma,
      phonetic: '',
      definitions: definitions,
      examples: examples,
      partsOfSpeech: posList,
      audioUrl: null,
      cefrLevel: _mapLevelToCEFR(level),
      frequency: totalAppearances,
      originalData: json,
      inOfficialList: inOfficialList,
      totalAppearances: totalAppearances,
      testedCount: testedCount,
      yearSpread: yearSpread,
      examYears: examYears,
      byRole: byRole,
      bySection: bySection,
      byExamType: byExamType,
      rootBreakdown: rootBreakdown,
      memoryStrategy: memoryStrategy,
      synonyms: synonyms,
      derivedForms: derivedForms,
      itemType: itemType ?? 'word',
    );
  }

  /// 從簡化格式載入（vocab.json.gz）
  factory VocabularyModel._fromSimpleFormat(Map<String, dynamic> json) {
    return VocabularyModel(
      word: json['word'] as String,
      phonetic: json['phonetic'] as String? ?? '',
      definitions: (json['definitions'] as List<dynamic>?)
              ?.map((e) => DefinitionModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      examples: (json['examples'] as List<dynamic>?)
              ?.map((e) => ExampleModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      partsOfSpeech: (json['partsOfSpeech'] as List<dynamic>?)?.cast<String>() ?? [],
      audioUrl: json['audioUrl'] as String?,
      cefrLevel: json['cefrLevel'] as String? ?? 'B1',
      frequency: json['frequency'] as int? ?? 0,
      originalData: Map<String, dynamic>.from(json),
      inOfficialList: false,
      totalAppearances: json['frequency'] as int? ?? 0,
      testedCount: 0,
      yearSpread: 0,
      examYears: [],
      byRole: {},
      bySection: {},
      byExamType: {},
      rootBreakdown: null,
      memoryStrategy: null,
      synonyms: [],
      derivedForms: [],
      itemType: 'word',
    );
  }

  static String _mapLevelToCEFR(int level) {
    switch (level) {
      case 1:
        return 'A1';
      case 2:
        return 'A2';
      case 3:
        return 'B1';
      case 4:
        return 'B2';
      case 5:
        return 'C1';
      case 6:
        return 'C2';
      default:
        return 'B1';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'word': word,
      'phonetic': phonetic,
      'definitions': definitions.map((e) => e.toJson()).toList(),
      'examples': examples.map((e) => e.toJson()).toList(),
      'partsOfSpeech': partsOfSpeech,
      'audioUrl': audioUrl,
      'cefrLevel': cefrLevel,
      'frequency': frequency,
      'inOfficialList': inOfficialList,
      'totalAppearances': totalAppearances,
      'testedCount': testedCount,
      'yearSpread': yearSpread,
      'examYears': examYears,
      'byRole': byRole,
      'bySection': bySection,
      'byExamType': byExamType,
      'rootBreakdown': rootBreakdown,
      'memoryStrategy': memoryStrategy,
      'synonyms': synonyms,
      'derivedForms': derivedForms,
      'itemType': itemType,
    };
  }
}
