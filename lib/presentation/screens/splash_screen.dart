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

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>  _fade;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _navigate(bool onboarded) {
    if (_navigated || !mounted) return;
    _navigated = true;
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      pageBuilder: (_, __, ___) => onboarded ? const MainShell() : const OnboardingScreen(),
      transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
      transitionDuration: const Duration(milliseconds: 400),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.pureBlack : AppTheme.offWhite;
    final fg = isDark ? AppTheme.pureWhite : AppTheme.pureBlack;

    final initAsync = ref.watch(appInitProvider);
    final settings = ref.watch(settingsProvider);

    // 當 appInitProvider 和 settingsProvider 都完成時才導航
    if (initAsync.hasValue && settings.isInitialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigate(settings.settings.hasCompletedOnboarding);
      });
    }

    return Scaffold(
      backgroundColor: bg,
      body: FadeTransition(
        opacity: _fade,
        child: Stack(children: [
          // Logo 置中
          Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                width: 68, height: 68,
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.pureWhite : AppTheme.pureBlack,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Center(child: Text('W', style: TextStyle(
                  fontFamily: AppTheme.fontFamilyEnglish,
                  fontSize: 36, fontWeight: FontWeight.w700,
                  color: isDark ? AppTheme.pureBlack : AppTheme.pureWhite,
                  letterSpacing: -1,
                ))),
              ),
              const SizedBox(height: 20),
              Text('WayFinder', style: TextStyle(
                fontFamily: AppTheme.fontFamilyEnglish,
                fontSize: 18, fontWeight: AppTheme.weightSemiBold,
                color: fg, letterSpacing: -0.3,
              )),
              const SizedBox(height: 4),
              Text('科學化英文學習', style: TextStyle(fontSize: 12, color: AppTheme.gray500, letterSpacing: 0.5)),
            ]),
          ),
          // 底部載入指示
          Positioned(
            bottom: 48, left: 0, right: 0,
            child: initAsync.when(
              data: (_) => const SizedBox.shrink(),
              loading: () => Column(children: [
                SizedBox(width: 24, height: 24,
                    child: CircularProgressIndicator(strokeWidth: 1.5,
                        color: isDark ? AppTheme.gray600 : AppTheme.gray400)),
              ]),
              error: (e, _) => Column(children: [
                Icon(Icons.error_outline, color: AppTheme.gray500, size: 20),
                const SizedBox(height: 8),
                Text('初始化失敗', style: TextStyle(fontSize: 12, color: AppTheme.gray500)),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => ref.invalidate(appInitProvider),
                  child: Text('重試', style: TextStyle(fontSize: 13, color: fg)),
                ),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}
