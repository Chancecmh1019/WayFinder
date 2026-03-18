import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Statistics card with large number and label
class StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData? icon;

  const StatCard({
    super.key,
    required this.value,
    required this.label,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
          if (icon != null) ...[
            Icon(
              icon,
              size: 24,
              color: isDark ? AppTheme.gray400 : AppTheme.gray600,
            ),
            const SizedBox(height: AppTheme.space12),
          ],
          Text(
            value,
            style: Theme.of(context).textTheme.displayLarge,
          ),
          const SizedBox(height: AppTheme.space4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: isDark ? AppTheme.gray400 : AppTheme.gray600,
            ),
          ),
        ],
      ),
    );
  }
}
