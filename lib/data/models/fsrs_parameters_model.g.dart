// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fsrs_parameters_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FSRSParametersModelAdapter extends TypeAdapter<FSRSParametersModel> {
  @override
  final int typeId = 43;

  @override
  FSRSParametersModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FSRSParametersModel(
      userId: fields[0] as String,
      weights: (fields[1] as List).cast<double>(),
      requestRetention: fields[2] as double,
      maximumInterval: fields[3] as int,
      againMinutes: fields[4] as int,
      hardMinutes: fields[5] as int,
      goodMinutes: fields[6] as int,
      updatedAt: fields[7] as DateTime,
      isOptimized: fields[8] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, FSRSParametersModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.userId)
      ..writeByte(1)
      ..write(obj.weights)
      ..writeByte(2)
      ..write(obj.requestRetention)
      ..writeByte(3)
      ..write(obj.maximumInterval)
      ..writeByte(4)
      ..write(obj.againMinutes)
      ..writeByte(5)
      ..write(obj.hardMinutes)
      ..writeByte(6)
      ..write(obj.goodMinutes)
      ..writeByte(7)
      ..write(obj.updatedAt)
      ..writeByte(8)
      ..write(obj.isOptimized);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FSRSParametersModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
