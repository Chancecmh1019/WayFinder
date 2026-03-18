import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Proficiency distribution bar chart
class ProficiencyChart extends StatelessWidget {
  final Map<int, int> distribution;

  const ProficiencyChart({
    super.key,
    required this.distribution,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final maxCount = distribution.values.isEmpty 
        ? 1 
        : distribution.values.reduce((a, b) => a > b ? a : b);

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
            '熟練度分佈',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppTheme.space20),
          LayoutBuilder(
            builder: (context, constraints) {
              const baseHeight = 180.0;
              return SizedBox(
                height: baseHeight + 40, // Extra space for labels
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(6, (index) {
                    final count = distribution[index] ?? 0;
                    // Clamp height to prevent overflow
                    final barHeight = maxCount > 0 
                        ? ((count / maxCount) * baseHeight).clamp(0.0, baseHeight)
                        : 0.0;
                    
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Tooltip(
                          message: '等級 $index: $count 個單字',
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.gray900 : AppTheme.pureBlack,
                            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                            boxShadow: AppTheme.deepShadow,
                          ),
                          textStyle: const TextStyle(
                            color: AppTheme.pureWhite,
                            fontSize: 13,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              // Count label - Fixed height
                              SizedBox(
                                height: 20,
                                child: count > 0
                                    ? Text(
                                        count.toString(),
                                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                          color: isDark ? AppTheme.gray400 : AppTheme.gray600,
                                        ),
                                      )
                                    : const SizedBox(),
                              ),
                              // Bar
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOut,
                                height: barHeight,
                                decoration: BoxDecoration(
                                  color: isDark ? AppTheme.pureWhite : AppTheme.pureBlack,
                                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                                ),
                              ),
                              const SizedBox(height: AppTheme.space8),
                              // Level label
                              Text(
                                'L$index',
                                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: isDark ? AppTheme.gray400 : AppTheme.gray600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
