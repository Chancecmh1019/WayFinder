import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../../core/providers/word_folder_providers.dart';
import '../../../data/models/word_folder_model.dart';
import '../browse/word_detail_screen.dart';
import '../study/flashcard_screen.dart';
import '../study/cloze_screen.dart';
import '../study/multiple_choice_screen.dart';

/// 資料夾詳情畫面
/// 
/// 顯示資料夾內的單字列表，可以學習、移除單字
class WordFolderDetailScreen extends ConsumerWidget {
  final String folderId;

  const WordFolderDetailScreen({
    super.key,
    required this.folderId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final folderAsync = ref.watch(folderProvider(folderId));

    return Scaffold(
      backgroundColor: isDark ? AppTheme.pureBlack : AppTheme.offWhite,
      body: folderAsync.when(
        data: (folder) {
          if (folder == null) {
            return const Center(child: Text('資料夾不存在'));
          }
          return _buildContent(context, ref, folder, isDark);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('載入失敗: $e')),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    WordFolderModel folder,
    bool isDark,
  ) {
    return CustomScrollView(
      slivers: [
        // App Bar
        SliverAppBar(
          backgroundColor: isDark ? AppTheme.pureBlack : AppTheme.offWhite,
          elevation: 0,
          pinned: true,
          title: Text(folder.name),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showEditDialog(context, ref, folder, isDark),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _showDeleteDialog(context, ref, folder, isDark),
            ),
          ],
        ),

        // 統計資訊和學習按鈕
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.space24),
            child: Column(
              children: [
                // 統計卡片
                Container(
                  padding: const EdgeInsets.all(AppTheme.space20),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.gray900 : AppTheme.pureWhite,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    boxShadow: isDark ? null : AppTheme.cardShadow,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(context, '單字數', '${folder.wordCount}', isDark),
                      _buildStatItem(context, '已學習', '0', isDark),
                      _buildStatItem(context, '待複習', '0', isDark),
                    ],
                  ),
                ),
                
                const SizedBox(height: AppTheme.space16),
                
                // 學習按鈕
                if (folder.wordLemmas.isNotEmpty)
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () => _showLearningModes(context, ref, folder, isDark),
                      icon: const Icon(Icons.school_outlined),
                      label: const Text('開始學習'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? AppTheme.pureWhite : AppTheme.pureBlack,
                        foregroundColor: isDark ? AppTheme.pureBlack : AppTheme.pureWhite,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // 單字列表
        if (folder.wordLemmas.isEmpty)
          const SliverFillRemaining(
            child: Center(child: Text('還沒有單字')),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.space24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final lemma = folder.wordLemmas[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppTheme.space12),
                    child: _buildWordCard(context, ref, folder, lemma, isDark),
                  );
                },
                childCount: folder.wordLemmas.length,
              ),
            ),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: AppTheme.space32)),
      ],
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, bool isDark) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: isDark ? AppTheme.gray400 : AppTheme.gray600,
          ),
        ),
      ],
    );
  }

  Widget _buildWordCard(
    BuildContext context,
    WidgetRef ref,
    WordFolderModel folder,
    String lemma,
    bool isDark,
  ) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WordDetailScreen(lemma: lemma),
          ),
        );
      },
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.space16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.gray900 : AppTheme.pureWhite,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          boxShadow: isDark ? null : AppTheme.cardShadow,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                lemma,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: () => _removeWord(context, ref, folder, lemma),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(
    BuildContext context,
    WidgetRef ref,
    WordFolderModel folder,
    bool isDark,
  ) {
    final controller = TextEditingController(text: folder.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppTheme.gray900 : AppTheme.pureWhite,
        title: const Text('編輯資料夾'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: '資料夾名稱'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                final updated = folder.copyWith(name: controller.text.trim());
                await ref.read(wordFolderRepositoryProvider).updateFolder(updated);
                ref.invalidate(folderProvider(folderId));
                ref.invalidate(allFoldersProvider);
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('儲存'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    WidgetRef ref,
    WordFolderModel folder,
    bool isDark,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppTheme.gray900 : AppTheme.pureWhite,
        title: const Text('刪除資料夾'),
        content: const Text('確定要刪除這個資料夾嗎？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(wordFolderRepositoryProvider).deleteFolder(folderId);
              ref.invalidate(allFoldersProvider);
              if (context.mounted) {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back to folders list
              }
            },
            child: const Text('刪除', style: TextStyle(color: Color(0xFF666666))),
          ),
        ],
      ),
    );
  }

  void _removeWord(
    BuildContext context,
    WidgetRef ref,
    WordFolderModel folder,
    String lemma,
  ) async {
    final updated = folder.removeWord(lemma);
    await ref.read(wordFolderRepositoryProvider).updateFolder(updated);
    ref.invalidate(folderProvider(folderId));
    ref.invalidate(allFoldersProvider);
  }

  void _showLearningModes(
    BuildContext context,
    WidgetRef ref,
    WordFolderModel folder,
    bool isDark,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppTheme.gray900 : AppTheme.pureWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLarge)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppTheme.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '選擇學習模式',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppTheme.space24),
            
            _buildLearningModeItem(
              context,
              isDark,
              title: '翻牌複習',
              subtitle: '主動回想 + FSRS 間隔重複',
              icon: Icons.flip_to_front,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FlashcardScreen(
                      customWordList: folder.wordLemmas,
                    ),
                  ),
                );
              },
            ),
            
            _buildLearningModeItem(
              context,
              isDark,
              title: '填空練習',
              subtitle: '真實考題例句填空',
              icon: Icons.edit_note,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ClozeScreen(
                      customWordList: folder.wordLemmas,
                    ),
                  ),
                );
              },
            ),
            
            _buildLearningModeItem(
              context,
              isDark,
              title: '四選一測驗',
              subtitle: '看英文選中文意思',
              icon: Icons.quiz_outlined,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MultipleChoiceScreen(
                      customWordList: folder.wordLemmas,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLearningModeItem(
    BuildContext context,
    bool isDark, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.space12),
      child: Material(
        color: isDark ? AppTheme.gray800 : AppTheme.gray50,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          child: Container(
            padding: const EdgeInsets.all(AppTheme.space16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.space12),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.gray700 : AppTheme.gray100,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Icon(
                    icon,
                    color: isDark ? AppTheme.pureWhite : AppTheme.pureBlack,
                  ),
                ),
                const SizedBox(width: AppTheme.space16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark ? AppTheme.gray400 : AppTheme.gray600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: isDark ? AppTheme.gray600 : AppTheme.gray400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
