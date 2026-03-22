import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../providers/study_provider.dart';
import 'session_complete_screen.dart';

class MultipleChoiceScreen extends ConsumerStatefulWidget {
  final List<String>? customWordList;
  const MultipleChoiceScreen({super.key, this.customWordList});

  @override
  ConsumerState<MultipleChoiceScreen> createState() => _MultipleChoiceScreenState();
}

class _MultipleChoiceScreenState extends ConsumerState<MultipleChoiceScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(mcSessionProvider.notifier).start(customWordList: widget.customWordList);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mcSessionProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (state.isComplete) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(PageRouteBuilder(
          pageBuilder: (_, __, ___) => SessionCompleteScreen(
            correctCount: state.correctCount, totalCount: state.items.length,
            mode: StudyMode.multipleChoice,
          ),
          transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
        ));
      });
      return const SizedBox.shrink();
    }

    final item = state.current;
    if (item == null) return const SizedBox.shrink();
    final bg   = isDark ? AppTheme.pureBlack : AppTheme.offWhite;
    final card = isDark ? AppTheme.gray900 : AppTheme.pureWhite;
    final fg   = isDark ? AppTheme.pureWhite : AppTheme.pureBlack;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg, elevation: 0, scrolledUnderElevation: 0,
        leading: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.of(context).pop(),
          child: Icon(Icons.close_rounded, color: isDark ? AppTheme.gray400 : AppTheme.gray600),
        ),
        title: Text('四選一測驗',
            style: TextStyle(fontSize: 15, color: AppTheme.gray500, fontWeight: AppTheme.weightRegular)),
        actions: [
          Padding(padding: const EdgeInsets.only(right: 20),
              child: Text('${state.currentIndex + 1} / ${state.items.length}',
                  style: TextStyle(fontSize: 13, color: AppTheme.gray400))),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Progress
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: state.progress, minHeight: 3,
              backgroundColor: isDark ? AppTheme.gray800 : AppTheme.gray100,
              valueColor: AlwaysStoppedAnimation(isDark ? AppTheme.pureWhite : AppTheme.pureBlack),
            ),
          ),
          const SizedBox(height: 36),

          // Question
          Text('這個英文單字的中文意思是？',
              style: TextStyle(fontSize: 13, color: AppTheme.gray500)),
          const SizedBox(height: 12),
          Text(item.item.lemma,
              style: TextStyle(
                fontFamily: AppTheme.fontFamilyEnglish,
                fontSize: 40, fontWeight: AppTheme.weightBold,
                color: fg, letterSpacing: -1.5, height: 1.1,
              )),
          if (item.item.word.pos.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(item.item.word.pos.take(2).join(' · '),
                style: TextStyle(fontFamily: AppTheme.fontFamilyEnglish,
                    fontSize: 14, color: AppTheme.gray500, fontStyle: FontStyle.italic)),
          ],

          const SizedBox(height: 32),

          // Choices
          ...List.generate(item.choices.length, (i) {
            final selected = state.selectedIndex;
            final isSelected = selected == i;
            final isCorrect  = i == item.correctIndex;
            Color bg2 = card;
            Color borderColor = isDark ? AppTheme.gray800 : AppTheme.gray200;

            if (selected != null) {
              if (isCorrect) {
                bg2 = isDark ? const Color(0xFF1A2E1A) : const Color(0xFFEDF7ED);
                borderColor = const Color(0xFF2D7A2D);
              } else if (isSelected) {
                bg2 = isDark ? const Color(0xFF2E1A1A) : const Color(0xFFFAEDED);
                borderColor = const Color(0xFFB84040);
              }
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: selected == null ? () {
                  HapticFeedback.lightImpact();
                  ref.read(mcSessionProvider.notifier).select(i);
                } : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  decoration: BoxDecoration(
                    color: bg2,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    border: Border.all(color: borderColor, width: selected != null && (isCorrect || isSelected) ? 1.5 : 1),
                  ),
                  child: Row(children: [
                    Expanded(child: Text(item.choices[i],
                        style: TextStyle(
                          fontSize: 15, color: fg,
                          fontWeight: isSelected || (selected != null && isCorrect)
                              ? AppTheme.weightSemiBold : AppTheme.weightRegular,
                        ))),
                    if (selected != null) ...[
                      const SizedBox(width: 12),
                      Icon(
                        isCorrect ? Icons.check_circle_rounded : (isSelected ? Icons.cancel_rounded : null),
                        size: 20,
                        color: isCorrect ? const Color(0xFF2D7A2D) : const Color(0xFFB84040),
                      ),
                    ],
                  ]),
                ),
              ),
            );
          }),

          const Spacer(),

          if (state.selectedIndex != null)
            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  ref.read(mcSessionProvider.notifier).next();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? AppTheme.pureWhite : AppTheme.pureBlack,
                  foregroundColor: isDark ? AppTheme.pureBlack : AppTheme.pureWhite,
                  elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
                ),
                child: Text(
                  state.currentIndex + 1 >= state.items.length ? '查看結果' : '下一題',
                  style: const TextStyle(fontSize: 15, fontWeight: AppTheme.weightSemiBold),
                ),
              ),
            ),
        ]),
      ),
    );
  }
}
