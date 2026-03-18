/// 學習風格
enum LearningStyle {
  balanced,   // 平衡模式：新學+複習各半
  intensive,  // 強化模式：多新學，高強度
  relaxed;    // 輕鬆模式：重複習，穩固記憶

  String get displayName {
    switch (this) {
      case LearningStyle.balanced:
        return '平衡模式';
      case LearningStyle.intensive:
        return '強化模式';
      case LearningStyle.relaxed:
        return '輕鬆模式';
    }
  }

  String get description {
    switch (this) {
      case LearningStyle.balanced:
        return '新學與複習平衡，適合多數人';
      case LearningStyle.intensive:
        return '大量新學，快速擴充字彙量';
      case LearningStyle.relaxed:
        return '重點複習已學，穩固記憶';
    }
  }

  String get icon {
    switch (this) {
      case LearningStyle.balanced:
        return '●';
      case LearningStyle.intensive:
        return '▲';
      case LearningStyle.relaxed:
        return '○';
    }
  }

  int suggestedDailyGoal() {
    switch (this) {
      case LearningStyle.balanced:
        return 30;
      case LearningStyle.intensive:
        return 50;
      case LearningStyle.relaxed:
        return 15;
    }
  }
}

/// 使用者設定
class UserSettings {
  // 學習設定
  final int targetLevel; // 目標級別 1-6 (CEFR A1-C2)
  final List<String> focusAreas; // 重點加強題型
  final LearningStyle learningStyle; // 學習風格
  final bool includePhrasesInStudy; // 是否網記片語

  // 每日目標
  final int dailyGoal; // 每日新字目標 (5-100)

  // 發音與音訊設定
  final PronunciationType preferredPronunciation; // 偏好發音
  final bool autoPlayAudio; // 自動播放音訊
  final TtsEngineType ttsEngine; // TTS 引擎偏好

  // 系統狀態
  final bool hasCompletedOnboarding; // 是否完成初始設定

  const UserSettings({
    this.targetLevel = 4,
    this.focusAreas = const [],
    this.learningStyle = LearningStyle.balanced,
    this.includePhrasesInStudy = true,
    required this.dailyGoal,
    required this.preferredPronunciation,
    required this.autoPlayAudio,
    required this.ttsEngine,
    this.hasCompletedOnboarding = false,
  });

  /// 預設設定
  factory UserSettings.defaultSettings() {
    return const UserSettings(
      targetLevel: 4,
      focusAreas: [],
      learningStyle: LearningStyle.balanced,
      includePhrasesInStudy: true,
      dailyGoal: 30,
      preferredPronunciation: PronunciationType.us,
      autoPlayAudio: false,
      ttsEngine: TtsEngineType.flutterTts,
      hasCompletedOnboarding: false,
    );
  }

  UserSettings copyWith({
    int? targetLevel,
    List<String>? focusAreas,
    LearningStyle? learningStyle,
    bool? includePhrasesInStudy,
    int? dailyGoal,
    PronunciationType? preferredPronunciation,
    bool? autoPlayAudio,
    TtsEngineType? ttsEngine,
    bool? hasCompletedOnboarding,
  }) {
    return UserSettings(
      targetLevel: targetLevel ?? this.targetLevel,
      focusAreas: focusAreas ?? this.focusAreas,
      learningStyle: learningStyle ?? this.learningStyle,
      includePhrasesInStudy: includePhrasesInStudy ?? this.includePhrasesInStudy,
      dailyGoal: dailyGoal ?? this.dailyGoal,
      preferredPronunciation: preferredPronunciation ?? this.preferredPronunciation,
      autoPlayAudio: autoPlayAudio ?? this.autoPlayAudio,
      ttsEngine: ttsEngine ?? this.ttsEngine,
      hasCompletedOnboarding: hasCompletedOnboarding ?? this.hasCompletedOnboarding,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserSettings &&
          runtimeType == other.runtimeType &&
          targetLevel == other.targetLevel &&
          focusAreas == other.focusAreas &&
          learningStyle == other.learningStyle &&
          includePhrasesInStudy == other.includePhrasesInStudy &&
          dailyGoal == other.dailyGoal &&
          preferredPronunciation == other.preferredPronunciation &&
          autoPlayAudio == other.autoPlayAudio &&
          ttsEngine == other.ttsEngine &&
          hasCompletedOnboarding == other.hasCompletedOnboarding;

  @override
  int get hashCode => Object.hash(
        targetLevel,
        focusAreas,
        learningStyle,
        includePhrasesInStudy,
        dailyGoal,
        preferredPronunciation,
        autoPlayAudio,
        ttsEngine,
        hasCompletedOnboarding,
      );
}

/// 發音類型偏好
enum PronunciationType {
  us, // 美式英語
  uk; // 英式英語

  String get displayName {
    switch (this) {
      case PronunciationType.us:
        return '美式發音';
      case PronunciationType.uk:
        return '英式發音';
    }
  }

  String get countryFlag {
    switch (this) {
      case PronunciationType.us:
        return 'US';
      case PronunciationType.uk:
        return 'UK';
    }
  }

  String get edgeTtsVoice {
    switch (this) {
      case PronunciationType.us:
        return 'en-US-GuyNeural'; // 美國男聲
      case PronunciationType.uk:
        return 'en-GB-RyanNeural'; // 英國男聲
    }
  }
}

/// TTS 引擎類型偏好
enum TtsEngineType {
  flutterTts, // 離線 TTS 使用 flutter_tts
  edgeTts; // 線上 TTS 使用 Microsoft Edge TTS

  String get displayName {
    switch (this) {
      case TtsEngineType.flutterTts:
        return 'Flutter TTS（離線）';
      case TtsEngineType.edgeTts:
        return 'Edge TTS（線上）';
    }
  }

  String get description {
    switch (this) {
      case TtsEngineType.flutterTts:
        return '使用系統內建語音引擎，完全離線運作';
      case TtsEngineType.edgeTts:
        return '使用 Microsoft Edge 語音，音質優異且支援多國口音';
    }
  }
}
