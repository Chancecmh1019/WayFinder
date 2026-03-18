// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'definition_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DefinitionModelAdapter extends TypeAdapter<DefinitionModel> {
  @override
  final int typeId = 3;

  @override
  DefinitionModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DefinitionModel(
      definition: fields[0] as String,
      partOfSpeech: fields[1] as String?,
      translation: fields[2] as String?,
      synonyms: (fields[3] as List?)?.cast<String>(),
      antonyms: (fields[4] as List?)?.cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, DefinitionModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.definition)
      ..writeByte(1)
      ..write(obj.partOfSpeech)
      ..writeByte(2)
      ..write(obj.translation)
      ..writeByte(3)
      ..write(obj.synonyms)
      ..writeByte(4)
      ..write(obj.antonyms);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DefinitionModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
