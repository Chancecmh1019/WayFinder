import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../providers/fsrs_learning_provider.dart';

/// 連續天數徽章組件
/// 
/// 顯示學習連續天數和里程碑成就
/// 使用極簡黑白灰配色
class StreakBadgeWidget extends ConsumerWidget {
  final String userId;

  const StreakBadgeWidget({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentStreak = ref.watch(currentStreakProvider(userId));
    final longestStreak = ref.watch(longestStreakProvider(userId));

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            isDark ? AppTheme.gray850 : AppTheme.gray100,
            isDark ? AppTheme.gray900 : AppTheme.pureWhite,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppTheme.gray700 : AppTheme.gray300,
          width: 2,
        ),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          // 火焰圖示
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: isDark ? AppTheme.gray800 : AppTheme.gray200,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.local_fire_department,
              size: 48,
              color: isDark ? AppTheme.pureWhite : AppTheme.pureBlack,
            ),
          ),

          const SizedBox(height: 16),

          // 當前連續天數
          Text(
            '$currentStreak 天',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? AppTheme.pureWhite : AppTheme.pureBlack,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            '當前連續學習',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: isDark ? AppTheme.gray400 : AppTheme.gray600,
            ),
          ),
          Text(
            'Current Streak',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isDark ? AppTheme.gray500 : AppTheme.gray500,
              fontSize: 11,
            ),
          ),

          const SizedBox(height: 24),

          // 統計資訊
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                context,
                '最長紀錄',
                'Longest',
                '$longestStreak 天',
                isDark,
              ),
              Container(
                width: 1,
                height: 40,
                color: isDark ? AppTheme.gray700 : AppTheme.gray300,
              ),
              _buildStatItem(
                context,
                '本週學習',
                'This Week',
                '${currentStreak > 7 ? 7 : currentStreak} 天',
                isDark,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 里程碑提示
          if (currentStreak >= 7)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.gray800 : AppTheme.gray200,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.emoji_events,
                    size: 16,
                    color: isDark ? AppTheme.pureWhite : AppTheme.pureBlack,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '已達成 7 天里程碑！',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDark ? AppTheme.pureWhite : AppTheme.pureBlack,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String labelEn,
    String value,
    bool isDark,
  ) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: isDark ? AppTheme.gray400 : AppTheme.gray600,
          ),
        ),
        Text(
          labelEn,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: isDark ? AppTheme.gray500 : AppTheme.gray500,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
