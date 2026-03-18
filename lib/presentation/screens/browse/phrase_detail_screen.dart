import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../widgets/common/audio_button.dart';

const _examL = {'gsat':'學測','gsat_ref':'學測參','gsat_makeup':'補考','ast':'指考','gsat_115actual':'115學測','sped':'身障'};
const _sectionL = {'vocabulary':'詞彙','cloze':'克漏字','reading':'閱讀','discourse':'篇章','structure':'句構','translation':'翻譯'};

class PhraseDetailScreen extends ConsumerWidget {
  final String lemma;
  const PhraseDetailScreen({super.key, required this.lemma});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppTheme.pureBlack : AppTheme.offWhite,
      appBar: AppBar(
        backgroundColor: isDark ? AppTheme.pureBlack : AppTheme.offWhite,
        elevation: 0, scrolledUnderElevation: 0,
        leading: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.of(context).pop(),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const SizedBox(width: 4),
            Icon(Icons.chevron_left_rounded, size: 28,
                color: isDark ? AppTheme.pureWhite : AppTheme.pureBlack),
            Text('\u7247\u8a9e', style: TextStyle(fontSize: 17,
                color: isDark ? AppTheme.pureWhite : AppTheme.pureBlack)),
          ]),
        ),
        actions: [
          Padding(padding: const EdgeInsets.only(right: 16),
              child: AudioButton(text: lemma, size: 22)),
        ],
      ),
      body: ref.watch(phraseDetailProvider(lemma)).when(
        loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 1.5)),
        error: (e, _) => Center(child: Text('\u932f\u8aa4: $e')),
        data: (phrase) {
          if (phrase == null) return const Center(child: Text('\u627e\u4e0d\u5230\u7247\u8a9e\u8cc7\u6599'));
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            physics: const BouncingScrollPhysics(),
            children: [
              const SizedBox(height: 8),
              Text(phrase.lemma, style: TextStyle(
                fontFamily: AppTheme.fontFamilyEnglish, fontSize: 36,
                fontWeight: FontWeight.w600, letterSpacing: -1,
                color: isDark ? AppTheme.pureWhite : AppTheme.pureBlack)),
              const SizedBox(height: 12),
              Wrap(spacing: 6, children: phrase.senses.expand((s) => 
                (s.pos.isNotEmpty) ? [Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(border: Border.all(
                      color: isDark ? AppTheme.gray700 : AppTheme.gray200),
                      borderRadius: BorderRadius.circular(4)),
                  child: Text(s.pos.toLowerCase(), style: TextStyle(fontSize: 12, color: AppTheme.gray500)),
                )] : <Widget>[]
              ).toList()),
              if (phrase.frequency != null) ...[
                const SizedBox(height: 8),
                Row(children: [
                  Text('\u51fa\u73fe ${phrase.frequency!.totalAppearances} \u6b21',
                      style: TextStyle(fontSize: 13, color: AppTheme.gray500)),
                  const SizedBox(width: 12),
                  Text('\u91cd\u8981\u6027 ${(phrase.frequency!.importanceScore * 100).round()}%',
                      style: TextStyle(fontSize: 13, color: AppTheme.gray500)),
                ]),
              ],
              Divider(color: isDark ? AppTheme.gray800 : AppTheme.gray100, height: 32),
              ...phrase.senses.asMap().entries.map((entry) {
                final i = entry.key;
                final s = entry.value;
                return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (phrase.senses.length > 1) Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: isDark ? AppTheme.gray800 : AppTheme.gray100,
                        borderRadius: BorderRadius.circular(4)),
                    child: Text('\u7fa9\u9805 ${i+1}',
                        style: TextStyle(fontSize: 11, color: AppTheme.gray500))),
                  Text(s.zhDef, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700,
                      letterSpacing: -0.4, height: 1.3,
                      color: isDark ? AppTheme.pureWhite : AppTheme.pureBlack)),
                  if (s.enDef != null) ...[
                    const SizedBox(height: 6),
                    Text(s.enDef!, style: TextStyle(fontFamily: AppTheme.fontFamilyEnglish,
                        fontSize: 16, fontStyle: FontStyle.italic,
                        color: AppTheme.gray600, height: 1.5)),
                  ],
                  const SizedBox(height: 14),
                  if (s.examples.isNotEmpty) ...[
                    Text('\u8003\u984c\u4f8b\u53e5', style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w700,
                        color: AppTheme.gray400, letterSpacing: 0.8)),
                    const SizedBox(height: 8),
                    ...s.examples.map((ex) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                          color: isDark ? AppTheme.gray900 : AppTheme.gray50,
                          borderRadius: BorderRadius.circular(10)),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(ex.text, style: TextStyle(
                            fontFamily: AppTheme.fontFamilyEnglish, fontSize: 15,
                            color: isDark ? AppTheme.gray200 : AppTheme.gray800, height: 1.6)),
                        const SizedBox(height: 6),
                        Wrap(spacing: 4, children: [
                          _Tag('${ex.source.year}\u5e74'),
                          _Tag(_examL[ex.source.examType] ?? ex.source.examType),
                          _Tag(_sectionL[ex.source.sectionType] ?? ex.source.sectionType),
                        ]),
                      ]),
                    )),
                  ],
                  if (s.generatedExample != null)
                    Container(
                      padding: const EdgeInsets.all(12), margin: const EdgeInsets.only(bottom: 4),
                      decoration: BoxDecoration(
                          color: isDark ? AppTheme.gray900 : AppTheme.pureWhite,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: isDark ? AppTheme.gray800 : AppTheme.gray100)),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('AI', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
                            color: AppTheme.gray400)),
                        const SizedBox(width: 8),
                        Expanded(child: Text(s.generatedExample!, style: TextStyle(
                            fontFamily: AppTheme.fontFamilyEnglish, fontSize: 15,
                            fontStyle: FontStyle.italic, color: AppTheme.gray600, height: 1.6))),
                      ]),
                    ),
                  if (i < phrase.senses.length - 1)
                    Divider(color: isDark ? AppTheme.gray800 : AppTheme.gray100, height: 28),
                ]);
              }),
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  const _Tag(this.text);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
    decoration: BoxDecoration(color: AppTheme.gray100, borderRadius: BorderRadius.circular(3)),
    child: Text(text, style: const TextStyle(fontSize: 10, color: AppTheme.gray600)),
  );
}
