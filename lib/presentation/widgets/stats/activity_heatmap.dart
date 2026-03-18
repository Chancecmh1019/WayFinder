import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// GitHub-style activity heatmap
class ActivityHeatmap extends StatelessWidget {
  final Map<DateTime, int> dailyActivity;

  const ActivityHeatmap({
    super.key,
    required this.dailyActivity,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final today = DateTime.now();
    final startDate = DateTime(today.year, today.month, today.day)
        .subtract(const Duration(days: 90)); // Show last 90 days

    // Calculate max activity for color intensity
    final maxActivity = dailyActivity.values.isEmpty 
        ? 1 
        : dailyActivity.values.reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(AppTheme.space20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.gray900 : AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '學習活動',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppTheme.space16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(13, (weekIndex) {
                return Padding(
                  padding: const EdgeInsets.only(right: 2),
                  child: Column(
                    children: List.generate(7, (dayIndex) {
                      final date = startDate.add(
                        Duration(days: weekIndex * 7 + dayIndex),
                      );
                      
                      if (date.isAfter(today)) {
                        return const SizedBox(width: 12, height: 12);
                      }

                      final activity = dailyActivity[DateTime(
                        date.year,
                        date.month,
                        date.day,
                      )] ?? 0;

                      final intensity = maxActivity > 0 
                          ? (activity / maxActivity) 
                          : 0.0;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Tooltip(
                          message: '${date.month}/${date.day}: $activity 次複習',
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.gray900 : AppTheme.pureBlack,
                            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                            boxShadow: AppTheme.deepShadow,
                          ),
                          textStyle: const TextStyle(
                            color: AppTheme.pureWhite,
                            fontSize: 13,
                          ),
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: _getHeatmapColor(intensity, isDark),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: AppTheme.space12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                '少',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isDark ? AppTheme.gray400 : AppTheme.gray600,
                ),
              ),
              const SizedBox(width: 4),
              ...List.generate(5, (index) {
                final intensity = (index + 1) / 5;
                return Padding(
                  padding: const EdgeInsets.only(left: 2),
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _getHeatmapColor(intensity, isDark),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
              const SizedBox(width: 4),
              Text(
                '多',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isDark ? AppTheme.gray400 : AppTheme.gray600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getHeatmapColor(double intensity, bool isDark) {
    if (intensity == 0) {
      return isDark ? AppTheme.gray800 : AppTheme.gray200;
    }
    
    if (isDark) {
      // Dark mode: white with varying opacity
      return AppTheme.pureWhite.withValues(alpha: 0.2 + intensity * 0.8);
    } else {
      // Light mode: black with varying opacity
      return AppTheme.pureBlack.withValues(alpha: 0.1 + intensity * 0.9);
    }
  }
}
