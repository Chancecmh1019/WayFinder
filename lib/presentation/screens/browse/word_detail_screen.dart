import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/providers/word_folder_providers.dart';
import '../../../data/models/word_folder_model.dart';
import '../../widgets/common/wf_app_bar.dart';
import '../../widgets/common/audio_button.dart';
import '../../widgets/multi_accent_audio_button.dart';
import '../../widgets/common/skeleton_loader.dart';
import '../../widgets/word/word_learning_aids_section.dart';

const _levelNames = {1: 'A1', 2: 'A2', 3: 'B1', 4: 'B2', 5: 'C1', 6: 'C2'};
const _examLabels = {
  'gsat': '學測',
  'gsat_ref': '學測參',
  'gsat_makeup': '補考',
  'gsat_trial': '試辦',
  'gsat_115actual': '115學測',
  'ast': '指考',
  'ast_makeup': '指考補',
  'sped': '身障', // v6.0.0 新增
};
const _sectionLabels = {
  'vocabulary': '詞彙',
  'cloze': '克漏字',
  'reading': '閱讀',
  'discourse': '篇章',
  'structure': '句構',
  'translation': '翻譯',
  'essay': '作文',
  'mixed': '混合',
};
const _roleLabels = {
  'correct_answer': '正確答案',
  'distractor': '干擾選項',
  'none': '文章中',
  'tested_keyword': '關鍵字',
  'notable_phrase': '重要片語',
  'cloze': '填空',
  'passage': '段落',
  'option': '選項',
};

class WordDetailScreen extends ConsumerStatefulWidget {
  final String lemma;
  const WordDetailScreen({super.key, required this.lemma});

  @override
  ConsumerState<WordDetailScreen> createState() => _WordDetailScreenState();
}

class _WordDetailScreenState extends ConsumerState<WordDetailScreen> {
  int _senseIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final wordAsync = ref.watch(wordDetailProvider(widget.lemma));

    return Scaffold(
      backgroundColor: isDark ? AppTheme.pureBlack : AppTheme.offWhite,
      body: wordAsync.when(
        loading: () => _buildLoading(isDark),
        error: (e, _) => _buildError(e.toString()),
        data: (word) {
          if (word == null) return _buildError('找不到單字資料');
          return _buildContent(context, word, isDark);
        },
      ),
    );
  }

  Widget _buildLoading(bool isDark) => Scaffold(
        backgroundColor: isDark ? AppTheme.pureBlack : AppTheme.offWhite,
        appBar: WfAppBar(showBack: true, backLabel: '單字庫'),
        body: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            SkeletonBox(width: 200, height: 44),
            const SizedBox(height: 16),
            SkeletonBox(width: 150, height: 20),
            const SizedBox(height: 24),
            ...List.generate(3, (_) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: SkeletonBox(width: double.infinity, height: 80),
                )),
          ],
        ),
      );

  Widget _buildError(String msg) => Scaffold(
        appBar: WfAppBar(showBack: true),
        body: Center(child: Text(msg)),
      );

  Widget _buildContent(BuildContext context, dynamic word, bool isDark) {
    final mlPct = ((word.frequency?.importanceScore ?? 0.0) * 100).round();

    return Scaffold(
      backgroundColor: isDark ? AppTheme.pureBlack : AppTheme.offWhite,
      appBar: AppBar(
        backgroundColor: isDark ? AppTheme.pureBlack : AppTheme.offWhite,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.of(context).pop(),
          child: Icon(
            Icons.chevron_left_rounded,
            size: 28,
            color: isDark ? AppTheme.pureWhite : AppTheme.pureBlack,
          ),
        ),
        actions: [
          // 加入資料夾按鈕
          IconButton(
            icon: const Icon(Icons.folder_outlined),
            onPressed: () => _showAddToFolderDialog(context, ref, word.lemma, isDark),
            tooltip: '加入資料夾',
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: AudioButton(text: word.lemma, size: 22),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        physics: const BouncingScrollPhysics(),
        children: [
          // ── Header ──────────────────────────────────────
          _buildHeader(context, word, isDark, mlPct),
          _divider(),

          // ── Senses (定義和AI例句，不含歷屆例句) ──────────
          _buildSensesWithoutExamples(context, word, isDark),
          _divider(),

          // ── Root Analysis ────────────────────────────────
          if (word.rootInfo != null) ...[
            _buildRootInfo(context, word.rootInfo, isDark),
            _divider(),
          ],

          // ── Learning Aids (v7.0.0 新增) ──────────────────
          if (word.collocations.isNotEmpty ||
              word.usageNotes != null ||
              word.grammarNotes != null ||
              word.commonMistakes != null) ...[
            WordLearningAidsSection(
              collocations: word.collocations,
              usageNotes: word.usageNotes,
              grammarNotes: word.grammarNotes,
              commonMistakes: word.commonMistakes,
              isDark: isDark,
            ),
            _divider(),
          ],

          // ── Related Words ────────────────────────────────
          _buildRelated(context, word, isDark),
          if ((word.synonyms as List).isNotEmpty ||
              (word.antonyms as List).isNotEmpty ||
              (word.derivedForms as List).isNotEmpty ||
              ((word.wordFamily ?? []) as List).isNotEmpty)
            _divider(),

          // ── Confusion Notes ───────────────────────────────
          if ((word.confusionNotes as List).isNotEmpty) ...[
            _buildConfusion(context, word.confusionNotes, word.lemma, isDark),
            _divider(),
          ],

          // ── Frequency Stats ───────────────────────────────
          if (word.frequency != null) ...[
            _buildFrequency(context, word.frequency, isDark),
            _divider(),
          ],

          // ── 歷屆例句 (移到最下面) ──────────────────────────
          _buildExamExamples(context, word, isDark),

          const SizedBox(height: 48),
        ],
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, dynamic word, bool isDark, int mlPct) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            word.lemma as String,
            style: TextStyle(
              fontFamily: AppTheme.fontFamilyEnglish,
              fontSize: 44,
              fontWeight: AppTheme.weightSemiBold,
              letterSpacing: -1.5,
              height: 1,
              color: isDark ? AppTheme.pureWhite : AppTheme.pureBlack,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (word.level != null)
                _Tag(_levelNames[word.level] ?? 'L${word.level}',
                    solid: true, isDark: isDark),
              if (word.inOfficialList as bool)
                _Tag('官方字彙', isDark: isDark),
              ...(word.pos as List)
                  .map((p) => _Tag(p.toString().toLowerCase(), isDark: isDark)),
              const SizedBox(width: 4),
              Text('重要性 $mlPct%',
                  style: TextStyle(fontSize: 12, color: AppTheme.gray500)),
              if (word.frequency != null)
                Text('出現 ${word.frequency.totalAppearances} 次',
                    style: TextStyle(fontSize: 12, color: AppTheme.gray400)),
            ],
          ),
        ],
      ),
    );
  }

  // ── Senses ──────────────────────────────────────────────────

  Widget _buildSensesWithoutExamples(BuildContext context, dynamic word, bool isDark) {
    final senses = word.senses as List;
    if (senses.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sense tabs
        if (senses.length > 1)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(senses.length, (i) {
                final s = senses[i];
                final active = i == _senseIndex;
                return GestureDetector(
                  onTap: () => setState(() => _senseIndex = i),
                  child: Container(
                    margin: const EdgeInsets.only(right: 6, bottom: 12),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: active
                          ? (isDark ? AppTheme.pureWhite : AppTheme.pureBlack)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: active
                            ? Colors.transparent
                            : (isDark ? AppTheme.gray700 : AppTheme.gray200),
                      ),
                    ),
                    child: Text(
                      '${s.zhDef.split('；').first}  ${s.pos.toLowerCase()}',
                      style: TextStyle(
                        fontSize: 12,
                        color: active
                            ? (isDark
                                ? AppTheme.pureBlack
                                : AppTheme.pureWhite)
                            : AppTheme.gray600,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

        // Active sense (只顯示定義和AI例句)
        _buildSenseDefinition(context, senses[_senseIndex], word.lemma, isDark),
      ],
    );
  }

  Widget _buildSenseDefinition(BuildContext context, dynamic sense, String lemma, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(sense.zhDef as String,
            style: TextStyle(
                fontSize: 22,
                fontWeight: AppTheme.weightSemiBold,
                letterSpacing: -0.4,
                height: 1.3,
                color: isDark ? AppTheme.pureWhite : AppTheme.pureBlack)),
        const SizedBox(height: 6),
        if (sense.enDef != null)
          Text(sense.enDef as String,
              style: TextStyle(
                  fontFamily: AppTheme.fontFamilyEnglish,
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                  color: AppTheme.gray600,
                  height: 1.5,
                  letterSpacing: -0.1)),
        const SizedBox(height: 16),

        // AI generated example
        if (sense.generatedExample != null) ...[
          _SectionLabel('AI 例句'),
          _GeneratedExample(text: sense.generatedExample, lemma: lemma, isDark: isDark),
        ],
        const SizedBox(height: 8),
      ],
    );
  }

  // ── 歷屆例句 (獨立方法，放在最下面) ──────────────────────────
  
  Widget _buildExamExamples(BuildContext context, dynamic word, bool isDark) {
    final senses = word.senses as List;
    if (senses.isEmpty) return const SizedBox.shrink();
    
    // 收集所有sense的歷屆例句
    final allExamples = <dynamic>[];
    for (final sense in senses) {
      final examples = sense.examples as List;
      allExamples.addAll(examples);
    }
    
    if (allExamples.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel('歷屆考題例句'),
        const SizedBox(height: 8),
        ...allExamples.map((ex) => _ExampleCard(
            example: ex, lemma: word.lemma, isDark: isDark)),
      ],
    );
  }

  // ── Root Info ────────────────────────────────────────────────

  Widget _buildRootInfo(BuildContext context, dynamic rootInfo, bool isDark) {
    final parts = (rootInfo.rootBreakdown as String).split('+');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel('字根分析'),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.gray900 : AppTheme.pureWhite,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            boxShadow: isDark ? null : AppTheme.subtleShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: parts.expand((p) sync* {
                  yield _RootTag(p.trim(), isDark: isDark);
                  if (p != parts.last) {
                    yield Text(' + ',
                        style: TextStyle(
                            fontSize: 14, color: AppTheme.gray400));
                  }
                }).toList(),
              ),
              const SizedBox(height: 12),
              Container(height: 0.5, color: isDark ? AppTheme.gray800 : AppTheme.gray100),
              const SizedBox(height: 10),
              Text('記憶策略',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: AppTheme.weightBold,
                      letterSpacing: 0.8,
                      color: AppTheme.gray400)),
              const SizedBox(height: 4),
              Text(rootInfo.memoryStrategy as String,
                  style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.gray600,
                      height: 1.6)),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // ── Related Words ────────────────────────────────────────────

  Widget _buildRelated(BuildContext context, dynamic word, bool isDark) {
    final synonyms = word.synonyms as List;
    final antonyms = word.antonyms as List;
    final derived = word.derivedForms as List;
    final wordFamily = (word.wordFamily ?? []) as List;

    if (synonyms.isEmpty && antonyms.isEmpty && derived.isEmpty && wordFamily.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (synonyms.isNotEmpty) ...[
          _RelatedGroup('同義詞', synonyms, isDark: isDark, strikethrough: false),
          const SizedBox(height: 12),
        ],
        if (antonyms.isNotEmpty) ...[
          _RelatedGroup('反義詞', antonyms, isDark: isDark, strikethrough: true),
          const SizedBox(height: 12),
        ],
        if (derived.isNotEmpty) ...[
          _RelatedGroup('衍生詞', derived, isDark: isDark, italic: true),
          const SizedBox(height: 12),
        ],
        if (wordFamily.isNotEmpty) ...[
          _RelatedGroup('同字族', wordFamily, isDark: isDark, italic: false),
        ],
        const SizedBox(height: 8),
      ],
    );
  }

  // ── Confusion Notes ──────────────────────────────────────────

  Widget _buildConfusion(BuildContext context, List notes, String lemma, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel('易混淆詞'),
        ...notes.map((cn) => _ConfusionCard(
              currentLemma: lemma,
              confusedWith: cn.confusedWith as String,
              distinction: cn.distinction as String,
              memoryTip: cn.memoryTip as String?,
              isDark: isDark,
            )),
        const SizedBox(height: 8),
      ],
    );
  }

  // ── Frequency Stats ──────────────────────────────────────────

  Widget _buildFrequency(BuildContext context, dynamic freq, bool isDark) {
    final card = isDark ? AppTheme.gray900 : AppTheme.pureWhite;
    final shadow = isDark ? null : AppTheme.subtleShadow;
    final mlPct = (freq.importanceScore * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel('出題頻率分析'),

        // Core stats
        Row(
          children: [
            _FreqCell('${freq.totalAppearances}', '總出現', card, shadow, isDark),
            const SizedBox(width: 10),
            _FreqCell('${freq.testedCount}', '出題次', card, shadow, isDark),
            const SizedBox(width: 10),
            _FreqCell('${freq.activeTestedCount}', '正確答案', card, shadow, isDark),
          ],
        ),
        const SizedBox(height: 10),

        // ML score bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            boxShadow: shadow,
          ),
          child: Row(
            children: [
              Text('AI 重要性',
                  style: TextStyle(fontSize: 12, color: AppTheme.gray500)),
              const SizedBox(width: 10),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: freq.importanceScore.clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor:
                        isDark ? AppTheme.gray800 : AppTheme.gray100,
                    valueColor: AlwaysStoppedAnimation(
                        isDark ? AppTheme.pureWhite : AppTheme.pureBlack),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text('$mlPct%',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: AppTheme.weightSemiBold,
                      color: isDark ? AppTheme.pureWhite : AppTheme.pureBlack)),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Years
        Wrap(
          spacing: 5,
          runSpacing: 5,
          children: [
            Text('出現年份',
                style: TextStyle(fontSize: 11, color: AppTheme.gray500)),
            ...(freq.years as List).map((y) => Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.gray850 : AppTheme.gray50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('$y',
                      style: TextStyle(
                          fontFamily: AppTheme.fontFamilyEnglish,
                          fontSize: 11,
                          color: AppTheme.gray600)),
                )),
          ],
        ),
        const SizedBox(height: 12),

        // Distribution bars
        _DistSection('按題目角色', freq.byRole as Map, isDark),
        const SizedBox(height: 8),
        _DistSection('按題型', freq.bySection as Map, isDark),
        const SizedBox(height: 8),
        _DistSection('按考試類型', freq.byExamType as Map, isDark),
        const SizedBox(height: 16),
      ],
    );
  }

  // ── Helpers ──────────────────────────────────────────────────

  Widget _divider() => Container(
      height: 0.5,
      color: AppTheme.dividerGray,
      margin: const EdgeInsets.symmetric(vertical: 20));

  void _showAddToFolderDialog(BuildContext context, WidgetRef ref, String lemma, bool isDark) async {
    // 載入所有資料夾
    final foldersAsync = ref.read(allFoldersProvider);
    
    await showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppTheme.gray900 : AppTheme.pureWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLarge)),
      ),
      builder: (context) => foldersAsync.when(
        data: (folders) {
          if (folders.isEmpty) {
            return Container(
              padding: const EdgeInsets.all(AppTheme.space24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '加入資料夾',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppTheme.space24),
                  Text(
                    '還沒有資料夾',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDark ? AppTheme.gray400 : AppTheme.gray600,
                    ),
                  ),
                  const SizedBox(height: AppTheme.space16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _showCreateFolderDialog(context, ref, lemma, isDark);
                    },
                    child: const Text('建立資料夾'),
                  ),
                ],
              ),
            );
          }
          
          return Container(
            padding: const EdgeInsets.all(AppTheme.space24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '加入資料夾',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        Navigator.pop(context);
                        _showCreateFolderDialog(context, ref, lemma, isDark);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.space16),
                ...folders.map((folder) {
                  final isInFolder = folder.containsWord(lemma);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppTheme.space8),
                    child: Material(
                      color: isDark ? AppTheme.gray800 : AppTheme.gray50,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      child: InkWell(
                        onTap: () async {
                          if (isInFolder) {
                            await ref.read(wordFolderRepositoryProvider).removeWordFromFolder(folder.id, lemma);
                          } else {
                            await ref.read(wordFolderRepositoryProvider).addWordToFolder(folder.id, lemma);
                          }
                          ref.invalidate(allFoldersProvider);
                          ref.invalidate(folderProvider(folder.id));
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(isInFolder ? '已從資料夾移除' : '已加入資料夾'),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          }
                        },
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                        child: Container(
                          padding: const EdgeInsets.all(AppTheme.space16),
                          child: Row(
                            children: [
                              Icon(
                                isInFolder ? Icons.check_circle : Icons.folder_outlined,
                                color: isInFolder
                                    ? (isDark ? AppTheme.pureWhite : AppTheme.pureBlack)
                                    : (isDark ? AppTheme.gray400 : AppTheme.gray600),
                              ),
                              const SizedBox(width: AppTheme.space12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      folder.name,
                                      style: Theme.of(context).textTheme.bodyLarge,
                                    ),
                                    Text(
                                      '${folder.wordCount} 個單字',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: isDark ? AppTheme.gray400 : AppTheme.gray600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(AppTheme.space24),
            child: CircularProgressIndicator(),
          ),
        ),
        error: (e, s) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.space24),
            child: Text('載入失敗: $e'),
          ),
        ),
      ),
    );
  }

  void _showCreateFolderDialog(BuildContext context, WidgetRef ref, String lemma, bool isDark) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppTheme.gray900 : AppTheme.pureWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
        title: const Text('建立資料夾'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '資料夾名稱',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              '取消',
              style: TextStyle(
                color: isDark ? AppTheme.gray400 : AppTheme.gray600,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                final folder = WordFolderModel.create(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: controller.text.trim(),
                );
                await ref.read(wordFolderRepositoryProvider).createFolder(folder);
                await ref.read(wordFolderRepositoryProvider).addWordToFolder(folder.id, lemma);
                ref.invalidate(allFoldersProvider);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('資料夾已建立並加入單字'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              }
            },
            child: const Text('建立'),
          ),
        ],
      ),
    );
  }
}

// ── Reusable sub-widgets ─────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(text,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: AppTheme.weightSemiBold,
                  letterSpacing: -0.2)),
          const SizedBox(width: 8),
          Expanded(
            child: Container(height: 0.5, color: AppTheme.dividerGray),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final bool solid;
  final bool isDark;

  const _Tag(this.label, {this.solid = false, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: solid
            ? (isDark ? AppTheme.pureWhite : AppTheme.pureBlack)
            : Colors.transparent,
        border: solid
            ? null
            : Border.all(
                color: isDark ? AppTheme.gray700 : AppTheme.gray200),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11,
              fontWeight: AppTheme.weightSemiBold,
              letterSpacing: 0.2,
              color: solid
                  ? (isDark ? AppTheme.pureBlack : AppTheme.pureWhite)
                  : AppTheme.gray600)),
    );
  }
}

class _ExampleCard extends StatelessWidget {
  final dynamic example;
  final String lemma;
  final bool isDark;

  const _ExampleCard(
      {required this.example, required this.lemma, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final role = example.source.sentenceRole ?? '';
    final isAnswer = role == 'correct_answer';
    final isCloze = role == 'cloze';
    final examLabel = _examLabels[example.source.examType] ?? example.source.examType;
    final sectionLabel = _sectionLabels[example.source.sectionType] ?? example.source.sectionType;

    // Highlight lemma in text
    final text = example.text as String;
    final spans = _buildTextSpans(text, lemma, isDark);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.gray900 : AppTheme.gray50,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        border: Border(
          left: BorderSide(
            color: isAnswer
                ? (isDark ? AppTheme.pureWhite : AppTheme.pureBlack)
                : isCloze
                    ? AppTheme.gray400
                    : Colors.transparent,
            width: 2.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(
                        fontFamily: AppTheme.fontFamilyEnglish,
                        fontSize: 16,
                        color: isDark ? AppTheme.gray100 : AppTheme.gray800,
                        height: 1.6),
                    children: spans,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              MultiAccentAudioButton(
                text: text,
                size: 18,
                showAccentSelector: true,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 5,
            children: [
              if (isAnswer)
                _SmallTag('正確答案', dark: true)
              else if (isCloze)
                _SmallTag('填空'),
              _SmallTag('${example.source.year}年'),
              _SmallTag(examLabel),
              _SmallTag(sectionLabel),
              if (example.source.questionNumber != null)
                _SmallTag('第${example.source.questionNumber}題'),
            ],
          ),
        ],
      ),
    );
  }

  List<TextSpan> _buildTextSpans(String text, String lemma, bool isDark) {
    final lower = text.toLowerCase();
    final lemmaLower = lemma.toLowerCase();
    final spans = <TextSpan>[];
    int start = 0;
    while (true) {
      final idx = lower.indexOf(lemmaLower, start);
      if (idx == -1) {
        spans.add(TextSpan(text: text.substring(start)));
        break;
      }
      if (idx > start) {
        spans.add(TextSpan(text: text.substring(start, idx)));
      }
      spans.add(TextSpan(
        text: text.substring(idx, idx + lemma.length),
        style: TextStyle(
            fontWeight: AppTheme.weightBold,
            color: isDark ? AppTheme.pureWhite : AppTheme.pureBlack,
            decoration: TextDecoration.underline,
            decorationStyle: TextDecorationStyle.dotted),
      ));
      start = idx + lemma.length;
    }
    return spans;
  }
}

class _GeneratedExample extends StatelessWidget {
  final String? text;
  final String lemma;
  final bool isDark;

  const _GeneratedExample(
      {required this.text, required this.lemma, required this.isDark});

  @override
  Widget build(BuildContext context) {
    if (text == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.gray900 : AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        border: Border.all(
            color: isDark ? AppTheme.gray800 : AppTheme.gray100),
      ),
      child: Row(
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
            child: Text(text!,
                style: TextStyle(
                    fontFamily: AppTheme.fontFamilyEnglish,
                    fontSize: 15,
                    fontStyle: FontStyle.italic,
                    color: isDark ? AppTheme.gray300 : AppTheme.gray700,
                    height: 1.6)),
          ),
          const SizedBox(width: 8),
          MultiAccentAudioButton(
            text: text!,
            size: 16,
            showAccentSelector: true,
          ),
        ],
      ),
    );
  }
}

class _RootTag extends StatelessWidget {
  final String text;
  final bool isDark;
  const _RootTag(this.text, {required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.gray800 : AppTheme.gray50,
        border: Border.all(
            color: isDark ? AppTheme.gray700 : AppTheme.gray200),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text,
          style: TextStyle(
              fontFamily: AppTheme.fontFamilyEnglish,
              fontSize: 14, // 從 13 增加到 14
              color: isDark ? AppTheme.gray100 : AppTheme.gray700)), // 改善對比度
    );
  }
}

class _RelatedGroup extends StatelessWidget {
  final String label;
  final List words;
  final bool isDark;
  final bool strikethrough;
  final bool italic;

  const _RelatedGroup(this.label, this.words,
      {required this.isDark,
      this.strikethrough = false,
      this.italic = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: AppTheme.weightSemiBold,
                color: AppTheme.gray500)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: words
              .map<Widget>((w) => _ClickableWordChip(
                    word: w.toString(),
                    isDark: isDark,
                    strikethrough: strikethrough,
                    italic: italic,
                  ))
              .toList(),
        ),
      ],
    );
  }
}

class _ClickableWordChip extends ConsumerWidget {
  final String word;
  final bool isDark;
  final bool strikethrough;
  final bool italic;

  const _ClickableWordChip({
    required this.word,
    required this.isDark,
    this.strikethrough = false,
    this.italic = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () async {
        // 檢查單字是否存在
        final wordExists = await _checkWordExists(ref, word);
        
        if (wordExists) {
          // 跳轉到單字詳細頁面
          if (context.mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => WordDetailScreen(lemma: word),
              ),
            );
          }
        } else {
          // 顯示提示對話框
          if (context.mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: isDark ? AppTheme.gray900 : AppTheme.pureWhite,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                ),
                title: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: isDark ? AppTheme.gray400 : AppTheme.gray600,
                    ),
                    const SizedBox(width: 8),
                    const Text('單字不存在'),
                  ],
                ),
                content: Text(
                  '字典中找不到「$word」這個單字。',
                  style: TextStyle(
                    color: isDark ? AppTheme.gray300 : AppTheme.gray700,
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('確定'),
                  ),
                ],
              ),
            );
          }
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.gray850 : AppTheme.gray50,
          border: Border.all(
              color: isDark ? AppTheme.gray800 : AppTheme.gray200),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(word,
                style: TextStyle(
                    fontFamily: AppTheme.fontFamilyEnglish,
                    fontSize: 14,
                    fontStyle: italic ? FontStyle.italic : FontStyle.normal,
                    decoration: strikethrough ? TextDecoration.lineThrough : null,
                    color: AppTheme.gray600)),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_forward_ios,
              size: 10,
              color: isDark ? AppTheme.gray600 : AppTheme.gray400,
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _checkWordExists(WidgetRef ref, String lemma) async {
    try {
      final wordDetail = await ref.read(wordDetailProvider(lemma).future);
      return wordDetail != null;
    } catch (e) {
      return false;
    }
  }
}

class _SmallTag extends StatelessWidget {
  final String text;
  final bool dark;
  const _SmallTag(this.text, {this.dark = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: dark ? AppTheme.gray900 : AppTheme.gray100,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(text,
          style: TextStyle(
              fontSize: 10,
              color: dark ? AppTheme.pureWhite : AppTheme.gray600,
              fontWeight: AppTheme.weightMedium)),
    );
  }
}

class _FreqCell extends StatelessWidget {
  final String value;
  final String label;
  final Color card;
  final List<BoxShadow>? shadow;
  final bool isDark;

  const _FreqCell(this.value, this.label, this.card, this.shadow, this.isDark);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          boxShadow: shadow,
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: AppTheme.weightBold,
                    letterSpacing: -0.5,
                    fontFamily: AppTheme.fontFamilyEnglish,
                    color: isDark ? AppTheme.pureWhite : AppTheme.pureBlack)),
            const SizedBox(height: 3),
            Text(label,
                style: TextStyle(fontSize: 10, color: AppTheme.gray500)),
          ],
        ),
      ),
    );
  }
}

class _DistSection extends StatelessWidget {
  final String title;
  final Map data;
  final bool isDark;

  const _DistSection(this.title, this.data, this.isDark);

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();
    final max =
        data.values.fold<int>(0, (m, v) => v > m ? (v as int) : m);

    String humanKey(String k) =>
        _roleLabels[k] ?? _sectionLabels[k] ?? _examLabels[k] ?? k;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(fontSize: 11, color: AppTheme.gray500,
                fontWeight: AppTheme.weightMedium)),
        const SizedBox(height: 6),
        ...data.entries.map<Widget>((e) {
          final pct = max > 0 ? (e.value as int) / max : 0.0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                SizedBox(
                    width: 72,
                    child: Text(humanKey(e.key.toString()),
                        style: TextStyle(
                            fontSize: 11, color: AppTheme.gray600),
                        overflow: TextOverflow.ellipsis)),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 5,
                      backgroundColor:
                          isDark ? AppTheme.gray800 : AppTheme.gray100,
                      valueColor: AlwaysStoppedAnimation(
                          isDark ? AppTheme.gray500 : AppTheme.gray700),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                SizedBox(
                  width: 16,
                  child: Text('${e.value}',
                      style: TextStyle(
                          fontSize: 11, color: AppTheme.gray500)),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}


class _ConfusionCard extends ConsumerWidget {
  final String currentLemma;
  final String confusedWith;
  final String distinction;
  final String? memoryTip;
  final bool isDark;

  const _ConfusionCard({
    required this.currentLemma,
    required this.confusedWith,
    required this.distinction,
    this.memoryTip,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.gray950 : AppTheme.gray950,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(currentLemma,
                  style: TextStyle(
                      fontFamily: AppTheme.fontFamilyEnglish,
                      fontSize: 18,
                      fontWeight: AppTheme.weightSemiBold,
                      color: AppTheme.pureWhite)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text('vs',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: AppTheme.weightBold,
                        color: AppTheme.gray600)),
              ),
              InkWell(
                onTap: () async {
                  // 檢查單字是否存在
                  final wordExists = await _checkWordExists(ref, confusedWith);
                  
                  if (wordExists) {
                    // 跳轉到單字詳細頁面
                    if (context.mounted) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => WordDetailScreen(lemma: confusedWith),
                        ),
                      );
                    }
                  } else {
                    // 顯示提示對話框
                    if (context.mounted) {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: isDark ? AppTheme.gray900 : AppTheme.pureWhite,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                          ),
                          title: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: isDark ? AppTheme.gray400 : AppTheme.gray600,
                              ),
                              const SizedBox(width: 8),
                              const Text('單字不存在'),
                            ],
                          ),
                          content: Text(
                            '字典中找不到「$confusedWith」這個單字。',
                            style: TextStyle(
                              color: isDark ? AppTheme.gray300 : AppTheme.gray700,
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('確定'),
                            ),
                          ],
                        ),
                      );
                    }
                  }
                },
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(confusedWith,
                          style: TextStyle(
                              fontFamily: AppTheme.fontFamilyEnglish,
                              fontSize: 18,
                              fontWeight: AppTheme.weightSemiBold,
                              color: AppTheme.gray500)),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 12,
                        color: AppTheme.gray600,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(distinction,
              style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.gray300,
                  height: 1.6)),
          const SizedBox(height: 8),
          Container(height: 0.5, color: AppTheme.gray800),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('記憶技巧：',
                  style: TextStyle(fontSize: 12, color: AppTheme.gray600)),
              Expanded(
                child: Text(memoryTip ?? "",
                    style: TextStyle(fontSize: 12, color: AppTheme.gray400)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<bool> _checkWordExists(WidgetRef ref, String lemma) async {
    try {
      final wordDetail = await ref.read(wordDetailProvider(lemma).future);
      return wordDetail != null;
    } catch (e) {
      return false;
    }
  }
}
