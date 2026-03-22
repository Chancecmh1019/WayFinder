import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../providers/study_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/contextual_enhancement_provider.dart';
import '../../../core/providers/app_providers.dart';
import '../main_shell.dart';

class SessionCompleteScreen extends ConsumerWidget {
  final int correctCount;
  final int totalCount;
  final StudyMode? mode;
  final SessionMode sessionMode;

  const SessionCompleteScreen({
    super.key,
    required this.correctCount,
    required this.totalCount,
    this.mode,
    this.sessionMode = SessionMode.daily,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final bg   = isDark ? AppTheme.pureBlack : AppTheme.offWhite;
    final card = isDark ? AppTheme.gray900   : AppTheme.pureWhite;
    final fg   = isDark ? AppTheme.pureWhite : AppTheme.pureBlack;

    final todayStats = ref.watch(todayStatsProvider);
    final dailyGoal  = ref.watch(dailyGoalProvider);
    final ctxCount   = ref.watch(contextualWordCountProvider);

    final accuracy     = totalCount > 0 ? (correctCount / totalCount * 100).round() : 0;
    final todayNew     = todayStats?.newCards ?? 0;
    final todayReviews = todayStats?.totalReviews ?? 0;
    final goalDone     = todayNew >= dailyGoal;

    final goodCount  = (todayStats?.goodCount ?? 0) + (todayStats?.easyCount ?? 0);
    final hardCount  = todayStats?.hardCount ?? 0;
    final againCount = todayStats?.againCount ?? 0;

    final headline = goalDone ? '今日目標\n已完成' : '本次\n學習完成';

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),

              // ── Headline ──────────────────────────────────────
              Text('DONE', style: TextStyle(
                fontSize: 11, fontWeight: AppTheme.weightBold,
                letterSpacing: 3, color: AppTheme.gray500,
              )),
              const SizedBox(height: 10),
              Text(headline, style: TextStyle(
                fontFamily: AppTheme.fontFamilyChinese,
                fontSize: 44, fontWeight: FontWeight.w700,
                letterSpacing: -2, height: 1.1, color: fg,
              )),

              const SizedBox(height: 40),

              // ── 本次成績 ──────────────────────────────────────
              _StatBlock(
                label: '本次成績',
                isDark: isDark, card: card, fg: fg,
                children: [
                  _Stat('$totalCount', '題數', fg: fg),
                  _Divider(isDark: isDark),
                  _Stat('$correctCount', '答對', fg: fg),
                  _Divider(isDark: isDark),
                  _Stat('$accuracy%', '正確率', fg: fg),
                ],
              ),

              const SizedBox(height: 10),

              // ── 今日累計 ──────────────────────────────────────
              _StatBlock(
                label: '今日累計',
                isDark: isDark, card: card, fg: fg,
                children: [
                  _Stat('$todayNew', '新單字', fg: fg),
                  _Divider(isDark: isDark),
                  _Stat('$todayReviews', '總複習', fg: fg),
                  _Divider(isDark: isDark),
                  _Stat('$dailyGoal', '每日目標', fg: fg),
                ],
              ),

              // ── 回饋分布 ──────────────────────────────────────
              if (todayReviews > 0) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: card,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                    border: Border.all(
                        color: isDark ? AppTheme.gray800 : AppTheme.gray100),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('回饋分布', style: TextStyle(
                        fontSize: 11, letterSpacing: 1,
                        color: AppTheme.gray500, fontWeight: AppTheme.weightSemiBold)),
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: Row(children: [
                        if (goodCount > 0) Flexible(flex: goodCount, child: Container(
                            height: 5,
                            color: isDark ? AppTheme.pureWhite : AppTheme.pureBlack)),
                        if (hardCount > 0) Flexible(flex: hardCount, child: Container(
                            height: 5,
                            color: isDark ? AppTheme.gray500 : AppTheme.gray400)),
                        if (againCount > 0) Flexible(flex: againCount, child: Container(
                            height: 5,
                            color: isDark ? AppTheme.gray700 : AppTheme.gray200)),
                      ]),
                    ),
                    const SizedBox(height: 10),
                    Row(children: [
                      _MiniTag('熟悉 $goodCount', isDark),
                      const SizedBox(width: 8),
                      _MiniTag('困難 $hardCount', isDark),
                      const SizedBox(width: 8),
                      _MiniTag('忘記 $againCount', isDark),
                    ]),
                  ]),
                ),
              ],

              // ── 情境強化推薦（每日完成後提示）──────────────────
              if (goalDone && ctxCount >= kMinContextualWords && sessionMode == SessionMode.daily) ...[
                const SizedBox(height: 16),
                _ContextualSuggestion(
                  isDark: isDark, card: card, fg: fg,
                  ctxCount: ctxCount,
                  onTap: () {
                    // 回到主殼 → Study tab
                    Navigator.of(context).popUntil((r) => r.isFirst);
                    ref.read(mainTabProvider.notifier).state = 2;
                  },
                ),
              ],

              const SizedBox(height: 40),

              // ── 行動按鈕 ──────────────────────────────────────
              SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    Navigator.of(context).popUntil((r) => r.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? AppTheme.pureWhite : AppTheme.pureBlack,
                    foregroundColor: isDark ? AppTheme.pureBlack : AppTheme.pureWhite,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
                  ),
                  child: const Text('返回首頁',
                      style: TextStyle(fontSize: 15, fontWeight: AppTheme.weightSemiBold)),
                ),
              ),

              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity, height: 52,
                child: OutlinedButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    // 回主殼 Study tab
                    Navigator.of(context).popUntil((r) => r.isFirst);
                    ref.read(mainTabProvider.notifier).state = 2;
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: fg,
                    side: BorderSide(color: isDark ? AppTheme.gray700 : AppTheme.gray200),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
                  ),
                  child: const Text('繼續練習',
                      style: TextStyle(fontSize: 15, fontWeight: AppTheme.weightSemiBold)),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Contextual Suggestion ─────────────────────────────────────

class _ContextualSuggestion extends StatelessWidget {
  final bool isDark;
  final Color card, fg;
  final int ctxCount;
  final VoidCallback onTap;

  const _ContextualSuggestion({
    required this.isDark, required this.card, required this.fg,
    required this.ctxCount, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.gray900 : AppTheme.pureWhite,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(color: isDark ? AppTheme.gray800 : AppTheme.gray100),
        ),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('NEXT STEP', style: TextStyle(
                fontSize: 10, letterSpacing: 2,
                color: AppTheme.gray500, fontWeight: AppTheme.weightSemiBold)),
            const SizedBox(height: 6),
            Text('情境強化練習', style: TextStyle(
                fontSize: 16, fontWeight: AppTheme.weightSemiBold, color: fg)),
            const SizedBox(height: 3),
            Text('用 $ctxCount 個已學單字進行情境練習',
                style: TextStyle(fontSize: 12, color: AppTheme.gray500)),
          ])),
          Icon(Icons.arrow_forward_ios_rounded,
              size: 14, color: AppTheme.gray500),
        ]),
      ),
    );
  }
}

// ── Components ────────────────────────────────────────────────

class _StatBlock extends StatelessWidget {
  final String label;
  final bool isDark;
  final Color card, fg;
  final List<Widget> children;
  const _StatBlock({required this.label, required this.isDark,
      required this.card, required this.fg, required this.children});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: card,
      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      border: Border.all(color: isDark ? AppTheme.gray800 : AppTheme.gray100),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(
          fontSize: 11, letterSpacing: 1,
          color: AppTheme.gray500, fontWeight: AppTheme.weightSemiBold)),
      const SizedBox(height: 16),
      Row(children: children),
    ]),
  );
}

class _MiniTag extends StatelessWidget {
  final String text;
  final bool isDark;
  const _MiniTag(this.text, this.isDark);
  @override
  Widget build(BuildContext context) =>
      Text(text, style: TextStyle(fontSize: 11, color: AppTheme.gray500));
}

class _Stat extends StatelessWidget {
  final String value, label;
  final Color fg;
  const _Stat(this.value, this.label, {required this.fg});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(children: [
      Text(value, style: TextStyle(
          fontFamily: AppTheme.fontFamilyEnglish,
          fontSize: 28, fontWeight: FontWeight.w700,
          color: fg, letterSpacing: -1)),
      const SizedBox(height: 3),
      Text(label, style: TextStyle(fontSize: 11, color: AppTheme.gray500)),
    ]),
  );
}

class _Divider extends StatelessWidget {
  final bool isDark;
  const _Divider({required this.isDark});
  @override
  Widget build(BuildContext context) => Container(
    width: 1, height: 44,
    color: isDark ? AppTheme.gray800 : AppTheme.gray100,
    margin: const EdgeInsets.symmetric(horizontal: 4),
  );
}
