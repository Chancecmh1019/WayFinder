import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../providers/settings_provider.dart';
import '../settings_screen.dart';
import '../study/flashcard_screen.dart';
import '../../providers/study_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg   = isDark ? AppTheme.pureBlack : AppTheme.offWhite;
    final card = isDark ? AppTheme.gray900 : AppTheme.pureWhite;
    final fg   = isDark ? AppTheme.pureWhite : AppTheme.pureBlack;

    final streak     = ref.watch(streakProvider);
    final dueCount   = ref.watch(dueCountProvider);
    final todayNew   = ref.watch(todayStudiedProvider);
    final dailyGoal  = ref.watch(dailyGoalProvider);
    final retention  = ref.watch(retentionRateProvider);
    final learned    = ref.watch(learnedCountProvider);
    final totalAsync = ref.watch(allWordsProvider);
    final fsrs       = ref.watch(fsrsServiceProvider);
    final remaining  = fsrs.isInitialized() ? fsrs.getRemainingNewCardsToday(dailyGoal) : dailyGoal;
    final mastery    = fsrs.isInitialized() ? fsrs.getMasteryDistribution() : <String, int>{};
    final pct        = (todayNew / dailyGoal).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [

            // ── Header ─────────────────────────────────────────────
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 20, 0),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_greeting(), style: TextStyle(fontSize: 12, color: AppTheme.gray500,
                      letterSpacing: 0.5, fontWeight: AppTheme.weightMedium)),
                  const SizedBox(height: 4),
                  Text('今日學習', style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    letterSpacing: -0.5, fontFamily: AppTheme.fontFamilyChinese,
                  )),
                ])),
                IconButton(
                  icon: Icon(Icons.settings_outlined, color: isDark ? AppTheme.gray400 : AppTheme.gray600, size: 22),
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
                ),
              ]),
            )),

            // ── Today CTA Card ─────────────────────────────────────
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: _TodayCard(
                todayNew: todayNew, dailyGoal: dailyGoal,
                dueCount: dueCount, remaining: remaining,
                pct: pct, isDark: isDark, card: card, fg: fg,
                onTap: () {
                  HapticFeedback.mediumImpact();
                  ref.read(studySessionProvider.notifier).startSession();
                  Navigator.of(context).push(PageRouteBuilder(
                    pageBuilder: (_, __, ___) => const FlashcardScreen(),
                    transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
                    transitionDuration: const Duration(milliseconds: 220),
                  )).then((_) => ref.read(statsRefreshTriggerProvider.notifier).state++);
                },
              ),
            )),

            // ── Streak ────────────────────────────────────────────
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              child: _StreakCard(streak: streak, isDark: isDark, card: card, fg: fg),
            )),

            // ── Stats Grid ────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 1.35,
                ),
                delegate: SliverChildListDelegate([
                  _StatCard('$learned', '已掌握', isDark: isDark, card: card, fg: fg),
                  _StatCard('${retention.toStringAsFixed(0)}%', '記憶保留率', isDark: isDark, card: card, fg: fg),
                  totalAsync.when(
                    data: (w) => _StatCard('${w.length}', '詞庫總量', isDark: isDark, card: card, fg: fg),
                    loading: () => _StatCard('—', '詞庫總量', isDark: isDark, card: card, fg: fg),
                    error: (_, __) => _StatCard('—', '詞庫總量', isDark: isDark, card: card, fg: fg),
                  ),
                  _StatCard('$dueCount', '待複習', isDark: isDark, card: card, fg: fg,
                      sub: dueCount > 0 ? '需要複習' : '全部清空 ✓'),
                ]),
              ),
            ),

            // ── Mastery Bar ───────────────────────────────────────
            if (mastery.isNotEmpty && mastery.values.any((v) => v > 0))
              SliverToBoxAdapter(child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                child: _MasteryBar(mastery: mastery, isDark: isDark, card: card, fg: fg),
              )),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 5)  return '深夜好  ·  GOOD NIGHT';
    if (h < 12) return '早安  ·  GOOD MORNING';
    if (h < 18) return '午安  ·  GOOD AFTERNOON';
    return '晚安  ·  GOOD EVENING';
  }
}

// ── Today Card ──────────────────────────────────────────────

class _TodayCard extends StatelessWidget {
  final int todayNew, dailyGoal, dueCount, remaining;
  final double pct;
  final bool isDark;
  final Color card, fg;
  final VoidCallback onTap;
  const _TodayCard({
    required this.todayNew, required this.dailyGoal, required this.dueCount,
    required this.remaining, required this.pct, required this.isDark,
    required this.card, required this.fg, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final done = todayNew >= dailyGoal && dueCount == 0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: done ? (isDark ? AppTheme.gray900 : AppTheme.pureWhite) : (isDark ? AppTheme.pureWhite : AppTheme.pureBlack),
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          boxShadow: done ? (isDark ? null : AppTheme.cardShadow) : (isDark ? null : AppTheme.cardShadow),
        ),
        child: done ? _buildDone() : _buildActive(),
      ),
    );
  }

  Widget _buildDone() {
    final lf = isDark ? AppTheme.pureWhite : AppTheme.pureBlack;
    return Row(children: [
      Icon(Icons.check_circle_outline_rounded, size: 20, color: isDark ? AppTheme.gray400 : AppTheme.gray600),
      const SizedBox(width: 10),
      Text('今日學習已完成', style: TextStyle(fontSize: 15, fontWeight: AppTheme.weightSemiBold, color: lf)),
      const Spacer(),
      Text('繼續練習 →', style: TextStyle(fontSize: 13, color: isDark ? AppTheme.gray500 : AppTheme.gray600)),
    ]);
  }

  Widget _buildActive() {
    final lf = isDark ? AppTheme.pureBlack : AppTheme.pureWhite;
    final sub = isDark ? AppTheme.gray700 : const Color(0xFF555555);
    final track = isDark ? AppTheme.gray800 : const Color(0xFF333333);
    final fill  = isDark ? AppTheme.pureBlack : AppTheme.pureWhite;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            dueCount > 0 ? '$dueCount 個待複習' : '$remaining 個新單字',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: lf, letterSpacing: -0.5),
          ),
          const SizedBox(height: 3),
          Text(
            dueCount > 0 ? '今日複習到期' : '今日新學目標',
            style: TextStyle(fontSize: 13, color: sub),
          ),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: lf.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          child: Text('開始', style: TextStyle(fontSize: 14, fontWeight: AppTheme.weightSemiBold, color: lf)),
        ),
      ]),
      const SizedBox(height: 16),
      // 進度條
      ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: LinearProgressIndicator(
          value: pct, minHeight: 4,
          backgroundColor: track,
          valueColor: AlwaysStoppedAnimation(fill),
        ),
      ),
      const SizedBox(height: 8),
      Text('今日已學 $todayNew / $dailyGoal 個',
          style: TextStyle(fontSize: 11, color: sub)),
    ]);
  }
}

// ── Streak Card ─────────────────────────────────────────────

class _StreakCard extends StatelessWidget {
  final int streak;
  final bool isDark;
  final Color card, fg;
  const _StreakCard({required this.streak, required this.isDark, required this.card, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: card, borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: isDark ? AppTheme.gray800 : AppTheme.gray100),
      ),
      child: Row(children: [
        Icon(
          streak > 0 ? Icons.local_fire_department_outlined : Icons.circle_outlined,
          color: isDark ? AppTheme.gray400 : AppTheme.gray600,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(
          streak > 0 ? '連續學習 $streak 天' : '今天是第一天，加油！',
          style: TextStyle(fontSize: 14, fontWeight: AppTheme.weightMedium, color: fg),
        )),
        if (streak > 0)
          Text('streak', style: TextStyle(fontSize: 11, color: AppTheme.gray500, letterSpacing: 1)),
      ]),
    );
  }
}

// ── Stat Card ────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String value, label;
  final String? sub;
  final bool isDark;
  final Color card, fg;
  const _StatCard(this.value, this.label,
      {required this.isDark, required this.card, required this.fg, this.sub});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      decoration: BoxDecoration(
        color: card, borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: isDark ? AppTheme.gray800 : AppTheme.gray100),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700,
            color: fg, letterSpacing: -0.5, fontFamily: AppTheme.fontFamilyEnglish)),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 12, fontWeight: AppTheme.weightMedium, color: fg)),
          if (sub != null)
            Text(sub!, style: TextStyle(fontSize: 11, color: AppTheme.gray500)),
        ]),
      ]),
    );
  }
}

// ── Mastery Bar ──────────────────────────────────────────────

class _MasteryBar extends StatelessWidget {
  final Map<String, int> mastery;
  final bool isDark;
  final Color card, fg;
  const _MasteryBar({required this.mastery, required this.isDark, required this.card, required this.fg});

  @override
  Widget build(BuildContext context) {
    final total = mastery.values.fold(0, (a, b) => a + b);
    if (total == 0) return const SizedBox.shrink();

    final labels = {'new': '新', 'learning': '學習中', 'review': '複習', 'relearning': '重學'};
    final colors = {
      'new':        isDark ? AppTheme.gray700 : AppTheme.gray300,
      'learning':   isDark ? AppTheme.gray500 : AppTheme.gray500,
      'review':     isDark ? AppTheme.gray200 : AppTheme.gray800,
      'relearning': isDark ? AppTheme.gray400 : AppTheme.gray400,
    };

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(color: isDark ? AppTheme.gray800 : AppTheme.gray100)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('掌握程度分佈', style: TextStyle(fontSize: 12, fontWeight: AppTheme.weightMedium,
            color: isDark ? AppTheme.gray400 : AppTheme.gray600, letterSpacing: 0.3)),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Row(children: ['new','learning','review','relearning'].map((k) {
            final v = mastery[k] ?? 0;
            if (v == 0) return const SizedBox.shrink();
            return Expanded(flex: v, child: Container(height: 10, color: colors[k]));
          }).toList()),
        ),
        const SizedBox(height: 12),
        Wrap(spacing: 16, runSpacing: 6,
          children: ['new','learning','review','relearning'].map((k) {
            final v = mastery[k] ?? 0;
            if (v == 0) return const SizedBox.shrink();
            return Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: colors[k], shape: BoxShape.circle)),
              const SizedBox(width: 5),
              Text('${labels[k]} $v', style: TextStyle(fontSize: 11, color: isDark ? AppTheme.gray400 : AppTheme.gray600)),
            ]);
          }).toList(),
        ),
      ]),
    );
  }
}
