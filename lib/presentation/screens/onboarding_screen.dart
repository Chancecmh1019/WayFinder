import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wayfinder/presentation/theme/app_theme.dart';
import '../providers/settings_provider.dart';
import 'main_shell.dart';

/// 引導流程畫面
/// 
/// 極簡卡片式設計，介紹學習原理並設定初始偏好
/// 設計風格：高冷、文青、簡約、黑白灰、iOS 風格
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  int _dailyGoal = 30;
  bool _isCompleting = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _complete();
    }
  }

  void _skip() {
    _complete();
  }

  Future<void> _complete() async {
    if (_isCompleting) {
      debugPrint('🔄 Already completing, skipping...');
      return;
    }
    
    debugPrint('🚀 Starting onboarding completion...');
    setState(() {
      _isCompleting = true;
    });
    
    try {
      // 更新設定
      final notifier = ref.read(settingsProvider.notifier);
      debugPrint('📝 Updating daily goal to $_dailyGoal');
      await notifier.updateDailyGoal(_dailyGoal);
      
      debugPrint('✅ Marking onboarding as completed');
      await notifier.updateOnboardingCompleted(true);
      
      // 短暫延遲確保設定已保存
      await Future.delayed(const Duration(milliseconds: 200));
      
      debugPrint('🎉 Onboarding completed, navigating to main shell');
      
      // 直接導航到主畫面，不使用 callback
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const MainShell(),
            transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
            transitionDuration: const Duration(milliseconds: 400),
          ),
        );
      } else {
        debugPrint('⚠️ Widget not mounted, cannot navigate');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error completing onboarding: $e');
      debugPrint('Stack trace: $stackTrace');
      
      if (mounted) {
        setState(() {
          _isCompleting = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('設定儲存失敗：$e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.pureBlack : AppTheme.offWhite,
      body: SafeArea(
        child: Column(
          children: [
            // 頂部導航
            Padding(
              padding: const EdgeInsets.all(AppTheme.space16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 頁面指示器
                  Row(
                    children: List.generate(2, (index) {
                      return Container(
                        margin: const EdgeInsets.only(right: AppTheme.space8),
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? (isDark ? AppTheme.pureWhite : AppTheme.pureBlack)
                              : (isDark ? AppTheme.gray700 : AppTheme.gray300),
                          borderRadius: BorderRadius.circular(AppTheme.radiusTiny),
                        ),
                      );
                    }),
                  ),
                  // 跳過按鈕
                  TextButton(
                    onPressed: _isCompleting ? null : _skip,
                    style: TextButton.styleFrom(
                      foregroundColor: isDark ? AppTheme.gray400 : AppTheme.gray600,
                    ),
                    child: Text(
                      '跳過',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),

            // 內容區域
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  _buildPrinciplePage(theme, isDark),
                  _buildGoalPage(theme, isDark),
                ],
              ),
            ),

            // 底部按鈕
            Padding(
              padding: const EdgeInsets.all(AppTheme.space24),
              child: ElevatedButton(
                onPressed: _isCompleting ? null : _nextPage,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: _isCompleting
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: isDark ? AppTheme.pureBlack : AppTheme.pureWhite,
                        ),
                      )
                    : Text(_currentPage == 1 ? '開始學習' : '下一步'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrinciplePage(ThemeData theme, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: AppTheme.space48),
          
          // Logo
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: isDark ? AppTheme.pureWhite : AppTheme.pureBlack,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            child: Center(
              child: Text(
                'W',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamilyEnglish,
                  fontSize: 38,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppTheme.pureBlack : AppTheme.pureWhite,
                  letterSpacing: -1,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.space32),
          
          // 標題
          Text(
            '科學化學習',
            style: theme.textTheme.displaySmall?.copyWith(
              fontSize: 28,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.space12),
          Text(
            'WayFinder 基於學習科學原理\n幫助你高效記憶單字',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark ? AppTheme.gray400 : AppTheme.gray600,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.space48),

          // 原理列表 - 更簡約的設計
          _buildSimplePrincipleItem(theme, isDark, '間隔重複', '根據記憶曲線安排複習'),
          _buildSimplePrincipleItem(theme, isDark, '主動回想', '通過測驗加深記憶'),
          _buildSimplePrincipleItem(theme, isDark, '交錯練習', '混合練習提高辨識'),
          _buildSimplePrincipleItem(theme, isDark, '適度困難', '保持適當的挑戰性'),
        ],
      ),
    );
  }

  Widget _buildSimplePrincipleItem(ThemeData theme, bool isDark, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.space20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 圓點
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 7),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.gray600 : AppTheme.gray400,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppTheme.space16),
          // 文字
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppTheme.space4),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark ? AppTheme.gray500 : AppTheme.gray600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildGoalPage(ThemeData theme, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: AppTheme.space64),
          
          // 標題
          Text(
            '設定每日目標',
            style: theme.textTheme.displaySmall?.copyWith(
              fontSize: 28,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.space12),
          Text(
            '選擇每天想學習的新單字數量',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark ? AppTheme.gray400 : AppTheme.gray600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.space64),

          // 數字顯示 - 極簡設計
          Text(
            '$_dailyGoal',
            style: TextStyle(
              fontFamily: AppTheme.fontFamilyEnglish,
              fontSize: 72,
              fontWeight: FontWeight.w300,
              color: isDark ? AppTheme.pureWhite : AppTheme.pureBlack,
              letterSpacing: -2,
              height: 1,
            ),
          ),
          const SizedBox(height: AppTheme.space8),
          Text(
            '個新單字 / 天',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark ? AppTheme.gray500 : AppTheme.gray600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: AppTheme.space56),
          
          // 滑桿
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: isDark ? AppTheme.pureWhite : AppTheme.pureBlack,
              inactiveTrackColor: isDark ? AppTheme.gray800 : AppTheme.gray200,
              thumbColor: isDark ? AppTheme.pureWhite : AppTheme.pureBlack,
              overlayColor: (isDark ? AppTheme.pureWhite : AppTheme.pureBlack)
                  .withValues(alpha: 0.1),
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            ),
            child: Slider(
              value: _dailyGoal.toDouble(),
              min: 5,
              max: 100,
              divisions: 19,
              onChanged: (value) {
                setState(() {
                  _dailyGoal = value.toInt();
                });
              },
            ),
          ),
          const SizedBox(height: AppTheme.space8),
          
          // 範圍提示
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.space8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '5',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark ? AppTheme.gray600 : AppTheme.gray500,
                  ),
                ),
                Text(
                  '100',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark ? AppTheme.gray600 : AppTheme.gray500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.space48),

          // 建議文字
          Text(
            '建議從 10-20 個開始\n之後可以在設定中調整',
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark ? AppTheme.gray500 : AppTheme.gray600,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
