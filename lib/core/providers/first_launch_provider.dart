import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wayfinder/data/services/first_launch_service.dart';

/// SharedPreferences Provider - initialized once at app startup
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  return await SharedPreferences.getInstance();
});

/// FirstLaunchService Provider - waits for SharedPreferences to be ready
final firstLaunchServiceProvider = FutureProvider<FirstLaunchService>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return FirstLaunchService(prefs);
});

/// 首次啟動狀態 Provider
final isFirstLaunchProvider = FutureProvider<bool>((ref) async {
  final service = await ref.watch(firstLaunchServiceProvider.future);
  return service.isFirstLaunch;
});

/// 歡迎畫面顯示狀態 Provider
final hasShownWelcomeProvider = FutureProvider<bool>((ref) async {
  final service = await ref.watch(firstLaunchServiceProvider.future);
  return service.hasShownWelcome;
});

/// 引導流程完成狀態 Provider
final hasCompletedOnboardingProvider = FutureProvider<bool>((ref) async {
  final service = await ref.watch(firstLaunchServiceProvider.future);
  return service.hasCompletedOnboarding;
});
