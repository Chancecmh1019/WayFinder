import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../providers/browse_provider.dart';
import '../../../core/providers/app_providers.dart';
import '../../widgets/common/skeleton_loader.dart';
import 'word_detail_screen.dart';
import '../folders/word_folders_screen.dart';
import '../root_dictionary_screen.dart';
import '../../../core/providers/word_folder_providers.dart';
import '../../../data/models/word_folder_model.dart';
import 'phrase_detail_screen.dart';

const _levelNames = {1: 'A1', 2: 'A2', 3: 'B1', 4: 'B2', 5: 'C1', 6: 'C2'};

class BrowseScreen extends ConsumerStatefulWidget {
  const BrowseScreen({super.key});
  @override
  ConsumerState<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends ConsumerState<BrowseScreen>
    with SingleTickerProviderStateMixin {
  final _ctrl = TextEditingController();
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() {
      if (!_tab.indexIsChanging) {
        ref.read(browseFilterProvider.notifier)
            .setTab(_tab.index == 0 ? BrowseTab.words : BrowseTab.phrases);
        _ctrl.clear();
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filter = ref.watch(browseFilterProvider);

    return Scaffold(
      backgroundColor: isDark ? AppTheme.pureBlack : AppTheme.offWhite,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 8, 0),
              child: Row(children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('LIBRARY', style: TextStyle(fontSize: 11, letterSpacing: 3,
                      color: isDark ? AppTheme.gray600 : AppTheme.gray400, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('字彙庫', style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      letterSpacing: -0.5, fontFamily: AppTheme.fontFamilyChinese)),
                ]),
                const Spacer(),
                if (filter.tab == BrowseTab.words) ...[
                  IconButton(
                    icon: const Icon(Icons.book_outlined),
                    tooltip: '字根字首字典',
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const RootDictionaryScreen())),
                  ),
                  IconButton(
                    icon: Icon(Icons.filter_list_rounded,
                        color: (filter.levels.isNotEmpty || filter.officialOnly || filter.posTags.isNotEmpty)
                            ? (isDark ? AppTheme.pureWhite : AppTheme.pureBlack)
                            : (isDark ? AppTheme.gray500 : AppTheme.gray400)),
                    tooltip: '篩選',
                    onPressed: () => _showFilterSheet(context, ref, isDark),
                  ),
                ],
                IconButton(
                  icon: const Icon(Icons.folder_outlined),
                  tooltip: '我的資料夾',
                  onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const WordFoldersScreen())),
                ),
                _SortButton(isDark: isDark),
              ]),
            ),

            // ── Tabs ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.gray850 : AppTheme.gray100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TabBar(
                  controller: _tab,
                  indicator: BoxDecoration(
                    color: isDark ? AppTheme.pureWhite : AppTheme.pureBlack,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: isDark ? AppTheme.pureBlack : AppTheme.pureWhite,
                  unselectedLabelColor: isDark ? AppTheme.gray400 : AppTheme.gray600,
                  labelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  unselectedLabelStyle: const TextStyle(fontSize: 15),
                  dividerColor: Colors.transparent,
                  tabs: [
                    Consumer(builder: (_, r, __) {
                      final w = r.watch(allWordsProvider);
                      final n = w.maybeWhen(data: (l) => l.length, orElse: () => 0);
                      return Tab(text: '單字${n > 0 ? " $n" : ""}');
                    }),
                    Consumer(builder: (_, r, __) {
                      final p = r.watch(allPhrasesProvider);
                      final n = p.maybeWhen(data: (l) => l.length, orElse: () => 0);
                      return Tab(text: '片語${n > 0 ? " $n" : ""}');
                    }),
                  ],
                ),
              ),
            ),

            // ── Search ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
              child: _SearchField(
                controller: _ctrl, isDark: isDark,
                hintText: filter.tab == BrowseTab.words ? '搜尋單字或中文…' : '搜尋片語或中文…',
                onChanged: (q) => ref.read(browseFilterProvider.notifier).setQuery(q),
              ),
            ),

            const SizedBox(height: 4),

            // ── List ──────────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: [
                  _WordsTab(isDark: isDark, ctrl: _ctrl),
                  _PhrasesTab(isDark: isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterSheet(BuildContext context, WidgetRef ref, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.gray900 : AppTheme.pureWhite,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 36, height: 4,
              decoration: BoxDecoration(color: isDark ? AppTheme.gray700 : AppTheme.gray300,
                  borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: Row(children: [
              Text('篩選條件', style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              TextButton(
                onPressed: () { ref.read(browseFilterProvider.notifier).reset(); Navigator.pop(context); },
                child: const Text('重置'),
              ),
            ]),
          ),
          Consumer(builder: (_, r, __) {
            final f = r.watch(browseFilterProvider);
            return CheckboxListTile(
              title: const Text('僅顯示官方字彙'),
              value: f.officialOnly,
              activeColor: isDark ? AppTheme.pureWhite : AppTheme.pureBlack,
              checkColor: isDark ? AppTheme.pureBlack : AppTheme.pureWhite,
              onChanged: (v) => r.read(browseFilterProvider.notifier).setOfficialOnly(v ?? false),
            );
          }),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('CEFR 級別', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              Consumer(builder: (_, r, __) {
                final f = r.watch(browseFilterProvider);
                return Wrap(spacing: 8, runSpacing: 8, children: [1,2,3,4,5,6].map((lvl) {
                  final active = f.levels.contains(lvl);
                  return FilterChip(
                    label: Text(_levelNames[lvl]!), selected: active, showCheckmark: false,
                    onSelected: (_) => r.read(browseFilterProvider.notifier).toggleLevel(lvl),
                    selectedColor: isDark ? AppTheme.pureWhite : AppTheme.pureBlack,
                    labelStyle: TextStyle(color: active ? (isDark ? AppTheme.pureBlack : AppTheme.pureWhite) : (isDark ? AppTheme.gray300 : AppTheme.gray700)),
                    side: BorderSide(color: active ? Colors.transparent : (isDark ? AppTheme.gray700 : AppTheme.gray300)),
                  );
                }).toList());
              }),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: SizedBox(
              width: double.infinity, height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? AppTheme.pureWhite : AppTheme.pureBlack,
                  foregroundColor: isDark ? AppTheme.pureBlack : AppTheme.pureWhite,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
                ),
                child: const Text('套用篩選'),
              ),
            ),
          ),
        ])),
      ),
    );
  }
}

// ── Words Tab ────────────────────────────────────────────────

class _WordsTab extends ConsumerWidget {
  final bool isDark;
  final TextEditingController ctrl;
  const _WordsTab({required this.isDark, required this.ctrl});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredAsync = ref.watch(filteredWordsProvider);
    return filteredAsync.when(
      loading: () => _skeleton(isDark),
      error: (e, _) => Center(child: Text('載入失敗: $e')),
      data: (words) {
        if (words.isEmpty) return _empty('找不到符合的單字', isDark);
        final groups = <int, List<dynamic>>{};
        for (final w in words) {
          groups.putIfAbsent(w.level ?? 99, () => []).add(w);
        }
        final keys = groups.keys.toList()..sort();
        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 16),
          itemCount: keys.fold<int>(0, (s, k) => s + 1 + groups[k]!.length),
          itemBuilder: (ctx, idx) {
            int acc = 0;
            for (final k in keys) {
              final grp = groups[k]!;
              if (idx == acc) return _LevelHeader(level: k, count: grp.length, isDark: isDark);
              acc++;
              if (idx < acc + grp.length) {
                final w = grp[idx - acc];
                return _WordRow(
                  word: w, isDark: isDark,
                  onTap: () => Navigator.of(ctx).push(_slideRoute(WordDetailScreen(lemma: w.lemma))),
                  onAddToFolder: () => _addToFolder(ctx, ref, w.lemma, isDark),
                );
              }
              acc += grp.length;
            }
            return const SizedBox.shrink();
          },
        );
      },
    );
  }

  void _addToFolder(BuildContext context, WidgetRef ref, String lemma, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppTheme.gray900 : AppTheme.pureWhite,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _AddToFolderSheet(lemma: lemma, isDark: isDark),
    );
  }
}

// ── Phrases Tab ───────────────────────────────────────────────

class _PhrasesTab extends ConsumerWidget {
  final bool isDark;
  const _PhrasesTab({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredAsync = ref.watch(filteredPhrasesProvider);
    return filteredAsync.when(
      loading: () => _skeleton(isDark),
      error: (e, _) => Center(child: Text('載入失敗: $e')),
      data: (phrases) {
        if (phrases.isEmpty) return _empty('找不到符合的片語', isDark);
        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(top: 8, bottom: 16),
          itemCount: phrases.length,
          itemBuilder: (ctx, i) {
            final p = phrases[i];
            return _PhraseRow(
              phrase: p, isDark: isDark,
              onTap: () => Navigator.of(ctx).push(_slideRoute(PhraseDetailScreen(lemma: p.lemma))),
              onAddToFolder: () => _addPhraseToFolder(ctx, ref, p.lemma, isDark),
            );
          },
        );
      },
    );
  }

  void _addPhraseToFolder(BuildContext context, WidgetRef ref, String lemma, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppTheme.gray900 : AppTheme.pureWhite,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _AddPhraseToFolderSheet(lemma: lemma, isDark: isDark),
    );
  }
}

// ── Helpers ──────────────────────────────────────────────────

Widget _skeleton(bool isDark) => ListView.separated(
  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
  itemCount: 12, separatorBuilder: (_, __) => const SizedBox(height: 12),
  itemBuilder: (_, __) => SkeletonBox(width: double.infinity, height: 68,
      borderRadius: BorderRadius.circular(12)),
);

Widget _empty(String msg, bool isDark) => Center(
    child: Text(msg, style: TextStyle(fontSize: 15, color: AppTheme.gray400)));

PageRoute _slideRoute(Widget page) => PageRouteBuilder(
  pageBuilder: (_, __, ___) => page,
  transitionsBuilder: (_, a, __, c) => SlideTransition(
    position: Tween(begin: const Offset(1, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
    child: c,
  ),
  transitionDuration: const Duration(milliseconds: 300),
);

// ── Sub-widgets ───────────────────────────────────────────────

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final bool isDark;
  final String hintText;
  final ValueChanged<String> onChanged;
  const _SearchField({required this.controller, required this.isDark,
      required this.hintText, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
          color: isDark ? AppTheme.gray850 : AppTheme.gray100,
          borderRadius: BorderRadius.circular(10)),
      child: Row(children: [
        const SizedBox(width: 12),
        Icon(Icons.search_rounded, size: 20,
            color: isDark ? AppTheme.gray500 : AppTheme.gray400),
        const SizedBox(width: 8),
        Expanded(child: TextField(
          controller: controller, onChanged: onChanged,
          style: TextStyle(fontSize: 16,
              color: isDark ? AppTheme.pureWhite : AppTheme.pureBlack),
          decoration: InputDecoration(
            border: InputBorder.none, hintText: hintText,
            hintStyle: TextStyle(fontSize: 15,
                color: isDark ? AppTheme.gray600 : AppTheme.gray400),
            isDense: true, contentPadding: EdgeInsets.zero,
          ),
        )),
        if (controller.text.isNotEmpty)
          GestureDetector(
            onTap: () { controller.clear(); onChanged(''); },
            child: Padding(padding: const EdgeInsets.all(10),
                child: Icon(Icons.close_rounded, size: 16, color: AppTheme.gray400)),
          ),
      ]),
    );
  }
}

class _LevelHeader extends StatelessWidget {
  final int level; final int count; final bool isDark;
  const _LevelHeader({required this.level, required this.count, required this.isDark});
  @override
  Widget build(BuildContext context) {
    final name = _levelNames[level] ?? '其他';
    return Container(
      color: isDark ? AppTheme.pureBlack : AppTheme.offWhite,
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 8),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.pureWhite : AppTheme.pureBlack,
            borderRadius: BorderRadius.circular(4)),
          child: Text(name, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
              color: isDark ? AppTheme.pureBlack : AppTheme.pureWhite, letterSpacing: 0.3)),
        ),
        const SizedBox(width: 8),
        Text('$count 個', style: TextStyle(fontSize: 13, color: AppTheme.gray400)),
      ]),
    );
  }
}

class _WordRow extends StatelessWidget {
  final dynamic word; final bool isDark;
  final VoidCallback onTap; final VoidCallback onAddToFolder;
  const _WordRow({required this.word, required this.isDark,
      required this.onTap, required this.onAddToFolder});

  @override
  Widget build(BuildContext context) {
    final zh = word.senses.isNotEmpty
        ? (word.senses.first.zhDef as String).split('；').first : '';
    final ml = (word.frequency?.importanceScore ?? 0.0) as double;
    final isOfficial = word.inOfficialList as bool;

    return GestureDetector(
      behavior: HitTestBehavior.opaque, 
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.gray900 : AppTheme.pureWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppTheme.gray800 : AppTheme.gray200,
              width: 0.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 第一行：單字 + 詞性 + 資料夾按鈕
              Row(
                children: [
                  // 官方標記
                  if (isOfficial)
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark ? AppTheme.gray400 : AppTheme.gray600,
                      ),
                    ),
                  // 單字
                  Expanded(
                    child: Text(
                      word.lemma as String,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamilyEnglish,
                        fontSize: 19,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppTheme.pureWhite : AppTheme.pureBlack,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  // 詞性標籤
                  if ((word.pos as List).isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.gray850 : AppTheme.gray100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        (word.pos as List).first.toString().toLowerCase(),
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppTheme.gray400 : AppTheme.gray600,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  // 資料夾按鈕
                  GestureDetector(
                    onTap: onAddToFolder,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.gray850 : AppTheme.gray100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.folder_outlined,
                        size: 16,
                        color: isDark ? AppTheme.gray400 : AppTheme.gray600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // 第二行：中文翻譯 + 重要度
              Row(
                children: [
                  Expanded(
                    child: Text(
                      zh,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? AppTheme.gray400 : AppTheme.gray600,
                        height: 1.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 重要度指示器
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(5, (i) {
                      final filled = i < (ml * 5).round();
                      return Container(
                        width: 4,
                        height: 12,
                        margin: const EdgeInsets.only(right: 2),
                        decoration: BoxDecoration(
                          color: filled
                              ? (isDark ? AppTheme.gray500 : AppTheme.gray600)
                              : (isDark ? AppTheme.gray850 : AppTheme.gray200),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhraseRow extends StatelessWidget {
  final dynamic phrase; final bool isDark; 
  final VoidCallback onTap; final VoidCallback onAddToFolder;
  const _PhraseRow({required this.phrase, required this.isDark, 
      required this.onTap, required this.onAddToFolder});

  @override
  Widget build(BuildContext context) {
    final zh = phrase.senses.isNotEmpty
        ? (phrase.senses.first.zhDef as String).split('；').first : '';
    final senseCount = (phrase.senses as List).length;
    
    return GestureDetector(
      behavior: HitTestBehavior.opaque, 
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.gray900 : AppTheme.pureWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppTheme.gray800 : AppTheme.gray200,
              width: 0.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 第一行：片語 + 義項數量 + 資料夾按鈕
              Row(
                children: [
                  // 片語
                  Expanded(
                    child: Text(
                      phrase.lemma as String,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamilyEnglish,
                        fontSize: 19,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppTheme.pureWhite : AppTheme.pureBlack,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  // 義項數量標籤
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.gray850 : AppTheme.gray100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '$senseCount 義',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppTheme.gray400 : AppTheme.gray600,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  // 資料夾按鈕
                  GestureDetector(
                    onTap: onAddToFolder,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.gray850 : AppTheme.gray100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.folder_outlined,
                        size: 16,
                        color: isDark ? AppTheme.gray400 : AppTheme.gray600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // 第二行：中文翻譯
              Text(
                zh,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppTheme.gray400 : AppTheme.gray600,
                  height: 1.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SortButton extends ConsumerWidget {
  final bool isDark;
  const _SortButton({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(browseFilterProvider).sort;
    const labels = {
      BrowseSortMode.level: '等級',
      BrowseSortMode.alphabetical: '字母',
      BrowseSortMode.frequency: '重要',
    };
    return GestureDetector(
      onTap: () => ref.read(browseFilterProvider.notifier)
          .setSort(BrowseSortMode.values[(current.index + 1) % 3]),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(color: isDark ? AppTheme.gray850 : AppTheme.gray100,
            borderRadius: BorderRadius.circular(8)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.swap_vert_rounded, size: 16, color: isDark ? AppTheme.gray400 : AppTheme.gray600),
          const SizedBox(width: 4),
          Text(labels[current]!,
              style: TextStyle(fontSize: 13, color: isDark ? AppTheme.gray400 : AppTheme.gray600)),
        ]),
      ),
    );
  }
}

class _AddToFolderSheet extends ConsumerStatefulWidget {
  final String lemma; final bool isDark;
  const _AddToFolderSheet({required this.lemma, required this.isDark});
  @override ConsumerState<_AddToFolderSheet> createState() => _AddToFolderSheetState();
}

class _AddToFolderSheetState extends ConsumerState<_AddToFolderSheet> {
  @override
  Widget build(BuildContext context) {
    final foldersAsync = ref.watch(allFoldersProvider);
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('加入資料夾', style: Theme.of(context).textTheme.titleLarge),
          const Spacer(),
          TextButton.icon(
            onPressed: () => _createFolder(context),
            icon: const Icon(Icons.add, size: 18), label: const Text('新增'),
          ),
        ]),
        const SizedBox(height: 16),
        foldersAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('載入失敗: $e'),
          data: (folders) {
            if (folders.isEmpty) {
              return const Center(
                  child: Padding(padding: EdgeInsets.all(24),
                      child: Text('還沒有資料夾，請先新增')));
            }
            return ListView.builder(
              shrinkWrap: true,
              itemCount: folders.length,
              itemBuilder: (_, i) {
                final folder = folders[i];
                final added = folder.wordLemmas.contains(widget.lemma);
                return ListTile(
                  leading: Icon(Icons.folder_outlined,
                      color: widget.isDark ? AppTheme.gray400 : AppTheme.gray600),
                  title: Text(folder.name),
                  subtitle: Text('${folder.totalCount} 個詞彙'),
                  trailing: added ? const Icon(Icons.check_circle, color: AppTheme.gray500) : null,
                  onTap: () async {
                    final updated = added ? folder.removeWord(widget.lemma) : folder.addWord(widget.lemma);
                    await ref.read(wordFolderRepositoryProvider).updateFolder(updated);
                    ref.invalidate(allFoldersProvider);
                  },
                );
              },
            );
          },
        ),
      ]),
    );
  }

  void _createFolder(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: widget.isDark ? AppTheme.gray900 : AppTheme.pureWhite,
        title: const Text('新增資料夾'),
        content: TextField(controller: ctrl, autofocus: true,
            decoration: const InputDecoration(hintText: '資料夾名稱')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          TextButton(
            onPressed: () async {
              if (ctrl.text.trim().isNotEmpty) {
                final folder = WordFolderModel.create(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: ctrl.text.trim()).addWord(widget.lemma);
                await ref.read(wordFolderRepositoryProvider).createFolder(folder);
                ref.invalidate(allFoldersProvider);
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('建立'),
          ),
        ],
      ),
    );
  }
}

class _AddPhraseToFolderSheet extends ConsumerStatefulWidget {
  final String lemma; final bool isDark;
  const _AddPhraseToFolderSheet({required this.lemma, required this.isDark});
  @override ConsumerState<_AddPhraseToFolderSheet> createState() => _AddPhraseToFolderSheetState();
}

class _AddPhraseToFolderSheetState extends ConsumerState<_AddPhraseToFolderSheet> {
  @override
  Widget build(BuildContext context) {
    final foldersAsync = ref.watch(allFoldersProvider);
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('加入資料夾', style: Theme.of(context).textTheme.titleLarge),
          const Spacer(),
          TextButton.icon(
            onPressed: () => _createFolder(context),
            icon: const Icon(Icons.add, size: 18), label: const Text('新增'),
          ),
        ]),
        const SizedBox(height: 16),
        foldersAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('載入失敗: $e'),
          data: (folders) {
            if (folders.isEmpty) {
              return const Center(
                  child: Padding(padding: EdgeInsets.all(24),
                      child: Text('還沒有資料夾，請先新增')));
            }
            return ListView.builder(
              shrinkWrap: true,
              itemCount: folders.length,
              itemBuilder: (_, i) {
                final folder = folders[i];
                final added = folder.phraseLemmas.contains(widget.lemma);
                return ListTile(
                  leading: Icon(Icons.folder_outlined,
                      color: widget.isDark ? AppTheme.gray400 : AppTheme.gray600),
                  title: Text(folder.name),
                  subtitle: Text('${folder.totalCount} 個詞彙'),
                  trailing: added ? const Icon(Icons.check_circle, color: AppTheme.gray500) : null,
                  onTap: () async {
                    final updated = added ? folder.removePhrase(widget.lemma) : folder.addPhrase(widget.lemma);
                    await ref.read(wordFolderRepositoryProvider).updateFolder(updated);
                    ref.invalidate(allFoldersProvider);
                  },
                );
              },
            );
          },
        ),
      ]),
    );
  }

  void _createFolder(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: widget.isDark ? AppTheme.gray900 : AppTheme.pureWhite,
        title: const Text('新增資料夾'),
        content: TextField(controller: ctrl, autofocus: true,
            decoration: const InputDecoration(hintText: '資料夾名稱')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          TextButton(
            onPressed: () async {
              if (ctrl.text.trim().isNotEmpty) {
                final folder = WordFolderModel.create(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: ctrl.text.trim()).addPhrase(widget.lemma);
                await ref.read(wordFolderRepositoryProvider).createFolder(folder);
                ref.invalidate(allFoldersProvider);
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('建立'),
          ),
        ],
      ),
    );
  }
}
