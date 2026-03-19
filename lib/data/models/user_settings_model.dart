import 'package:hive/hive.dart';
import '../../domain/entities/user_settings.dart';

part 'user_settings_model.g.dart';

/// Data model for UserSettings with Hive serialization
@HiveType(typeId: 11)
class UserSettingsModel extends HiveObject {
  @HiveField(0)
  final int dailyGoal;

  @HiveField(4)
  final String preferredPronunciation; // 'us' or 'uk'

  @HiveField(5)
  final bool autoPlayAudio;

  @HiveField(6)
  final String ttsEngine; // 'flutterTts' or 'googleCloudTts'

  @HiveField(7)
  final bool hasCompletedOnboarding;

  @HiveField(8)
  final int targetLevel;

  @HiveField(9)
  final String learningStyle; // 'balanced', 'intensive', 'relaxed'

  @HiveField(10)
  final bool includePhrasesInStudy;

  @HiveField(11)
  final double speechRate;

  UserSettingsModel({
    required this.dailyGoal,
    required this.preferredPronunciation,
    required this.autoPlayAudio,
    required this.ttsEngine,
    this.hasCompletedOnboarding = false,
    required this.targetLevel,
    required this.learningStyle,
    required this.includePhrasesInStudy,
    this.speechRate = 0.45,
  });

  /// Convert to domain entity
  UserSettings toEntity() {
    return UserSettings(
      dailyGoal: dailyGoal,
      preferredPronunciation: preferredPronunciation == 'us'
          ? PronunciationType.us
          : PronunciationType.uk,
      autoPlayAudio: autoPlayAudio,
      ttsEngine: ttsEngine == 'edgeTts'
          ? TtsEngineType.edgeTts
          : TtsEngineType.flutterTts,
      hasCompletedOnboarding: hasCompletedOnboarding,
      targetLevel: targetLevel,
      learningStyle: LearningStyle.values.firstWhere(
        (s) => s.name == learningStyle,
        orElse: () => LearningStyle.balanced,
      ),
      includePhrasesInStudy: includePhrasesInStudy,
      speechRate: speechRate,
    );
  }

  /// Create from domain entity
  factory UserSettingsModel.fromEntity(UserSettings settings) {
    return UserSettingsModel(
      dailyGoal: settings.dailyGoal,
      preferredPronunciation:
          settings.preferredPronunciation == PronunciationType.us ? 'us' : 'uk',
      autoPlayAudio: settings.autoPlayAudio,
      ttsEngine: settings.ttsEngine == TtsEngineType.edgeTts
          ? 'edgeTts'
          : 'flutterTts',
      hasCompletedOnboarding: settings.hasCompletedOnboarding,
      targetLevel: settings.targetLevel,
      learningStyle: settings.learningStyle.name,
      includePhrasesInStudy: settings.includePhrasesInStudy,
      speechRate: settings.speechRate,
    );
  }

  /// Create from map (for Firestore)
  factory UserSettingsModel.fromMap(Map<String, dynamic> map) {
    return UserSettingsModel(
      dailyGoal: map['dailyGoal'] as int? ?? 30,
      preferredPronunciation: map['preferredPronunciation'] as String? ?? 'us',
      autoPlayAudio: map['autoPlayAudio'] as bool? ?? false,
      ttsEngine: map['ttsEngine'] as String? ?? 'flutterTts',
      hasCompletedOnboarding: map['hasCompletedOnboarding'] as bool? ?? false,
      targetLevel: map['targetLevel'] as int? ?? 4,
      learningStyle: map['learningStyle'] as String? ?? 'balanced',
      includePhrasesInStudy: map['includePhrasesInStudy'] as bool? ?? true,
      speechRate: (map['speechRate'] as num?)?.toDouble() ?? 0.45,
    );
  }

  /// Convert to map (for Firestore)
  Map<String, dynamic> toMap() {
    return {
      'dailyGoal': dailyGoal,
      'preferredPronunciation': preferredPronunciation,
      'autoPlayAudio': autoPlayAudio,
      'ttsEngine': ttsEngine,
      'hasCompletedOnboarding': hasCompletedOnboarding,
      'targetLevel': targetLevel,
      'learningStyle': learningStyle,
      'includePhrasesInStudy': includePhrasesInStudy,
      'speechRate': speechRate,
    };
  }

  /// Default settings
  factory UserSettingsModel.defaultSettings() {
    return UserSettingsModel(
      dailyGoal: 30,
      preferredPronunciation: 'us',
      autoPlayAudio: false,
      ttsEngine: 'flutterTts',
      hasCompletedOnboarding: false,
      targetLevel: 4,
      learningStyle: 'balanced',
      includePhrasesInStudy: true,
      speechRate: 0.45,
    );
  }
}