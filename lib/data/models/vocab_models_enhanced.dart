import 'package:hive/hive.dart';
import 'package:equatable/equatable.dart';

part 'vocab_models_enhanced.g.dart';

/// 詞彙類型
enum VocabType {
  word,
  phrase,
  pattern,
}

/// 考試類型
enum ExamType {
  gsat,
  gsatMakeup,
  ast,
  astMakeup,
  gsatTrial,
  gsatRef,
  sped, // v6.0.0 新增：身障甄試
}

/// 題型
enum SectionType {
  vocabulary,
  cloze,
  discourse,
  structure,
  reading,
  translation,
  mixed,
}

/// 來源資訊
@HiveType(typeId: 50)
class SourceInfoModel extends Equatable {
  @HiveField(0)
  final int year;

  @HiveField(1)
  final String examType;

  @HiveField(2)
  final String sectionType;

  @HiveField(3)
  final int? questionNumber;

  @HiveField(4)
  final String? role;

  @HiveField(5)
  final String? sentenceRole;

  const SourceInfoModel({
    required this.year,
    required this.examType,
    required this.sectionType,
    this.questionNumber,
    this.role,
    this.sentenceRole,
  });

  factory SourceInfoModel.fromJson(Map<String, dynamic> json) {
    final examType = json['exam_type'];
    final sectionType = json['section_type'];
    
    return SourceInfoModel(
      year: json['year'] as int? ?? 0,
      examType: examType is String ? examType : (examType?.toString() ?? ''),
      sectionType: sectionType is String ? sectionType : (sectionType?.toString() ?? ''),
      questionNumber: json['question_number'] as int?,
      role: json['role'] as String?,
      sentenceRole: json['sentence_role'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'year': year,
      'exam_type': examType,
      'section_type': sectionType,
      if (questionNumber != null) 'question_number': questionNumber,
      if (role != null) 'role': role,
      if (sentenceRole != null) 'sentence_role': sentenceRole,
    };
  }

  @override
  List<Object?> get props => [year, examType, sectionType, questionNumber, role, sentenceRole];
}

/// 考題例句
@HiveType(typeId: 51)
class ExamExampleModel extends Equatable {
  @HiveField(0)
  final String text;

  @HiveField(1)
  final SourceInfoModel source;

  @HiveField(2)
  final String? audioHash;

  @HiveField(3)
  final String? translation; // 快取的翻譯

  const ExamExampleModel({
    required this.text,
    required this.source,
    this.audioHash,
    this.translation,
  });

  factory ExamExampleModel.fromJson(Map<String, dynamic> json) {
    final text = json['text'];
    
    return ExamExampleModel(
      text: text is String ? text : (text?.toString() ?? ''),
      source: SourceInfoModel.fromJson(json['source'] as Map<String, dynamic>),
      audioHash: json['audio_hash'] as String?,
      translation: json['translation'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'source': source.toJson(),
      if (audioHash != null) 'audio_hash': audioHash,
      if (translation != null) 'translation': translation,
    };
  }

  ExamExampleModel copyWith({
    String? text,
    SourceInfoModel? source,
    String? audioHash,
    String? translation,
  }) {
    return ExamExampleModel(
      text: text ?? this.text,
      source: source ?? this.source,
      audioHash: audioHash ?? this.audioHash,
      translation: translation ?? this.translation,
    );
  }

  @override
  List<Object?> get props => [text, source, audioHash, translation];
}


/// 詞彙義項（Sense）
@HiveType(typeId: 52)
class VocabSenseModel extends Equatable {
  @HiveField(0)
  final String senseId;

  @HiveField(1)
  final String pos;

  @HiveField(2)
  final String zhDef;

  @HiveField(3)
  final String? enDef;

  @HiveField(4)
  final List<ExamExampleModel> examples;

  @HiveField(5)
  final String? generatedExample;

  const VocabSenseModel({
    required this.senseId,
    required this.pos,
    required this.zhDef,
    this.enDef,
    required this.examples,
    this.generatedExample,
  });

  factory VocabSenseModel.fromJson(Map<String, dynamic> json) {
    final senseId = json['sense_id'];
    final pos = json['pos'];
    final zhDef = json['zh_def'];
    
    return VocabSenseModel(
      senseId: senseId is String ? senseId : (senseId?.toString() ?? ''),
      pos: pos is String ? pos : (pos?.toString() ?? ''),
      zhDef: zhDef is String ? zhDef : (zhDef?.toString() ?? ''),
      enDef: json['en_def'] as String?,
      examples: (json['examples'] as List<dynamic>?)
              ?.map((e) => ExamExampleModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      generatedExample: json['generated_example'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sense_id': senseId,
      'pos': pos,
      'zh_def': zhDef,
      if (enDef != null) 'en_def': enDef,
      'examples': examples.map((e) => e.toJson()).toList(),
      if (generatedExample != null) 'generated_example': generatedExample,
    };
  }

  @override
  List<Object?> get props => [senseId, pos, zhDef, enDef, examples, generatedExample];
}

/// 頻率資料
@HiveType(typeId: 53)
class FrequencyDataModel extends Equatable {
  @HiveField(0)
  final int totalAppearances;

  @HiveField(1)
  final int testedCount;

  @HiveField(2)
  final int activeTestedCount;

  @HiveField(3)
  final int yearSpread;

  @HiveField(4)
  final List<int> years;

  @HiveField(5)
  final Map<String, int> byRole;

  @HiveField(6)
  final Map<String, int> bySection;

  @HiveField(7)
  final Map<String, int> byExamType;

  @HiveField(8)
  final double? mlScore;

  @HiveField(9)
  final double importanceScore;

  const FrequencyDataModel({
    required this.totalAppearances,
    required this.testedCount,
    required this.activeTestedCount,
    required this.yearSpread,
    required this.years,
    required this.byRole,
    required this.bySection,
    required this.byExamType,
    this.mlScore,
    required this.importanceScore,
  });

  factory FrequencyDataModel.fromJson(Map<String, dynamic> json) {
    // 優先使用 importance_score，如果不存在則使用 ml_score
    final importanceScore = json['importance_score'] != null
        ? (json['importance_score'] as num).toDouble()
        : (json['ml_score'] != null ? (json['ml_score'] as num).toDouble() : 0.0);
    
    return FrequencyDataModel(
      totalAppearances: json['total_appearances'] as int? ?? 0,
      testedCount: json['tested_count'] as int? ?? 0,
      activeTestedCount: json['active_tested_count'] as int? ?? 0,
      yearSpread: json['year_spread'] as int? ?? 0,
      years: (json['years'] as List<dynamic>?)?.map((e) => e as int).toList() ?? [],
      byRole: (json['by_role'] as Map<String, dynamic>?)?.map((k, v) => MapEntry(k, v as int)) ?? {},
      bySection: (json['by_section'] as Map<String, dynamic>?)?.map((k, v) => MapEntry(k, v as int)) ?? {},
      byExamType: (json['by_exam_type'] as Map<String, dynamic>?)?.map((k, v) => MapEntry(k, v as int)) ?? {},
      mlScore: json['ml_score'] != null ? (json['ml_score'] as num).toDouble() : null,
      importanceScore: importanceScore,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_appearances': totalAppearances,
      'tested_count': testedCount,
      'active_tested_count': activeTestedCount,
      'year_spread': yearSpread,
      'years': years,
      'by_role': byRole,
      'by_section': bySection,
      'by_exam_type': byExamType,
      if (mlScore != null) 'ml_score': mlScore,
      'importance_score': importanceScore,
    };
  }

  @override
  List<Object?> get props => [
        totalAppearances,
        testedCount,
        activeTestedCount,
        yearSpread,
        years,
        byRole,
        bySection,
        byExamType,
        mlScore,
        importanceScore,
      ];
}

/// 易混淆詞說明
@HiveType(typeId: 54)
class ConfusionNoteModel extends Equatable {
  @HiveField(0)
  final String confusedWith;

  @HiveField(1)
  final String distinction;

  @HiveField(2)
  final String? memoryTip;

  const ConfusionNoteModel({
    required this.confusedWith,
    required this.distinction,
    this.memoryTip,
  });

  factory ConfusionNoteModel.fromJson(Map<String, dynamic> json) {
    final confusedWith = json['confused_with'];
    final distinction = json['distinction'];
    
    return ConfusionNoteModel(
      confusedWith: confusedWith is String ? confusedWith : (confusedWith?.toString() ?? ''),
      distinction: distinction is String ? distinction : (distinction?.toString() ?? ''),
      memoryTip: json['memory_tip'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'confused_with': confusedWith,
      'distinction': distinction,
      if (memoryTip != null) 'memory_tip': memoryTip,
    };
  }

  @override
  List<Object?> get props => [confusedWith, distinction, memoryTip];
}

/// 詞根資訊
@HiveType(typeId: 55)
class RootInfoModel extends Equatable {
  @HiveField(0)
  final String rootBreakdown;

  @HiveField(1)
  final String memoryStrategy;

  const RootInfoModel({
    required this.rootBreakdown,
    required this.memoryStrategy,
  });

  factory RootInfoModel.fromJson(Map<String, dynamic> json) {
    // Handle null values gracefully
    final rootBreakdown = json['root_breakdown'];
    final memoryStrategy = json['memory_strategy'];
    
    return RootInfoModel(
      rootBreakdown: rootBreakdown is String ? rootBreakdown : (rootBreakdown?.toString() ?? ''),
      memoryStrategy: memoryStrategy is String ? memoryStrategy : (memoryStrategy?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'root_breakdown': rootBreakdown,
      'memory_strategy': memoryStrategy,
    };
  }

  @override
  List<Object?> get props => [rootBreakdown, memoryStrategy];
}

/// 完整的詞彙條目
@HiveType(typeId: 56)
class VocabEntryModel extends Equatable {
  @HiveField(0)
  final String lemma;

  @HiveField(1)
  final String type; // word, phrase, pattern

  @HiveField(2)
  final List<String> pos;

  @HiveField(3)
  final int? level;

  @HiveField(4)
  final bool inOfficialList;

  @HiveField(5)
  final FrequencyDataModel? frequency;

  @HiveField(6)
  final List<VocabSenseModel> senses;

  @HiveField(7)
  final RootInfoModel? rootInfo;

  @HiveField(8)
  final List<ConfusionNoteModel> confusionNotes;

  @HiveField(9)
  final List<String> synonyms;

  @HiveField(10)
  final List<String> antonyms;

  @HiveField(11)
  final List<String> derivedForms;

  @HiveField(12)
  final DateTime? lastUpdated;

  const VocabEntryModel({
    required this.lemma,
    required this.type,
    required this.pos,
    this.level,
    required this.inOfficialList,
    this.frequency,
    required this.senses,
    this.rootInfo,
    required this.confusionNotes,
    required this.synonyms,
    required this.antonyms,
    required this.derivedForms,
    this.lastUpdated,
  });

  factory VocabEntryModel.fromJson(Map<String, dynamic> json) {
    final lemma = json['lemma'];
    // 從 _type 或 type 欄位取得類型，預設為 word
    final type = json['_type'] as String? ?? json['type'] as String? ?? 'word';
    
    return VocabEntryModel(
      lemma: lemma is String ? lemma : (lemma?.toString() ?? ''),
      type: type,
      pos: (json['pos'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      level: json['level'] as int?,
      inOfficialList: json['in_official_list'] as bool? ?? false,
      frequency: json['frequency'] != null
          ? FrequencyDataModel.fromJson(json['frequency'] as Map<String, dynamic>)
          : null,
      senses: (json['senses'] as List<dynamic>?)
              ?.map((e) => VocabSenseModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      rootInfo: json['root_info'] != null
          ? RootInfoModel.fromJson(json['root_info'] as Map<String, dynamic>)
          : null,
      confusionNotes: (json['confusion_notes'] as List<dynamic>?)
              ?.map((e) => ConfusionNoteModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      synonyms: (json['synonyms'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      antonyms: (json['antonyms'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      derivedForms: (json['derived_forms'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      lastUpdated: json['last_updated'] != null
          ? DateTime.parse(json['last_updated'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lemma': lemma,
      'type': type,
      'pos': pos,
      if (level != null) 'level': level,
      'in_official_list': inOfficialList,
      if (frequency != null) 'frequency': frequency!.toJson(),
      'senses': senses.map((e) => e.toJson()).toList(),
      if (rootInfo != null) 'root_info': rootInfo!.toJson(),
      'confusion_notes': confusionNotes.map((e) => e.toJson()).toList(),
      'synonyms': synonyms,
      'antonyms': antonyms,
      'derived_forms': derivedForms,
      if (lastUpdated != null) 'last_updated': lastUpdated!.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        lemma,
        type,
        pos,
        level,
        inOfficialList,
        frequency,
        senses,
        rootInfo,
        confusionNotes,
        synonyms,
        antonyms,
        derivedForms,
        lastUpdated,
      ];
}

/// 輕量級索引項目（用於首次下載）
@HiveType(typeId: 57)
class VocabIndexItemModel extends Equatable {
  @HiveField(0)
  final String lemma;

  @HiveField(1)
  final String type;

  @HiveField(2)
  final List<String> pos;

  @HiveField(3)
  final int? level;

  @HiveField(4)
  final bool inOfficialList;

  @HiveField(5)
  final double importanceScore;

  @HiveField(6)
  final String zhPreview;

  @HiveField(7)
  final int senseCount;

  @HiveField(8)
  final bool hasRootInfo;

  @HiveField(9)
  final bool hasConfusionNotes;

  @HiveField(10)
  final bool hasSynonyms;

  @HiveField(11)
  final int testedCount;

  @HiveField(12)
  final int yearSpread;

  const VocabIndexItemModel({
    required this.lemma,
    required this.type,
    required this.pos,
    this.level,
    required this.inOfficialList,
    required this.importanceScore,
    required this.zhPreview,
    required this.senseCount,
    required this.hasRootInfo,
    required this.hasConfusionNotes,
    required this.hasSynonyms,
    required this.testedCount,
    required this.yearSpread,
  });

  factory VocabIndexItemModel.fromJson(Map<String, dynamic> json) {
    final lemma = json['lemma'];
    final type = json['type'];
    
    return VocabIndexItemModel(
      lemma: lemma is String ? lemma : (lemma?.toString() ?? ''),
      type: type is String ? type : (type?.toString() ?? 'word'),
      pos: (json['pos'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      level: json['level'] as int?,
      inOfficialList: json['in_official_list'] as bool? ?? false,
      importanceScore: (json['importance_score'] as num?)?.toDouble() ?? 0.0,
      zhPreview: json['zh_preview'] as String? ?? '',
      senseCount: json['sense_count'] as int? ?? 0,
      hasRootInfo: json['has_root_info'] as bool? ?? false,
      hasConfusionNotes: json['has_confusion_notes'] as bool? ?? false,
      hasSynonyms: json['has_synonyms'] as bool? ?? false,
      testedCount: json['tested_count'] as int? ?? 0,
      yearSpread: json['year_spread'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lemma': lemma,
      'type': type,
      'pos': pos,
      if (level != null) 'level': level,
      'in_official_list': inOfficialList,
      'importance_score': importanceScore,
      'zh_preview': zhPreview,
      'sense_count': senseCount,
      'has_root_info': hasRootInfo,
      'has_confusion_notes': hasConfusionNotes,
      'has_synonyms': hasSynonyms,
      'tested_count': testedCount,
      'year_spread': yearSpread,
    };
  }

  @override
  List<Object?> get props => [
        lemma,
        type,
        pos,
        level,
        inOfficialList,
        importanceScore,
        zhPreview,
        senseCount,
        hasRootInfo,
        hasConfusionNotes,
        hasSynonyms,
        testedCount,
        yearSpread,
      ];
}

/// Pattern 子類型
@HiveType(typeId: 58)
class PatternSubtypeModel extends Equatable {
  @HiveField(0)
  final String subtype;

  @HiveField(1)
  final String displayName;

  @HiveField(2)
  final String structure;

  @HiveField(3)
  final List<ExamExampleModel> examples;

  @HiveField(4)
  final String generatedExample;

  const PatternSubtypeModel({
    required this.subtype,
    required this.displayName,
    required this.structure,
    required this.examples,
    required this.generatedExample,
  });

  factory PatternSubtypeModel.fromJson(Map<String, dynamic> json) {
    final subtype = json['subtype'];
    final displayName = json['display_name'];
    final structure = json['structure'];
    final generatedExample = json['generated_example'];
    
    return PatternSubtypeModel(
      subtype: subtype is String ? subtype : (subtype?.toString() ?? ''),
      displayName: displayName is String ? displayName : (displayName?.toString() ?? ''),
      structure: structure is String ? structure : (structure?.toString() ?? ''),
      examples: (json['examples'] as List<dynamic>?)
              ?.map((e) => ExamExampleModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      generatedExample: generatedExample is String ? generatedExample : (generatedExample?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subtype': subtype,
      'display_name': displayName,
      'structure': structure,
      'examples': examples.map((e) => e.toJson()).toList(),
      'generated_example': generatedExample,
    };
  }

  @override
  List<Object?> get props => [subtype, displayName, structure, examples, generatedExample];
}

/// Pattern 條目（文法句型）
@HiveType(typeId: 59)
class PatternEntryModel extends Equatable {
  @HiveField(0)
  final String lemma;

  @HiveField(1)
  final String patternCategory;

  @HiveField(2)
  final List<PatternSubtypeModel> subtypes;

  @HiveField(3)
  final String teachingExplanation;

  @HiveField(4)
  final DateTime? lastUpdated;

  @HiveField(5)
  final String? beginnerSummary;

  const PatternEntryModel({
    required this.lemma,
    required this.patternCategory,
    required this.subtypes,
    required this.teachingExplanation,
    this.lastUpdated,
    this.beginnerSummary,
  });

  factory PatternEntryModel.fromJson(Map<String, dynamic> json) {
    final lemma = json['lemma'];
    final patternCategory = json['pattern_category'];
    final teachingExplanation = json['teaching_explanation'];
    
    return PatternEntryModel(
      lemma: lemma is String ? lemma : (lemma?.toString() ?? ''),
      patternCategory: patternCategory is String ? patternCategory : (patternCategory?.toString() ?? ''),
      subtypes: (json['subtypes'] as List<dynamic>?)
              ?.map((e) => PatternSubtypeModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      teachingExplanation: teachingExplanation is String ? teachingExplanation : (teachingExplanation?.toString() ?? ''),
      lastUpdated: json['last_updated'] != null
          ? DateTime.parse(json['last_updated'] as String)
          : null,
      beginnerSummary: json['beginner_summary'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lemma': lemma,
      'pattern_category': patternCategory,
      'subtypes': subtypes.map((e) => e.toJson()).toList(),
      'teaching_explanation': teachingExplanation,
      if (lastUpdated != null) 'last_updated': lastUpdated!.toIso8601String(),
      if (beginnerSummary != null) 'beginner_summary': beginnerSummary,
    };
  }

  @override
  List<Object?> get props => [lemma, patternCategory, subtypes, teachingExplanation, lastUpdated, beginnerSummary];
}

/// Phrase 條目（片語）
@HiveType(typeId: 61)
class PhraseEntryModel extends Equatable {
  @HiveField(0)
  final String lemma;

  @HiveField(1)
  final FrequencyDataModel? frequency;

  @HiveField(2)
  final List<VocabSenseModel> senses;

  @HiveField(3)
  final DateTime? lastUpdated;

  const PhraseEntryModel({
    required this.lemma,
    this.frequency,
    required this.senses,
    this.lastUpdated,
  });

  factory PhraseEntryModel.fromJson(Map<String, dynamic> json) {
    final lemma = json['lemma'];
    
    return PhraseEntryModel(
      lemma: lemma is String ? lemma : (lemma?.toString() ?? ''),
      frequency: json['frequency'] != null
          ? FrequencyDataModel.fromJson(json['frequency'] as Map<String, dynamic>)
          : null,
      senses: (json['senses'] as List<dynamic>?)
              ?.map((e) => VocabSenseModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      lastUpdated: json['last_updated'] != null
          ? DateTime.parse(json['last_updated'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lemma': lemma,
      if (frequency != null) 'frequency': frequency!.toJson(),
      'senses': senses.map((e) => e.toJson()).toList(),
      if (lastUpdated != null) 'last_updated': lastUpdated!.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [lemma, frequency, senses, lastUpdated];
}

/// 搭配詞組
@HiveType(typeId: 63)
class CollocationModel extends Equatable {
  @HiveField(0)
  final String english;

  @HiveField(1)
  final String chinese;

  const CollocationModel({
    required this.english,
    required this.chinese,
  });

  factory CollocationModel.fromJson(Map<String, dynamic> json) {
    return CollocationModel(
      english: json['collocation'] as String? ?? json['english'] as String? ?? '',
      chinese: json['zh'] as String? ?? json['chinese'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'english': english,
      'chinese': chinese,
    };
  }

  @override
  List<Object?> get props => [english, chinese];
}

/// Word 條目（單字）- 重新命名 VocabEntryModel 為 WordEntryModel
@HiveType(typeId: 62)
class WordEntryModel extends Equatable {
  @HiveField(0)
  final String lemma;

  @HiveField(1)
  final List<String> pos;

  @HiveField(2)
  final int? level;

  @HiveField(3)
  final bool inOfficialList;

  @HiveField(4)
  final FrequencyDataModel? frequency;

  @HiveField(5)
  final List<VocabSenseModel> senses;

  @HiveField(6)
  final RootInfoModel? rootInfo;

  @HiveField(7)
  final List<ConfusionNoteModel> confusionNotes;

  @HiveField(8)
  final List<String> synonyms;

  @HiveField(9)
  final List<String> antonyms;

  @HiveField(10)
  final List<String> derivedForms;

  @HiveField(11)
  final DateTime? lastUpdated;

  @HiveField(12)
  final List<CollocationModel> collocations;

  @HiveField(13)
  final String? usageNotes;

  @HiveField(14)
  final String? grammarNotes;

  @HiveField(15)
  final String? commonMistakes;

  const WordEntryModel({
    required this.lemma,
    required this.pos,
    this.level,
    required this.inOfficialList,
    this.frequency,
    required this.senses,
    this.rootInfo,
    required this.confusionNotes,
    required this.synonyms,
    required this.antonyms,
    required this.derivedForms,
    this.lastUpdated,
    this.collocations = const [],
    this.usageNotes,
    this.grammarNotes,
    this.commonMistakes,
  });

  factory WordEntryModel.fromJson(Map<String, dynamic> json) {
    final lemma = json['lemma'];
    
    return WordEntryModel(
      lemma: lemma is String ? lemma : (lemma?.toString() ?? ''),
      pos: (json['pos'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      level: json['level'] as int?,
      inOfficialList: json['in_official_list'] as bool? ?? false,
      frequency: json['frequency'] != null
          ? FrequencyDataModel.fromJson(json['frequency'] as Map<String, dynamic>)
          : null,
      senses: (json['senses'] as List<dynamic>?)
              ?.map((e) => VocabSenseModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      rootInfo: json['root_info'] != null
          ? RootInfoModel.fromJson(json['root_info'] as Map<String, dynamic>)
          : null,
      confusionNotes: (json['confusion_notes'] as List<dynamic>?)
              ?.map((e) => ConfusionNoteModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      synonyms: (json['synonyms'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      antonyms: (json['antonyms'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      derivedForms: (json['derived_forms'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      lastUpdated: json['last_updated'] != null
          ? DateTime.parse(json['last_updated'] as String)
          : null,
      collocations: (json['collocations'] as List<dynamic>?)
              ?.map((e) => CollocationModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      usageNotes: json['usage_notes'] as String?,
      grammarNotes: json['grammar_notes'] as String?,
      commonMistakes: json['common_mistakes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lemma': lemma,
      'pos': pos,
      if (level != null) 'level': level,
      'in_official_list': inOfficialList,
      if (frequency != null) 'frequency': frequency!.toJson(),
      'senses': senses.map((e) => e.toJson()).toList(),
      if (rootInfo != null) 'root_info': rootInfo!.toJson(),
      'confusion_notes': confusionNotes.map((e) => e.toJson()).toList(),
      'synonyms': synonyms,
      'antonyms': antonyms,
      'derived_forms': derivedForms,
      if (lastUpdated != null) 'last_updated': lastUpdated!.toIso8601String(),
      'collocations': collocations.map((e) => e.toJson()).toList(),
      if (usageNotes != null) 'usage_notes': usageNotes,
      if (grammarNotes != null) 'grammar_notes': grammarNotes,
      if (commonMistakes != null) 'common_mistakes': commonMistakes,
    };
  }

  @override
  List<Object?> get props => [
        lemma,
        pos,
        level,
        inOfficialList,
        frequency,
        senses,
        rootInfo,
        confusionNotes,
        synonyms,
        antonyms,
        derivedForms,
        lastUpdated,
        collocations,
        usageNotes,
        grammarNotes,
        commonMistakes,
      ];
}

/// 完整的詞彙資料庫結構
class VocabDatabaseModel {
  final String version;
  final String generatedAt;
  final Map<String, dynamic> metadata;
  final List<WordEntryModel> words;
  final List<PhraseEntryModel> phrases;
  final List<PatternEntryModel> patterns;

  const VocabDatabaseModel({
    required this.version,
    required this.generatedAt,
    required this.metadata,
    required this.words,
    required this.phrases,
    required this.patterns,
  });

  factory VocabDatabaseModel.fromJson(Map<String, dynamic> json) {
    final version = json['version'];
    final generatedAt = json['generated_at'];
    
    return VocabDatabaseModel(
      version: version is String ? version : (version?.toString() ?? ''),
      generatedAt: generatedAt is String ? generatedAt : (generatedAt?.toString() ?? ''),
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      words: (json['words'] as List<dynamic>?)
              ?.map((e) => WordEntryModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      phrases: (json['phrases'] as List<dynamic>?)
              ?.map((e) => PhraseEntryModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      patterns: (json['patterns'] as List<dynamic>?)
              ?.map((e) => PatternEntryModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'generated_at': generatedAt,
      'metadata': metadata,
      'words': words.map((e) => e.toJson()).toList(),
      'phrases': phrases.map((e) => e.toJson()).toList(),
      'patterns': patterns.map((e) => e.toJson()).toList(),
    };
  }
}
