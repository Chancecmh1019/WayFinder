// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'word_folder_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WordFolderModelAdapter extends TypeAdapter<WordFolderModel> {
  @override
  final int typeId = 60;

  @override
  WordFolderModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WordFolderModel(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String?,
      wordLemmas: (fields[3] as List).cast<String>(),
      createdAt: fields[4] as DateTime,
      updatedAt: fields[5] as DateTime,
      color: fields[6] as String?,
      icon: fields[7] as String?,
      sortOrder: fields[8] as int,
      phraseLemmas: (fields[9] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, WordFolderModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.wordLemmas)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.updatedAt)
      ..writeByte(6)
      ..write(obj.color)
      ..writeByte(7)
      ..write(obj.icon)
      ..writeByte(8)
      ..write(obj.sortOrder)
      ..writeByte(9)
      ..write(obj.phraseLemmas);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WordFolderModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
