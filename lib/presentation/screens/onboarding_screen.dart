import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../providers/settings_provider.dart';
import 'main_shell.dart';

/// 全新引導流程 — 極簡、iOS 風格、黑白灰
/// 頁面：1) 歡迎  2) 功能亮點  3) 每日目標設定
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _ctrl = PageController();
  int _page  = 0;
  int _goal  = 20;
  bool _busy = false;

  static const int _total = 3;

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _next() {
    if (_page < _total - 1) {
      HapticFeedback.lightImpact();
      _ctrl.nextPage(duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic);
    } else { _finish(); }
  }

  Future<void> _finish() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final n = ref.read(settingsProvider.notifier);
      await n.updateDailyGoal(_goal);
      await n.updateOnboardingCompleted(true);
      await Future.delayed(const Duration(milliseconds: 150));
      if (!mounted) return;
      Navigator.of(context).pushReplacement(PageRouteBuilder(
        pageBuilder: (_, __, ___) => const MainShell(),
        transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
        transitionDuration: const Duration(milliseconds: 400),
      ));
    } catch (e) {
      setState(() => _busy = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('錯誤：$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.pureBlack : AppTheme.offWhite;
    final fg = isDark ? AppTheme.pureWhite : AppTheme.pureBlack;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(children: [
          // ── 頂部指示器 & 跳過 ─────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 點狀指示器
                Row(children: List.generate(_total, (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.only(right: 6),
                  width: _page == i ? 20 : 6, height: 6,
                  decoration: BoxDecoration(
                    color: _page == i ? fg : (isDark ? AppTheme.gray700 : AppTheme.gray300),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ))),
                // 跳過
                if (_page < _total - 1)
                  GestureDetector(
                    onTap: _finish,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      child: Text('跳過', style: TextStyle(fontSize: 14, color: isDark ? AppTheme.gray500 : AppTheme.gray500)),
                    ),
                  )
                else const SizedBox(width: 40),
              ],
            ),
          ),

          // ── 頁面內容 ──────────────────────────────
          Expanded(
            child: PageView(
              controller: _ctrl,
              physics: const BouncingScrollPhysics(),
              onPageChanged: (i) => setState(() => _page = i),
              children: [
                _Page1(isDark: isDark, fg: fg, bg: bg),
                _Page2(isDark: isDark, fg: fg, bg: bg),
                _Page3(isDark: isDark, fg: fg, goal: _goal, onGoalChanged: (v) => setState(() => _goal = v)),
              ],
            ),
          ),

          // ── 下方按鈕 ─────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            child: SizedBox(
              width: double.infinity, height: 56,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _busy
                    ? const Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)))
                    : ElevatedButton(
                        key: ValueKey(_page),
                        onPressed: _next,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? AppTheme.pureWhite : AppTheme.pureBlack,
                          foregroundColor: isDark ? AppTheme.pureBlack : AppTheme.pureWhite,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
                          elevation: 0,
                        ),
                        child: Text(
                          _page == _total - 1 ? '開始學習' : '繼續',
                          style: const TextStyle(fontSize: 16, fontWeight: AppTheme.weightSemiBold, letterSpacing: 0.3),
                        ),
                      ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─── Page 1 : 歡迎 ─────────────────────────────────────────

class _Page1 extends StatelessWidget {
  final bool isDark; final Color fg, bg;
  const _Page1({required this.isDark, required this.fg, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo mark
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: isDark ? AppTheme.gray900 : AppTheme.pureWhite,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: isDark ? AppTheme.gray800 : AppTheme.gray200),
            ),
            child: Center(
              child: Text('W', style: TextStyle(
                fontFamily: AppTheme.fontFamilyEnglish,
                fontSize: 32, fontWeight: FontWeight.w700,
                color: fg, letterSpacing: -1,
              )),
            ),
          ),
          const SizedBox(height: 40),
          Text(
            'WayFinder',
            style: TextStyle(fontSize: 13, letterSpacing: 2, color: isDark ? AppTheme.gray500 : AppTheme.gray500,
                fontWeight: AppTheme.weightSemiBold),
          ),
          const SizedBox(height: 10),
          Text(
            '科學化\n英文學習',
            style: TextStyle(fontSize: 42, fontWeight: FontWeight.w700,
                color: fg, height: 1.15, letterSpacing: -1.5,
                fontFamily: AppTheme.fontFamilyChinese),
          ),
          const SizedBox(height: 20),
          Text(
            '基於 FSRS 間隔重複演算法\n讓記憶效率最大化',
            style: TextStyle(fontSize: 16, height: 1.65,
                color: isDark ? AppTheme.gray400 : AppTheme.gray600),
          ),
        ],
      ),
    );
  }
}

// ─── Page 2 : 功能亮點 ─────────────────────────────────────

class _Page2 extends StatelessWidget {
  final bool isDark; final Color fg, bg;
  const _Page2({required this.isDark, required this.fg, required this.bg});

  @override
  Widget build(BuildContext context) {
    final card = isDark ? AppTheme.gray900 : AppTheme.pureWhite;
    final features = [
      ('翻牌記憶', 'FSRS 自適應，依記憶曲線排程', '01'),
      ('情境強化', '填空、配對、造句、聽力四合一', '02'),
      ('進度追蹤', '熱力圖、保留率、連勝紀錄', '03'),
      ('多義解鎖', '掌握第一譯後自動解鎖第二譯', '04'),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('核心功能', style: TextStyle(fontSize: 13, letterSpacing: 2,
              color: isDark ? AppTheme.gray500 : AppTheme.gray500, fontWeight: AppTheme.weightSemiBold)),
          const SizedBox(height: 14),
          Text('完整的\n學習體驗', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w700,
              color: fg, height: 1.2, letterSpacing: -1, fontFamily: AppTheme.fontFamilyChinese)),
          const SizedBox(height: 28),
          ...features.map((f) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: card, borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border: Border.all(color: isDark ? AppTheme.gray800 : AppTheme.gray100),
              ),
              child: Row(children: [
                Text(f.$3, style: TextStyle(fontSize: 11, fontWeight: AppTheme.weightBold,
                    color: isDark ? AppTheme.gray700 : AppTheme.gray300, letterSpacing: 1)),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(f.$1, style: TextStyle(fontSize: 14, fontWeight: AppTheme.weightSemiBold, color: fg)),
                  const SizedBox(height: 2),
                  Text(f.$2, style: TextStyle(fontSize: 12, color: isDark ? AppTheme.gray500 : AppTheme.gray500)),
                ])),
              ]),
            ),
          )),
        ],
      ),
    );
  }
}

// ─── Page 3 : 每日目標 ─────────────────────────────────────

class _Page3 extends StatelessWidget {
  final bool isDark; final Color fg;
  final int goal;
  final ValueChanged<int> onGoalChanged;
  const _Page3({required this.isDark, required this.fg, required this.goal, required this.onGoalChanged});

  String _desc(int v) {
    if (v <= 10) return '輕鬆 · 適合剛開始';
    if (v <= 20) return '均衡 · 建議從這裡開始';
    if (v <= 40) return '積極 · 每日約 20 分鐘';
    return '進階 · 高強度挑戰';
  }

  @override
  Widget build(BuildContext context) {
    final thumb = isDark ? AppTheme.pureWhite : AppTheme.pureBlack;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('每日目標', style: TextStyle(fontSize: 13, letterSpacing: 2,
              color: isDark ? AppTheme.gray500 : AppTheme.gray500, fontWeight: AppTheme.weightSemiBold)),
          const SizedBox(height: 14),
          Text('你想每天\n學多少個？', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w700,
              color: fg, height: 1.2, letterSpacing: -1, fontFamily: AppTheme.fontFamilyChinese)),
          const SizedBox(height: 48),

          // 大數字
          Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
            Text('$goal', style: TextStyle(
              fontFamily: AppTheme.fontFamilyEnglish, fontSize: 80, fontWeight: FontWeight.w200,
              color: fg, letterSpacing: -4, height: 1,
            )),
            const SizedBox(width: 8),
            Text('個 / 天', style: TextStyle(fontSize: 16, color: isDark ? AppTheme.gray400 : AppTheme.gray500)),
          ]),
          const SizedBox(height: 6),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: Text(key: ValueKey(goal), _desc(goal),
                style: TextStyle(fontSize: 13, color: isDark ? AppTheme.gray500 : AppTheme.gray600)),
          ),
          const SizedBox(height: 32),

          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: thumb, inactiveTrackColor: isDark ? AppTheme.gray800 : AppTheme.gray200,
              thumbColor: thumb, overlayColor: thumb.withValues(alpha: 0.1),
              trackHeight: 2, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
            ),
            child: Slider(
              value: goal.toDouble(), min: 5, max: 60, divisions: 11,
              onChanged: (v) => onGoalChanged(v.round()),
            ),
          ),

          const SizedBox(height: 6),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('5', style: TextStyle(fontSize: 12, color: isDark ? AppTheme.gray600 : AppTheme.gray500)),
            Text('60', style: TextStyle(fontSize: 12, color: isDark ? AppTheme.gray600 : AppTheme.gray500)),
          ]),
          const SizedBox(height: 24),
          Text('可以隨時在設定中更改', style: TextStyle(fontSize: 12, color: isDark ? AppTheme.gray600 : AppTheme.gray500)),
        ],
      ),
    );
  }
}
