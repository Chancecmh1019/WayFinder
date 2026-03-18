import '../models/vocab_models_enhanced.dart';
import '../../domain/entities/vocabulary_entity.dart';

/// Mapper for converting between VocabularyEntity and VocabEntryModel
class VocabularyMapper {
  /// Convert VocabEntryModel to VocabularyEntity
  static VocabularyEntity toEntity(VocabEntryModel model) {
    return VocabularyEntity(
      lemma: model.lemma,
      type: model.type,
      pos: model.pos,
      level: model.level,
      inOfficialList: model.inOfficialList,
      frequency: model.frequency != null
          ? FrequencyDataMapper.toEntity(model.frequency!)
          : null,
      senses: model.senses.map((s) => VocabSenseMapper.toEntity(s)).toList(),
      rootInfo: model.rootInfo != null
          ? RootInfoMapper.toEntity(model.rootInfo!)
          : null,
      confusionNotes: model.confusionNotes
          .map((c) => ConfusionNoteMapper.toEntity(c))
          .toList(),
      synonyms: model.synonyms,
      antonyms: model.antonyms,
      derivedForms: model.derivedForms,
      lastUpdated: model.lastUpdated,
    );
  }

  /// Convert VocabularyEntity to VocabEntryModel
  static VocabEntryModel toModel(VocabularyEntity entity) {
    return VocabEntryModel(
      lemma: entity.lemma,
      type: entity.type,
      pos: entity.pos,
      level: entity.level,
      inOfficialList: entity.inOfficialList,
      frequency: entity.frequency != null
          ? FrequencyDataMapper.toModel(entity.frequency!)
          : null,
      senses: entity.senses.map((s) => VocabSenseMapper.toModel(s)).toList(),
      rootInfo: entity.rootInfo != null
          ? RootInfoMapper.toModel(entity.rootInfo!)
          : null,
      confusionNotes: entity.confusionNotes
          .map((c) => ConfusionNoteMapper.toModel(c))
          .toList(),
      synonyms: entity.synonyms,
      antonyms: entity.antonyms,
      derivedForms: entity.derivedForms,
      lastUpdated: entity.lastUpdated,
    );
  }

  /// Convert list of models to entities
  static List<VocabularyEntity> toEntityList(List<VocabEntryModel> models) {
    return models.map((m) => toEntity(m)).toList();
  }

  /// Convert list of entities to models
  static List<VocabEntryModel> toModelList(List<VocabularyEntity> entities) {
    return entities.map((e) => toModel(e)).toList();
  }
}

/// Helper mappers for nested types
class FrequencyDataMapper {
  static FrequencyData toEntity(FrequencyDataModel model) {
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

  static FrequencyDataModel toModel(FrequencyData entity) {
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
}

class VocabSenseMapper {
  static VocabSense toEntity(VocabSenseModel model) {
    return VocabSense(
      senseId: model.senseId,
      pos: model.pos,
      zhDef: model.zhDef,
      enDef: model.enDef,
      examples: model.examples.map((e) => ExamExampleMapper.toEntity(e)).toList(),
      generatedExample: model.generatedExample,
    );
  }

  static VocabSenseModel toModel(VocabSense entity) {
    return VocabSenseModel(
      senseId: entity.senseId,
      pos: entity.pos,
      zhDef: entity.zhDef,
      enDef: entity.enDef,
      examples: entity.examples.map((e) => ExamExampleMapper.toModel(e)).toList(),
      generatedExample: entity.generatedExample,
    );
  }
}

class ExamExampleMapper {
  static ExamExample toEntity(ExamExampleModel model) {
    return ExamExample(
      text: model.text,
      source: SourceInfoMapper.toEntity(model.source),
      audioHash: model.audioHash,
      translation: model.translation,
    );
  }

  static ExamExampleModel toModel(ExamExample entity) {
    return ExamExampleModel(
      text: entity.text,
      source: SourceInfoMapper.toModel(entity.source),
      audioHash: entity.audioHash,
      translation: entity.translation,
    );
  }
}

class SourceInfoMapper {
  static SourceInfo toEntity(SourceInfoModel model) {
    return SourceInfo(
      year: model.year,
      examType: model.examType,
      sectionType: model.sectionType,
      questionNumber: model.questionNumber,
      role: model.role,
      sentenceRole: model.sentenceRole,
    );
  }

  static SourceInfoModel toModel(SourceInfo entity) {
    return SourceInfoModel(
      year: entity.year,
      examType: entity.examType,
      sectionType: entity.sectionType,
      questionNumber: entity.questionNumber,
      role: entity.role,
      sentenceRole: entity.sentenceRole,
    );
  }
}

class RootInfoMapper {
  static RootInfo toEntity(RootInfoModel model) {
    return RootInfo(
      rootBreakdown: model.rootBreakdown,
      memoryStrategy: model.memoryStrategy,
    );
  }

  static RootInfoModel toModel(RootInfo entity) {
    return RootInfoModel(
      rootBreakdown: entity.rootBreakdown,
      memoryStrategy: entity.memoryStrategy,
    );
  }
}

class ConfusionNoteMapper {
  static ConfusionNote toEntity(ConfusionNoteModel model) {
    return ConfusionNote(
      confusedWith: model.confusedWith,
      distinction: model.distinction,
      memoryTip: model.memoryTip,
    );
  }

  static ConfusionNoteModel toModel(ConfusionNote entity) {
    return ConfusionNoteModel(
      confusedWith: entity.confusedWith,
      distinction: entity.distinction,
      memoryTip: entity.memoryTip,
    );
  }
}
