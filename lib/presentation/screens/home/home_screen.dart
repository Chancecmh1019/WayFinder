import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../providers/settings_provider.dart';
import '../settings_screen.dart';
import '../study/flashcard_screen.dart';
import '../../providers/study_provider.dart';
import '../../providers/contextual_enhancement_provider.dart';
import '../main_shell.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg   = isDark ? AppTheme.pureBlack : AppTheme.offWhite;
    final card = isDark ? AppTheme.gray900 : AppTheme.pureWhite;
    final fg   = isDark ? AppTheme.pureWhite : AppTheme.pureBlack;

    final streak    = ref.watch(streakProvider);
    final dueCount  = ref.watch(dueCountProvider);
    final todayNew  = ref.watch(todayStudiedProvider);
    final dailyGoal = ref.watch(dailyGoalProvider);
    final retention = ref.watch(retentionRateProvider);
    final learned   = ref.watch(learnedCountProvider);
    final todayStats = ref.watch(todayStatsProvider);
    final totalAsync = ref.watch(allWordsProvider);
    final fsrs      = ref.watch(fsrsServiceProvider);
    final ctxCount  = ref.watch(contextualWordCountProvider);

    final remaining = fsrs.isInitialized()
        ? fsrs.getRemainingNewCardsToday(dailyGoal)
        : dailyGoal;
    final mastery = fsrs.isInitialized()
        ? fsrs.getMasteryDistribution()
        : <String, int>{};
    final pct = (todayNew / dailyGoal).clamp(0.0, 1.0);
    final dailyDone = dueCount == 0 && remaining == 0;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [

            // ── Header ──────────────────────────────────────────
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 20, 0),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_greeting(), style: TextStyle(
                      fontSize: 11, color: AppTheme.gray500,
                      letterSpacing: 1.5, fontWeight: AppTheme.weightMedium)),
                  const SizedBox(height: 4),
                  Text('今日學習', style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    letterSpacing: -0.5, fontFamily: AppTheme.fontFamilyChinese,
                  )),
                ])),
                IconButton(
                  icon: Icon(Icons.settings_outlined,
                      color: isDark ? AppTheme.gray400 : AppTheme.gray600, size: 22),
                  onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SettingsScreen())),
                ),
              ]),
            )),

            // ── Today CTA Card ───────────────────────────────────
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: _TodayCard(
                todayNew: todayNew, dailyGoal: dailyGoal,
                dueCount: dueCount, remaining: remaining,
                pct: pct, isDark: isDark, card: card, fg: fg,
                // ★ 不呼叫 startSession() — 由 FlashcardScreen 內部負責
                onTap: () {
                  HapticFeedback.mediumImpact();
                  Navigator.of(context).push(PageRouteBuilder(
                    pageBuilder: (_, __, ___) =>
                        const FlashcardScreen(mode: SessionMode.daily),
                    transitionsBuilder: (_, a, __, c) =>
                        FadeTransition(opacity: a, child: c),
                    transitionDuration: const Duration(milliseconds: 220),
                  ));
                },
              ),
            )),

            // ── Streak ──────────────────────────────────────────
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              child: _StreakCard(streak: streak, isDark: isDark, card: card, fg: fg),
            )),

            // ── Stats Grid ──────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10,
                  childAspectRatio: 1.35,
                ),
                delegate: SliverChildListDelegate([
                  _StatCard('$learned', '已掌握', isDark: isDark, card: card, fg: fg),
                  _StatCard('${retention.toStringAsFixed(0)}%', '記憶保留率',
                      isDark: isDark, card: card, fg: fg),
                  totalAsync.when(
                    data: (w) => _StatCard('${w.length}', '詞庫總量',
                        isDark: isDark, card: card, fg: fg),
                    loading: () => _StatCard('—', '詞庫總量',
                        isDark: isDark, card: card, fg: fg),
                    error: (_, __) => _StatCard('—', '詞庫總量',
                        isDark: isDark, card: card, fg: fg),
                  ),
                  _StatCard('$dueCount', '待複習',
                      sub: dueCount > 0 ? '需要複習' : '全部清空',
                      isDark: isDark, card: card, fg: fg),
                ]),
              ),
            ),

            // ── Today detail bar ─────────────────────────────────
            if (todayStats != null)
              SliverToBoxAdapter(child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                child: _TodayDetailBar(
                    stats: todayStats, isDark: isDark, card: card, fg: fg),
              )),

            // ── 情境強化快速入口（每日完成後顯示）───────────────
            if (dailyDone && ctxCount >= kMinContextualWords)
              SliverToBoxAdapter(child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                child: _ContextualShortcut(
                  isDark: isDark, card: card, fg: fg, ctxCount: ctxCount,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    ref.read(mainTabProvider.notifier).state = 2;
                  },
                ),
              )),

            // ── Mastery Bar ─────────────────────────────────────
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
    if (h < 5)  return 'GOOD NIGHT';
    if (h < 12) return 'GOOD MORNING';
    if (h < 18) return 'GOOD AFTERNOON';
    return 'GOOD EVENING';
  }
}

// ── Today Card ───────────────────────────────────────────────

class _TodayCard extends StatelessWidget {
  final int todayNew, dailyGoal, dueCount, remaining;
  final double pct;
  final bool isDark;
  final Color card, fg;
  final VoidCallback onTap;
  const _TodayCard({
    required this.todayNew, required this.dailyGoal,
    required this.dueCount, required this.remaining,
    required this.pct, required this.isDark,
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
          color: done ? card : (isDark ? AppTheme.pureWhite : AppTheme.pureBlack),
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          boxShadow: done ? (isDark ? null : AppTheme.cardShadow) : AppTheme.cardShadow,
        ),
        child: done ? _buildDone() : _buildActive(),
      ),
    );
  }

  Widget _buildDone() {
    final lf = isDark ? AppTheme.pureWhite : AppTheme.pureBlack;
    return Row(children: [
      Icon(Icons.check_circle_outline_rounded,
          size: 20, color: isDark ? AppTheme.gray400 : AppTheme.gray500),
      const SizedBox(width: 10),
      Text('今日學習已完成', style: TextStyle(
          fontSize: 15, fontWeight: AppTheme.weightSemiBold, color: lf)),
      const Spacer(),
      Text('繼續練習 →',
          style: TextStyle(fontSize: 13, color: AppTheme.gray500)),
    ]);
  }

  Widget _buildActive() {
    final lf  = isDark ? AppTheme.pureBlack : AppTheme.pureWhite;
    final sub  = isDark ? AppTheme.gray700 : const Color(0xFF555555);
    final track = isDark ? AppTheme.gray800 : const Color(0xFF333333);
    final fill  = isDark ? AppTheme.pureBlack : AppTheme.pureWhite;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            dueCount > 0 ? '$dueCount 個待複習' : '$remaining 個新單字',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700,
                color: lf, letterSpacing: -0.5),
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
          child: Text('開始', style: TextStyle(
              fontSize: 14, fontWeight: AppTheme.weightSemiBold, color: lf)),
        ),
      ]),
      const SizedBox(height: 16),
      ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: LinearProgressIndicator(
          value: pct, minHeight: 3,
          backgroundColor: track,
          valueColor: AlwaysStoppedAnimation(fill),
        ),
      ),
      const SizedBox(height: 8),
      Row(children: [
        Text('$todayNew / $dailyGoal', style: TextStyle(
            fontSize: 12, color: sub, fontWeight: AppTheme.weightMedium)),
        const Spacer(),
        Text('${(pct * 100).round()}%', style: TextStyle(fontSize: 12, color: sub)),
      ]),
    ]);
  }
}

// ── Contextual Shortcut ──────────────────────────────────────

class _ContextualShortcut extends StatelessWidget {
  final bool isDark;
  final Color card, fg;
  final int ctxCount;
  final VoidCallback onTap;
  const _ContextualShortcut({
    required this.isDark, required this.card, required this.fg,
    required this.ctxCount, required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: isDark ? AppTheme.gray800 : AppTheme.gray100),
      ),
      child: Row(children: [
        Icon(Icons.auto_awesome_rounded, size: 18,
            color: isDark ? AppTheme.gray400 : AppTheme.gray600),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('情境強化練習', style: TextStyle(
              fontSize: 14, fontWeight: AppTheme.weightSemiBold, color: fg)),
          Text('$ctxCount 個已學單字可用',
              style: TextStyle(fontSize: 12, color: AppTheme.gray500)),
        ])),
        Text('前往 →', style: TextStyle(fontSize: 13, color: AppTheme.gray500)),
      ]),
    ),
  );
}

// ── Streak Card ──────────────────────────────────────────────

class _StreakCard extends StatelessWidget {
  final int streak;
  final bool isDark;
  final Color card, fg;
  const _StreakCard({required this.streak, required this.isDark,
      required this.card, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: isDark ? AppTheme.gray800 : AppTheme.gray100),
      ),
      child: Row(children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('連續學習', style: TextStyle(
              fontSize: 11, letterSpacing: 0.5,
              color: AppTheme.gray500, fontWeight: AppTheme.weightMedium)),
          const SizedBox(height: 4),
          RichText(text: TextSpan(children: [
            TextSpan(text: '$streak', style: TextStyle(
                fontFamily: AppTheme.fontFamilyEnglish,
                fontSize: 32, fontWeight: FontWeight.w700,
                color: fg, letterSpacing: -1)),
            TextSpan(text: '  天',
                style: TextStyle(fontSize: 14, color: AppTheme.gray500)),
          ])),
        ]),
        const Spacer(),
        _StreakDots(streak: streak, isDark: isDark, fg: fg),
      ]),
    );
  }
}

class _StreakDots extends StatelessWidget {
  final int streak;
  final bool isDark;
  final Color fg;
  const _StreakDots({required this.streak, required this.isDark, required this.fg});

  @override
  Widget build(BuildContext context) => Row(
    children: List.generate(7, (i) {
      final active = (6 - i) < streak;
      return Container(
        width: 10, height: 10,
        margin: const EdgeInsets.only(left: 5),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active
              ? (isDark ? AppTheme.pureWhite : AppTheme.pureBlack)
              : (isDark ? AppTheme.gray800 : AppTheme.gray200),
        ),
      );
    }),
  );
}

// ── Stat Card ────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String value, label;
  final String? sub;
  final bool isDark;
  final Color card, fg;
  const _StatCard(this.value, this.label, {
    this.sub, required this.isDark, required this.card, required this.fg});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: card,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      border: Border.all(color: isDark ? AppTheme.gray800 : AppTheme.gray100),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(value, style: TextStyle(
          fontFamily: AppTheme.fontFamilyEnglish,
          fontSize: 28, fontWeight: FontWeight.w700,
          color: fg, letterSpacing: -0.5)),
      const Spacer(),
      Text(label, style: TextStyle(fontSize: 12, color: AppTheme.gray500)),
      if (sub != null)
        Text(sub!, style: TextStyle(fontSize: 10, color: AppTheme.gray500)),
    ]),
  );
}

// ── Today Detail Bar ─────────────────────────────────────────

class _TodayDetailBar extends StatelessWidget {
  final dynamic stats;
  final bool isDark;
  final Color card, fg;
  const _TodayDetailBar({required this.stats,
      required this.isDark, required this.card, required this.fg});

  @override
  Widget build(BuildContext context) {
    final total = stats.totalReviews as int;
    if (total == 0) return const SizedBox.shrink();
    final good  = (stats.goodCount as int) + (stats.easyCount as int);
    final hard  = stats.hardCount as int;
    final again = stats.againCount as int;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: isDark ? AppTheme.gray800 : AppTheme.gray100),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('今日回饋', style: TextStyle(
            fontSize: 11, letterSpacing: 0.5,
            color: AppTheme.gray500, fontWeight: AppTheme.weightMedium)),
        const SizedBox(height: 10),
        Row(children: [
          _MiniStat('$good', '熟悉', isDark, fg),
          _MiniStat('$hard', '困難', isDark, fg),
          _MiniStat('$again', '忘記', isDark, fg),
          _MiniStat('$total', '總計', isDark, fg),
        ]),
        const SizedBox(height: 10),
        _FeedbackBar(good: good, hard: hard, again: again, isDark: isDark),
      ]),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String value, label;
  final bool isDark;
  final Color fg;
  const _MiniStat(this.value, this.label, this.isDark, this.fg);

  @override
  Widget build(BuildContext context) => Expanded(child: Column(children: [
    Text(value, style: TextStyle(fontFamily: AppTheme.fontFamilyEnglish,
        fontSize: 20, fontWeight: FontWeight.w700, color: fg, letterSpacing: -0.5)),
    Text(label, style: TextStyle(fontSize: 10, color: AppTheme.gray500)),
  ]));
}

class _FeedbackBar extends StatelessWidget {
  final int good, hard, again;
  final bool isDark;
  const _FeedbackBar({required this.good, required this.hard,
      required this.again, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final total = good + hard + again;
    if (total == 0) return const SizedBox.shrink();
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Row(children: [
        if (good > 0) Flexible(flex: good, child: Container(
            height: 4, color: isDark ? AppTheme.pureWhite : AppTheme.pureBlack)),
        if (hard > 0) Flexible(flex: hard, child: Container(
            height: 4, color: isDark ? AppTheme.gray500 : AppTheme.gray400)),
        if (again > 0) Flexible(flex: again, child: Container(
            height: 4, color: isDark ? AppTheme.gray700 : AppTheme.gray200)),
      ]),
    );
  }
}

// ── Mastery Bar ──────────────────────────────────────────────

class _MasteryBar extends StatelessWidget {
  final Map<String, int> mastery;
  final bool isDark;
  final Color card, fg;
  const _MasteryBar({required this.mastery,
      required this.isDark, required this.card, required this.fg});

  @override
  Widget build(BuildContext context) {
    final n  = mastery['new']        ?? 0;
    final l  = mastery['learning']   ?? 0;
    final r  = mastery['review']     ?? 0;
    final rl = mastery['relearning'] ?? 0;
    final total = n + l + r + rl;
    if (total == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: isDark ? AppTheme.gray800 : AppTheme.gray100),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('記憶狀態', style: TextStyle(
              fontSize: 12, fontWeight: AppTheme.weightSemiBold, color: fg)),
          const Spacer(),
          Text('$total 個詞卡',
              style: TextStyle(fontSize: 11, color: AppTheme.gray500)),
        ]),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: Row(children: [
            if (r > 0) Flexible(flex: r, child: Container(height: 6,
                color: isDark ? AppTheme.pureWhite : AppTheme.pureBlack)),
            if (l > 0) Flexible(flex: l, child: Container(height: 6,
                color: isDark ? AppTheme.gray500 : AppTheme.gray400)),
            if (rl > 0) Flexible(flex: rl, child: Container(height: 6,
                color: isDark ? AppTheme.gray600 : AppTheme.gray300)),
            if (n > 0) Flexible(flex: n, child: Container(height: 6,
                color: isDark ? AppTheme.gray800 : AppTheme.gray100)),
          ]),
        ),
        const SizedBox(height: 10),
        Row(children: [
          _MasteryLegend('已掌握', r, isDark ? AppTheme.pureWhite : AppTheme.pureBlack),
          const SizedBox(width: 12),
          _MasteryLegend('學習中', l, isDark ? AppTheme.gray500 : AppTheme.gray400),
          const SizedBox(width: 12),
          _MasteryLegend('重學', rl, isDark ? AppTheme.gray600 : AppTheme.gray300),
          const Spacer(),
          Text('新 $n', style: TextStyle(fontSize: 10, color: AppTheme.gray500)),
        ]),
      ]),
    );
  }
}

class _MasteryLegend extends StatelessWidget {
  final String label;
  final int count;
  final Color dot;
  const _MasteryLegend(this.label, this.count, this.dot);

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 8, height: 8,
        decoration: BoxDecoration(shape: BoxShape.circle, color: dot)),
    const SizedBox(width: 4),
    Text('$label $count',
        style: TextStyle(fontSize: 10, color: AppTheme.gray500)),
  ]);
}
