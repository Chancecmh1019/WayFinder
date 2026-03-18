import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../providers/fsrs_learning_provider.dart';

/// 卡片狀態分布圖組件
/// 
/// 顯示 New/Learning/Review/Relearning 卡片的數量分布
/// 使用極簡黑白灰配色
class CardDistributionChartWidget extends ConsumerWidget {
  final String userId;

  const CardDistributionChartWidget({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final stats = ref.watch(cardStatisticsProvider(userId));

    final newCards = stats['new'] ?? 0;
    final learningCards = stats['learning'] ?? 0;
    final reviewCards = stats['review'] ?? 0;
    final relearnCards = stats['relearning'] ?? 0;
    final total = stats['total'] ?? 0;

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
        children: [
          // 總數
          Text(
            '$total',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '總卡片數',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDark ? AppTheme.gray400 : AppTheme.gray600,
            ),
          ),
          Text(
            'Total Cards',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isDark ? AppTheme.gray500 : AppTheme.gray500,
              fontSize: 11,
            ),
          ),

          const SizedBox(height: 24),

          // 進度條（使用灰階）
          if (total > 0)
            _buildProgressBar(
              context,
              isDark,
              newCards / total,
              learningCards / total,
              reviewCards / total,
              relearnCards / total,
            ),

          const SizedBox(height: 24),

          // 圖例
          Column(
            children: [
              _buildLegendItem(
                context,
                '新卡片',
                'New',
                newCards,
                isDark ? AppTheme.gray400 : AppTheme.gray800,
                isDark,
              ),
              const SizedBox(height: 12),
              _buildLegendItem(
                context,
                '學習中',
                'Learning',
                learningCards,
                isDark ? AppTheme.gray500 : AppTheme.gray700,
                isDark,
              ),
              const SizedBox(height: 12),
              _buildLegendItem(
                context,
                '複習中',
                'Review',
                reviewCards,
                isDark ? AppTheme.gray600 : AppTheme.gray600,
                isDark,
              ),
              const SizedBox(height: 12),
              _buildLegendItem(
                context,
                '重新學習',
                'Relearning',
                relearnCards,
                isDark ? AppTheme.gray700 : AppTheme.gray500,
                isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(
    BuildContext context,
    bool isDark,
    double newRatio,
    double learningRatio,
    double reviewRatio,
    double relearnRatio,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: 16,
        child: Row(
          children: [
            if (newRatio > 0)
              Expanded(
                flex: (newRatio * 100).round(),
                child: Container(
                  color: isDark ? AppTheme.gray400 : AppTheme.gray800,
                ),
              ),
            if (learningRatio > 0)
              Expanded(
                flex: (learningRatio * 100).round(),
                child: Container(
                  color: isDark ? AppTheme.gray500 : AppTheme.gray700,
                ),
              ),
            if (reviewRatio > 0)
              Expanded(
                flex: (reviewRatio * 100).round(),
                child: Container(
                  color: isDark ? AppTheme.gray600 : AppTheme.gray600,
                ),
              ),
            if (relearnRatio > 0)
              Expanded(
                flex: (relearnRatio * 100).round(),
                child: Container(
                  color: isDark ? AppTheme.gray700 : AppTheme.gray500,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(
    BuildContext context,
    String label,
    String labelEn,
    int count,
    Color color,
    bool isDark,
  ) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 12),
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
                labelEn,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isDark ? AppTheme.gray500 : AppTheme.gray500,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        Text(
          '$count',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
