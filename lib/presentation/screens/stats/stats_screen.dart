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

    final fsrs       = ref.watch(fsrsServiceProvider);
    final streak     = ref.watch(streakProvider);
    final learned    = ref.watch(learnedCountProvider);
    final due        = ref.watch(dueCountProvider);
    final retention  = ref.watch(retentionRateProvider);
    final totalAsync = ref.watch(allWordsProvider);

    final heatmap = fsrs.isInitialized() ? fsrs.getHeatmapData(91) : <String, int>{};
    final mastery = fsrs.isInitialized() ? fsrs.getMasteryDistribution() : <String, int>{};

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [

            // ── Header ──────────────────────────────────────────
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('STATS', style: TextStyle(fontSize: 11, letterSpacing: 3,
                    color: isDark ? AppTheme.gray600 : AppTheme.gray400, fontWeight: AppTheme.weightSemiBold)),
                const SizedBox(height: 6),
                Text('統計', style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    letterSpacing: -0.5, fontFamily: AppTheme.fontFamilyChinese)),
              ]),
            )),

            // ── Core metrics row ─────────────────────────────────
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

            // ── Retention + vocabulary ───────────────────────────
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
              child: Row(children: [
                Expanded(child: _InfoBlock(
                  '${retention.toStringAsFixed(0)}%', '記憶保留率',
                  '近期 Good/Easy 比例', isDark: isDark, card: card, fg: fg,
                )),
                const SizedBox(width: 10),
                Expanded(child: totalAsync.when(
                  data:    (w) => _InfoBlock('${w.length}', '詞庫規模', '單字＋片語', isDark: isDark, card: card, fg: fg),
                  loading: ()  => _InfoBlock('—', '詞庫規模', '', isDark: isDark, card: card, fg: fg),
                  error:   (_, __) => _InfoBlock('—', '詞庫規模', '', isDark: isDark, card: card, fg: fg),
                )),
              ]),
            )),

            // ── Section: Heatmap ─────────────────────────────────
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 10),
              child: _SectionTitle('學習熱力圖', '過去 91 天', isDark, fg),
            )),
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _HeatmapGrid(data: heatmap, isDark: isDark, card: card),
            )),

            // ── Section: FSRS state ──────────────────────────────
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 10),
              child: _SectionTitle('FSRS 記憶狀態', '依演算法分級', isDark, fg),
            )),
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _MasteryBars(data: mastery, isDark: isDark, card: card, fg: fg),
            )),

            // ── Section: About FSRS ──────────────────────────────
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
              child: _FSRSNote(isDark: isDark, card: card, fg: fg),
            )),

            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }
}

// ── Section title ────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title, sub;
  final bool isDark;
  final Color fg;
  const _SectionTitle(this.title, this.sub, this.isDark, this.fg);
  @override
  Widget build(BuildContext context) => Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
    Text(title, style: TextStyle(fontSize: 15, fontWeight: AppTheme.weightSemiBold, color: fg)),
    const SizedBox(width: 8),
    Text(sub, style: TextStyle(fontSize: 12, color: AppTheme.gray500)),
  ]);
}

// ── Core Stat ────────────────────────────────────────────────

class _CoreStat extends StatelessWidget {
  final String value, label;
  final bool showIcon;
  final bool isDark;
  final Color card, fg;
  const _CoreStat(this.value, this.label, this.showIcon, {required this.isDark, required this.card, required this.fg});

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
        if (showIcon) Icon(Icons.local_fire_department_outlined, 
            color: isDark ? AppTheme.gray400 : AppTheme.gray600, size: 18),
        if (showIcon) const SizedBox(height: 3),
        Text(value, style: TextStyle(fontFamily: AppTheme.fontFamilyEnglish,
            fontSize: 26, fontWeight: FontWeight.w700, color: fg, letterSpacing: -0.5)),
        const SizedBox(height: 3),
        Text(label, style: TextStyle(fontSize: 10, color: AppTheme.gray500, letterSpacing: 0.3),
            textAlign: TextAlign.center),
      ]),
    ),
  );
}

// ── Info Block ───────────────────────────────────────────────

class _InfoBlock extends StatelessWidget {
  final String value, label, sub;
  final bool isDark;
  final Color card, fg;
  const _InfoBlock(this.value, this.label, this.sub, {required this.isDark, required this.card, required this.fg});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: card,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      border: Border.all(color: isDark ? AppTheme.gray800 : AppTheme.gray100),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(value, style: TextStyle(fontFamily: AppTheme.fontFamilyEnglish,
          fontSize: 28, fontWeight: FontWeight.w700, color: fg, letterSpacing: -1)),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(fontSize: 13, fontWeight: AppTheme.weightMedium, color: fg)),
      if (sub.isNotEmpty) ...[
        const SizedBox(height: 2),
        Text(sub, style: TextStyle(fontSize: 11, color: AppTheme.gray500)),
      ],
    ]),
  );
}

// ── Heatmap ──────────────────────────────────────────────────

class _HeatmapGrid extends StatelessWidget {
  final Map<String, int> data;
  final bool isDark;
  final Color card;
  const _HeatmapGrid({required this.data, required this.isDark, required this.card});

  @override
  Widget build(BuildContext context) {
    final maxVal = data.values.fold(0, (a, b) => a > b ? a : b);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: isDark ? AppTheme.gray800 : AppTheme.gray100),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(
          spacing: 3, runSpacing: 3,
          children: List.generate(91, (i) {
            final d = DateTime.now().subtract(Duration(days: 90 - i));
            final key = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
            final count = data[key] ?? 0;
            final intensity = maxVal > 0 ? (count / maxVal).clamp(0.0, 1.0) : 0.0;
            final base = isDark ? 210 : 30;
            return Container(
              width: 10, height: 10,
              decoration: BoxDecoration(
                color: count == 0
                    ? (isDark ? AppTheme.gray850 : AppTheme.gray100)
                    : Color.fromARGB(
                        ((intensity * 180) + 60).toInt().clamp(0, 255),
                        base, base, base,
                      ),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        ),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('91 天前', style: TextStyle(fontSize: 10, color: AppTheme.gray500)),
          Text('今天', style: TextStyle(fontSize: 10, color: AppTheme.gray500)),
        ]),
      ]),
    );
  }
}

// ── Mastery Bars ─────────────────────────────────────────────

class _MasteryBars extends StatelessWidget {
  final Map<String, int> data;
  final bool isDark;
  final Color card, fg;
  const _MasteryBars({required this.data, required this.isDark, required this.card, required this.fg});

  @override
  Widget build(BuildContext context) {
    final total = data.values.fold(0, (a, b) => a + b);
    final rows = [
      ('新詞',  'new',        isDark ? AppTheme.gray700 : AppTheme.gray200),
      ('學習中', 'learning',  isDark ? AppTheme.gray500 : AppTheme.gray400),
      ('複習',  'review',    isDark ? AppTheme.gray200 : AppTheme.gray800),
      ('重學',  'relearning', isDark ? AppTheme.gray600 : AppTheme.gray400),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: isDark ? AppTheme.gray800 : AppTheme.gray100),
      ),
      child: Column(children: [
        ...rows.map((r) {
          final count = data[r.$2] ?? 0;
          final pct = total > 0 ? count / total : 0.0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(children: [
              SizedBox(width: 44, child: Text(r.$1,
                  style: TextStyle(fontSize: 12, color: AppTheme.gray500))),
              const SizedBox(width: 8),
              Expanded(child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: pct, minHeight: 7,
                  backgroundColor: isDark ? AppTheme.gray800 : AppTheme.gray100,
                  valueColor: AlwaysStoppedAnimation(r.$3),
                ),
              )),
              const SizedBox(width: 8),
              SizedBox(width: 32, child: Text('$count',
                  style: TextStyle(fontSize: 12, color: fg, fontWeight: AppTheme.weightSemiBold),
                  textAlign: TextAlign.right)),
            ]),
          );
        }),
        Container(height: 0.5, color: isDark ? AppTheme.gray800 : AppTheme.gray100),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          Text('共 $total 張卡片', style: TextStyle(fontSize: 11, color: AppTheme.gray500)),
        ]),
      ]),
    );
  }
}

// ── FSRS Note ────────────────────────────────────────────────

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
      Text('關於 FSRS v5', style: TextStyle(fontSize: 11, letterSpacing: 0.8,
          fontWeight: AppTheme.weightSemiBold, color: AppTheme.gray500)),
      const SizedBox(height: 8),
      Text(
        'FSRS 是 Jarrett Ye 開發的記憶科學演算法，以記憶保留率公式 R(t,S) 為核心，'
        '根據每次評分動態調整難度與穩定度，精確預測最佳複習時機，'
        '以最少學習時間維持最高記憶保留率。',
        style: TextStyle(fontSize: 13, color: isDark ? AppTheme.gray400 : AppTheme.gray600, height: 1.6),
      ),
    ]),
  );
}
