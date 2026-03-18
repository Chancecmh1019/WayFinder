// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review_history_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ReviewHistoryModelAdapter extends TypeAdapter<ReviewHistoryModel> {
  @override
  final int typeId = 2;

  @override
  ReviewHistoryModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ReviewHistoryModel(
      reviewDate: fields[0] as DateTime,
      quality: fields[1] as int,
      timeSpentSeconds: fields[2] as int,
      questionType: fields[3] as String,
      correct: fields[4] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, ReviewHistoryModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.reviewDate)
      ..writeByte(1)
      ..write(obj.quality)
      ..writeByte(2)
      ..write(obj.timeSpentSeconds)
      ..writeByte(3)
      ..write(obj.questionType)
      ..writeByte(4)
      ..write(obj.correct);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReviewHistoryModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
