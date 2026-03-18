
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

enum SRSRating {
  again,
  hard,
  good,
  easy,
}

class SRSRatingButtons extends StatelessWidget {
  final Function(SRSRating) onRate;
  
  const SRSRatingButtons({
    super.key,
    required this.onRate,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildButton(context, SRSRating.again, "忘記", "1m", const Color(0xFFEF4444)),
        const SizedBox(width: 8),
        _buildButton(context, SRSRating.hard, "困難", "6m", const Color(0xFFF97316)),
        const SizedBox(width: 8),
        _buildButton(context, SRSRating.good, "普通", "10m", const Color(0xFF3B82F6)),
        const SizedBox(width: 8),
        _buildButton(context, SRSRating.easy, "簡單", "4d", const Color(0xFF10B981)),
      ],
    );
  }

  Widget _buildButton(BuildContext context, SRSRating rating, String label, String interval, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onRate(rating),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(
                color: color.withValues(alpha: 0.3),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(12),
              color: color.withValues(alpha: 0.05),
            ),
            child: Column(
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  interval,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppTheme.gray400 : AppTheme.gray600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
