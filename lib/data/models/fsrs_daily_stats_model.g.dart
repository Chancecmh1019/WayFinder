// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fsrs_daily_stats_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FSRSDailyStatsModelAdapter extends TypeAdapter<FSRSDailyStatsModel> {
  @override
  final int typeId = 42;

  @override
  FSRSDailyStatsModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FSRSDailyStatsModel(
      userId: fields[0] as String,
      date: fields[1] as DateTime,
      newCards: fields[2] as int,
      learningCards: fields[3] as int,
      reviewCards: fields[4] as int,
      relearningCards: fields[5] as int,
      totalReviews: fields[6] as int,
      againCount: fields[7] as int,
      hardCount: fields[8] as int,
      goodCount: fields[9] as int,
      easyCount: fields[10] as int,
      studyTimeSeconds: fields[11] as int,
      uniqueWords: fields[12] as int,
      uniqueSenses: fields[13] as int,
      createdAt: fields[14] as DateTime,
      updatedAt: fields[15] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, FSRSDailyStatsModel obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.userId)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.newCards)
      ..writeByte(3)
      ..write(obj.learningCards)
      ..writeByte(4)
      ..write(obj.reviewCards)
      ..writeByte(5)
      ..write(obj.relearningCards)
      ..writeByte(6)
      ..write(obj.totalReviews)
      ..writeByte(7)
      ..write(obj.againCount)
      ..writeByte(8)
      ..write(obj.hardCount)
      ..writeByte(9)
      ..write(obj.goodCount)
      ..writeByte(10)
      ..write(obj.easyCount)
      ..writeByte(11)
      ..write(obj.studyTimeSeconds)
      ..writeByte(12)
      ..write(obj.uniqueWords)
      ..writeByte(13)
      ..write(obj.uniqueSenses)
      ..writeByte(14)
      ..write(obj.createdAt)
      ..writeByte(15)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FSRSDailyStatsModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
