import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../providers/fsrs_learning_provider.dart';

/// 學習時間統計圖表組件
/// 
/// 顯示過去 7 天的學習時間趨勢
class LearningTimeChartWidget extends ConsumerWidget {
  final String userId;

  const LearningTimeChartWidget({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // 獲取過去 7 天的統計數據
    final now = DateTime.now();
    final startDate = now.subtract(const Duration(days: 6));
    final stats = ref.watch(dailyStatsRangeProvider((
      userId: userId,
      startDate: startDate,
      endDate: now,
    )));

    // 計算總學習時間
    final totalMinutes = stats.fold<int>(
      0,
      (sum, stat) => sum + stat.studyTimeSeconds,
    ) ~/ 60;

    // 計算平均學習時間
    final avgMinutes = stats.isNotEmpty ? totalMinutes ~/ stats.length : 0;

    // 找出最大值用於縮放
    final maxMinutes = stats.isEmpty
        ? 60
        : stats.map((s) => s.studyTimeSeconds ~/ 60).reduce((a, b) => a > b ? a : b);
    final chartMax = maxMinutes > 0 ? maxMinutes : 60;

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
          // 標題和統計
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '本週學習時間',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '過去 7 天',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDark ? AppTheme.gray400 : AppTheme.gray600,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatTime(totalMinutes),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '平均 ${_formatTime(avgMinutes)}/天',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDark ? AppTheme.gray400 : AppTheme.gray600,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 24),

          // 圖表
          SizedBox(
            height: 120,
            child: _buildChart(context, isDark, stats, chartMax, startDate),
          ),

          const SizedBox(height: 16),

          // 日期標籤
          _buildDateLabels(context, isDark, startDate),
        ],
      ),
    );
  }

  Widget _buildChart(
    BuildContext context,
    bool isDark,
    List<dynamic> stats,
    int maxMinutes,
    DateTime startDate,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(7, (index) {
        final date = startDate.add(Duration(days: index));
        final dateKey = DateTime.utc(date.year, date.month, date.day);
        
        // 找到對應日期的統計數據
        final stat = stats.cast<dynamic>().firstWhere(
          (s) => s.date.year == dateKey.year && 
                 s.date.month == dateKey.month && 
                 s.date.day == dateKey.day,
          orElse: () => null,
        );

        final minutes = stat != null ? (stat.studyTimeSeconds ~/ 60) : 0;
        final height = maxMinutes > 0 ? (minutes / maxMinutes * 100).clamp(4.0, 100.0) : 4.0;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // 時間標籤
                if (minutes > 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '${minutes}m',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                        color: isDark ? AppTheme.gray400 : AppTheme.gray600,
                      ),
                    ),
                  ),

                // 柱狀圖
                Container(
                  height: height,
                  decoration: BoxDecoration(
                    color: minutes > 0
                        ? (isDark ? AppTheme.gray700 : AppTheme.gray800)
                        : (isDark ? AppTheme.gray850 : AppTheme.gray200),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildDateLabels(BuildContext context, bool isDark, DateTime startDate) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(7, (index) {
        final date = startDate.add(Duration(days: index));
        final weekday = _getWeekdayShort(date.weekday);
        final isToday = date.day == DateTime.now().day &&
            date.month == DateTime.now().month &&
            date.year == DateTime.now().year;

        return Expanded(
          child: Center(
            child: Text(
              weekday,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 11,
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                color: isToday
                    ? (isDark ? AppTheme.pureWhite : AppTheme.pureBlack)
                    : (isDark ? AppTheme.gray500 : AppTheme.gray400),
              ),
            ),
          ),
        );
      }),
    );
  }

  String _getWeekdayShort(int weekday) {
    const weekdays = ['一', '二', '三', '四', '五', '六', '日'];
    return weekdays[weekday - 1];
  }

  String _formatTime(int minutes) {
    if (minutes < 60) {
      return '$minutes分';
    } else {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      return mins > 0 ? '$hours小時$mins分' : '$hours小時';
    }
  }
}
