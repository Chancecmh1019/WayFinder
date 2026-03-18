import 'package:flutter/material.dart';
import 'package:wayfinder/presentation/theme/app_theme.dart';

/// 歡迎動畫畫面
/// 
/// 首次啟動時顯示的歡迎動畫，展示 WayFinder 品牌
/// 設計風格：高冷、文青、簡約、黑白灰
class WelcomeScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const WelcomeScreen({
    super.key,
    required this.onComplete,
  });

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // 初始化動畫控制器（3 秒總時長）
    _controller = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    // 淡入動畫（200-300ms ease-in-out）
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(
          0.0,
          0.3,
          curve: Curves.easeInOut,
        ),
      ),
    );

    // 滑動動畫（iOS 風格過渡）
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(
          0.0,
          0.4,
          curve: Curves.easeOut,
        ),
      ),
    );

    // 啟動動畫
    _controller.forward();

    // 動畫完成後自動跳轉
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            widget.onComplete();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _skip() {
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.pureBlack : AppTheme.offWhite,
      body: GestureDetector(
        onTap: _skip,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            // 主要內容
            Center(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // 主標題 - 使用 displayLarge（40px, bold, -1.0 字距）
                          Text(
                            'WayFinder',
                            style: theme.textTheme.displayLarge,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppTheme.space16),
                          // 副標題
                          Text(
                            '行路',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: isDark
                                  ? AppTheme.gray300
                                  : AppTheme.gray700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppTheme.space48),
                          // 標語
                          Text(
                            '科學化單字學習',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: isDark
                                  ? AppTheme.gray400
                                  : AppTheme.gray600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            // 跳過按鈕（極簡按鈕）
            Positioned(
              top: MediaQuery.of(context).padding.top + AppTheme.space16,
              right: AppTheme.space20,
              child: AnimatedBuilder(
                animation: _fadeAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeAnimation.value,
                    child: TextButton(
                      onPressed: _skip,
                      style: TextButton.styleFrom(
                        foregroundColor: isDark
                            ? AppTheme.gray400
                            : AppTheme.gray600,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.space16,
                          vertical: AppTheme.space8,
                        ),
                      ),
                      child: Text(
                        '跳過',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
