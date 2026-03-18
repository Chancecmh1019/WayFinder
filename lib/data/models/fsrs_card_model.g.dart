// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fsrs_card_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FSRSCardModelAdapter extends TypeAdapter<FSRSCardModel> {
  @override
  final int typeId = 40;

  @override
  FSRSCardModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FSRSCardModel(
      userId: fields[0] as String,
      lemma: fields[1] as String,
      senseId: fields[2] as String,
      state: fields[3] as int,
      scheduledDays: fields[4] as int,
      due: fields[5] as DateTime,
      stability: fields[6] as double,
      difficulty: fields[7] as double,
      reps: fields[8] as int,
      lapses: fields[9] as int,
      lastReview: fields[10] as DateTime?,
      isUnlocked: fields[11] as bool,
      createdAt: fields[12] as DateTime,
      updatedAt: fields[13] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, FSRSCardModel obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.userId)
      ..writeByte(1)
      ..write(obj.lemma)
      ..writeByte(2)
      ..write(obj.senseId)
      ..writeByte(3)
      ..write(obj.state)
      ..writeByte(4)
      ..write(obj.scheduledDays)
      ..writeByte(5)
      ..write(obj.due)
      ..writeByte(6)
      ..write(obj.stability)
      ..writeByte(7)
      ..write(obj.difficulty)
      ..writeByte(8)
      ..write(obj.reps)
      ..writeByte(9)
      ..write(obj.lapses)
      ..writeByte(10)
      ..write(obj.lastReview)
      ..writeByte(11)
      ..write(obj.isUnlocked)
      ..writeByte(12)
      ..write(obj.createdAt)
      ..writeByte(13)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FSRSCardModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
