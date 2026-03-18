import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../providers/study_provider.dart';
import '../../../domain/services/fsrs_algorithm.dart';
import '../../../data/models/vocab_models_enhanced.dart';
import 'session_complete_screen.dart';

class FlashcardScreen extends ConsumerStatefulWidget {
  final List<String>? customWordList;
  const FlashcardScreen({super.key, this.customWordList});

  @override
  ConsumerState<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends ConsumerState<FlashcardScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flipCtrl;
  late final Animation<double> _flipAnim;

  @override
  void initState() {
    super.initState();
    _flipCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 360));
    _flipAnim = CurvedAnimation(parent: _flipCtrl, curve: Curves.easeInOutCubic);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.customWordList != null) {
        ref.read(studySessionProvider.notifier).startSession(customList: widget.customWordList);
      } else {
        ref.read(studySessionProvider.notifier).startSession();
      }
    });
  }

  @override
  void dispose() {
    _flipCtrl.dispose();
    super.dispose();
  }

  void _flip() {
    if (ref.read(studySessionProvider).isFlipped) return;
    HapticFeedback.lightImpact();
    ref.read(studySessionProvider.notifier).flip();
    _flipCtrl.forward(from: 0);
  }

  Future<void> _rate(FSRSRating r) async {
    HapticFeedback.mediumImpact();
    await ref.read(studySessionProvider.notifier).rate(r);
    _flipCtrl.reset();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(studySessionProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (state.isComplete) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(PageRouteBuilder(
          pageBuilder: (_, __, ___) => SessionCompleteScreen(
            correctCount: state.correctCount, totalCount: state.totalSeen,
            mode: StudyMode.flashcard,
          ),
          transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
        ));
      });
      return const SizedBox.shrink();
    }

    final item = state.currentItem;
    if (item == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: isDark ? AppTheme.pureBlack : AppTheme.offWhite,
      appBar: _buildAppBar(context, state, isDark),
      body: Column(
        children: [
          _ProgressBar(progress: state.progress, isDark: isDark),
          const SizedBox(height: 20),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: GestureDetector(
                onTap: state.isFlipped ? null : _flip,
                child: AnimatedBuilder(
                  animation: _flipAnim,
                  builder: (_, __) {
                    final angle = _flipAnim.value * math.pi;
                    final showFront = angle <= math.pi / 2;
                    return Transform(
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateY(angle),
                      alignment: Alignment.center,
                      child: showFront
                          ? _CardFront(item: item, isDark: isDark)
                          : Transform(
                              transform: Matrix4.rotationY(math.pi),
                              alignment: Alignment.center,
                              child: _CardBack(item: item, isDark: isDark, intervals: state.nextIntervals),
                            ),
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (!state.isFlipped)
            _FlipHint(isDark: isDark)
          else
            _RatingBar(onRate: _rate, isDark: isDark, intervals: state.nextIntervals),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context, FlashcardSessionState state, bool isDark) {
    return AppBar(
      backgroundColor: isDark ? AppTheme.pureBlack : AppTheme.offWhite,
      elevation: 0, scrolledUnderElevation: 0,
      leading: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _confirmExit(context),
        child: Icon(Icons.close_rounded, color: isDark ? AppTheme.gray400 : AppTheme.gray600),
      ),
      title: Row(mainAxisSize: MainAxisSize.min, children: [
        if (state.currentItem?.isNew ?? false)
          _Tag('新', solid: true, isDark: isDark),
        const SizedBox(width: 6),
        Text(state.currentItem?.isNew ?? false ? '新學習' : '複習',
            style: TextStyle(fontSize: 15, color: AppTheme.gray500, fontWeight: AppTheme.weightRegular)),
      ]),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 20),
          child: Text('${state.currentIndex + 1} / ${state.queue.length}',
              style: TextStyle(fontSize: 13, color: AppTheme.gray400)),
        ),
      ],
    );
  }

  void _confirmExit(BuildContext context) {
    Navigator.of(context).pop();
  }
}

// ── Progress Bar ─────────────────────────────────────────────

class _ProgressBar extends StatelessWidget {
  final double progress;
  final bool isDark;
  const _ProgressBar({required this.progress, required this.isDark});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
        value: progress, minHeight: 3,
        backgroundColor: isDark ? AppTheme.gray800 : AppTheme.gray100,
        valueColor: AlwaysStoppedAnimation(isDark ? AppTheme.pureWhite : AppTheme.pureBlack),
      ),
    ),
  );
}

// ── Card Front ───────────────────────────────────────────────

class _CardFront extends StatelessWidget {
  final StudyItem item;
  final bool isDark;
  const _CardFront({required this.item, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppTheme.gray900 : AppTheme.pureWhite;
    final levelNames = {1: 'A1', 2: 'A2', 3: 'B1', 4: 'B2', 5: 'C1', 6: 'C2'};
    final levelLabel = levelNames[item.word.level];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
        boxShadow: isDark ? null : AppTheme.cardShadow,
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tags
          Row(children: [
            if (item.isNew) _Tag('新詞', solid: true, isDark: isDark),
            if (levelLabel != null) ...[
              const SizedBox(width: 6),
              _Tag(levelLabel, isDark: isDark),
            ],
            ...item.word.pos.take(2).map((p) => Padding(
              padding: const EdgeInsets.only(left: 6),
              child: _Tag(p, isDark: isDark),
            )),
          ]),

          const Spacer(),

          // Main word
          Text(
            item.lemma,
            style: TextStyle(
              fontFamily: AppTheme.fontFamilyEnglish,
              fontSize: 44,
              fontWeight: AppTheme.weightBold,
              color: isDark ? AppTheme.pureWhite : AppTheme.pureBlack,
              letterSpacing: -1.5,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 8),

          // Phonetic
          if (item.word.pos.isNotEmpty)
            Text(
              item.word.pos.take(2).join(' · '),
              style: TextStyle(
                fontFamily: AppTheme.fontFamilyEnglish,
                fontSize: 14,
                color: AppTheme.gray500,
                fontStyle: FontStyle.italic,
              ),
            ),

          const Spacer(),

          // Root memory hint (if available)
          if (item.word.rootInfo != null && item.word.rootInfo!.memoryStrategy.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.gray800 : AppTheme.gray50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(children: [
                Icon(Icons.psychology_outlined, size: 14, color: AppTheme.gray500),
                const SizedBox(width: 8),
                Expanded(child: Text(
                  item.word.rootInfo!.memoryStrategy,
                  style: TextStyle(fontSize: 12, color: AppTheme.gray500, height: 1.4),
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                )),
              ]),
            ),

          const SizedBox(height: 16),
          Center(child: Text('點擊翻牌',
              style: TextStyle(fontSize: 12, color: AppTheme.gray400, letterSpacing: 0.5))),
        ],
      ),
    );
  }
}

// ── Card Back ────────────────────────────────────────────────

class _CardBack extends StatelessWidget {
  final StudyItem item;
  final bool isDark;
  final SchedulingInfo? intervals;
  const _CardBack({required this.item, required this.isDark, this.intervals});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppTheme.gray900 : AppTheme.pureWhite;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
        boxShadow: isDark ? null : AppTheme.cardShadow,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Word header
          Text(item.lemma,
              style: TextStyle(
                fontFamily: AppTheme.fontFamilyEnglish,
                fontSize: 28, fontWeight: AppTheme.weightBold,
                color: isDark ? AppTheme.pureWhite : AppTheme.pureBlack,
                letterSpacing: -1,
              )),

          const SizedBox(height: 16),
          _Divider(isDark: isDark),
          const SizedBox(height: 16),

          // Chinese definition
          if (item.sense.zhDef.isNotEmpty) ...[
            Text('釋義', style: TextStyle(fontSize: 11, color: AppTheme.gray500, letterSpacing: 0.8, fontWeight: AppTheme.weightSemiBold)),
            const SizedBox(height: 6),
            Text(item.sense.zhDef,
                style: TextStyle(fontSize: 20, fontWeight: AppTheme.weightSemiBold,
                    color: isDark ? AppTheme.pureWhite : AppTheme.pureBlack, height: 1.3)),
          ],

          // English definition
          if (item.sense.enDef?.isNotEmpty ?? false) ...[
            const SizedBox(height: 8),
            Text(item.sense.enDef!,
                style: TextStyle(
                    fontFamily: AppTheme.fontFamilyEnglish,
                    fontSize: 14, color: AppTheme.gray500, height: 1.5, fontStyle: FontStyle.italic)),
          ],

          const SizedBox(height: 16),

          // Example sentence from exam
          if (item.sense.examples.isNotEmpty) ...[
            Text('例句', style: TextStyle(fontSize: 11, color: AppTheme.gray500, letterSpacing: 0.8, fontWeight: AppTheme.weightSemiBold)),
            const SizedBox(height: 6),
            _ExampleBox(example: item.sense.examples.first, isDark: isDark),
          ] else if (item.sense.generatedExample?.isNotEmpty ?? false) ...[
            Text('例句', style: TextStyle(fontSize: 11, color: AppTheme.gray500, letterSpacing: 0.8, fontWeight: AppTheme.weightSemiBold)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.gray800 : AppTheme.gray50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(item.sense.generatedExample!,
                  style: TextStyle(fontFamily: AppTheme.fontFamilyEnglish,
                      fontSize: 14, color: isDark ? AppTheme.gray300 : AppTheme.gray700, height: 1.6)),
            ),
          ],

          // Root analysis
          if (item.word.rootInfo != null && item.word.rootInfo!.rootBreakdown.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('字根記憶', style: TextStyle(fontSize: 11, color: AppTheme.gray500, letterSpacing: 0.8, fontWeight: AppTheme.weightSemiBold)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.gray800 : AppTheme.gray50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(item.word.rootInfo!.rootBreakdown,
                  style: TextStyle(fontSize: 13, color: isDark ? AppTheme.gray300 : AppTheme.gray700, height: 1.5)),
            ),
          ],

          // Synonyms
          if (item.word.synonyms.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('同義詞', style: TextStyle(fontSize: 11, color: AppTheme.gray500, letterSpacing: 0.8, fontWeight: AppTheme.weightSemiBold)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6, runSpacing: 6,
              children: item.word.synonyms.take(5).map((s) => _Chip(s.toString(), isDark: isDark)).toList(),
            ),
          ],

          // Confusion notes
          if (item.word.confusionNotes.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: isDark ? AppTheme.gray700 : AppTheme.gray200),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(children: [
                Icon(Icons.compare_arrows_rounded, size: 14, color: AppTheme.gray500),
                const SizedBox(width: 8),
                Expanded(child: Text(
                  '注意與「${item.word.confusionNotes.first.confusedWith}」的區別',
                  style: TextStyle(fontSize: 12, color: AppTheme.gray500),
                )),
              ]),
            ),
          ],

          const SizedBox(height: 24),
        ]),
      ),
    );
  }
}

class _ExampleBox extends StatelessWidget {
  final ExamExampleModel example;
  final bool isDark;
  const _ExampleBox({required this.example, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.gray800 : AppTheme.gray50,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(example.text,
            style: TextStyle(
                fontFamily: AppTheme.fontFamilyEnglish,
                fontSize: 14,
                color: isDark ? AppTheme.gray200 : AppTheme.gray800,
                height: 1.6)),
        const SizedBox(height: 6),
        Text('${example.source.year} 學測',
            style: TextStyle(fontSize: 11, color: AppTheme.gray500)),
      ]),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool isDark;
  const _Chip(this.label, {required this.isDark});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: isDark ? AppTheme.gray800 : AppTheme.gray100,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(label, style: TextStyle(fontFamily: AppTheme.fontFamilyEnglish, fontSize: 12, color: AppTheme.gray600)),
  );
}

class _Divider extends StatelessWidget {
  final bool isDark;
  const _Divider({required this.isDark});
  @override
  Widget build(BuildContext context) => Container(height: 0.5, color: isDark ? AppTheme.gray800 : AppTheme.gray100);
}

// ── Flip Hint ────────────────────────────────────────────────

class _FlipHint extends StatelessWidget {
  final bool isDark;
  const _FlipHint({required this.isDark});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 32),
    child: Column(children: [
      Icon(Icons.touch_app_outlined, size: 20, color: AppTheme.gray400),
      const SizedBox(height: 6),
      Text('點擊翻牌，誠實自評記憶狀況', style: TextStyle(fontSize: 12, color: AppTheme.gray400)),
    ]),
  );
}

// ── Rating Bar ───────────────────────────────────────────────

class _RatingBar extends StatelessWidget {
  final Future<void> Function(FSRSRating) onRate;
  final bool isDark;
  final SchedulingInfo? intervals;

  const _RatingBar({required this.onRate, required this.isDark, this.intervals});

  String _label(FSRSCard? card) {
    if (card == null) return '';
    final d = card.scheduledDays;
    if (d == 0) return '${card.due.difference(DateTime.now()).inMinutes}分鐘';
    if (d == 1) return '1天';
    if (d < 7)  return '$d天';
    if (d < 30) return '${(d / 7).round()}週';
    if (d < 365) return '${(d / 30).round()}月';
    return '${(d / 365).round()}年';
  }

  @override
  Widget build(BuildContext context) {
    final ratings = [FSRSRating.again, FSRSRating.hard, FSRSRating.good, FSRSRating.easy];
    final bgs = isDark
        ? [AppTheme.gray850, AppTheme.gray800, AppTheme.gray700, AppTheme.pureWhite]
        : [AppTheme.gray50, AppTheme.gray100, AppTheme.gray800, AppTheme.pureBlack];
    final fgs = isDark
        ? [AppTheme.gray300, AppTheme.gray200, AppTheme.pureWhite, AppTheme.pureBlack]
        : [AppTheme.gray700, AppTheme.gray800, AppTheme.pureWhite, AppTheme.pureWhite];
    final cards = [intervals?.again, intervals?.hard, intervals?.good, intervals?.easy];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(children: [
        Row(children: List.generate(4, (i) => Expanded(
          child: Padding(
            padding: EdgeInsets.only(left: i > 0 ? 8 : 0),
            child: GestureDetector(
              onTap: () => onRate(ratings[i]),
              child: Container(
                height: 64,
                decoration: BoxDecoration(
                  color: bgs[i], borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(ratings[i].label,
                      style: TextStyle(fontSize: 13, fontWeight: AppTheme.weightSemiBold, color: fgs[i])),
                  const SizedBox(height: 3),
                  Text(_label(cards[i]),
                      style: TextStyle(fontSize: 10, color: fgs[i].withValues(alpha: 0.65))),
                ]),
              ),
            ),
          ),
        ))),
      ]),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final bool solid;
  final bool isDark;
  const _Tag(this.label, {this.solid = false, required this.isDark});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: solid ? (isDark ? AppTheme.pureWhite : AppTheme.pureBlack) : Colors.transparent,
      border: solid ? null : Border.all(color: isDark ? AppTheme.gray700 : AppTheme.gray200),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(label,
        style: TextStyle(
          fontSize: 11, fontWeight: AppTheme.weightSemiBold,
          color: solid ? (isDark ? AppTheme.pureBlack : AppTheme.pureWhite) : AppTheme.gray500,
        )),
  );
}
