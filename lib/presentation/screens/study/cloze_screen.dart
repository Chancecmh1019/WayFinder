import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../providers/study_provider.dart';
import 'session_complete_screen.dart';

class ClozeScreen extends ConsumerStatefulWidget {
  final List<String>? customWordList;
  const ClozeScreen({super.key, this.customWordList});

  @override
  ConsumerState<ClozeScreen> createState() => _ClozeScreenState();
}

class _ClozeScreenState extends ConsumerState<ClozeScreen> {
  final _ctrl  = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(clozeSessionProvider.notifier).start(customWordList: widget.customWordList);
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
    final state = ref.read(clozeSessionProvider);
    if (state.isCorrect != null) return;
    HapticFeedback.lightImpact();
    ref.read(clozeSessionProvider.notifier).submit(_ctrl.text);
  }

  Future<void> _next() async {
    _ctrl.clear();
    await ref.read(clozeSessionProvider.notifier).next();
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(clozeSessionProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (state.isComplete) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(PageRouteBuilder(
          pageBuilder: (_, __, ___) => SessionCompleteScreen(
            correctCount: state.correctCount, totalCount: state.items.length,
            mode: StudyMode.cloze,
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
        title: Text('考題填空',
            style: TextStyle(fontSize: 15, color: AppTheme.gray500, fontWeight: AppTheme.weightRegular)),
        actions: [
          Padding(padding: const EdgeInsets.only(right: 20),
              child: Text('${state.currentIndex + 1} / ${state.items.length}',
                  style: TextStyle(fontSize: 13, color: AppTheme.gray400))),
        ],
      ),
      body: Column(children: [
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
              Text('填入正確的英文單字', style: TextStyle(fontSize: 13, color: AppTheme.gray500)),
              const SizedBox(height: 20),

              // Sentence card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  boxShadow: isDark ? null : AppTheme.cardShadow,
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      border: Border.all(color: isDark ? AppTheme.gray700 : AppTheme.gray200),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('學測真題', style: TextStyle(fontSize: 11, color: AppTheme.gray500)),
                  ),
                  const SizedBox(height: 16),
                  _buildBlankSentence(item.sentence, state.isCorrect, isDark, fg),
                  if (state.isCorrect != null && item.sense.zhDef.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(height: 0.5, color: isDark ? AppTheme.gray800 : AppTheme.gray100),
                    const SizedBox(height: 12),
                    Text(item.sense.zhDef,
                        style: TextStyle(fontSize: 14, color: AppTheme.gray500, height: 1.4)),
                  ],
                ]),
              ),

              const SizedBox(height: 24),

              // Input
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
                  fontSize: 20, fontWeight: AppTheme.weightSemiBold,
                  color: state.isCorrect == null ? fg
                      : (state.isCorrect! ? const Color(0xFF2D7A2D) : const Color(0xFFB84040)),
                  letterSpacing: 1.2,
                ),
                decoration: InputDecoration(
                  hintText: '輸入缺少的單字…',
                  hintStyle: TextStyle(fontFamily: AppTheme.fontFamilyEnglish, fontSize: 16, color: AppTheme.gray400, fontWeight: AppTheme.weightRegular),
                  filled: true,
                  fillColor: isDark ? AppTheme.gray900 : AppTheme.pureWhite,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMedium), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      borderSide: BorderSide(color: isDark ? AppTheme.gray600 : AppTheme.gray800, width: 1.5)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  suffixIcon: state.isCorrect == null
                      ? IconButton(icon: Icon(Icons.send_rounded, size: 20, color: isDark ? AppTheme.gray400 : AppTheme.gray600), onPressed: _submit)
                      : Icon(state.isCorrect! ? Icons.check_circle_rounded : Icons.cancel_rounded,
                            color: state.isCorrect! ? const Color(0xFF2D7A2D) : const Color(0xFFB84040)),
                ),
              ),
            ]),
          ),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton(
              onPressed: state.isCorrect == null ? _submit : _next,
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? AppTheme.pureWhite : AppTheme.pureBlack,
                foregroundColor: isDark ? AppTheme.pureBlack : AppTheme.pureWhite,
                elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
              ),
              child: Text(
                state.isCorrect == null ? '確認'
                    : (state.currentIndex + 1 >= state.items.length ? '查看結果' : '下一題'),
                style: const TextStyle(fontSize: 15, fontWeight: AppTheme.weightSemiBold),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildBlankSentence(String sentence, bool? isCorrect, bool isDark, Color fg) {
    final parts = sentence.split('___');
    if (parts.length < 2) {
      return Text(sentence, style: TextStyle(fontFamily: AppTheme.fontFamilyEnglish, fontSize: 17, color: fg, height: 1.6));
    }
    return RichText(
      text: TextSpan(
        style: TextStyle(fontFamily: AppTheme.fontFamilyEnglish, fontSize: 17, color: fg, height: 1.6),
        children: [
          TextSpan(text: parts[0]),
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isCorrect == null
                    ? (isDark ? AppTheme.gray800 : AppTheme.gray100)
                    : isCorrect
                        ? const Color(0xFF2D7A2D).withValues(alpha: 0.15)
                        : const Color(0xFFB84040).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                isCorrect == null ? '  ___  ' : (ref.read(clozeSessionProvider).current?.answer ?? ''),
                style: TextStyle(
                  fontFamily: AppTheme.fontFamilyEnglish,
                  fontSize: 17,
                  fontWeight: AppTheme.weightSemiBold,
                  color: isCorrect == null
                      ? AppTheme.gray400
                      : isCorrect ? const Color(0xFF2D7A2D) : const Color(0xFFB84040),
                ),
              ),
            ),
          ),
          TextSpan(text: parts.sublist(1).join('')),
        ],
      ),
    );
  }
}
