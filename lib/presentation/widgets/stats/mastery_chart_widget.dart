import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../providers/fsrs_learning_provider.dart';

/// 詞彙掌握度圖表組件
/// 
/// 顯示不同狀態的卡片數量分布
class MasteryChartWidget extends ConsumerWidget {
  final String userId;

  const MasteryChartWidget({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final stats = ref.watch(cardStatisticsProvider(userId));

    final total = stats['total'] ?? 0;
    final newCards = stats['new'] ?? 0;
    final learning = stats['learning'] ?? 0;
    final review = stats['review'] ?? 0;
    final relearning = stats['relearning'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.gray900 : AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark ? null : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 總計
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '總詞彙量',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '$total',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // 進度條
          if (total > 0) ...[
            _buildProgressBar(
              context,
              isDark,
              newCards: newCards,
              learning: learning,
              review: review,
              relearning: relearning,
              total: total,
            ),
            const SizedBox(height: 24),
          ],

          // 狀態列表
          _buildStatusItem(
            context,
            isDark,
            '新卡片',
            'New',
            newCards,
            total,
            AppTheme.gray400,
          ),
          const SizedBox(height: 12),
          _buildStatusItem(
            context,
            isDark,
            '學習中',
            'Learning',
            learning,
            total,
            AppTheme.gray600,
          ),
          const SizedBox(height: 12),
          _buildStatusItem(
            context,
            isDark,
            '複習中',
            'Review',
            review,
            total,
            AppTheme.gray800,
          ),
          const SizedBox(height: 12),
          _buildStatusItem(
            context,
            isDark,
            '重新學習',
            'Relearning',
            relearning,
            total,
            AppTheme.gray500,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(
    BuildContext context,
    bool isDark, {
    required int newCards,
    required int learning,
    required int review,
    required int relearning,
    required int total,
  }) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 12,
            child: Row(
              children: [
                if (newCards > 0)
                  Expanded(
                    flex: newCards,
                    child: Container(color: AppTheme.gray400),
                  ),
                if (learning > 0)
                  Expanded(
                    flex: learning,
                    child: Container(color: AppTheme.gray600),
                  ),
                if (review > 0)
                  Expanded(
                    flex: review,
                    child: Container(color: AppTheme.gray800),
                  ),
                if (relearning > 0)
                  Expanded(
                    flex: relearning,
                    child: Container(color: AppTheme.gray500),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusItem(
    BuildContext context,
    bool isDark,
    String label,
    String sublabel,
    int count,
    int total,
    Color color,
  ) {
    final percentage = total > 0 ? (count / total * 100).toStringAsFixed(1) : '0.0';

    return Row(
      children: [
        // 顏色指示器
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 12),

        // 標籤
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                sublabel,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isDark ? AppTheme.gray500 : AppTheme.gray400,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),

        // 數量和百分比
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '$count',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '$percentage%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isDark ? AppTheme.gray500 : AppTheme.gray400,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
