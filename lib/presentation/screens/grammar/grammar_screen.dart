import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../widgets/common/skeleton_loader.dart';

class GrammarScreen extends ConsumerWidget {
  const GrammarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final patternsAsync = ref.watch(allPatternsProvider);

    return Scaffold(
      backgroundColor: isDark ? AppTheme.pureBlack : AppTheme.offWhite,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 4),
              child: Text('文法句型',
                  style: Theme.of(context).textTheme.displaySmall),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Text('學測高頻考點，共 21 個句型',
                  style:
                      TextStyle(fontSize: 14, color: AppTheme.gray500)),
            ),
            Expanded(
              child: patternsAsync.when(
                loading: () => ListView.separated(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 8),
                  itemCount: 7,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, __) => SkeletonBox(
                      width: double.infinity, height: 72,
                      borderRadius: BorderRadius.circular(12)),
                ),
                error: (e, _) =>
                    Center(child: Text('載入失敗: $e')),
                data: (patterns) => ListView.separated(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 8),
                  itemCount: patterns.length,
                  separatorBuilder: (_, __) => Container(
                      height: 0.5,
                      color: isDark
                          ? AppTheme.gray800
                          : AppTheme.dividerGray),
                  itemBuilder: (ctx, i) {
                    final p = patterns[i];
                    return _PatternRow(
                      pattern: p,
                      isDark: isDark,
                      onTap: () => Navigator.of(ctx).push(
                        _slideRoute(PatternDetailScreen(patternLemma: p.lemma)),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  PageRoute _slideRoute(Widget page) => PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, a, __, c) => SlideTransition(
          position: Tween(begin: const Offset(1, 0), end: Offset.zero)
              .animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
          child: c,
        ),
        transitionDuration: const Duration(milliseconds: 320),
      );
}

class _PatternRow extends StatelessWidget {
  final dynamic pattern;
  final bool isDark;
  final VoidCallback onTap;

  const _PatternRow(
      {required this.pattern, required this.isDark, required this.onTap});

  static const _catLabel = {
    'participle': '分詞',
    'inversion': '倒裝',
    'subjunctive': '假設語氣',
    'cleft_sentence': '強調句',
    'result_purpose': '結果目的',
    'comparison_adv': '比較',
    'concession_adv': '讓步',
    'relative_clause': '關係子句',
    'noun_clause': '名詞子句',
    'infinitive_gerund': '不定詞/動名詞',
    'adverbial_clause': '副詞子句',
    'passive_voice': '被動語態',
  };

  @override
  Widget build(BuildContext context) {
    final subtypes = (pattern.subtypes as List).length;
    final catLabel =
        _catLabel[pattern.patternCategory] ?? pattern.patternCategory;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pattern.lemma as String,
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: AppTheme.weightSemiBold,
                          letterSpacing: -0.3,
                          color: isDark
                              ? AppTheme.pureWhite
                              : AppTheme.pureBlack)),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color:
                              isDark ? AppTheme.gray800 : AppTheme.gray100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(catLabel,
                            style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.gray500,
                                fontWeight: AppTheme.weightMedium)),
                      ),
                      const SizedBox(width: 6),
                      Text('$subtypes 個子句型',
                          style: TextStyle(
                              fontSize: 12, color: AppTheme.gray400)),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 22,
                color: isDark ? AppTheme.gray700 : AppTheme.gray300),
          ],
        ),
      ),
    );
  }
}

// ── Pattern Detail ───────────────────────────────────────────

class PatternDetailScreen extends ConsumerWidget {
  final String patternLemma;
  const PatternDetailScreen({super.key, required this.patternLemma});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final patternsAsync = ref.watch(allPatternsProvider);

    return Scaffold(
      backgroundColor: isDark ? AppTheme.pureBlack : AppTheme.offWhite,
      appBar: AppBar(
        backgroundColor: isDark ? AppTheme.pureBlack : AppTheme.offWhite,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.of(context).pop(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: 4),
              Icon(Icons.chevron_left_rounded,
                  size: 28,
                  color: isDark ? AppTheme.pureWhite : AppTheme.pureBlack),
              Text('文法',
                  style: TextStyle(
                      fontSize: 17,
                      color:
                          isDark ? AppTheme.pureWhite : AppTheme.pureBlack,
                      fontFamily: AppTheme.fontFamilyChinese)),
            ],
          ),
        ),
      ),
      body: patternsAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(strokeWidth: 1.5)),
        error: (e, _) => Center(child: Text('錯誤: $e')),
        data: (patterns) {
          final pattern = patterns
              .where((p) => p.lemma == patternLemma)
              .firstOrNull;
          if (pattern == null) {
            return const Center(child: Text('找不到句型'));
          }
          return _buildDetail(context, pattern, isDark);
        },
      ),
    );
  }

  Widget _buildDetail(BuildContext context, dynamic pattern, bool isDark) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      physics: const BouncingScrollPhysics(),
      children: [
        // Hero
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(pattern.lemma as String,
                  style: TextStyle(
                      fontSize: 32,
                      fontWeight: AppTheme.weightBold,
                      letterSpacing: -1,
                      color:
                          isDark ? AppTheme.pureWhite : AppTheme.pureBlack)),
              const SizedBox(height: 4),
              Text(pattern.patternCategory as String,
                  style: TextStyle(
                      fontFamily: AppTheme.fontFamilyEnglish,
                      fontSize: 15,
                      fontStyle: FontStyle.italic,
                      color: AppTheme.gray500)),
            ],
          ),
        ),

        // Beginner Summary (v7.0.0 新增)
        if (pattern.beginnerSummary != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.gray850 : AppTheme.gray50,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              border: Border.all(
                color: isDark ? AppTheme.gray800 : AppTheme.gray200,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  size: 20,
                  color: isDark ? AppTheme.gray400 : AppTheme.gray600,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    pattern.beginnerSummary as String,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: AppTheme.weightMedium,
                      color: isDark ? AppTheme.gray200 : AppTheme.gray700,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Teaching explanation
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.gray900 : AppTheme.pureWhite,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            boxShadow: isDark ? null : AppTheme.subtleShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('教學說明',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: AppTheme.weightBold,
                      letterSpacing: 0.8,
                      color: AppTheme.gray400)),
              const SizedBox(height: 10),
              Text(pattern.teachingExplanation as String,
                  style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.gray600,
                      height: 1.8)),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Subtypes
        Text('句型結構',
            style: TextStyle(
                fontSize: 15,
                fontWeight: AppTheme.weightSemiBold,
                letterSpacing: -0.2,
                color:
                    isDark ? AppTheme.pureWhite : AppTheme.pureBlack)),
        const SizedBox(height: 12),
        ...(pattern.subtypes as List).map<Widget>((st) =>
            _SubtypeCard(subtype: st, isDark: isDark)),

        const SizedBox(height: 32),
      ],
    );
  }
}

class _SubtypeCard extends StatelessWidget {
  final dynamic subtype;
  final bool isDark;
  const _SubtypeCard({required this.subtype, required this.isDark});

  static const _examLabels = {
    'gsat': '學測',
    'gsat_ref': '學測參',
    'gsat_makeup': '補考',
    'ast': '指考',
    'gsat_115actual': '115學測',
    'sped': '身障', // v6.0.0 新增
  };

  @override
  Widget build(BuildContext context) {
    final examples = subtype.examples as List;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.gray900 : AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: isDark ? null : AppTheme.subtleShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(subtype.displayName as String,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: AppTheme.weightSemiBold,
                  letterSpacing: -0.2,
                  color: isDark ? AppTheme.pureWhite : AppTheme.pureBlack)),
          const SizedBox(height: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.gray850 : AppTheme.gray50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(subtype.structure as String,
                style: TextStyle(
                    fontFamily: AppTheme.fontFamilyEnglish,
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: AppTheme.gray600)),
          ),
          const SizedBox(height: 12),

          // Real examples
          if (examples.isNotEmpty) ...[
            Text('考題例句',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: AppTheme.weightBold,
                    letterSpacing: 0.5,
                    color: AppTheme.gray400)),
            const SizedBox(height: 6),
            ...examples.map<Widget>((ex) {
              final examL = _examLabels[ex.source.examType as String] ??
                  ex.source.examType;
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.gray850 : AppTheme.gray50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ex.text as String,
                        style: TextStyle(
                            fontFamily: AppTheme.fontFamilyEnglish,
                            fontSize: 14,
                            height: 1.6,
                            color: isDark
                                ? AppTheme.gray200
                                : AppTheme.gray700)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _MiniTag('${ex.source.year}年'),
                        const SizedBox(width: 4),
                        _MiniTag(examL),
                        const SizedBox(width: 4),
                        _MiniTag(ex.source.sectionType as String),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],

          // AI example
          if (subtype.generatedExample != null) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI',
                    style: TextStyle(
                        fontSize: 9,
                        fontWeight: AppTheme.weightBold,
                        letterSpacing: 0.5,
                        color: AppTheme.gray400)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(subtype.generatedExample as String,
                      style: TextStyle(
                          fontFamily: AppTheme.fontFamilyEnglish,
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          color: AppTheme.gray500,
                          height: 1.6)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniTag extends StatelessWidget {
  final String text;
  const _MiniTag(this.text);
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
        decoration: BoxDecoration(
          color: AppTheme.gray100,
          borderRadius: BorderRadius.circular(3),
        ),
        child: Text(text,
            style:
                TextStyle(fontSize: 10, color: AppTheme.gray600)),
      );
}
