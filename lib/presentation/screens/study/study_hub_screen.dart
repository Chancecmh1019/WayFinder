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

  // 導航到學習頁面並在返回時刷新數據
  Future<void> _navigateAndRefresh(BuildContext context, WidgetRef ref, Widget screen) async {
    await Navigator.of(context).push(_fade(screen));
    // 返回後觸發刷新
    ref.read(statsRefreshTriggerProvider.notifier).state++;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final due = ref.watch(dueCountProvider);
    final dailyGoal = ref.watch(dailyGoalProvider);
    final fsrs = ref.watch(fsrsServiceProvider);
    final remaining = fsrs.isInitialized()
        ? fsrs.getRemainingNewCardsToday(dailyGoal)
        : dailyGoal;
    final weak = ref.watch(weakWordsProvider);
    final todayNew = ref.watch(todayStudiedProvider);
    final contextualWordCount = ref.watch(contextualWordCountProvider);

    final bg   = isDark ? AppTheme.pureBlack   : AppTheme.offWhite;
    final card = isDark ? AppTheme.gray900      : AppTheme.pureWhite;
    final fg   = isDark ? AppTheme.pureWhite    : AppTheme.pureBlack;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── 標題區 ─────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('學習', style: Theme.of(context).textTheme.displaySmall),
                  const SizedBox(height: 5),
                  Text('FSRS 間隔重複 · 科學記憶法',
                      style: TextStyle(fontSize: 14, color: AppTheme.gray500)),
                ]),
              ),
            ),

            // ── 今日摘要橫幅 ────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: _TodayBanner(
                  due: due, remaining: remaining, todayNew: todayNew,
                  dailyGoal: dailyGoal, isDark: isDark, card: card, fg: fg,
                ),
              ),
            ),

            // ── 學習模式區 ─────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              sliver: SliverList(delegate: SliverChildListDelegate([
                _SectionTitle('每日必做', isDark),
                const SizedBox(height: 10),

                // 翻牌記憶（主要）
                _PrimaryCard(
                  icon: Icons.flip_to_front_rounded,
                  title: '翻牌記憶',
                  subtitle: 'FSRS 自適應間隔',
                  desc: '翻牌後誠實自評難度，AI 依你的記憶曲線計算最佳複習時機',
                  badge: due > 0 ? '$due 待複習' : (remaining > 0 ? '$remaining 個新詞' : '今日完成'),
                  isDark: isDark, card: card, fg: fg,
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    ref.read(studySessionProvider.notifier).startSession();
                    _navigateAndRefresh(context, ref, const FlashcardScreen());
                  },
                ),

                const SizedBox(height: 24),
                _SectionTitle('情境強化 · 今日+過去單字 ($contextualWordCount)', isDark),
                const SizedBox(height: 10),

                // 2x2 格 - 新的情境強化功能
                Row(children: [
                  Expanded(child: _SmallCard(
                    icon: Icons.edit_outlined,
                    title: '情境填空',
                    desc: '句子中選單字',
                    isDark: isDark, card: card, fg: fg,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _navigateAndRefresh(context, ref, const ContextualClozeScreen());
                    },
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _SmallCard(
                    icon: Icons.link_rounded,
                    title: '情境配對',
                    desc: '單字配定義',
                    isDark: isDark, card: card, fg: fg,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _navigateAndRefresh(context, ref, const ContextualMatchingScreen());
                    },
                  )),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _SmallCard(
                    icon: Icons.create_rounded,
                    title: '情境造句',
                    desc: '用單字造句',
                    isDark: isDark, card: card, fg: fg,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _navigateAndRefresh(context, ref, const ContextualSentenceScreen());
                    },
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _SmallCard(
                    icon: Icons.headphones_rounded,
                    title: '情境聽力',
                    desc: '聽音選單字',
                    isDark: isDark, card: card, fg: fg,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _navigateAndRefresh(context, ref, const ContextualListeningScreen());
                    },
                  )),
                ]),

                if (weak.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _SectionTitle('弱點攻克', isDark),
                  const SizedBox(height: 10),
                  _WeakWordsCard(weakWords: weak, isDark: isDark, card: card, fg: fg, ref: ref),
                ],

                const SizedBox(height: 32),
              ])),
            ),
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

// ── Today Banner ─────────────────────────────────────────────

class _TodayBanner extends StatelessWidget {
  final int due, remaining, todayNew, dailyGoal;
  final bool isDark;
  final Color card, fg;

  const _TodayBanner({
    required this.due, required this.remaining, required this.todayNew,
    required this.dailyGoal, required this.isDark, required this.card, required this.fg,
  });

  @override
  Widget build(BuildContext context) {
    final goalDone = todayNew >= dailyGoal && due == 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: isDark ? null : AppTheme.cardShadow,
      ),
      child: goalDone
          ? Row(children: [
              const Icon(Icons.check_circle_outline_rounded, size: 20, color: Color(0xFF666666)),
              const SizedBox(width: 10),
              Text('今日學習已完成', style: TextStyle(fontSize: 15, fontWeight: AppTheme.weightSemiBold, color: fg)),
              const Spacer(),
              Text('繼續練習', style: TextStyle(fontSize: 13, color: AppTheme.gray500)),
            ])
          : Row(
              children: [
                _BannerStat('$due', '待複習', isDark: isDark, fg: fg),
                _Divider(isDark: isDark),
                _BannerStat('$remaining', '新詞額度', isDark: isDark, fg: fg),
                _Divider(isDark: isDark),
                _BannerStat('$todayNew / $dailyGoal', '今日完成', isDark: isDark, fg: fg),
              ],
            ),
    );
  }
}

class _BannerStat extends StatelessWidget {
  final String value, label;
  final bool isDark;
  final Color fg;
  const _BannerStat(this.value, this.label, {required this.isDark, required this.fg});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Text(value, style: TextStyle(fontSize: 17, fontWeight: AppTheme.weightBold, color: fg)),
      const SizedBox(height: 2),
      Text(label, style: TextStyle(fontSize: 11, color: AppTheme.gray500)),
    ]),
  );
}

class _Divider extends StatelessWidget {
  final bool isDark;
  const _Divider({required this.isDark});
  @override
  Widget build(BuildContext context) => Container(
    width: 1, height: 32,
    color: isDark ? AppTheme.gray800 : AppTheme.gray100,
    margin: const EdgeInsets.symmetric(horizontal: 4),
  );
}

// ── Section Title ─────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  final bool isDark;
  const _SectionTitle(this.title, this.isDark);

  @override
  Widget build(BuildContext context) => Text(
    title,
    style: TextStyle(
      fontSize: 11, fontWeight: FontWeight.w700,
      color: isDark ? AppTheme.gray500 : AppTheme.gray600,
      letterSpacing: 1.0,
    ),
  );
}

// ── Primary Card ─────────────────────────────────────────────

class _PrimaryCard extends StatelessWidget {
  final IconData icon;
  final String title, subtitle, desc, badge;
  final bool isDark;
  final Color card, fg;
  final VoidCallback onTap;

  const _PrimaryCard({
    required this.icon, required this.title, required this.subtitle,
    required this.desc, required this.badge,
    required this.isDark, required this.card, required this.fg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          boxShadow: isDark ? null : AppTheme.cardShadow,
        ),
        child: Row(
          children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(title, style: TextStyle(fontSize: 17, fontWeight: AppTheme.weightSemiBold, color: fg)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.gray800 : AppTheme.gray100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(badge, style: TextStyle(fontSize: 11, color: isDark ? AppTheme.gray300 : AppTheme.gray700, fontWeight: AppTheme.weightMedium)),
                ),
              ]),
              const SizedBox(height: 3),
              Text(subtitle, style: TextStyle(fontSize: 12, color: AppTheme.gray500)),
              const SizedBox(height: 10),
              Text(desc, style: TextStyle(fontSize: 13, color: isDark ? AppTheme.gray400 : AppTheme.gray600, height: 1.5)),
            ])),
            const SizedBox(width: 16),
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: isDark ? AppTheme.gray800 : AppTheme.gray100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 22, color: isDark ? AppTheme.gray300 : AppTheme.gray700),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Small Card ─────────────────────────────────────────────

class _SmallCard extends StatelessWidget {
  final IconData icon;
  final String title, desc;
  final bool isDark;
  final Color card, fg;
  final VoidCallback onTap;

  const _SmallCard({
    required this.icon, required this.title, required this.desc,
    required this.isDark, required this.card, required this.fg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          boxShadow: isDark ? null : AppTheme.subtleShadow,
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 20, color: isDark ? AppTheme.gray400 : AppTheme.gray600),
          const SizedBox(height: 12),
          Text(title, style: TextStyle(fontSize: 14, fontWeight: AppTheme.weightSemiBold, color: fg)),
          const SizedBox(height: 3),
          Text(desc, style: TextStyle(fontSize: 12, color: AppTheme.gray500)),
        ]),
      ),
    );
  }
}

// ── Weak Words Card ───────────────────────────────────────

class _WeakWordsCard extends StatelessWidget {
  final List<String> weakWords;
  final bool isDark;
  final Color card, fg;
  final WidgetRef ref;

  const _WeakWordsCard({
    required this.weakWords, required this.isDark,
    required this.card, required this.fg, required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        ref.read(studySessionProvider.notifier).startSession(customList: weakWords);
        Navigator.of(context).push(PageRouteBuilder(
          pageBuilder: (_, __, ___) => const FlashcardScreen(),
          transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
          transitionDuration: const Duration(milliseconds: 200),
        )).then((_) {
          // 返回後觸發刷新
          ref.read(statsRefreshTriggerProvider.notifier).state++;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(color: isDark ? AppTheme.gray800 : AppTheme.gray200),
        ),
        child: Row(children: [
          Icon(Icons.trending_up_rounded, size: 20, color: isDark ? AppTheme.gray400 : AppTheme.gray600),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${weakWords.length} 個弱點單字',
                style: TextStyle(fontSize: 14, fontWeight: AppTheme.weightSemiBold, color: fg)),
            const SizedBox(height: 3),
            Text(weakWords.take(4).join('、'), style: TextStyle(fontSize: 12, color: AppTheme.gray500)),
          ])),
          Icon(Icons.chevron_right, size: 20, color: AppTheme.gray400),
        ]),
      ),
    );
  }
}
