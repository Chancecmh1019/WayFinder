import 'package:flutter/material.dart';

/// Sense Unlock Indicator Widget
/// 
/// Shows the unlock progress for a word's senses with visual indicators.
class SenseUnlockIndicator extends StatelessWidget {
  final int totalSenses;
  final int unlockedSenses;
  final int masteredSenses;
  final String? unlockHint;
  final bool showHint;

  const SenseUnlockIndicator({
    super.key,
    required this.totalSenses,
    required this.unlockedSenses,
    required this.masteredSenses,
    this.unlockHint,
    this.showHint = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (totalSenses <= 1) {
      // Single sense - no need to show unlock indicator
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lock_open,
                size: 16,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
              const SizedBox(width: 8),
              Text(
                '義項解鎖進度',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                ),
              ),
              const Spacer(),
              Text(
                '$unlockedSenses / $totalSenses',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(totalSenses, (index) {
              return Expanded(
                child: Container(
                  height: 8,
                  margin: EdgeInsets.only(
                    right: index < totalSenses - 1 ? 4 : 0,
                  ),
                  decoration: BoxDecoration(
                    color: _getSenseColor(index, isDark),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              );
            }),
          ),
          if (showHint && unlockHint != null && unlockHint!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 14,
                  color: isDark ? Colors.blue.shade300 : Colors.blue.shade700,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    unlockHint!,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (masteredSenses > 0) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  size: 14,
                  color: Colors.green.shade600,
                ),
                const SizedBox(width: 6),
                Text(
                  '已熟練掌握 $masteredSenses 個義項',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _getSenseColor(int index, bool isDark) {
    if (index < masteredSenses) {
      // Mastered - green
      return isDark ? Colors.green.shade700 : Colors.green.shade400;
    } else if (index < unlockedSenses) {
      // Unlocked but not mastered - blue
      return isDark ? Colors.blue.shade700 : Colors.blue.shade400;
    } else {
      // Locked - grey
      return isDark ? Colors.grey.shade800 : Colors.grey.shade300;
    }
  }
}

/// Compact version for list items
class CompactSenseUnlockIndicator extends StatelessWidget {
  final int totalSenses;
  final int unlockedSenses;
  final int masteredSenses;

  const CompactSenseUnlockIndicator({
    super.key,
    required this.totalSenses,
    required this.unlockedSenses,
    required this.masteredSenses,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (totalSenses <= 1) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          masteredSenses == totalSenses
              ? Icons.check_circle
              : Icons.lock_open,
          size: 14,
          color: masteredSenses == totalSenses
              ? Colors.green.shade600
              : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
        ),
        const SizedBox(width: 4),
        Text(
          '$unlockedSenses/$totalSenses',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}
