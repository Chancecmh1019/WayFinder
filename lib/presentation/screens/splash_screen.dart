import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../providers/settings_provider.dart';
import 'main_shell.dart';
import 'onboarding_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _navigated = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final initAsync = ref.watch(appInitProvider);

    return initAsync.when(
      data: (_) {
        final settingsState = ref.watch(settingsProvider);
        if (!settingsState.isInitialized) return _buildSplash(context, isDark, true);
        if (!_navigated) {
          _navigated = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            final done = settingsState.settings.hasCompletedOnboarding;
            
            if (done) {
              // 已完成引導，直接進入主畫面
              Navigator.of(context).pushReplacement(
                PageRouteBuilder(
                  pageBuilder: (_, __, ___) => const MainShell(),
                  transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
                  transitionDuration: const Duration(milliseconds: 400),
                ),
              );
            } else {
              // 未完成引導，顯示引導畫面
              Navigator.of(context).pushReplacement(
                PageRouteBuilder(
                  pageBuilder: (_, __, ___) => const OnboardingScreen(),
                  transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
                  transitionDuration: const Duration(milliseconds: 400),
                ),
              );
            }
          });
        }
        return _buildSplash(context, isDark, false);
      },
      loading: () => _buildSplash(context, isDark, true),
      error: (e, _) => _buildError(context, isDark, e.toString()),
    );
  }

  Widget _buildSplash(BuildContext context, bool isDark, bool loading) {
    return Scaffold(
      backgroundColor: isDark ? AppTheme.pureBlack : AppTheme.offWhite,
      body: Stack(
        children: [
          // 主要內容 - 居中
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo 區域 - 極簡設計
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.pureWhite : AppTheme.pureBlack,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  ),
                  child: Center(
                    child: Text(
                      'W',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamilyEnglish,
                        fontSize: 42,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppTheme.pureBlack : AppTheme.pureWhite,
                        letterSpacing: -1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.space24),
                
                // 應用名稱
                Text(
                  'WayFinder',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamilyEnglish,
                    fontSize: 36,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -1.5,
                    color: isDark ? AppTheme.pureWhite : AppTheme.pureBlack,
                  ),
                ),
                const SizedBox(height: AppTheme.space8),
                
                // 副標題
                Text(
                  '學測英文字彙',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamilyChinese,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: AppTheme.gray500,
                    letterSpacing: 3,
                  ),
                ),
              ],
            ),
          ),
          
          // 載入指示器 - 底部
          if (loading)
            Positioned(
              left: 0,
              right: 0,
              bottom: 80,
              child: Column(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: isDark ? AppTheme.gray500 : AppTheme.gray600,
                    ),
                  ),
                  const SizedBox(height: AppTheme.space16),
                  Text(
                    '載入中',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: AppTheme.gray500,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, bool isDark, String msg) {
    return Scaffold(
      backgroundColor: isDark ? AppTheme.pureBlack : AppTheme.offWhite,
      body: Center(child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.error_outline, size: 48,
              color: isDark ? AppTheme.gray400 : AppTheme.gray600),
          const SizedBox(height: 16),
          Text('載入失敗', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 10),
          Text(msg, style: TextStyle(fontSize: 14, color: AppTheme.gray500), textAlign: TextAlign.center),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            onPressed: () => ref.invalidate(appInitProvider),
            icon: const Icon(Icons.refresh), label: const Text('重試'),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? AppTheme.pureWhite : AppTheme.pureBlack,
              foregroundColor: isDark ? AppTheme.pureBlack : AppTheme.pureWhite,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
          ),
        ]),
      )),
    );
  }
}
