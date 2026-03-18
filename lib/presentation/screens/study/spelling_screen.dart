import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../providers/study_provider.dart';
import 'session_complete_screen.dart';

class SpellingScreen extends ConsumerStatefulWidget {
  final List<String>? customWordList;
  const SpellingScreen({super.key, this.customWordList});

  @override
  ConsumerState<SpellingScreen> createState() => _SpellingScreenState();
}

class _SpellingScreenState extends ConsumerState<SpellingScreen> {
  final _ctrl  = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(spellingSessionProvider.notifier).start(customWordList: widget.customWordList);
      _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _submit() {
    if (_ctrl.text.trim().isEmpty) return;
    final state = ref.read(spellingSessionProvider);
    if (state.isCorrect != null) return;
    HapticFeedback.lightImpact();
    ref.read(spellingSessionProvider.notifier).submit(_ctrl.text);
  }

  Future<void> _next() async {
    HapticFeedback.selectionClick();
    _ctrl.clear();
    await ref.read(spellingSessionProvider.notifier).next();
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(spellingSessionProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (state.isComplete) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(PageRouteBuilder(
          pageBuilder: (_, __, ___) => SessionCompleteScreen(
            correctCount: state.correctCount, totalCount: state.items.length,
            mode: StudyMode.spelling,
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
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: bg, elevation: 0, scrolledUnderElevation: 0,
        leading: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.of(context).pop(),
          child: Icon(Icons.close_rounded, color: isDark ? AppTheme.gray400 : AppTheme.gray600),
        ),
        title: Text('拼寫測驗',
            style: TextStyle(fontSize: 15, color: AppTheme.gray500, fontWeight: AppTheme.weightRegular)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Text('${state.currentIndex + 1} / ${state.items.length}',
                style: TextStyle(fontSize: 13, color: AppTheme.gray400)),
          ),
        ],
      ),
      body: Column(children: [
        // Progress bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: state.progress, minHeight: 3,
              backgroundColor: isDark ? AppTheme.gray800 : AppTheme.gray100,
              valueColor: AlwaysStoppedAnimation(isDark ? AppTheme.pureWhite : AppTheme.pureBlack),
            ),
          ),
        ),
        const SizedBox(height: 32),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Instruction
              Text('看中文定義，拼出正確的英文單字',
                  style: TextStyle(fontSize: 13, color: AppTheme.gray500)),
              const SizedBox(height: 20),

              // Definition card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  boxShadow: isDark ? null : AppTheme.cardShadow,
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // POS tags
                  Wrap(spacing: 6, children: item.word.pos.take(2).map((p) =>
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        border: Border.all(color: isDark ? AppTheme.gray700 : AppTheme.gray200),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(p, style: TextStyle(fontSize: 11, color: AppTheme.gray500)),
                    )).toList(),
                  ),
                  const SizedBox(height: 12),
                  // Chinese definition
                  Text(item.sense.zhDef,
                      style: TextStyle(fontSize: 22, fontWeight: AppTheme.weightSemiBold, color: fg, height: 1.3)),
                  if (item.sense.enDef?.isNotEmpty ?? false) ...[
                    const SizedBox(height: 8),
                    Text(item.sense.enDef!,
                        style: TextStyle(fontFamily: AppTheme.fontFamilyEnglish,
                            fontSize: 13, color: AppTheme.gray500, fontStyle: FontStyle.italic, height: 1.5)),
                  ],
                  // Length hint
                  const SizedBox(height: 16),
                  Text('${item.word.lemma.length} 個字母',
                      style: TextStyle(fontSize: 12, color: AppTheme.gray400)),
                ]),
              ),

              const SizedBox(height: 24),

              // Input field
              TextField(
                controller: _ctrl,
                focusNode: _focus,
                enabled: state.isCorrect == null,
                textInputAction: TextInputAction.done,
                autocorrect: false,
                enableSuggestions: false,
                textCapitalization: TextCapitalization.none,
                onSubmitted: (_) => _submit(),
                style: TextStyle(
                  fontFamily: AppTheme.fontFamilyEnglish,
                  fontSize: 24, fontWeight: AppTheme.weightSemiBold,
                  color: state.isCorrect == null
                      ? fg
                      : (state.isCorrect! ? const Color(0xFF2D7A2D) : const Color(0xFFB84040)),
                  letterSpacing: 1.5,
                ),
                decoration: InputDecoration(
                  hintText: '在此輸入英文單字…',
                  hintStyle: TextStyle(
                    fontFamily: AppTheme.fontFamilyEnglish,
                    fontSize: 18, color: AppTheme.gray400, fontWeight: AppTheme.weightRegular,
                  ),
                  filled: true,
                  fillColor: isDark ? AppTheme.gray900 : AppTheme.pureWhite,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    borderSide: BorderSide(color: isDark ? AppTheme.gray600 : AppTheme.gray800, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  suffixIcon: state.isCorrect == null
                      ? IconButton(
                          icon: Icon(Icons.send_rounded, size: 20, color: isDark ? AppTheme.gray400 : AppTheme.gray600),
                          onPressed: _submit,
                        )
                      : Icon(
                          state.isCorrect! ? Icons.check_circle_rounded : Icons.cancel_rounded,
                          color: state.isCorrect! ? const Color(0xFF2D7A2D) : const Color(0xFFB84040),
                        ),
                ),
              ),

              // Feedback
              if (state.isCorrect != null) ...[
                const SizedBox(height: 20),
                _FeedbackCard(
                  isCorrect: state.isCorrect!,
                  correctAnswer: item.word.lemma,
                  userInput: state.userInput ?? '',
                  isDark: isDark,
                ),
              ],

              const SizedBox(height: 24),
            ]),
          ),
        ),

        // Bottom buttons
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          child: state.isCorrect == null
              ? SizedBox(
                  width: double.infinity, height: 52,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? AppTheme.pureWhite : AppTheme.pureBlack,
                      foregroundColor: isDark ? AppTheme.pureBlack : AppTheme.pureWhite,
                      elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
                    ),
                    child: const Text('確認', style: TextStyle(fontSize: 15, fontWeight: AppTheme.weightSemiBold)),
                  ),
                )
              : SizedBox(
                  width: double.infinity, height: 52,
                  child: ElevatedButton(
                    onPressed: _next,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? AppTheme.pureWhite : AppTheme.pureBlack,
                      foregroundColor: isDark ? AppTheme.pureBlack : AppTheme.pureWhite,
                      elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
                    ),
                    child: Text(
                      state.currentIndex + 1 >= state.items.length ? '查看結果' : '下一個',
                      style: const TextStyle(fontSize: 15, fontWeight: AppTheme.weightSemiBold),
                    ),
                  ),
                ),
        ),
      ]),
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  final bool isCorrect;
  final String correctAnswer, userInput;
  final bool isDark;

  const _FeedbackCard({required this.isCorrect, required this.correctAnswer, required this.userInput, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final correct = isCorrect;
    final bg = correct
        ? (isDark ? const Color(0xFF1A2E1A) : const Color(0xFFF0FAF0))
        : (isDark ? const Color(0xFF2E1A1A) : const Color(0xFFFAF0F0));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: correct
          ? Row(children: [
              const Icon(Icons.check_circle_rounded, size: 20, color: Color(0xFF2D7A2D)),
              const SizedBox(width: 10),
              Text('答對了！', style: TextStyle(
                  fontSize: 15, fontWeight: AppTheme.weightSemiBold, color: const Color(0xFF2D7A2D))),
            ])
          : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.cancel_rounded, size: 20, color: Color(0xFFB84040)),
                const SizedBox(width: 10),
                Text('答錯了', style: TextStyle(
                    fontSize: 15, fontWeight: AppTheme.weightSemiBold, color: const Color(0xFFB84040))),
              ]),
              const SizedBox(height: 8),
              Text('正確拼法：',
                  style: TextStyle(fontSize: 12, color: isDark ? AppTheme.gray400 : AppTheme.gray600)),
              const SizedBox(height: 4),
              Text(correctAnswer,
                  style: TextStyle(
                      fontFamily: AppTheme.fontFamilyEnglish,
                      fontSize: 20, fontWeight: AppTheme.weightBold,
                      color: const Color(0xFF2D7A2D), letterSpacing: 1)),
            ]),
    );
  }
}
