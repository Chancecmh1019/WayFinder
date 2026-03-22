import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../providers/study_provider.dart';
import '../../../domain/services/fsrs_algorithm.dart';
import 'session_complete_screen.dart';

class FlashcardScreen extends ConsumerStatefulWidget {
  /// 學習模式 — 外部僅傳入模式，session 在此啟動（避免雙重呼叫）
  final SessionMode mode;
  final List<String>? customWordList;

  const FlashcardScreen({
    super.key,
    this.mode = SessionMode.daily,
    this.customWordList,
  });

  @override
  ConsumerState<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends ConsumerState<FlashcardScreen>
    with TickerProviderStateMixin {
  late final AnimationController _flipCtrl;
  late final Animation<double> _flipAnim;
  late final AnimationController _slideCtrl;
  late final Animation<Offset> _slideAnim;
  bool _sessionStarted = false;

  @override
  void initState() {
    super.initState();
    _flipCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 380));
    _flipAnim = CurvedAnimation(parent: _flipCtrl, curve: Curves.easeInOutCubic);

    _slideCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
    _slideAnim = Tween<Offset>(begin: const Offset(0.06, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));
    // ★ 初始值設為 1.0（動畫終點 = Offset.zero），
    //   避免第一張卡片停在 begin 偏右位置
    _slideCtrl.value = 1.0;

    // ★ 唯一的 startSession 呼叫點 — 確保只初始化一次
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_sessionStarted) return;
      _sessionStarted = true;
      ref.read(studySessionProvider.notifier).startSession(
        mode: widget.mode,
        customList: widget.customWordList,
      );
    });
  }

  @override
  void dispose() {
    _flipCtrl.dispose();
    _slideCtrl.dispose();
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
    _slideCtrl.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final state  = ref.watch(studySessionProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg     = isDark ? AppTheme.pureBlack : AppTheme.offWhite;

    // 載入中
    if (state.isLoading) {
      return Scaffold(
        backgroundColor: bg,
        body: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            SizedBox(
              width: 24, height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: isDark ? AppTheme.gray500 : AppTheme.gray400,
              ),
            ),
            const SizedBox(height: 16),
            Text('準備學習內容...',
                style: TextStyle(fontSize: 14, color: AppTheme.gray500)),
          ]),
        ),
      );
    }

    // 完成 → 跳至結算頁
    if (state.isComplete) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(PageRouteBuilder(
          pageBuilder: (_, __, ___) => SessionCompleteScreen(
            correctCount: state.correctCount,
            totalCount: state.totalSeen,
            mode: StudyMode.flashcard,
            sessionMode: state.mode,
          ),
          transitionsBuilder: (_, a, __, c) =>
              FadeTransition(opacity: a, child: c),
          transitionDuration: const Duration(milliseconds: 280),
        ));
      });
      return Scaffold(backgroundColor: bg, body: const SizedBox.shrink());
    }

    final item = state.currentItem;
    if (item == null) {
      return Scaffold(
        backgroundColor: bg,
        body: const Center(child: CircularProgressIndicator(strokeWidth: 1.5)),
      );
    }

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(children: [
          // ── Top Bar ─────────────────────────────────────────
          _TopBar(state: state, isDark: isDark, onClose: () => Navigator.pop(context)),

          // ── Card ────────────────────────────────────────────
          Expanded(
            child: SlideTransition(
              position: _slideAnim,
              child: GestureDetector(
                onTap: _flip,
                child: AnimatedBuilder(
                  animation: _flipAnim,
                  builder: (context, _) {
                    final angle = _flipAnim.value * math.pi;
                    final showBack = angle > math.pi / 2;
                    return Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateY(angle),
                      child: showBack
                          ? Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.identity()..rotateY(math.pi),
                              child: _CardBack(item: item, isDark: isDark),
                            )
                          : _CardFront(item: item, isDark: isDark),
                    );
                  },
                ),
              ),
            ),
          ),

          // ── Bottom Area ──────────────────────────────────────
          if (!state.isFlipped)
            _FlipHint(isDark: isDark)
          else
            _RatingBar(
              onRate: _rate,
              isDark: isDark,
              intervals: state.nextIntervals,
            ),

          const SizedBox(height: 8),
        ]),
      ),
    );
  }
}

// ── Top Bar ───────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final FlashcardSessionState state;
  final bool isDark;
  final VoidCallback onClose;

  const _TopBar({required this.state, required this.isDark, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final current = state.currentIndex + 1;
    final total   = state.queue.length;
    final pct     = state.progress;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Column(children: [
        Row(children: [
          GestureDetector(
            onTap: onClose,
            child: Icon(Icons.close_rounded, size: 22,
                color: isDark ? AppTheme.gray500 : AppTheme.gray600),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: pct, minHeight: 3,
                backgroundColor: isDark ? AppTheme.gray800 : AppTheme.gray100,
                valueColor: AlwaysStoppedAnimation(
                    isDark ? AppTheme.pureWhite : AppTheme.pureBlack),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text('$current / $total',
              style: TextStyle(fontSize: 13, color: AppTheme.gray500,
                  fontWeight: AppTheme.weightMedium)),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          const SizedBox(width: 38),
          if (state.newCount > 0)
            _Tag('新詞 ${state.newCount}', isDark: isDark),
          if (state.newCount > 0 && state.reviewCount > 0)
            const SizedBox(width: 6),
          if (state.reviewCount > 0)
            _Tag('複習 ${state.reviewCount}', isDark: isDark),
        ]),
      ]),
    );
  }
}

// ── Card Front ───────────────────────────────────────────────

class _CardFront extends StatelessWidget {
  final StudyItem item;
  final bool isDark;
  const _CardFront({required this.item, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final card = isDark ? AppTheme.gray900 : AppTheme.pureWhite;
    final fg   = isDark ? AppTheme.pureWhite : AppTheme.pureBlack;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
          border: Border.all(
              color: isDark ? AppTheme.gray800 : AppTheme.gray100),
          boxShadow: isDark ? null : AppTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tags
            Row(children: [
              if (item.isPhrase) _Tag('片語', isDark: isDark, solid: true),
              if (item.isNew) ...[
                if (item.isPhrase) const SizedBox(width: 6),
                _Tag('新詞', isDark: isDark),
              ],
            ]),
            const Spacer(),
            // Word
            Text(item.lemma, style: TextStyle(
              fontFamily: AppTheme.fontFamilyEnglish,
              fontSize: 38, fontWeight: FontWeight.w700,
              color: fg, letterSpacing: -1, height: 1.1,
            )),
            if (item.word.pos.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(item.word.pos.take(2).join(' · '),
                  style: TextStyle(fontSize: 13, color: AppTheme.gray500,
                      fontStyle: FontStyle.italic)),
            ],
            const Spacer(),
            Center(
              child: Text('點擊翻牌',
                  style: TextStyle(fontSize: 13, color: AppTheme.gray500)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Card Back ────────────────────────────────────────────────

class _CardBack extends StatelessWidget {
  final StudyItem item;
  final bool isDark;
  const _CardBack({required this.item, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final card = isDark ? AppTheme.gray900 : AppTheme.pureWhite;
    final fg   = isDark ? AppTheme.pureWhite : AppTheme.pureBlack;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
          border: Border.all(
              color: isDark ? AppTheme.gray800 : AppTheme.gray100),
          boxShadow: isDark ? null : AppTheme.cardShadow,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          physics: const BouncingScrollPhysics(),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.lemma, style: TextStyle(
              fontFamily: AppTheme.fontFamilyEnglish,
              fontSize: 24, fontWeight: AppTheme.weightBold,
              color: fg, letterSpacing: -0.5,
            )),
            if (item.word.pos.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(item.word.pos.take(2).join(' · '),
                  style: TextStyle(fontSize: 12, color: AppTheme.gray500,
                      fontStyle: FontStyle.italic)),
            ],
            const SizedBox(height: 16),
            Divider(color: isDark ? AppTheme.gray800 : AppTheme.gray100, height: 1),
            const SizedBox(height: 16),
            // Definitions
            ...item.word.senses.take(3).map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (s.pos.isNotEmpty)
                  Text(s.pos, style: TextStyle(
                      fontSize: 10, letterSpacing: 0.5,
                      color: AppTheme.gray500, fontWeight: AppTheme.weightMedium)),
                const SizedBox(height: 3),
                Text(s.zhDef, style: TextStyle(
                    fontSize: 20, fontWeight: AppTheme.weightSemiBold,
                    color: fg, height: 1.3)),
                if (s.enDef != null && s.enDef!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(s.enDef!, style: TextStyle(
                      fontFamily: AppTheme.fontFamilyEnglish,
                      fontSize: 13, color: AppTheme.gray500, height: 1.4),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
                // Example sentence
                if (s.examples.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.gray850 : AppTheme.gray50,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(s.examples.first.text, style: TextStyle(
                          fontFamily: AppTheme.fontFamilyEnglish,
                          fontSize: 13, color: fg, height: 1.5)),
                      if (s.examples.first.translation != null && s.examples.first.translation!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(s.examples.first.translation!, style: TextStyle(
                            fontSize: 12, color: AppTheme.gray500, height: 1.4)),
                      ],
                    ]),
                  ),
                ],
              ]),
            )),
            const SizedBox(height: 8),
          ]),
        ),
      ),
    );
  }
}

// ── Flip Hint ─────────────────────────────────────────────────

class _FlipHint extends StatelessWidget {
  final bool isDark;
  const _FlipHint({required this.isDark});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 16),
    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.touch_app_outlined, size: 14, color: AppTheme.gray500),
      const SizedBox(width: 6),
      Text('點擊卡片查看答案',
          style: TextStyle(fontSize: 13, color: AppTheme.gray500)),
    ]),
  );
}

// ── Rating Bar ────────────────────────────────────────────────

class _RatingBar extends StatelessWidget {
  final Future<void> Function(FSRSRating) onRate;
  final bool isDark;
  final SchedulingInfo? intervals;
  const _RatingBar({required this.onRate, required this.isDark, this.intervals});

  String _intervalLabel(int days) {
    if (days == 0) return '1 分鐘';
    if (days < 30) return '$days 天';
    if (days < 365) return '${(days / 30).round()} 月';
    return '${(days / 365 * 10).round() / 10} 年';
  }

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppTheme.gray900 : AppTheme.pureWhite;
    final ratings = [
      (FSRSRating.again, '忘記', intervals?.again.scheduledDays),
      (FSRSRating.hard,  '困難', intervals?.hard.scheduledDays),
      (FSRSRating.good,  '記得', intervals?.good.scheduledDays),
      (FSRSRating.easy,  '輕鬆', intervals?.easy.scheduledDays),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Row(
        children: ratings.map((r) {
          final (rating, label, days) = r;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: _RateButton(
                label: label,
                subtitle: days != null ? _intervalLabel(days) : null,
                onTap: () => onRate(rating),
                isDark: isDark, bg: bg,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _RateButton extends StatelessWidget {
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  final bool isDark;
  final Color bg;
  const _RateButton({
    required this.label, this.subtitle, required this.onTap,
    required this.isDark, required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    final fg = isDark ? AppTheme.pureWhite : AppTheme.pureBlack;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(color: isDark ? AppTheme.gray800 : AppTheme.gray100),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(label, style: TextStyle(
              fontSize: 14, fontWeight: AppTheme.weightSemiBold, color: fg)),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle!, style: TextStyle(fontSize: 10, color: AppTheme.gray500)),
          ],
        ]),
      ),
    );
  }
}

// ── Tag ───────────────────────────────────────────────────────

class _Tag extends StatelessWidget {
  final String text;
  final bool isDark;
  final bool solid;
  const _Tag(this.text, {required this.isDark, this.solid = false});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: solid
          ? (isDark ? AppTheme.pureWhite : AppTheme.pureBlack)
          : (isDark ? AppTheme.gray800 : AppTheme.gray100),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(text, style: TextStyle(
        fontSize: 11, fontWeight: AppTheme.weightMedium,
        color: solid
            ? (isDark ? AppTheme.pureBlack : AppTheme.pureWhite)
            : (isDark ? AppTheme.gray400 : AppTheme.gray600))),
  );
}
