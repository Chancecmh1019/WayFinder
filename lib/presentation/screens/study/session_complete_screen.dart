import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../providers/study_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/unified_learning_provider.dart';

class SessionCompleteScreen extends ConsumerWidget {
  final int correctCount;
  final int totalCount;
  final StudyMode? mode;

  const SessionCompleteScreen({
    super.key,
    required this.correctCount,
    required this.totalCount,
    this.mode,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark    = Theme.of(context).brightness == Brightness.dark;
    final accuracy  = totalCount > 0 ? (correctCount / totalCount * 100).round() : 0;
    final todayStats = ref.watch(todayStatsProvider);
    final dailyGoal  = ref.watch(dailyGoalProvider);
    final bg   = isDark ? AppTheme.pureBlack : AppTheme.offWhite;
    final card = isDark ? AppTheme.gray900 : AppTheme.pureWhite;
    final fg   = isDark ? AppTheme.pureWhite : AppTheme.pureBlack;

    final todayNew     = todayStats?.newCards ?? 0;
    final todayReviews = todayStats?.totalReviews ?? 0;
    final goalDone     = todayNew >= dailyGoal;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(flex: 2),

              // Headline
              Text('DONE',
                  style: TextStyle(
                    fontSize: 12, fontWeight: AppTheme.weightBold,
                    letterSpacing: 3, color: AppTheme.gray400,
                  )),
              const SizedBox(height: 8),
              Text(
                goalDone ? '今日目標\n已完成 ✓' : '本次\n學習完成',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamilyChinese,
                  fontSize: 42, fontWeight: AppTheme.weightBold,
                  letterSpacing: -1.5, height: 1.1, color: fg,
                ),
              ),

              const Spacer(),

              // This session stats
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  boxShadow: isDark ? null : AppTheme.cardShadow,
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('本次', style: TextStyle(fontSize: 12, color: AppTheme.gray500, fontWeight: AppTheme.weightSemiBold)),
                  const SizedBox(height: 16),
                  Row(children: [
                    _MiniStat('$totalCount', '題', isDark: isDark, fg: fg),
                    _VertDivider(isDark: isDark),
                    _MiniStat('$correctCount', '答對', isDark: isDark, fg: fg),
                    _VertDivider(isDark: isDark),
                    _MiniStat('$accuracy%', '正確率', isDark: isDark, fg: fg),
                  ]),
                ]),
              ),

              const SizedBox(height: 12),

              // Today total
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  boxShadow: isDark ? null : AppTheme.cardShadow,
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('今日累計', style: TextStyle(fontSize: 12, color: AppTheme.gray500, fontWeight: AppTheme.weightSemiBold)),
                  const SizedBox(height: 16),
                  Row(children: [
                    _MiniStat('$todayNew', '新單字', isDark: isDark, fg: fg),
                    _VertDivider(isDark: isDark),
                    _MiniStat('$todayReviews', '總複習', isDark: isDark, fg: fg),
                    _VertDivider(isDark: isDark),
                    _MiniStat('$dailyGoal', '每日目標', isDark: isDark, fg: fg),
                  ]),
                ]),
              ),

              const Spacer(flex: 2),

              // CTA buttons
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
                    elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
                  ),
                  child: const Text('返回首頁', style: TextStyle(fontSize: 15, fontWeight: AppTheme.weightSemiBold)),
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity, height: 52,
                child: OutlinedButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).pop();
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: fg,
                    side: BorderSide(color: isDark ? AppTheme.gray700 : AppTheme.gray300),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
                  ),
                  child: const Text('繼續學習', style: TextStyle(fontSize: 15, fontWeight: AppTheme.weightSemiBold)),
                ),
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String value, label;
  final bool isDark;
  final Color fg;
  const _MiniStat(this.value, this.label, {required this.isDark, required this.fg});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(children: [
      Text(value,
          style: TextStyle(
              fontFamily: AppTheme.fontFamilyEnglish,
              fontSize: 28, fontWeight: AppTheme.weightBold,
              color: fg, letterSpacing: -1)),
      const SizedBox(height: 3),
      Text(label, style: TextStyle(fontSize: 11, color: AppTheme.gray500)),
    ]),
  );
}

class _VertDivider extends StatelessWidget {
  final bool isDark;
  const _VertDivider({required this.isDark});
  @override
  Widget build(BuildContext context) => Container(
    width: 1, height: 44,
    color: isDark ? AppTheme.gray800 : AppTheme.gray100,
    margin: const EdgeInsets.symmetric(horizontal: 4),
  );
}
