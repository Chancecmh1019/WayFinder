import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../../core/providers/quiz_providers.dart';
import '../../../domain/entities/quiz_skill.dart';

/// 測驗歷史頁面
/// 
/// 顯示所有測驗記錄和統計
class QuizHistoryScreen extends ConsumerWidget {
  final String userId;

  const QuizHistoryScreen({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final historyAsync = ref.watch(getQuizHistoryProvider(userId));
    final skillsAsync = ref.watch(getQuizSkillsProvider(userId));

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
          '測驗歷史',
          style: TextStyle(
            color: isDark ? AppTheme.pureWhite : AppTheme.pureBlack,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 技能掌握度
            Text(
              '技能掌握度',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            skillsAsync.when(
              data: (skills) => _buildSkillsSection(context, skills, isDark),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => const SizedBox.shrink(),
            ),

            const SizedBox(height: 32),

            // 測驗記錄
            Text(
              '測驗記錄',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            historyAsync.when(
              data: (history) {
                if (history.isEmpty) {
                  return _buildEmptyState(context, isDark);
                }
                return _buildHistoryList(context, history, isDark);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text('載入失敗: $error'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillsSection(
    BuildContext context,
    List<QuizSkill> skills,
    bool isDark,
  ) {
    return Column(
      children: skills.map((skill) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildSkillCard(context, skill, isDark),
        );
      }).toList(),
    );
  }

  Widget _buildSkillCard(
    BuildContext context,
    QuizSkill skill,
    bool isDark,
  ) {
    final percentage = (skill.accuracy * 100).round();
    
    return Container(
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
          // 技能名稱和準確率
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      skill.nameZh,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      skill.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDark ? AppTheme.gray500 : AppTheme.gray500,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$percentage%',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${skill.correctAttempts}/${skill.totalAttempts}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDark ? AppTheme.gray500 : AppTheme.gray500,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 進度條
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: skill.masteryLevel,
              minHeight: 8,
              backgroundColor: isDark ? AppTheme.gray800 : AppTheme.gray200,
              valueColor: AlwaysStoppedAnimation<Color>(
                isDark ? AppTheme.pureWhite : AppTheme.pureBlack,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // 掌握度標籤
          Row(
            children: [
              Icon(
                skill.isMastered ? Icons.check_circle : Icons.circle_outlined,
                size: 16,
                color: isDark ? AppTheme.pureWhite : AppTheme.pureBlack,
              ),
              const SizedBox(width: 4),
              Text(
                skill.isMastered ? '已掌握' : '練習中',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const Spacer(),
              if (skill.lastPracticed != null)
                Text(
                  '最後練習: ${_formatDate(skill.lastPracticed!)}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isDark ? AppTheme.gray500 : AppTheme.gray500,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList(
    BuildContext context,
    List<QuizHistoryEntry> history,
    bool isDark,
  ) {
    return Column(
      children: history.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildHistoryCard(context, entry, isDark),
        );
      }).toList(),
    );
  }

  Widget _buildHistoryCard(
    BuildContext context,
    QuizHistoryEntry entry,
    bool isDark,
  ) {
    return Container(
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
          // 日期和分數
          Row(
            children: [
              Expanded(
                child: Text(
                  _formatDateTime(entry.timestamp),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark ? AppTheme.gray400 : AppTheme.gray600,
                  ),
                ),
              ),
              Text(
                '${entry.percentage}%',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 詳細資訊
          Row(
            children: [
              _buildInfoChip(
                context,
                Icons.quiz_outlined,
                '${entry.totalQuestions} 題',
                isDark,
              ),
              const SizedBox(width: 8),
              _buildInfoChip(
                context,
                Icons.check_circle_outline,
                '${entry.correctCount} 對',
                isDark,
              ),
              const SizedBox(width: 8),
              _buildInfoChip(
                context,
                Icons.timer_outlined,
                _formatDuration(entry.duration),
                isDark,
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 題型標籤
          Wrap(
            spacing: 8,
            children: entry.skillTypes.map((type) {
              final skill = QuizSkill(type: type);
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.gray850 : AppTheme.gray100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  skill.nameZh,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(
    BuildContext context,
    IconData icon,
    String label,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.gray850 : AppTheme.gray100,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: isDark ? AppTheme.gray400 : AppTheme.gray600,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: isDark ? AppTheme.gray600 : AppTheme.gray400,
            ),
            const SizedBox(height: 16),
            Text(
              '還沒有測驗記錄',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '開始你的第一次測驗吧！',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDark ? AppTheme.gray400 : AppTheme.gray600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return '今天';
    } else if (difference.inDays == 1) {
      return '昨天';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} 天前';
    } else {
      return '${date.month}/${date.day}';
    }
  }

  String _formatDateTime(DateTime date) {
    return '${date.year}/${date.month}/${date.day} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    if (minutes > 0) {
      return '$minutes 分 $seconds 秒';
    }
    return '$seconds 秒';
  }
}
