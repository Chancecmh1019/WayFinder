import 'package:equatable/equatable.dart';

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
class SourceInfo extends Equatable {
  final int year;
  final String examType;
  final String sectionType;
  final int? questionNumber;
  final String? role;
  final String? sentenceRole;

  const SourceInfo({
    required this.year,
    required this.examType,
    required this.sectionType,
    this.questionNumber,
    this.role,
    this.sentenceRole,
  });

  @override
  List<Object?> get props => [year, examType, sectionType, questionNumber, role, sentenceRole];
}

/// 考題例句
class ExamExample extends Equatable {
  final String text;
  final SourceInfo source;
  final String? audioHash;
  final String? translation;

  const ExamExample({
    required this.text,
    required this.source,
    this.audioHash,
    this.translation,
  });

  ExamExample copyWith({
    String? text,
    SourceInfo? source,
    String? audioHash,
    String? translation,
  }) {
    return ExamExample(
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
class VocabSense extends Equatable {
  final String senseId;
  final String pos;
  final String zhDef;
  final String? enDef;
  final List<ExamExample> examples;
  final String? generatedExample;

  const VocabSense({
    required this.senseId,
    required this.pos,
    required this.zhDef,
    this.enDef,
    required this.examples,
    this.generatedExample,
  });

  @override
  List<Object?> get props => [senseId, pos, zhDef, enDef, examples, generatedExample];
}

/// 頻率資料
class FrequencyData extends Equatable {
  final int totalAppearances;
  final int testedCount;
  final int activeTestedCount;
  final int yearSpread;
  final List<int> years;
  final Map<String, int> byRole;
  final Map<String, int> bySection;
  final Map<String, int> byExamType;
  final double? mlScore;
  final double importanceScore;

  const FrequencyData({
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
class ConfusionNote extends Equatable {
  final String confusedWith;
  final String distinction;
  final String? memoryTip;

  const ConfusionNote({
    required this.confusedWith,
    required this.distinction,
    this.memoryTip,
  });

  @override
  List<Object?> get props => [confusedWith, distinction, memoryTip];
}

/// 搭配詞組
class Collocation extends Equatable {
  final String english;
  final String chinese;

  const Collocation({
    required this.english,
    required this.chinese,
  });

  @override
  List<Object?> get props => [english, chinese];
}

/// 詞根資訊
class RootInfo extends Equatable {
  final String rootBreakdown;
  final String memoryStrategy;

  const RootInfo({
    required this.rootBreakdown,
    required this.memoryStrategy,
  });

  @override
  List<Object?> get props => [rootBreakdown, memoryStrategy];
}

/// 完整的詞彙條目（通用基類）
class VocabularyEntity extends Equatable {
  final String lemma;
  final String type; // word, phrase, pattern
  final List<String> pos;
  final int? level;
  final bool inOfficialList;
  final FrequencyData? frequency;
  final List<VocabSense> senses;
  final RootInfo? rootInfo;
  final List<ConfusionNote> confusionNotes;
  final List<String> synonyms;
  final List<String> antonyms;
  final List<String> derivedForms;
  final DateTime? lastUpdated;

  const VocabularyEntity({
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
class VocabIndexItem extends Equatable {
  final String lemma;
  final String type;
  final List<String> pos;
  final int? level;
  final bool inOfficialList;
  final double importanceScore;
  final String zhPreview;
  final int senseCount;
  final bool hasRootInfo;
  final bool hasConfusionNotes;
  final bool hasSynonyms;
  final int testedCount;
  final int yearSpread;

  const VocabIndexItem({
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
class PatternSubtype extends Equatable {
  final String subtype;
  final String displayName;
  final String structure;
  final List<ExamExample> examples;
  final String generatedExample;

  const PatternSubtype({
    required this.subtype,
    required this.displayName,
    required this.structure,
    required this.examples,
    required this.generatedExample,
  });

  @override
  List<Object?> get props => [subtype, displayName, structure, examples, generatedExample];
}

/// Pattern 條目（文法句型）
class PatternEntry extends Equatable {
  final String lemma;
  final String patternCategory;
  final List<PatternSubtype> subtypes;
  final String teachingExplanation;
  final DateTime? lastUpdated;
  final String? beginnerSummary;

  const PatternEntry({
    required this.lemma,
    required this.patternCategory,
    required this.subtypes,
    required this.teachingExplanation,
    this.lastUpdated,
    this.beginnerSummary,
  });

  @override
  List<Object?> get props => [lemma, patternCategory, subtypes, teachingExplanation, lastUpdated, beginnerSummary];
}

/// Phrase 條目（片語）
class PhraseEntry extends Equatable {
  final String lemma;
  final FrequencyData? frequency;
  final List<VocabSense> senses;
  final DateTime? lastUpdated;

  const PhraseEntry({
    required this.lemma,
    this.frequency,
    required this.senses,
    this.lastUpdated,
  });

  @override
  List<Object?> get props => [lemma, frequency, senses, lastUpdated];
}

/// Word 條目（單字）
class WordEntry extends Equatable {
  final String lemma;
  final List<String> pos;
  final int? level;
  final bool inOfficialList;
  final FrequencyData? frequency;
  final List<VocabSense> senses;
  final RootInfo? rootInfo;
  final List<ConfusionNote> confusionNotes;
  final List<String> synonyms;
  final List<String> antonyms;
  final List<String> derivedForms;
  final DateTime? lastUpdated;
  final List<Collocation> collocations;
  final String? usageNotes;
  final String? grammarNotes;
  final String? commonMistakes;

  const WordEntry({
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
class VocabDatabase {
  final String version;
  final String generatedAt;
  final Map<String, dynamic> metadata;
  final List<WordEntry> words;
  final List<PhraseEntry> phrases;
  final List<PatternEntry> patterns;

  const VocabDatabase({
    required this.version,
    required this.generatedAt,
    required this.metadata,
    required this.words,
    required this.phrases,
    required this.patterns,
  });
}
