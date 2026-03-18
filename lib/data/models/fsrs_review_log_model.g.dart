// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fsrs_review_log_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FSRSReviewLogModelAdapter extends TypeAdapter<FSRSReviewLogModel> {
  @override
  final int typeId = 41;

  @override
  FSRSReviewLogModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FSRSReviewLogModel(
      userId: fields[0] as String,
      lemma: fields[1] as String,
      senseId: fields[2] as String,
      rating: fields[3] as int,
      stateBefore: fields[4] as int,
      stateAfter: fields[5] as int,
      scheduledDaysBefore: fields[6] as int,
      scheduledDaysAfter: fields[7] as int,
      stabilityBefore: fields[8] as double,
      stabilityAfter: fields[9] as double,
      difficultyBefore: fields[10] as double,
      difficultyAfter: fields[11] as double,
      elapsedDays: fields[12] as int,
      reviewedAt: fields[13] as DateTime,
      reviewTimeSeconds: fields[14] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, FSRSReviewLogModel obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.userId)
      ..writeByte(1)
      ..write(obj.lemma)
      ..writeByte(2)
      ..write(obj.senseId)
      ..writeByte(3)
      ..write(obj.rating)
      ..writeByte(4)
      ..write(obj.stateBefore)
      ..writeByte(5)
      ..write(obj.stateAfter)
      ..writeByte(6)
      ..write(obj.scheduledDaysBefore)
      ..writeByte(7)
      ..write(obj.scheduledDaysAfter)
      ..writeByte(8)
      ..write(obj.stabilityBefore)
      ..writeByte(9)
      ..write(obj.stabilityAfter)
      ..writeByte(10)
      ..write(obj.difficultyBefore)
      ..writeByte(11)
      ..write(obj.difficultyAfter)
      ..writeByte(12)
      ..write(obj.elapsedDays)
      ..writeByte(13)
      ..write(obj.reviewedAt)
      ..writeByte(14)
      ..write(obj.reviewTimeSeconds);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FSRSReviewLogModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
