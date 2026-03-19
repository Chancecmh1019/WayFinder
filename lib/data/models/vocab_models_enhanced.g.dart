// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vocab_models_enhanced.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SourceInfoModelAdapter extends TypeAdapter<SourceInfoModel> {
  @override
  final int typeId = 50;

  @override
  SourceInfoModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SourceInfoModel(
      year: fields[0] as int,
      examType: fields[1] as String,
      sectionType: fields[2] as String,
      questionNumber: fields[3] as int?,
      role: fields[4] as String?,
      sentenceRole: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, SourceInfoModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.year)
      ..writeByte(1)
      ..write(obj.examType)
      ..writeByte(2)
      ..write(obj.sectionType)
      ..writeByte(3)
      ..write(obj.questionNumber)
      ..writeByte(4)
      ..write(obj.role)
      ..writeByte(5)
      ..write(obj.sentenceRole);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SourceInfoModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ExamExampleModelAdapter extends TypeAdapter<ExamExampleModel> {
  @override
  final int typeId = 51;

  @override
  ExamExampleModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ExamExampleModel(
      text: fields[0] as String,
      source: fields[1] as SourceInfoModel,
      audioHash: fields[2] as String?,
      translation: fields[3] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ExamExampleModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.text)
      ..writeByte(1)
      ..write(obj.source)
      ..writeByte(2)
      ..write(obj.audioHash)
      ..writeByte(3)
      ..write(obj.translation);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExamExampleModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class VocabSenseModelAdapter extends TypeAdapter<VocabSenseModel> {
  @override
  final int typeId = 52;

  @override
  VocabSenseModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return VocabSenseModel(
      senseId: fields[0] as String,
      pos: fields[1] as String,
      zhDef: fields[2] as String,
      enDef: fields[3] as String?,
      examples: (fields[4] as List).cast<ExamExampleModel>(),
      generatedExample: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, VocabSenseModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.senseId)
      ..writeByte(1)
      ..write(obj.pos)
      ..writeByte(2)
      ..write(obj.zhDef)
      ..writeByte(3)
      ..write(obj.enDef)
      ..writeByte(4)
      ..write(obj.examples)
      ..writeByte(5)
      ..write(obj.generatedExample);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VocabSenseModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class FrequencyDataModelAdapter extends TypeAdapter<FrequencyDataModel> {
  @override
  final int typeId = 53;

  @override
  FrequencyDataModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FrequencyDataModel(
      totalAppearances: fields[0] as int,
      testedCount: fields[1] as int,
      activeTestedCount: fields[2] as int,
      yearSpread: fields[3] as int,
      years: (fields[4] as List).cast<int>(),
      byRole: (fields[5] as Map).cast<String, int>(),
      bySection: (fields[6] as Map).cast<String, int>(),
      byExamType: (fields[7] as Map).cast<String, int>(),
      mlScore: fields[8] as double?,
      importanceScore: fields[9] as double,
    );
  }

  @override
  void write(BinaryWriter writer, FrequencyDataModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.totalAppearances)
      ..writeByte(1)
      ..write(obj.testedCount)
      ..writeByte(2)
      ..write(obj.activeTestedCount)
      ..writeByte(3)
      ..write(obj.yearSpread)
      ..writeByte(4)
      ..write(obj.years)
      ..writeByte(5)
      ..write(obj.byRole)
      ..writeByte(6)
      ..write(obj.bySection)
      ..writeByte(7)
      ..write(obj.byExamType)
      ..writeByte(8)
      ..write(obj.mlScore)
      ..writeByte(9)
      ..write(obj.importanceScore);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FrequencyDataModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ConfusionNoteModelAdapter extends TypeAdapter<ConfusionNoteModel> {
  @override
  final int typeId = 54;

  @override
  ConfusionNoteModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ConfusionNoteModel(
      confusedWith: fields[0] as String,
      distinction: fields[1] as String,
      memoryTip: fields[2] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ConfusionNoteModel obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.confusedWith)
      ..writeByte(1)
      ..write(obj.distinction)
      ..writeByte(2)
      ..write(obj.memoryTip);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConfusionNoteModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RootElementModelAdapter extends TypeAdapter<RootElementModel> {
  @override
  final int typeId = 57;

  @override
  RootElementModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RootElementModel(
      element: fields[0] as String,
      zhMeaning: fields[1] as String,
      enMeaning: fields[2] as String,
      language: fields[3] as String,
      familyExamples: (fields[4] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, RootElementModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.element)
      ..writeByte(1)
      ..write(obj.zhMeaning)
      ..writeByte(2)
      ..write(obj.enMeaning)
      ..writeByte(3)
      ..write(obj.language)
      ..writeByte(4)
      ..write(obj.familyExamples);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RootElementModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RootAnalysisModelAdapter extends TypeAdapter<RootAnalysisModel> {
  @override
  final int typeId = 58;

  @override
  RootAnalysisModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RootAnalysisModel(
      prefixes: (fields[0] as List).cast<RootElementModel>(),
      roots: (fields[1] as List).cast<RootElementModel>(),
      suffixes: (fields[2] as List).cast<RootElementModel>(),
    );
  }

  @override
  void write(BinaryWriter writer, RootAnalysisModel obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.prefixes)
      ..writeByte(1)
      ..write(obj.roots)
      ..writeByte(2)
      ..write(obj.suffixes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RootAnalysisModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RootInfoModelAdapter extends TypeAdapter<RootInfoModel> {
  @override
  final int typeId = 55;

  @override
  RootInfoModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RootInfoModel(
      rootBreakdown: fields[0] as String,
      memoryStrategy: fields[1] as String,
      analysis: fields[2] as RootAnalysisModel?,
    );
  }

  @override
  void write(BinaryWriter writer, RootInfoModel obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.rootBreakdown)
      ..writeByte(1)
      ..write(obj.memoryStrategy)
      ..writeByte(2)
      ..write(obj.analysis);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RootInfoModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class VocabEntryModelAdapter extends TypeAdapter<VocabEntryModel> {
  @override
  final int typeId = 56;

  @override
  VocabEntryModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return VocabEntryModel(
      lemma: fields[0] as String,
      type: fields[1] as String,
      pos: (fields[2] as List).cast<String>(),
      level: fields[3] as int?,
      inOfficialList: fields[4] as bool,
      frequency: fields[5] as FrequencyDataModel?,
      senses: (fields[6] as List).cast<VocabSenseModel>(),
      rootInfo: fields[7] as RootInfoModel?,
      confusionNotes: (fields[8] as List).cast<ConfusionNoteModel>(),
      synonyms: (fields[9] as List).cast<String>(),
      antonyms: (fields[10] as List).cast<String>(),
      derivedForms: (fields[11] as List).cast<String>(),
      lastUpdated: fields[12] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, VocabEntryModel obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.lemma)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.pos)
      ..writeByte(3)
      ..write(obj.level)
      ..writeByte(4)
      ..write(obj.inOfficialList)
      ..writeByte(5)
      ..write(obj.frequency)
      ..writeByte(6)
      ..write(obj.senses)
      ..writeByte(7)
      ..write(obj.rootInfo)
      ..writeByte(8)
      ..write(obj.confusionNotes)
      ..writeByte(9)
      ..write(obj.synonyms)
      ..writeByte(10)
      ..write(obj.antonyms)
      ..writeByte(11)
      ..write(obj.derivedForms)
      ..writeByte(12)
      ..write(obj.lastUpdated);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VocabEntryModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class VocabIndexItemModelAdapter extends TypeAdapter<VocabIndexItemModel> {
  @override
  final int typeId = 57;

  @override
  VocabIndexItemModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return VocabIndexItemModel(
      lemma: fields[0] as String,
      type: fields[1] as String,
      pos: (fields[2] as List).cast<String>(),
      level: fields[3] as int?,
      inOfficialList: fields[4] as bool,
      importanceScore: fields[5] as double,
      zhPreview: fields[6] as String,
      senseCount: fields[7] as int,
      hasRootInfo: fields[8] as bool,
      hasConfusionNotes: fields[9] as bool,
      hasSynonyms: fields[10] as bool,
      testedCount: fields[11] as int,
      yearSpread: fields[12] as int,
    );
  }

  @override
  void write(BinaryWriter writer, VocabIndexItemModel obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.lemma)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.pos)
      ..writeByte(3)
      ..write(obj.level)
      ..writeByte(4)
      ..write(obj.inOfficialList)
      ..writeByte(5)
      ..write(obj.importanceScore)
      ..writeByte(6)
      ..write(obj.zhPreview)
      ..writeByte(7)
      ..write(obj.senseCount)
      ..writeByte(8)
      ..write(obj.hasRootInfo)
      ..writeByte(9)
      ..write(obj.hasConfusionNotes)
      ..writeByte(10)
      ..write(obj.hasSynonyms)
      ..writeByte(11)
      ..write(obj.testedCount)
      ..writeByte(12)
      ..write(obj.yearSpread);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VocabIndexItemModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PatternSubtypeModelAdapter extends TypeAdapter<PatternSubtypeModel> {
  @override
  final int typeId = 58;

  @override
  PatternSubtypeModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PatternSubtypeModel(
      subtype: fields[0] as String,
      displayName: fields[1] as String,
      structure: fields[2] as String,
      examples: (fields[3] as List).cast<ExamExampleModel>(),
      generatedExample: fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, PatternSubtypeModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.subtype)
      ..writeByte(1)
      ..write(obj.displayName)
      ..writeByte(2)
      ..write(obj.structure)
      ..writeByte(3)
      ..write(obj.examples)
      ..writeByte(4)
      ..write(obj.generatedExample);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PatternSubtypeModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PatternEntryModelAdapter extends TypeAdapter<PatternEntryModel> {
  @override
  final int typeId = 59;

  @override
  PatternEntryModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PatternEntryModel(
      lemma: fields[0] as String,
      patternCategory: fields[1] as String,
      subtypes: (fields[2] as List).cast<PatternSubtypeModel>(),
      teachingExplanation: fields[3] as String,
      lastUpdated: fields[4] as DateTime?,
      beginnerSummary: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, PatternEntryModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.lemma)
      ..writeByte(1)
      ..write(obj.patternCategory)
      ..writeByte(2)
      ..write(obj.subtypes)
      ..writeByte(3)
      ..write(obj.teachingExplanation)
      ..writeByte(4)
      ..write(obj.lastUpdated)
      ..writeByte(5)
      ..write(obj.beginnerSummary);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PatternEntryModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PhraseEntryModelAdapter extends TypeAdapter<PhraseEntryModel> {
  @override
  final int typeId = 61;

  @override
  PhraseEntryModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PhraseEntryModel(
      lemma: fields[0] as String,
      frequency: fields[1] as FrequencyDataModel?,
      senses: (fields[2] as List).cast<VocabSenseModel>(),
      lastUpdated: fields[3] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, PhraseEntryModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.lemma)
      ..writeByte(1)
      ..write(obj.frequency)
      ..writeByte(2)
      ..write(obj.senses)
      ..writeByte(3)
      ..write(obj.lastUpdated);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PhraseEntryModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CollocationModelAdapter extends TypeAdapter<CollocationModel> {
  @override
  final int typeId = 63;

  @override
  CollocationModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CollocationModel(
      english: fields[0] as String,
      chinese: fields[1] as String,
    );
  }

  @override
  void write(BinaryWriter writer, CollocationModel obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.english)
      ..writeByte(1)
      ..write(obj.chinese);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CollocationModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class WordEntryModelAdapter extends TypeAdapter<WordEntryModel> {
  @override
  final int typeId = 62;

  @override
  WordEntryModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WordEntryModel(
      lemma: fields[0] as String,
      pos: (fields[1] as List).cast<String>(),
      level: fields[2] as int?,
      inOfficialList: fields[3] as bool,
      frequency: fields[4] as FrequencyDataModel?,
      senses: (fields[5] as List).cast<VocabSenseModel>(),
      rootInfo: fields[6] as RootInfoModel?,
      confusionNotes: (fields[7] as List).cast<ConfusionNoteModel>(),
      synonyms: (fields[8] as List).cast<String>(),
      antonyms: (fields[9] as List).cast<String>(),
      derivedForms: (fields[10] as List).cast<String>(),
      lastUpdated: fields[11] as DateTime?,
      collocations: (fields[12] as List).cast<CollocationModel>(),
      usageNotes: fields[13] as String?,
      grammarNotes: fields[14] as String?,
      commonMistakes: fields[15] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, WordEntryModel obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.lemma)
      ..writeByte(1)
      ..write(obj.pos)
      ..writeByte(2)
      ..write(obj.level)
      ..writeByte(3)
      ..write(obj.inOfficialList)
      ..writeByte(4)
      ..write(obj.frequency)
      ..writeByte(5)
      ..write(obj.senses)
      ..writeByte(6)
      ..write(obj.rootInfo)
      ..writeByte(7)
      ..write(obj.confusionNotes)
      ..writeByte(8)
      ..write(obj.synonyms)
      ..writeByte(9)
      ..write(obj.antonyms)
      ..writeByte(10)
      ..write(obj.derivedForms)
      ..writeByte(11)
      ..write(obj.lastUpdated)
      ..writeByte(12)
      ..write(obj.collocations)
      ..writeByte(13)
      ..write(obj.usageNotes)
      ..writeByte(14)
      ..write(obj.grammarNotes)
      ..writeByte(15)
      ..write(obj.commonMistakes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WordEntryModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
