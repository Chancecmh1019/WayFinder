// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vocabulary_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class VocabularyModelAdapter extends TypeAdapter<VocabularyModel> {
  @override
  final int typeId = 0;

  @override
  VocabularyModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return VocabularyModel(
      word: fields[0] as String,
      phonetic: fields[1] as String,
      definitions: (fields[2] as List).cast<DefinitionModel>(),
      examples: (fields[3] as List).cast<ExampleModel>(),
      partsOfSpeech: (fields[4] as List).cast<String>(),
      audioUrl: fields[5] as String?,
      cefrLevel: fields[6] as String,
      frequency: fields[7] as int,
      originalData: (fields[8] as Map).cast<String, dynamic>(),
      inOfficialList: fields[9] as bool,
      totalAppearances: fields[10] as int,
      testedCount: fields[11] as int,
      yearSpread: fields[12] as int,
      examYears: (fields[13] as List).cast<int>(),
      byRole: (fields[14] as Map).cast<String, int>(),
      bySection: (fields[15] as Map).cast<String, int>(),
      byExamType: (fields[16] as Map).cast<String, int>(),
      rootBreakdown: fields[17] as String?,
      memoryStrategy: fields[18] as String?,
      synonyms: (fields[19] as List).cast<String>(),
      derivedForms: (fields[20] as List).cast<String>(),
      itemType: fields[21] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, VocabularyModel obj) {
    writer
      ..writeByte(22)
      ..writeByte(0)
      ..write(obj.word)
      ..writeByte(1)
      ..write(obj.phonetic)
      ..writeByte(2)
      ..write(obj.definitions)
      ..writeByte(3)
      ..write(obj.examples)
      ..writeByte(4)
      ..write(obj.partsOfSpeech)
      ..writeByte(5)
      ..write(obj.audioUrl)
      ..writeByte(6)
      ..write(obj.cefrLevel)
      ..writeByte(7)
      ..write(obj.frequency)
      ..writeByte(8)
      ..write(obj.originalData)
      ..writeByte(9)
      ..write(obj.inOfficialList)
      ..writeByte(10)
      ..write(obj.totalAppearances)
      ..writeByte(11)
      ..write(obj.testedCount)
      ..writeByte(12)
      ..write(obj.yearSpread)
      ..writeByte(13)
      ..write(obj.examYears)
      ..writeByte(14)
      ..write(obj.byRole)
      ..writeByte(15)
      ..write(obj.bySection)
      ..writeByte(16)
      ..write(obj.byExamType)
      ..writeByte(17)
      ..write(obj.rootBreakdown)
      ..writeByte(18)
      ..write(obj.memoryStrategy)
      ..writeByte(19)
      ..write(obj.synonyms)
      ..writeByte(20)
      ..write(obj.derivedForms)
      ..writeByte(21)
      ..write(obj.itemType);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VocabularyModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
