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
    final learned    = ref.watch(learnedCountProvider);
    final todayNew   = ref.watch(todayStudiedProvider);
    final dailyGoal  = ref.watch(dailyGoalProvider);
    final totalAsync = ref.watch(allWordsProvider);
    final retention  = ref.watch(retentionRateProvider);
    final fsrs       = ref.watch(fsrsServiceProvider);
    final remaining  = fsrs.isInitialized() ? fsrs.getRemainingNewCardsToday(dailyGoal) : dailyGoal;
    final mastery    = fsrs.isInitialized() ? fsrs.getMasteryDistribution() : <String, int>{};

    final goalPct    = (todayNew / dailyGoal).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Header ─────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 16, 0),
                child: Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_greeting(), style: TextStyle(fontSize: 13, color: AppTheme.gray500)),
                    const SizedBox(height: 2),
                    Text('今日學習', style: Theme.of(context).textTheme.displayMedium),
                  ])),
                  IconButton(
                    icon: Icon(Icons.settings_outlined, color: isDark ? AppTheme.gray300 : AppTheme.gray700),
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
                  ),
                ]),
              ),
            ),

            // ── Streak Banner ───────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: _StreakCard(streak: streak, isDark: isDark, card: card, fg: fg),
              ),
            ),

            // ── Daily Goal Progress ─────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                child: _DailyGoalCard(
                  todayNew: todayNew, dailyGoal: dailyGoal,
                  dueCount: dueCount, remaining: remaining,
                  pct: goalPct, isDark: isDark, card: card, fg: fg,
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    ref.read(studySessionProvider.notifier).startSession();
                    Navigator.of(context).push(PageRouteBuilder(
                      pageBuilder: (_, __, ___) => const FlashcardScreen(),
                      transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
                      transitionDuration: const Duration(milliseconds: 200),
                    )).then((_) {
                      // 返回後觸發刷新
                      ref.read(statsRefreshTriggerProvider.notifier).state++;
                    });
                  },
                ),
              ),
            ),

            // ── Stats Grid ─────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12,
                  childAspectRatio: 1.3,
                ),
                delegate: SliverChildListDelegate([
                  _StatCard('$learned', '已掌握', '達 Review 階段', isDark: isDark, card: card, fg: fg),
                  _StatCard('${retention.toStringAsFixed(0)}%', '記憶保留率', '近期複習成效', isDark: isDark, card: card, fg: fg),
                  totalAsync.when(
                    data: (w) => _StatCard('${w.length}', '詞彙總量', '含單字與片語', isDark: isDark, card: card, fg: fg),
                    loading: () => _StatCard('—', '詞彙總量', '', isDark: isDark, card: card, fg: fg),
                    error: (_, __) => _StatCard('—', '詞彙總量', '', isDark: isDark, card: card, fg: fg),
                  ),
                  _StatCard('$dueCount', '待複習', dueCount > 0 ? '今日需要複習' : '全部清空 ✓', isDark: isDark, card: card, fg: fg),
                ]),
              ),
            ),

            // ── Mastery Distribution ────────────────────────
            if (mastery.isNotEmpty && (mastery.values.any((v) => v > 0)))
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                  child: _MasteryBar(mastery: mastery, isDark: isDark, card: card, fg: fg),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return '早安';
    if (h < 18) return '午安';
    return '晚安';
  }
}

// ── Streak Card ──────────────────────────────────────────────

class _StreakCard extends StatelessWidget {
  final int streak;
  final bool isDark;
  final Color card, fg;
  const _StreakCard({required this.streak, required this.isDark, required this.card, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: isDark ? null : AppTheme.subtleShadow,
      ),
      child: Row(children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isDark ? AppTheme.gray850 : AppTheme.gray100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.local_fire_department_outlined,
            size: 18,
            color: isDark ? AppTheme.gray400 : AppTheme.gray600,
          ),
        ),
        const SizedBox(width: 12),
        Text('連續學習',
            style: TextStyle(fontSize: 14, color: AppTheme.gray500)),
        const Spacer(),
        Text('$streak', style: TextStyle(fontSize: 24, fontWeight: AppTheme.weightBold, color: fg, fontFamily: AppTheme.fontFamilyEnglish, letterSpacing: -1)),
        const SizedBox(width: 4),
        Text('天', style: TextStyle(fontSize: 14, color: AppTheme.gray500)),
      ]),
    );
  }
}

// ── Daily Goal Card ──────────────────────────────────────────

class _DailyGoalCard extends StatelessWidget {
  final int todayNew, dailyGoal, dueCount, remaining;
  final double pct;
  final bool isDark;
  final Color card, fg;
  final VoidCallback onTap;

  const _DailyGoalCard({
    required this.todayNew, required this.dailyGoal,
    required this.dueCount, required this.remaining,
    required this.pct, required this.isDark, required this.card, required this.fg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final done = pct >= 1.0 && dueCount == 0;
    return GestureDetector(
      onTap: done ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: done
              ? (isDark ? const Color(0xFF1A1A1A) : AppTheme.pureBlack)
              : card,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          boxShadow: isDark ? null : AppTheme.cardShadow,
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(done ? '今日完成 ✓' : '今日目標',
                style: TextStyle(
                    fontSize: 14, fontWeight: AppTheme.weightSemiBold,
                    color: done ? AppTheme.pureWhite : AppTheme.gray500)),
            const Spacer(),
            if (!done)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.gray800 : AppTheme.gray100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  dueCount > 0 ? '開始複習 →' : '開始學習 →',
                  style: TextStyle(fontSize: 12, color: isDark ? AppTheme.gray300 : AppTheme.gray700, fontWeight: AppTheme.weightMedium),
                ),
              ),
          ]),

          if (!done) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: pct, minHeight: 6,
                backgroundColor: isDark ? AppTheme.gray800 : AppTheme.gray100,
                valueColor: AlwaysStoppedAnimation(isDark ? AppTheme.pureWhite : AppTheme.pureBlack),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '$todayNew / $dailyGoal 個新詞'
              '${dueCount > 0 ? ' · $dueCount 待複習' : ''}',
              style: TextStyle(fontSize: 12, color: AppTheme.gray500),
            ),
          ] else
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('明天繼續保持！',
                  style: TextStyle(fontSize: 14, color: AppTheme.pureWhite.withValues(alpha: 0.7))),
            ),
        ]),
      ),
    );
  }
}

// ── Stat Card ────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String value, label, sub;
  final bool isDark;
  final Color card, fg;

  const _StatCard(this.value, this.label, this.sub, {required this.isDark, required this.card, required this.fg});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: card,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      boxShadow: isDark ? null : AppTheme.subtleShadow,
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(value,
          style: TextStyle(
              fontFamily: AppTheme.fontFamilyEnglish,
              fontSize: 28, fontWeight: AppTheme.weightBold,
              color: fg, letterSpacing: -1)),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(fontSize: 13, fontWeight: AppTheme.weightMedium, color: fg)),
      const SizedBox(height: 2),
      Text(sub, style: TextStyle(fontSize: 11, color: AppTheme.gray500), maxLines: 1, overflow: TextOverflow.ellipsis),
    ]),
  );
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

    final items = [
      _MItem('新詞', mastery['new'] ?? 0, isDark ? AppTheme.gray700 : AppTheme.gray200),
      _MItem('學習中', mastery['learning'] ?? 0, isDark ? AppTheme.gray600 : AppTheme.gray300),
      _MItem('複習', mastery['review'] ?? 0, isDark ? AppTheme.gray400 : AppTheme.gray600),
      _MItem('重學', mastery['relearning'] ?? 0, isDark ? AppTheme.gray500 : AppTheme.gray400),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: isDark ? null : AppTheme.subtleShadow,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('記憶分佈',
            style: TextStyle(fontSize: 12, color: AppTheme.gray500, fontWeight: AppTheme.weightSemiBold)),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Row(children: items.map((i) {
            if (i.count == 0) return const SizedBox.shrink();
            return Expanded(
              flex: i.count,
              child: Container(height: 8, color: i.color),
            );
          }).toList()),
        ),
        const SizedBox(height: 10),
        Row(children: items.map((i) => Expanded(
          child: Column(children: [
            Text('${i.count}', style: TextStyle(fontSize: 13, fontWeight: AppTheme.weightSemiBold, color: fg)),
            Text(i.label, style: TextStyle(fontSize: 10, color: AppTheme.gray500)),
          ]),
        )).toList()),
      ]),
    );
  }
}

class _MItem {
  final String label; final int count; final Color color;
  const _MItem(this.label, this.count, this.color);
}
