// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'learning_session_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LearningSessionModelAdapter extends TypeAdapter<LearningSessionModel> {
  @override
  final int typeId = 20;

  @override
  LearningSessionModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LearningSessionModel(
      sessionId: fields[0] as String,
      startTime: fields[1] as DateTime,
      endTime: fields[2] as DateTime?,
      isActive: fields[3] as bool,
      dailyGoal: fields[4] as int,
      completedCount: fields[5] as int,
      totalCount: fields[6] as int,
      queue: (fields[7] as List).cast<LearningItemModel>(),
      currentItemIndex: fields[8] as int?,
      statistics: fields[9] as SessionStatisticsModel,
      currentItemTimeMs: fields[10] as int,
    );
  }

  @override
  void write(BinaryWriter writer, LearningSessionModel obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.sessionId)
      ..writeByte(1)
      ..write(obj.startTime)
      ..writeByte(2)
      ..write(obj.endTime)
      ..writeByte(3)
      ..write(obj.isActive)
      ..writeByte(4)
      ..write(obj.dailyGoal)
      ..writeByte(5)
      ..write(obj.completedCount)
      ..writeByte(6)
      ..write(obj.totalCount)
      ..writeByte(7)
      ..write(obj.queue)
      ..writeByte(8)
      ..write(obj.currentItemIndex)
      ..writeByte(9)
      ..write(obj.statistics)
      ..writeByte(10)
      ..write(obj.currentItemTimeMs);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LearningSessionModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class LearningItemModelAdapter extends TypeAdapter<LearningItemModel> {
  @override
  final int typeId = 21;

  @override
  LearningItemModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LearningItemModel(
      word: fields[0] as String,
      isNewWord: fields[1] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, LearningItemModel obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.word)
      ..writeByte(1)
      ..write(obj.isNewWord);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LearningItemModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SessionStatisticsModelAdapter
    extends TypeAdapter<SessionStatisticsModel> {
  @override
  final int typeId = 22;

  @override
  SessionStatisticsModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SessionStatisticsModel(
      totalReviews: fields[0] as int,
      correctReviews: fields[1] as int,
      newWordsCount: fields[2] as int,
      totalTimeMs: fields[3] as int,
      questionTypeDistribution: (fields[4] as Map).cast<String, int>(),
    );
  }

  @override
  void write(BinaryWriter writer, SessionStatisticsModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.totalReviews)
      ..writeByte(1)
      ..write(obj.correctReviews)
      ..writeByte(2)
      ..write(obj.newWordsCount)
      ..writeByte(3)
      ..write(obj.totalTimeMs)
      ..writeByte(4)
      ..write(obj.questionTypeDistribution);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SessionStatisticsModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
