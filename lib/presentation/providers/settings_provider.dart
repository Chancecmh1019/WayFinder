import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/user_settings.dart';
import '../../data/datasources/local/user_local_datasource.dart';
import '../../data/models/user_model.dart';
import '../../data/models/user_settings_model.dart';

/// Settings state
class SettingsState {
  final UserSettings settings;
  final bool isLoading;
  final bool isInitialized; // 新增：是否已初始化
  final String? errorMessage;

  const SettingsState({
    required this.settings,
    this.isLoading = false,
    this.isInitialized = false,
    this.errorMessage,
  });

  SettingsState copyWith({
    UserSettings? settings,
    bool? isLoading,
    bool? isInitialized,
    String? errorMessage,
  }) {
    return SettingsState(
      settings: settings ?? this.settings,
      isLoading: isLoading ?? this.isLoading,
      isInitialized: isInitialized ?? this.isInitialized,
      errorMessage: errorMessage,
    );
  }
}

/// Settings notifier
class SettingsNotifier extends StateNotifier<SettingsState> {
  final UserLocalDataSource _localDataSource;

  SettingsNotifier()
      : _localDataSource = UserLocalDataSource(),
        super(SettingsState(settings: UserSettings.defaultSettings())) {
      // debug: print('📱 SettingsNotifier: Initializing...');
    _loadSettings();
  }

  Future<void> _loadSettings() async {
      // debug: print('📱 SettingsNotifier: Loading settings...');
    try {
      final userModel = await _localDataSource.getUser();
      if (userModel != null) {
        final settings = userModel.settings.toEntity();
      // debug: print('📱 Settings loaded: hasCompletedOnboarding=${settings.hasCompletedOnboarding}, dailyGoal=${settings.dailyGoal}');
        state = state.copyWith(settings: settings, isInitialized: true);
      } else {
        // 如果沒有本地使用者資料，使用預設設定
      // debug: print('📱 No user found, using default settings');
        state = state.copyWith(settings: UserSettings.defaultSettings(), isInitialized: true);
      }
    } catch (e) {
      // 載入失敗時使用預設設定
      // debug: print('📱 Failed to load settings: $e');
      state = state.copyWith(
        settings: UserSettings.defaultSettings(),
        isInitialized: true,
        errorMessage: '載入設定失敗，使用預設設定',
      );
    }
  }

  Future<void> _saveSettings(UserSettings newSettings) async {
    try {
      var userModel = await _localDataSource.getUser();
      if (userModel == null) {
        // 首次使用，建立本地使用者
        userModel = UserModel(
          id: 'local_user',
          email: 'local@wayfinder.app',
          displayName: '本地用戶',
          createdAt: DateTime.now(),
          settings: UserSettingsModel.fromEntity(newSettings),
        );
      } else {
        userModel = userModel.copyWith(
          settings: UserSettingsModel.fromEntity(newSettings),
        );
      }
      await _localDataSource.saveUser(userModel);
    } catch (e) {
      throw Exception('Failed to save settings: $e');
    }
  }

  Future<void> updateDailyGoal(int goal) async {
    if (goal < 5 || goal > 100) return;

    try {
      state = state.copyWith(isLoading: true);
      final newSettings = state.settings.copyWith(dailyGoal: goal);
      await _saveSettings(newSettings);
      state = state.copyWith(settings: newSettings, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: '更新每日目標失敗',
      );
    }
  }

  Future<void> updatePronunciationType(PronunciationType type) async {
    try {
      state = state.copyWith(isLoading: true);
      final newSettings = state.settings.copyWith(preferredPronunciation: type);
      await _saveSettings(newSettings);
      state = state.copyWith(settings: newSettings, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: '更新發音偏好失敗',
      );
    }
  }

  Future<void> updateAutoPlayAudio(bool enabled) async {
    try {
      state = state.copyWith(isLoading: true);
      final newSettings = state.settings.copyWith(autoPlayAudio: enabled);
      await _saveSettings(newSettings);
      state = state.copyWith(settings: newSettings, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: '更新自動播放設定失敗',
      );
    }
  }

  Future<void> updateTtsEngine(TtsEngineType engine) async {
    try {
      state = state.copyWith(isLoading: true);
      final newSettings = state.settings.copyWith(ttsEngine: engine);
      await _saveSettings(newSettings);
      state = state.copyWith(settings: newSettings, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: '更新 TTS 引擎設定失敗',
      );
    }
  }

  Future<void> updateOnboardingCompleted(bool completed) async {
    try {
      debugPrint('📱 Updating onboarding completed: $completed');
      state = state.copyWith(isLoading: true);
      final newSettings = state.settings.copyWith(hasCompletedOnboarding: completed);
      await _saveSettings(newSettings);
      state = state.copyWith(settings: newSettings, isLoading: false);
      debugPrint('📱 Onboarding completed updated successfully: ${state.settings.hasCompletedOnboarding}');
    } catch (e) {
      debugPrint('📱 Failed to update onboarding completed: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: '更新引導完成狀態失敗',
      );
      rethrow; // 重新拋出錯誤以便 onboarding screen 可以捕獲
    }
  }
  Future<void> updateLearningStyle(LearningStyle style) async {
    try {
      state = state.copyWith(isLoading: true);
      final newSettings = state.settings.copyWith(learningStyle: style);
      await _saveSettings(newSettings);
      state = state.copyWith(settings: newSettings, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: '更新學習風格失敗');
    }
  }

  Future<void> updateTargetLevel(int level) async {
    if (level < 1 || level > 6) return;
    try {
      state = state.copyWith(isLoading: true);
      final newSettings = state.settings.copyWith(targetLevel: level);
      await _saveSettings(newSettings);
      state = state.copyWith(settings: newSettings, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: '更新目標級別失敗');
    }
  }

  Future<void> updateIncludePhrases(bool include) async {
    try {
      state = state.copyWith(isLoading: true);
      final newSettings = state.settings.copyWith(includePhrasesInStudy: include);
      await _saveSettings(newSettings);
      state = state.copyWith(settings: newSettings, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: '更新片語設定失敗');
    }
  }

}

/// Provider for settings
final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});

/// Provider for daily goal
final dailyGoalProvider = Provider<int>((ref) {
  return ref.watch(settingsProvider.select((state) => state.settings.dailyGoal));
});

/// Provider for pronunciation type
final pronunciationTypeProvider = Provider<PronunciationType>((ref) {
  return ref.watch(settingsProvider.select((state) => state.settings.preferredPronunciation));
});

/// Provider for auto play audio
final autoPlayAudioProvider = Provider<bool>((ref) {
  return ref.watch(settingsProvider.select((state) => state.settings.autoPlayAudio));
});

/// Provider for TTS engine type
final ttsEngineTypeProvider = Provider<TtsEngineType>((ref) {
  return ref.watch(settingsProvider.select((state) => state.settings.ttsEngine));
});
