import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../providers/study_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/contextual_enhancement_provider.dart';
import '../../../core/providers/app_providers.dart';
import 'flashcard_screen.dart';
import 'contextual_cloze_screen.dart';
import 'contextual_matching_screen.dart';
import 'contextual_sentence_screen.dart';
import 'contextual_listening_screen.dart';

class StudyHubScreen extends ConsumerWidget {
  const StudyHubScreen({super.key});

  Future<void> _go(BuildContext context, WidgetRef ref, Widget screen) async {
    await Navigator.of(context).push(_fade(screen));
    ref.read(statsRefreshTriggerProvider.notifier).state++;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg   = isDark ? AppTheme.pureBlack : AppTheme.offWhite;
    final card = isDark ? AppTheme.gray900 : AppTheme.pureWhite;
    final fg   = isDark ? AppTheme.pureWhite : AppTheme.pureBlack;

    final due       = ref.watch(dueCountProvider);
    final dailyGoal = ref.watch(dailyGoalProvider);
    final fsrs      = ref.watch(fsrsServiceProvider);
    final remaining = fsrs.isInitialized() ? fsrs.getRemainingNewCardsToday(dailyGoal) : dailyGoal;
    final todayNew  = ref.watch(todayStudiedProvider);
    final ctxCount  = ref.watch(contextualWordCountProvider);
    final weak      = ref.watch(weakWordsProvider);

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
                Text('STUDY', style: TextStyle(fontSize: 11, letterSpacing: 3,
                    color: isDark ? AppTheme.gray600 : AppTheme.gray400, fontWeight: AppTheme.weightSemiBold)),
                const SizedBox(height: 6),
                Text('學習', style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    letterSpacing: -0.5, fontFamily: AppTheme.fontFamilyChinese)),
              ]),
            )),

            // ── 今日概況 ───────────────────────────────────────────
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: _TodaySummary(due: due, remaining: remaining, todayNew: todayNew,
                  dailyGoal: dailyGoal, isDark: isDark, card: card, fg: fg),
            )),

            // ── 每日必做 ───────────────────────────────────────────
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _SectionLabel('每日必做', isDark),
                const SizedBox(height: 12),
                _PrimaryCard(
                  isDark: isDark, card: card, fg: fg,
                  icon: Icons.flip_to_front_rounded,
                  title: '翻牌記憶',
                  subtitle: 'FSRS 自適應間隔',
                  description: '翻開卡片後誠實評分，AI 依記憶曲線計算最佳複習時機',
                  badge: due > 0 ? '$due 待複習' : (remaining > 0 ? '$remaining 個新詞' : '今日完成 ✓'),
                  badgeDone: due == 0 && remaining == 0,
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    ref.read(studySessionProvider.notifier).startSession();
                    _go(context, ref, const FlashcardScreen());
                  },
                ),
              ]),
            )),

            // ── 情境強化 ───────────────────────────────────────────
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  _SectionLabel('情境強化', isDark),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.gray800 : AppTheme.gray100,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text('$ctxCount 個單字', style: TextStyle(fontSize: 11,
                        color: isDark ? AppTheme.gray400 : AppTheme.gray600)),
                  ),
                ]),
                const SizedBox(height: 6),
                Text('使用已學過的單字進行延伸練習',
                    style: TextStyle(fontSize: 12, color: isDark ? AppTheme.gray600 : AppTheme.gray500)),
                const SizedBox(height: 12),
                GridView.count(
                  shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10,
                  childAspectRatio: 1.45,
                  children: [
                    _ContextCard(icon: Icons.edit_note_rounded, title: '情境填空',
                        desc: '句中選單字', isDark: isDark, card: card, fg: fg, enabled: ctxCount >= kMinContextualWords,
                        onTap: () { HapticFeedback.lightImpact(); _go(context, ref, const ContextualClozeScreen()); }),
                    _ContextCard(icon: Icons.link_rounded, title: '情境配對',
                        desc: '單字配中文', isDark: isDark, card: card, fg: fg, enabled: ctxCount >= kMinContextualWords,
                        onTap: () { HapticFeedback.lightImpact(); _go(context, ref, const ContextualMatchingScreen()); }),
                    _ContextCard(icon: Icons.sort_by_alpha_rounded, title: '情境造句',
                        desc: '排列成句子', isDark: isDark, card: card, fg: fg, enabled: ctxCount >= kMinContextualWords,
                        onTap: () { HapticFeedback.lightImpact(); _go(context, ref, const ContextualSentenceScreen()); }),
                    _ContextCard(icon: Icons.headphones_rounded, title: '情境聽力',
                        desc: '聽音選單字', isDark: isDark, card: card, fg: fg, enabled: ctxCount >= kMinContextualWords,
                        onTap: () { HapticFeedback.lightImpact(); _go(context, ref, const ContextualListeningScreen()); }),
                  ],
                ),
                if (ctxCount < kMinContextualWords)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text('再學 ${kMinContextualWords - ctxCount} 個單字即可解鎖情境練習',
                        style: TextStyle(fontSize: 11, color: isDark ? AppTheme.gray600 : AppTheme.gray500)),
                  ),
              ]),
            )),

            // ── 弱點攻克 ───────────────────────────────────────────
            if (weak.isNotEmpty)
              SliverToBoxAdapter(child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _SectionLabel('弱點攻克', isDark),
                  const SizedBox(height: 12),
                  _WeakCard(words: weak, isDark: isDark, card: card, fg: fg,
                    onTap: () { HapticFeedback.lightImpact(); _go(context, ref, FlashcardScreen(customWordList: weak.take(10).toList())); }),
                ]),
              )),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  PageRoute _fade(Widget w) => PageRouteBuilder(
    pageBuilder: (_, __, ___) => w,
    transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
    transitionDuration: const Duration(milliseconds: 200),
  );
}

// ── Section Label ────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label; final bool isDark;
  const _SectionLabel(this.label, this.isDark);
  @override
  Widget build(BuildContext context) => Text(label, style: TextStyle(
    fontSize: 12, letterSpacing: 1, fontWeight: AppTheme.weightSemiBold,
    color: isDark ? AppTheme.gray500 : AppTheme.gray500,
  ));
}

// ── Today Summary ─────────────────────────────────────────────

class _TodaySummary extends StatelessWidget {
  final int due, remaining, todayNew, dailyGoal;
  final bool isDark; final Color card, fg;
  const _TodaySummary({required this.due, required this.remaining, required this.todayNew,
    required this.dailyGoal, required this.isDark, required this.card, required this.fg});

  @override
  Widget build(BuildContext context) {
    final done = todayNew >= dailyGoal && due == 0;
    final pct = (todayNew / dailyGoal).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(color: isDark ? AppTheme.gray800 : AppTheme.gray100)),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(done ? '今日已完成' : '$todayNew / $dailyGoal 個新單字',
              style: TextStyle(fontSize: 14, fontWeight: AppTheme.weightSemiBold, color: fg)),
          const SizedBox(height: 8),
          ClipRRect(borderRadius: BorderRadius.circular(999), child: LinearProgressIndicator(
            value: pct, minHeight: 3,
            backgroundColor: isDark ? AppTheme.gray800 : AppTheme.gray100,
            valueColor: AlwaysStoppedAnimation(isDark ? AppTheme.pureWhite : AppTheme.pureBlack),
          )),
        ])),
        if (due > 0) ...[
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.gray800 : AppTheme.gray100,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text('複習 $due', style: TextStyle(fontSize: 12, fontWeight: AppTheme.weightSemiBold,
                color: isDark ? AppTheme.gray300 : AppTheme.gray700)),
          ),
        ],
      ]),
    );
  }
}

// ── Primary Card ──────────────────────────────────────────────

class _PrimaryCard extends StatelessWidget {
  final bool isDark; final Color card, fg;
  final IconData icon;
  final String title, subtitle, description, badge;
  final bool badgeDone;
  final VoidCallback onTap;
  const _PrimaryCard({required this.isDark, required this.card, required this.fg,
    required this.icon, required this.title, required this.subtitle,
    required this.description, required this.badge, required this.onTap, required this.badgeDone});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: card, borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(color: isDark ? AppTheme.gray800 : AppTheme.gray100),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: isDark ? AppTheme.gray800 : AppTheme.gray100,
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 20, color: fg),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: TextStyle(fontSize: 16, fontWeight: AppTheme.weightSemiBold, color: fg)),
              Text(subtitle, style: TextStyle(fontSize: 12, color: AppTheme.gray500)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: badgeDone
                    ? (isDark ? AppTheme.gray800 : AppTheme.gray100)
                    : (isDark ? AppTheme.pureWhite : AppTheme.pureBlack),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(badge, style: TextStyle(fontSize: 11, fontWeight: AppTheme.weightSemiBold,
                  color: badgeDone ? AppTheme.gray500 : (isDark ? AppTheme.pureBlack : AppTheme.pureWhite))),
            ),
          ]),
          const SizedBox(height: 14),
          Text(description, style: TextStyle(fontSize: 13, color: AppTheme.gray500, height: 1.5)),
        ]),
      ),
    );
  }
}

// ── Context Card ──────────────────────────────────────────────

class _ContextCard extends StatelessWidget {
  final bool isDark, enabled; final Color card, fg;
  final IconData icon; final String title, desc; final VoidCallback onTap;
  const _ContextCard({required this.isDark, required this.card, required this.fg,
    required this.icon, required this.title, required this.desc,
    required this.onTap, required this.enabled});

  @override
  Widget build(BuildContext context) {
    final opacity = enabled ? 1.0 : 0.4;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: opacity,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              border: Border.all(color: isDark ? AppTheme.gray800 : AppTheme.gray100)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Icon(icon, size: 22, color: isDark ? AppTheme.gray300 : AppTheme.gray700),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: TextStyle(fontSize: 13, fontWeight: AppTheme.weightSemiBold, color: fg)),
              Text(desc, style: TextStyle(fontSize: 11, color: AppTheme.gray500)),
            ]),
          ]),
        ),
      ),
    );
  }
}

// ── Weak Card ────────────────────────────────────────────────

class _WeakCard extends StatelessWidget {
  final List<String> words;
  final bool isDark; final Color card, fg;
  final VoidCallback onTap;
  const _WeakCard({required this.words, required this.isDark, required this.card, required this.fg, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(color: isDark ? AppTheme.gray800 : AppTheme.gray100)),
        child: Row(children: [
          Expanded(child: Wrap(spacing: 6, runSpacing: 6,
            children: words.take(6).map((w) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.gray800 : AppTheme.gray100,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(w, style: TextStyle(fontSize: 12, color: fg)),
            )).toList(),
          )),
          const SizedBox(width: 12),
          Icon(Icons.chevron_right_rounded, color: AppTheme.gray500, size: 20),
        ]),
      ),
    );
  }
}
