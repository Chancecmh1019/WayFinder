// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'learning_progress_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LearningProgressModelAdapter extends TypeAdapter<LearningProgressModel> {
  @override
  final int typeId = 1;

  @override
  LearningProgressModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LearningProgressModel(
      userId: fields[0] as String,
      word: fields[1] as String,
      repetitions: fields[2] as int,
      interval: fields[3] as int,
      easeFactor: fields[4] as double,
      nextReviewDate: fields[5] as DateTime,
      lastReviewDate: fields[6] as DateTime,
      proficiencyLevel: fields[7] as int,
      history: (fields[8] as List).cast<ReviewHistoryModel>(),
      updatedAt: fields[9] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, LearningProgressModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.userId)
      ..writeByte(1)
      ..write(obj.word)
      ..writeByte(2)
      ..write(obj.repetitions)
      ..writeByte(3)
      ..write(obj.interval)
      ..writeByte(4)
      ..write(obj.easeFactor)
      ..writeByte(5)
      ..write(obj.nextReviewDate)
      ..writeByte(6)
      ..write(obj.lastReviewDate)
      ..writeByte(7)
      ..write(obj.proficiencyLevel)
      ..writeByte(8)
      ..write(obj.history)
      ..writeByte(9)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LearningProgressModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
