import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../../core/providers/quiz_providers.dart';
import '../../../domain/entities/quiz_skill.dart';
import '../browse/word_detail_screen.dart';

/// 錯題本頁面
/// 
/// 顯示所有答錯的題目，可以重新練習
class MistakeBookScreen extends ConsumerWidget {
  final String userId;

  const MistakeBookScreen({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mistakesAsync = ref.watch(getMistakeBookProvider(userId));

    return Scaffold(
      backgroundColor: isDark ? AppTheme.pureBlack : AppTheme.offWhite,
      appBar: AppBar(
        backgroundColor: isDark ? AppTheme.pureBlack : AppTheme.offWhite,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: isDark ? AppTheme.pureWhite : AppTheme.pureBlack,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          '錯題本',
          style: TextStyle(
            color: isDark ? AppTheme.pureWhite : AppTheme.pureBlack,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          mistakesAsync.when(
            data: (mistakes) => mistakes.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      color: isDark ? AppTheme.pureWhite : AppTheme.pureBlack,
                    ),
                    onPressed: () => _showClearDialog(context, ref),
                  )
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: mistakesAsync.when(
        data: (mistakes) {
          if (mistakes.isEmpty) {
            return _buildEmptyState(context, isDark);
          }
          
          return _buildMistakeList(context, ref, mistakes, isDark);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: isDark ? AppTheme.gray600 : AppTheme.gray400,
              ),
              const SizedBox(height: 16),
              Text(
                '載入失敗',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark ? AppTheme.gray400 : AppTheme.gray600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 80,
              color: isDark ? AppTheme.gray600 : AppTheme.gray400,
            ),
            const SizedBox(height: 24),
            Text(
              '太棒了！',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '目前沒有錯題\n繼續保持！',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDark ? AppTheme.gray400 : AppTheme.gray600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMistakeList(
    BuildContext context,
    WidgetRef ref,
    List<MistakeEntry> mistakes,
    bool isDark,
  ) {
    // 按單字分組
    final groupedMistakes = <String, List<MistakeEntry>>{};
    for (final mistake in mistakes) {
      groupedMistakes.putIfAbsent(mistake.word, () => []).add(mistake);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 統計卡片
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.gray900 : AppTheme.pureWhite,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                offset: const Offset(0, 2),
                blurRadius: 8,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                context,
                '錯題數',
                mistakes.length.toString(),
                Icons.error_outline,
                isDark,
              ),
              Container(
                width: 1,
                height: 40,
                color: isDark ? AppTheme.gray800 : AppTheme.gray200,
              ),
              _buildStatItem(
                context,
                '單字數',
                groupedMistakes.length.toString(),
                Icons.book_outlined,
                isDark,
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // 錯題列表
        ...groupedMistakes.entries.map((entry) {
          final word = entry.key;
          final wordMistakes = entry.value;
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildMistakeCard(
              context,
              ref,
              word,
              wordMistakes,
              isDark,
            ),
          );
        }),
      ],
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    bool isDark,
  ) {
    return Column(
      children: [
        Icon(
          icon,
          size: 32,
          color: isDark ? AppTheme.gray400 : AppTheme.gray600,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: isDark ? AppTheme.gray500 : AppTheme.gray500,
          ),
        ),
      ],
    );
  }

  Widget _buildMistakeCard(
    BuildContext context,
    WidgetRef ref,
    String word,
    List<MistakeEntry> mistakes,
    bool isDark,
  ) {
    final latestMistake = mistakes.first;
    
    return InkWell(
      onTap: () {
        // 導航到單字詳情頁
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => WordDetailScreen(lemma: word),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.gray900 : AppTheme.pureWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppTheme.gray800 : AppTheme.gray200,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 單字和錯誤次數
            Row(
              children: [
                Expanded(
                  child: Text(
                    word,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.gray800 : AppTheme.gray200,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '錯 ${mistakes.length} 次',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // 最近一次錯誤
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.gray850 : AppTheme.gray100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 題型標籤
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.gray800 : AppTheme.gray200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _getSkillTypeName(latestMistake.skillType),
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _formatTimestamp(latestMistake.timestamp),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: isDark ? AppTheme.gray500 : AppTheme.gray500,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // 題目
                  Text(
                    latestMistake.question,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 8),

                  // 答案對比
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '你的答案',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: isDark ? AppTheme.gray500 : AppTheme.gray500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              latestMistake.userAnswer.isEmpty 
                                  ? '未作答' 
                                  : latestMistake.userAnswer,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '正確答案',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: isDark ? AppTheme.gray500 : AppTheme.gray500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              latestMistake.correctAnswer,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getSkillTypeName(QuizSkillType type) {
    final skill = QuizSkill(type: type);
    return skill.nameZh;
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays} 天前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} 小時前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} 分鐘前';
    } else {
      return '剛剛';
    }
  }

  void _showClearDialog(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppTheme.gray900 : AppTheme.pureWhite,
        title: const Text('清空錯題本'),
        content: const Text('確定要清空所有錯題記錄嗎？此操作無法復原。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await ref.read(clearMistakeBookProvider(userId).future);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('已清空錯題本')),
                );
              }
            },
            child: const Text(
              '確定',
            ),
          ),
        ],
      ),
    );
  }
}
