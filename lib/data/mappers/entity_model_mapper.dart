library;

/// Mappers for converting between entities and models

/// Mapper between domain entities and data models
/// This provides conversion between VocabularyEntity (domain) and VocabEntryModel/WordEntryModel (data)

import '../../domain/entities/vocabulary_entity.dart';
import '../models/vocab_models_enhanced.dart';

class EntityModelMapper {
  /// Convert WordEntryModel to VocabularyEntity
  static VocabularyEntity wordEntryToEntity(WordEntryModel model) {
    return VocabularyEntity(
      lemma: model.lemma,
      type: 'word',
      pos: model.pos,
      level: model.level,
      inOfficialList: model.inOfficialList,
      frequency: model.frequency != null ? _frequencyModelToEntity(model.frequency!) : null,
      senses: model.senses.map(_senseModelToEntity).toList(),
      rootInfo: model.rootInfo != null ? _rootInfoModelToEntity(model.rootInfo!) : null,
      confusionNotes: model.confusionNotes.map(_confusionNoteModelToEntity).toList(),
      synonyms: model.synonyms,
      antonyms: model.antonyms,
      derivedForms: model.derivedForms,
      lastUpdated: model.lastUpdated,
    );
  }

  /// Convert PhraseEntryModel to VocabularyEntity
  static VocabularyEntity phraseEntryToEntity(PhraseEntryModel model) {
    return VocabularyEntity(
      lemma: model.lemma,
      type: 'phrase',
      pos: [],
      level: null,
      inOfficialList: false,
      frequency: model.frequency != null ? _frequencyModelToEntity(model.frequency!) : null,
      senses: model.senses.map(_senseModelToEntity).toList(),
      rootInfo: null,
      confusionNotes: [],
      synonyms: [],
      antonyms: [],
      derivedForms: [],
      lastUpdated: model.lastUpdated,
    );
  }

  /// Convert VocabEntryModel to VocabularyEntity
  static VocabularyEntity vocabEntryToEntity(VocabEntryModel model) {
    return VocabularyEntity(
      lemma: model.lemma,
      type: model.type,
      pos: model.pos,
      level: model.level,
      inOfficialList: model.inOfficialList,
      frequency: model.frequency != null ? _frequencyModelToEntity(model.frequency!) : null,
      senses: model.senses.map(_senseModelToEntity).toList(),
      rootInfo: model.rootInfo != null ? _rootInfoModelToEntity(model.rootInfo!) : null,
      confusionNotes: model.confusionNotes.map(_confusionNoteModelToEntity).toList(),
      synonyms: model.synonyms,
      antonyms: model.antonyms,
      derivedForms: model.derivedForms,
      lastUpdated: model.lastUpdated,
    );
  }

  /// Convert FrequencyDataModel to FrequencyData
  static FrequencyData _frequencyModelToEntity(FrequencyDataModel model) {
    return FrequencyData(
      totalAppearances: model.totalAppearances,
      testedCount: model.testedCount,
      activeTestedCount: model.activeTestedCount,
      yearSpread: model.yearSpread,
      years: model.years,
      byRole: model.byRole,
      bySection: model.bySection,
      byExamType: model.byExamType,
      mlScore: model.mlScore,
      importanceScore: model.importanceScore,
    );
  }

  /// Convert VocabSenseModel to VocabSense
  static VocabSense _senseModelToEntity(VocabSenseModel model) {
    return VocabSense(
      senseId: model.senseId,
      pos: model.pos,
      zhDef: model.zhDef,
      enDef: model.enDef,
      examples: model.examples.map(_examExampleModelToEntity).toList(),
      generatedExample: model.generatedExample,
    );
  }

  /// Convert ExamExampleModel to ExamExample
  static ExamExample _examExampleModelToEntity(ExamExampleModel model) {
    return ExamExample(
      text: model.text,
      source: _sourceInfoModelToEntity(model.source),
      audioHash: model.audioHash,
      translation: model.translation,
    );
  }

  /// Convert SourceInfoModel to SourceInfo
  static SourceInfo _sourceInfoModelToEntity(SourceInfoModel model) {
    return SourceInfo(
      year: model.year,
      examType: model.examType,
      sectionType: model.sectionType,
      questionNumber: model.questionNumber,
      role: model.role,
      sentenceRole: model.sentenceRole,
    );
  }

  /// Convert RootInfoModel to RootInfo
  static RootInfo _rootInfoModelToEntity(RootInfoModel model) {
    return RootInfo(
      rootBreakdown: model.rootBreakdown,
      memoryStrategy: model.memoryStrategy,
    );
  }

  /// Convert ConfusionNoteModel to ConfusionNote
  static ConfusionNote _confusionNoteModelToEntity(ConfusionNoteModel model) {
    return ConfusionNote(
      confusedWith: model.confusedWith,
      distinction: model.distinction,
      memoryTip: model.memoryTip,
    );
  }

  // Reverse conversions (Entity to Model)

  /// Convert VocabularyEntity to WordEntryModel
  static WordEntryModel entityToWordEntry(VocabularyEntity entity) {
    return WordEntryModel(
      lemma: entity.lemma,
      pos: entity.pos,
      level: entity.level,
      inOfficialList: entity.inOfficialList,
      frequency: entity.frequency != null ? _frequencyEntityToModel(entity.frequency!) : null,
      senses: entity.senses.map(_senseEntityToModel).toList(),
      rootInfo: entity.rootInfo != null ? _rootInfoEntityToModel(entity.rootInfo!) : null,
      confusionNotes: entity.confusionNotes.map(_confusionNoteEntityToModel).toList(),
      synonyms: entity.synonyms,
      antonyms: entity.antonyms,
      derivedForms: entity.derivedForms,
      lastUpdated: entity.lastUpdated,
      collocations: [],
      usageNotes: null,
      grammarNotes: null,
      commonMistakes: null,
    );
  }

  /// Convert FrequencyData to FrequencyDataModel
  static FrequencyDataModel _frequencyEntityToModel(FrequencyData entity) {
    return FrequencyDataModel(
      totalAppearances: entity.totalAppearances,
      testedCount: entity.testedCount,
      activeTestedCount: entity.activeTestedCount,
      yearSpread: entity.yearSpread,
      years: entity.years,
      byRole: entity.byRole,
      bySection: entity.bySection,
      byExamType: entity.byExamType,
      mlScore: entity.mlScore,
      importanceScore: entity.importanceScore,
    );
  }

  /// Convert VocabSense to VocabSenseModel
  static VocabSenseModel _senseEntityToModel(VocabSense entity) {
    return VocabSenseModel(
      senseId: entity.senseId,
      pos: entity.pos,
      zhDef: entity.zhDef,
      enDef: entity.enDef,
      examples: entity.examples.map(_examExampleEntityToModel).toList(),
      generatedExample: entity.generatedExample,
    );
  }

  /// Convert ExamExample to ExamExampleModel
  static ExamExampleModel _examExampleEntityToModel(ExamExample entity) {
    return ExamExampleModel(
      text: entity.text,
      source: _sourceInfoEntityToModel(entity.source),
      audioHash: entity.audioHash,
      translation: entity.translation,
    );
  }

  /// Convert SourceInfo to SourceInfoModel
  static SourceInfoModel _sourceInfoEntityToModel(SourceInfo entity) {
    return SourceInfoModel(
      year: entity.year,
      examType: entity.examType,
      sectionType: entity.sectionType,
      questionNumber: entity.questionNumber,
      role: entity.role,
      sentenceRole: entity.sentenceRole,
    );
  }

  /// Convert RootInfo to RootInfoModel
  static RootInfoModel _rootInfoEntityToModel(RootInfo entity) {
    return RootInfoModel(
      rootBreakdown: entity.rootBreakdown,
      memoryStrategy: entity.memoryStrategy,
    );
  }

  /// Convert ConfusionNote to ConfusionNoteModel
  static ConfusionNoteModel _confusionNoteEntityToModel(ConfusionNote entity) {
    return ConfusionNoteModel(
      confusedWith: entity.confusedWith,
      distinction: entity.distinction,
      memoryTip: entity.memoryTip,
    );
  }

  /// Convert CollocationModel to Collocation
  static Collocation _collocationModelToEntity(CollocationModel model) {
    return Collocation(
      english: model.english,
      chinese: model.chinese,
    );
  }

  /// Convert Collocation to CollocationModel
  static CollocationModel _collocationEntityToModel(Collocation entity) {
    return CollocationModel(
      english: entity.english,
      chinese: entity.chinese,
    );
  }
}
