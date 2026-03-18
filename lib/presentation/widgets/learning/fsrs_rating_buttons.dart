import 'package:flutter/material.dart';
import '../../../domain/services/fsrs_algorithm.dart';
import '../../theme/app_theme.dart';

/// FSRS 評分按鈕列
class FSRSRatingButtons extends StatelessWidget {
  final bool enabled;
  final Future<void> Function(FSRSRating) onRate;
  final SchedulingInfo? schedulingInfo;
  final bool isDark;

  const FSRSRatingButtons({
    super.key,
    required this.enabled,
    required this.onRate,
    this.schedulingInfo,
    this.isDark = false,
  });

  String _intervalLabel(FSRSCard? card) {
    if (card == null) return '';
    final d = card.scheduledDays;
    if (d == 0) {
      final mins = card.due.difference(DateTime.now()).inMinutes;
      return '${mins.clamp(1, 60)}分鐘';
    }
    if (d == 1) return '1天';
    if (d < 7)  return '$d天';
    if (d < 30) return '${(d / 7).round()}週';
    if (d < 365) return '${(d / 30).round()}月';
    return '${(d / 365).round()}年';
  }

  @override
  Widget build(BuildContext context) {
    final ratings = [FSRSRating.again, FSRSRating.hard, FSRSRating.good, FSRSRating.easy];
    final cards   = [schedulingInfo?.again, schedulingInfo?.hard, schedulingInfo?.good, schedulingInfo?.easy];

    return Row(
      children: List.generate(4, (i) {
        final r = ratings[i];
        final isLast = i == 3;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(left: i > 0 ? 8 : 0),
            child: _RateButton(
              rating: r,
              intervalLabel: _intervalLabel(cards[i]),
              enabled: enabled,
              onTap: enabled ? () => onRate(r) : null,
              isDark: isDark,
              isEmphasis: isLast,
            ),
          ),
        );
      }),
    );
  }
}

class _RateButton extends StatelessWidget {
  final FSRSRating rating;
  final String intervalLabel;
  final bool enabled, isDark, isEmphasis;
  final VoidCallback? onTap;

  const _RateButton({
    required this.rating, required this.intervalLabel,
    required this.enabled, required this.isDark, required this.isEmphasis,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg = isEmphasis
        ? (isDark ? AppTheme.pureWhite : AppTheme.pureBlack)
        : (isDark ? AppTheme.gray800 : AppTheme.gray100);
    final Color fg = isEmphasis
        ? (isDark ? AppTheme.pureBlack : AppTheme.pureWhite)
        : (isDark ? AppTheme.gray200 : AppTheme.gray700);

    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.4,
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(rating.label,
                style: TextStyle(fontSize: 13, fontWeight: AppTheme.weightSemiBold, color: fg)),
            const SizedBox(height: 2),
            Text(intervalLabel,
                style: TextStyle(fontSize: 10, color: fg.withValues(alpha: 0.65))),
          ]),
        ),
      ),
    );
  }
}
