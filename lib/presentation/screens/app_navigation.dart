import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wayfinder/core/providers/first_launch_provider.dart';
import 'package:wayfinder/core/providers/vocab_providers.dart';
import 'package:wayfinder/data/services/first_launch_service.dart';
import 'package:wayfinder/presentation/screens/onboarding_screen.dart';
import 'package:wayfinder/presentation/screens/welcome_screen.dart';
import 'package:wayfinder/presentation/screens/main_shell.dart';
import 'package:wayfinder/presentation/providers/settings_provider.dart';

/// 應用導航控制器
/// 
/// 根據應用狀態決定顯示哪個畫面：
/// 1. 首次啟動 → WelcomeScreen
/// 2. 未完成引導 → OnboardingScreen
/// 3. 已完成引導 → MainShell
class AppNavigation extends ConsumerWidget {
  const AppNavigation({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 初始化詞彙系統
    ref.watch(vocabInitializationProvider);
    
    // 等待 SharedPreferences 初始化
    final prefsAsync = ref.watch(sharedPreferencesProvider);

    return prefsAsync.when(
      data: (prefs) {
        final firstLaunchService = FirstLaunchService(prefs);

        // 檢查是否首次啟動
        if (!firstLaunchService.hasShownWelcome) {
          return WelcomeScreen(
            onComplete: () async {
              await firstLaunchService.markWelcomeShown();
              // 強制重建以顯示下一個畫面
              ref.invalidate(sharedPreferencesProvider);
            },
          );
        }

        // 檢查是否完成引導（從用戶設定中讀取）
        final settings = ref.watch(settingsProvider);
        if (!settings.settings.hasCompletedOnboarding) {
          return const OnboardingScreen();
        }

        // 已完成引導，顯示主畫面
        return const MainShell();
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  '初始化錯誤',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    ref.invalidate(sharedPreferencesProvider);
                  },
                  child: const Text('重試'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
