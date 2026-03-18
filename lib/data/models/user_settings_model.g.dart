// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_settings_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserSettingsModelAdapter extends TypeAdapter<UserSettingsModel> {
  @override
  final int typeId = 11;

  @override
  UserSettingsModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserSettingsModel(
      dailyGoal: fields[0] as int,
      preferredPronunciation: fields[4] as String,
      autoPlayAudio: fields[5] as bool,
      ttsEngine: fields[6] as String,
      hasCompletedOnboarding: fields[7] as bool,
      targetLevel: fields[8] as int,
      learningStyle: fields[9] as String,
      includePhrasesInStudy: fields[10] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, UserSettingsModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.dailyGoal)
      ..writeByte(4)
      ..write(obj.preferredPronunciation)
      ..writeByte(5)
      ..write(obj.autoPlayAudio)
      ..writeByte(6)
      ..write(obj.ttsEngine)
      ..writeByte(7)
      ..write(obj.hasCompletedOnboarding)
      ..writeByte(8)
      ..write(obj.targetLevel)
      ..writeByte(9)
      ..write(obj.learningStyle)
      ..writeByte(10)
      ..write(obj.includePhrasesInStudy);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserSettingsModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
