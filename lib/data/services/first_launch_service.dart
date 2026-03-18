import 'package:shared_preferences/shared_preferences.dart';

/// 首次啟動檢測服務
/// 
/// 用於檢測應用是否為首次啟動，並記錄啟動狀態
class FirstLaunchService {
  static const String _keyFirstLaunch = 'is_first_launch';
  static const String _keyWelcomeShown = 'welcome_shown';
  static const String _keyOnboardingCompleted = 'onboarding_completed';

  final SharedPreferences _prefs;

  FirstLaunchService(this._prefs);

  /// 檢查是否為首次啟動
  bool get isFirstLaunch {
    return _prefs.getBool(_keyFirstLaunch) ?? true;
  }

  /// 檢查是否已顯示歡迎畫面
  bool get hasShownWelcome {
    return _prefs.getBool(_keyWelcomeShown) ?? false;
  }

  /// 檢查是否已完成引導流程
  bool get hasCompletedOnboarding {
    return _prefs.getBool(_keyOnboardingCompleted) ?? false;
  }

  /// 標記歡迎畫面已顯示
  Future<void> markWelcomeShown() async {
    await _prefs.setBool(_keyWelcomeShown, true);
    await _prefs.setBool(_keyFirstLaunch, false);
  }

  /// 標記引導流程已完成
  Future<void> markOnboardingCompleted() async {
    await _prefs.setBool(_keyOnboardingCompleted, true);
  }

  /// 重置首次啟動狀態（用於測試）
  Future<void> reset() async {
    await _prefs.remove(_keyFirstLaunch);
    await _prefs.remove(_keyWelcomeShown);
    await _prefs.remove(_keyOnboardingCompleted);
  }
}
