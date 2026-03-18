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

    final fsrs      = ref.watch(fsrsServiceProvider);
    final streak    = ref.watch(streakProvider);
    final learned   = ref.watch(learnedCountProvider);
    final due       = ref.watch(dueCountProvider);
    final retention = ref.watch(retentionRateProvider);
    final totalAsync = ref.watch(allWordsProvider);

    final heatmap  = fsrs.isInitialized() ? fsrs.getHeatmapData(91) : <String, int>{};
    final mastery  = fsrs.isInitialized() ? fsrs.getMasteryDistribution() : <String, int>{};

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 4),
                child: Text('統計', style: Theme.of(context).textTheme.displaySmall),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Text('你的學習軌跡', style: TextStyle(fontSize: 14, color: AppTheme.gray500)),
              ),
            ),

            // ── 核心指標 ─────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(children: [
                  _BigNum('$streak', '連續天數', isDark: isDark, card: card, fg: fg),
                  const SizedBox(width: 12),
                  _BigNum('$learned', '已掌握', isDark: isDark, card: card, fg: fg),
                  const SizedBox(width: 12),
                  _BigNum('$due', '待複習', isDark: isDark, card: card, fg: fg),
                ]),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // ── 保留率 + 總詞彙 ───────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(children: [
                  Expanded(child: _InfoCard(
                    '${retention.toStringAsFixed(0)}%',
                    '記憶保留率',
                    '近期答對 Good/Easy 比例',
                    isDark: isDark, card: card, fg: fg,
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: totalAsync.when(
                    data: (w) => _InfoCard('${w.length}', '詞庫規模', '7,177 單字 + 688 片語', isDark: isDark, card: card, fg: fg),
                    loading: () => _InfoCard('—', '詞庫規模', '', isDark: isDark, card: card, fg: fg),
                    error: (_, __) => _InfoCard('—', '詞庫規模', '', isDark: isDark, card: card, fg: fg),
                  )),
                ]),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 28)),

            // ── 熱力圖 ────────────────────────────────────
            _sectionHeader(context, '學習熱力圖', '過去 91 天', isDark),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                child: _HeatmapWidget(data: heatmap, isDark: isDark, card: card),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 28)),

            // ── FSRS 分佈 ─────────────────────────────────
            _sectionHeader(context, 'FSRS 記憶狀態', '依演算法分級', isDark),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                child: _MasteryChart(data: mastery, isDark: isDark, card: card, fg: fg),
              ),
            ),

            // ── FSRS 說明 ─────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: _FSRSExplanation(isDark: isDark, card: card),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  SliverToBoxAdapter _sectionHeader(BuildContext ctx, String title, String sub, bool isDark) =>
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
          child: Row(children: [
            Text(title,
                style: TextStyle(fontSize: 16, fontWeight: AppTheme.weightSemiBold,
                    color: isDark ? AppTheme.pureWhite : AppTheme.pureBlack)),
            const SizedBox(width: 8),
            Text(sub, style: TextStyle(fontSize: 13, color: AppTheme.gray500)),
          ]),
        ),
      );
}

// ── Big Number ────────────────────────────────────────────────

class _BigNum extends StatelessWidget {
  final String value, label;
  final bool isDark;
  final Color card, fg;
  const _BigNum(this.value, this.label, {required this.isDark, required this.card, required this.fg});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: card, borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: isDark ? null : AppTheme.subtleShadow,
      ),
      child: Column(children: [
        Text(value,
            style: TextStyle(fontFamily: AppTheme.fontFamilyEnglish,
                fontSize: 28, fontWeight: AppTheme.weightBold,
                color: fg, letterSpacing: -1)),
        const SizedBox(height: 3),
        Text(label, style: TextStyle(fontSize: 11, color: AppTheme.gray500)),
      ]),
    ),
  );
}

// ── Info Card ─────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final String value, label, desc;
  final bool isDark;
  final Color card, fg;
  const _InfoCard(this.value, this.label, this.desc, {required this.isDark, required this.card, required this.fg});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: card, borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      boxShadow: isDark ? null : AppTheme.subtleShadow,
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(value,
          style: TextStyle(fontFamily: AppTheme.fontFamilyEnglish,
              fontSize: 28, fontWeight: AppTheme.weightBold,
              color: fg, letterSpacing: -1)),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(fontSize: 13, fontWeight: AppTheme.weightMedium, color: fg)),
      const SizedBox(height: 2),
      Text(desc, style: TextStyle(fontSize: 11, color: AppTheme.gray500),
          maxLines: 2, overflow: TextOverflow.ellipsis),
    ]),
  );
}

// ── Heatmap ───────────────────────────────────────────────────

class _HeatmapWidget extends StatelessWidget {
  final Map<String, int> data;
  final bool isDark;
  final Color card;
  const _HeatmapWidget({required this.data, required this.isDark, required this.card});

  @override
  Widget build(BuildContext context) {
    final maxVal = data.values.fold(0, (a, b) => a > b ? a : b);
    final days   = 91;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card, borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: isDark ? null : AppTheme.subtleShadow,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(
          spacing: 3,
          runSpacing: 3,
          children: List.generate(days, (i) {
            final d = DateTime.now().subtract(Duration(days: days - 1 - i));
            final key = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
            final count = data[key] ?? 0;
            final intensity = maxVal > 0 ? count / maxVal : 0.0;
            final alpha = (intensity * 200 + 30).clamp(30, 255).toInt();
            return Container(
              width: 10, height: 10,
              decoration: BoxDecoration(
                color: count == 0
                    ? (isDark ? AppTheme.gray800 : AppTheme.gray100)
                    : Color.fromARGB(alpha, isDark ? 200 : 50, isDark ? 200 : 50, isDark ? 200 : 50),
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

// ── Mastery Chart ─────────────────────────────────────────────

class _MasteryChart extends StatelessWidget {
  final Map<String, int> data;
  final bool isDark;
  final Color card, fg;
  const _MasteryChart({required this.data, required this.isDark, required this.card, required this.fg});

  @override
  Widget build(BuildContext context) {
    final total = data.values.fold(0, (a, b) => a + b);
    final items = [
      _Row('新詞', data['new'] ?? 0, isDark ? AppTheme.gray700 : AppTheme.gray200),
      _Row('學習中', data['learning'] ?? 0, isDark ? AppTheme.gray600 : AppTheme.gray300),
      _Row('複習', data['review'] ?? 0, isDark ? AppTheme.gray400 : AppTheme.gray600),
      _Row('重學', data['relearning'] ?? 0, isDark ? AppTheme.gray500 : AppTheme.gray400),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card, borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: isDark ? null : AppTheme.subtleShadow,
      ),
      child: Column(children: [
        ...items.map((item) {
          final pct = total > 0 ? item.count / total : 0.0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(children: [
              SizedBox(width: 48, child: Text(item.label, style: TextStyle(fontSize: 12, color: AppTheme.gray500))),
              const SizedBox(width: 10),
              Expanded(child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: pct, minHeight: 8,
                  backgroundColor: isDark ? AppTheme.gray800 : AppTheme.gray100,
                  valueColor: AlwaysStoppedAnimation(item.color),
                ),
              )),
              const SizedBox(width: 10),
              SizedBox(width: 36, child: Text('${item.count}',
                  style: TextStyle(fontSize: 12, color: fg, fontWeight: AppTheme.weightSemiBold),
                  textAlign: TextAlign.right)),
            ]),
          );
        }),
        Container(height: 0.5, color: isDark ? AppTheme.gray800 : AppTheme.gray100),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          Text('共 $total 張卡片', style: TextStyle(fontSize: 12, color: AppTheme.gray500)),
        ]),
      ]),
    );
  }
}

class _Row {
  final String label; final int count; final Color color;
  const _Row(this.label, this.count, this.color);
}

// ── FSRS 說明 ─────────────────────────────────────────────────

class _FSRSExplanation extends StatelessWidget {
  final bool isDark;
  final Color card;
  const _FSRSExplanation({required this.isDark, required this.card});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: card,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      border: Border.all(color: isDark ? AppTheme.gray800 : AppTheme.gray200),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('關於 FSRS v5',
          style: TextStyle(fontSize: 12, fontWeight: AppTheme.weightSemiBold, color: AppTheme.gray500, letterSpacing: 0.5)),
      const SizedBox(height: 8),
      Text(
        'FSRS（自由間隔重複排程）是由 Jarrett Ye 開發的記憶科學演算法，'
        '以記憶保留率公式 R(t,S) = (1 + t/9S)^(−1) 為核心，'
        '根據每次複習的評分動態調整難度與穩定度，精確預測每張卡片的最佳複習時機，'
        '目標是以最少時間維持最高記憶保留率。',
        style: TextStyle(fontSize: 13, color: isDark ? AppTheme.gray400 : AppTheme.gray600, height: 1.6),
      ),
    ]),
  );
}
