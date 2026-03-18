import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Learning Progress Indicator - 極簡線性進度條
/// 
/// 設計要點：
/// - 高度 4px，極簡設計
/// - 圓角 radiusRound（完全圓形）
/// - 背景使用 gray200/gray800
/// - 進度使用 pureBlack/pureWhite
/// - 平滑動畫過渡
class LearningProgressIndicator extends StatelessWidget {
  final int current;
  final int total;

  const LearningProgressIndicator({
    super.key,
    required this.current,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = total > 0 ? current / total : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space16,
        vertical: AppTheme.space12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress text
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$current / $total',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ],
          ),
          
          const SizedBox(height: AppTheme.space8),
          
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusRound),
            child: SizedBox(
              height: 4,
              child: Stack(
                children: [
                  // Background
                  Container(
                    width: double.infinity,
                    color: isDark ? AppTheme.gray800 : AppTheme.gray200,
                  ),
                  
                  // Progress
                  AnimatedFractionallySizedBox(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                    widthFactor: progress,
                    alignment: Alignment.centerLeft,
                    child: Container(
                      color: isDark ? AppTheme.pureWhite : AppTheme.pureBlack,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
