import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../../core/providers/app_providers.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg   = isDark ? AppTheme.pureBlack : AppTheme.offWhite;
    final card = isDark ? AppTheme.gray900 : AppTheme.pureWhite;
    final fg   = isDark ? AppTheme.pureWhite : AppTheme.pureBlack;

    // 全部即時響應 statsRefreshTriggerProvider
    final fsrs      = ref.watch(fsrsServiceProvider);
    final streak    = ref.watch(streakProvider);
    final learned   = ref.watch(learnedCountProvider);
    final due       = ref.watch(dueCountProvider);
    final retention = ref.watch(retentionRateProvider);
    final todayStats = ref.watch(todayStatsProvider);
    final totalAsync = ref.watch(allWordsProvider);

    final heatmap = fsrs.isInitialized() ? fsrs.getHeatmapData(91) : <String, int>{};
    final mastery = fsrs.isInitialized() ? fsrs.getMasteryDistribution() : <String, int>{};

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [

            // ── Header ─────────────────────────────────────────────
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('STATS', style: TextStyle(
                    fontSize: 11, letterSpacing: 3,
                    color: isDark ? AppTheme.gray600 : AppTheme.gray400,
                    fontWeight: AppTheme.weightSemiBold)),
                const SizedBox(height: 6),
                Text('統計', style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    letterSpacing: -0.5, fontFamily: AppTheme.fontFamilyChinese)),
              ]),
            )),

            // ── Core metrics ──────────────────────────────────────
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Row(children: [
                _CoreStat('$streak', '連續天數', streak > 0, isDark: isDark, card: card, fg: fg),
                const SizedBox(width: 10),
                _CoreStat('$learned', '已掌握', false, isDark: isDark, card: card, fg: fg),
                const SizedBox(width: 10),
                _CoreStat('$due', '待複習', false, isDark: isDark, card: card, fg: fg),
              ]),
            )),

            // ── Retention + vocab ─────────────────────────────────
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
              child: Row(children: [
                Expanded(child: _InfoBlock(
                  '${retention.toStringAsFixed(0)}%', '記憶保留率',
                  'Good+Easy 佔所有評分比例',
                  isDark: isDark, card: card, fg: fg,
                )),
                const SizedBox(width: 10),
                Expanded(child: totalAsync.when(
                  data: (w) => _InfoBlock(
                    '${w.length}', '詞庫規模', '單字 + 片語',
                    isDark: isDark, card: card, fg: fg),
                  loading: () => _InfoBlock('—', '詞庫規模', '',
                      isDark: isDark, card: card, fg: fg),
                  error: (_, __) => _InfoBlock('—', '詞庫規模', '',
                      isDark: isDark, card: card, fg: fg),
                )),
              ]),
            )),

            // ── Today detail ──────────────────────────────────────
            if (todayStats != null && todayStats.totalReviews > 0)
              SliverToBoxAdapter(child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
                child: _TodayDetail(stats: todayStats, isDark: isDark, card: card, fg: fg),
              )),

            // ── Heatmap ───────────────────────────────────────────
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: _SectionTitle('學習熱力圖', '過去 91 天', isDark, fg),
            )),
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _HeatmapGrid(data: heatmap, isDark: isDark, card: card),
            )),

            // ── FSRS state ────────────────────────────────────────
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: _SectionTitle('記憶狀態分布', '依 FSRS 演算法分級', isDark, fg),
            )),
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _MasteryBars(data: mastery, isDark: isDark, card: card, fg: fg),
            )),

            // ── FSRS Note ─────────────────────────────────────────
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: _FSRSNote(isDark: isDark, card: card, fg: fg),
            )),

            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }
}

// ── Section Title ─────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title, sub;
  final bool isDark;
  final Color fg;
  const _SectionTitle(this.title, this.sub, this.isDark, this.fg);
  @override
  Widget build(BuildContext context) =>
      Row(crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic, children: [
        Text(title, style: TextStyle(
            fontSize: 14, fontWeight: AppTheme.weightSemiBold, color: fg)),
        const SizedBox(width: 8),
        Text(sub, style: TextStyle(fontSize: 12, color: AppTheme.gray500)),
      ]);
}

// ── Core Stat ─────────────────────────────────────────────────

class _CoreStat extends StatelessWidget {
  final String value, label;
  final bool showIcon, isDark;
  final Color card, fg;
  const _CoreStat(this.value, this.label, this.showIcon,
      {required this.isDark, required this.card, required this.fg});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: isDark ? AppTheme.gray800 : AppTheme.gray100),
      ),
      child: Column(children: [
        if (showIcon) ...[
          Icon(Icons.radio_button_checked_rounded,
              color: isDark ? AppTheme.gray400 : AppTheme.gray500, size: 16),
          const SizedBox(height: 3),
        ],
        Text(value, style: TextStyle(
            fontFamily: AppTheme.fontFamilyEnglish,
            fontSize: 26, fontWeight: FontWeight.w700,
            color: fg, letterSpacing: -0.5)),
        const SizedBox(height: 3),
        Text(label, style: TextStyle(
            fontSize: 10, color: AppTheme.gray500, letterSpacing: 0.3),
            textAlign: TextAlign.center),
      ]),
    ),
  );
}

// ── Info Block ────────────────────────────────────────────────

class _InfoBlock extends StatelessWidget {
  final String value, label, sub;
  final bool isDark;
  final Color card, fg;
  const _InfoBlock(this.value, this.label, this.sub,
      {required this.isDark, required this.card, required this.fg});

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
      const SizedBox(height: 4),
      Text(label, style: TextStyle(fontSize: 12,
          fontWeight: AppTheme.weightSemiBold, color: fg)),
      if (sub.isNotEmpty) Text(sub,
          style: TextStyle(fontSize: 11, color: AppTheme.gray500)),
    ]),
  );
}

// ── Today Detail ──────────────────────────────────────────────

class _TodayDetail extends StatelessWidget {
  final dynamic stats;
  final bool isDark;
  final Color card, fg;
  const _TodayDetail({required this.stats,
      required this.isDark, required this.card, required this.fg});

  @override
  Widget build(BuildContext context) {
    final good  = (stats.goodCount as int) + (stats.easyCount as int);
    final hard  = stats.hardCount as int;
    final again = stats.againCount as int;
    final total = stats.totalReviews as int;
    final newCards = stats.newCards as int;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: isDark ? AppTheme.gray800 : AppTheme.gray100),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('今日', style: TextStyle(
            fontSize: 11, letterSpacing: 0.5,
            color: AppTheme.gray500, fontWeight: AppTheme.weightSemiBold)),
        const SizedBox(height: 12),
        Row(children: [
          _TodayNum('$newCards', '新單字', fg),
          _TodayNum('$total', '總複習', fg),
          _TodayNum('$good', '熟悉', fg),
          _TodayNum('$again', '忘記', fg),
        ]),
        const SizedBox(height: 12),
        if (total > 0) ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: Row(children: [
            if (good > 0) Flexible(flex: good, child: Container(height: 3,
                color: isDark ? AppTheme.pureWhite : AppTheme.pureBlack)),
            if (hard > 0) Flexible(flex: hard, child: Container(height: 3,
                color: isDark ? AppTheme.gray500 : AppTheme.gray400)),
            if (again > 0) Flexible(flex: again, child: Container(height: 3,
                color: isDark ? AppTheme.gray700 : AppTheme.gray200)),
          ]),
        ),
      ]),
    );
  }
}

class _TodayNum extends StatelessWidget {
  final String value, label;
  final Color fg;
  const _TodayNum(this.value, this.label, this.fg);
  @override
  Widget build(BuildContext context) => Expanded(child: Column(children: [
    Text(value, style: TextStyle(fontFamily: AppTheme.fontFamilyEnglish,
        fontSize: 20, fontWeight: FontWeight.w700, color: fg, letterSpacing: -0.5)),
    Text(label, style: TextStyle(fontSize: 10, color: AppTheme.gray500)),
  ]));
}

// ── Heatmap Grid ──────────────────────────────────────────────

class _HeatmapGrid extends StatelessWidget {
  final Map<String, int> data;
  final bool isDark;
  final Color card;
  const _HeatmapGrid(
      {required this.data, required this.isDark, required this.card});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();

    final sortedKeys = data.keys.toList()..sort();
    final maxVal = data.values.fold(1, (m, v) => v > m ? v : m);

    // 計算從今天算起 91 天前的週日
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startDate = today.subtract(Duration(days: today.weekday % 7 + 84));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: isDark ? AppTheme.gray800 : AppTheme.gray100),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          children: List.generate(13, (w) => Expanded(
            child: Column(
              children: List.generate(7, (d) {
                final date = startDate.add(Duration(days: w * 7 + d));
                final key =
                    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                final count = data[key] ?? 0;
                final ratio = count / maxVal;
                Color cellColor;
                if (count == 0) {
                  cellColor = isDark ? AppTheme.gray850 : AppTheme.gray100;
                } else {
                  cellColor = isDark
                      ? Color.lerp(AppTheme.gray700, AppTheme.pureWhite, ratio)!
                      : Color.lerp(AppTheme.gray300, AppTheme.pureBlack, ratio)!;
                }
                return Padding(
                  padding: const EdgeInsets.all(1.5),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        color: cellColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                );
              }),
            ),
          )),
        ),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(sortedKeys.isNotEmpty ? sortedKeys.first.substring(5) : '',
              style: TextStyle(fontSize: 10, color: AppTheme.gray500)),
          Text('今天',
              style: TextStyle(fontSize: 10, color: AppTheme.gray500)),
        ]),
      ]),
    );
  }
}

// ── Mastery Bars ──────────────────────────────────────────────

class _MasteryBars extends StatelessWidget {
  final Map<String, int> data;
  final bool isDark;
  final Color card, fg;
  const _MasteryBars(
      {required this.data, required this.isDark, required this.card, required this.fg});

  @override
  Widget build(BuildContext context) {
    final n  = data['new']        ?? 0;
    final l  = data['learning']   ?? 0;
    final r  = data['review']     ?? 0;
    final rl = data['relearning'] ?? 0;
    final total = n + l + r + rl;

    if (total == 0) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(color: isDark ? AppTheme.gray800 : AppTheme.gray100),
        ),
        child: Center(child: Text('尚無學習記錄',
            style: TextStyle(fontSize: 13, color: AppTheme.gray500))),
      );
    }

    final items = [
      ('已掌握', r, isDark ? AppTheme.pureWhite : AppTheme.pureBlack),
      ('學習中', l, isDark ? AppTheme.gray500 : AppTheme.gray400),
      ('重學',  rl, isDark ? AppTheme.gray600 : AppTheme.gray300),
      ('待學',  n,  isDark ? AppTheme.gray800 : AppTheme.gray100),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: isDark ? AppTheme.gray800 : AppTheme.gray100),
      ),
      child: Column(children: [
        ...items.where((e) => e.$2 > 0).map((e) {
          final (label, count, color) = e;
          final pct = count / total;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(children: [
              SizedBox(
                width: 40,
                child: Text(label, style: TextStyle(
                    fontSize: 11, color: AppTheme.gray500)),
              ),
              const SizedBox(width: 8),
              Expanded(child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: pct, minHeight: 6,
                  backgroundColor: isDark ? AppTheme.gray800 : AppTheme.gray100,
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              )),
              const SizedBox(width: 10),
              SizedBox(
                width: 32,
                child: Text('$count', textAlign: TextAlign.right,
                    style: TextStyle(fontSize: 12,
                        fontWeight: AppTheme.weightMedium, color: fg)),
              ),
            ]),
          );
        }),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(children: [
            const SizedBox(width: 48),
            Expanded(child: Text('共 $total 張詞卡',
                style: TextStyle(fontSize: 11, color: AppTheme.gray500))),
          ]),
        ),
      ]),
    );
  }
}

// ── FSRS Note ─────────────────────────────────────────────────

class _FSRSNote extends StatelessWidget {
  final bool isDark;
  final Color card, fg;
  const _FSRSNote({required this.isDark, required this.card, required this.fg});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: card,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      border: Border.all(color: isDark ? AppTheme.gray800 : AppTheme.gray100),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('關於 FSRS', style: TextStyle(
          fontSize: 13, fontWeight: AppTheme.weightSemiBold, color: fg)),
      const SizedBox(height: 8),
      Text(
        'Free Spaced Repetition Scheduler (FSRS) 是最先進的間隔重複演算法之一，由 Jarrett Ye 基於記憶科學研究開發。\n\n'
        '演算法根據你對每張卡片的評分（忘記 / 困難 / 記得 / 輕鬆），計算每個人專屬的最佳複習時機，讓記憶效率最大化。',
        style: TextStyle(
            fontSize: 13, color: AppTheme.gray500, height: 1.6),
      ),
    ]),
  );
}
