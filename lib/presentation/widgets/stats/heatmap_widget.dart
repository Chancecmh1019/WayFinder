import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../providers/fsrs_learning_provider.dart';

/// 學習熱力圖組件
/// 
/// 顯示過去 90 天的學習情況
/// 使用極簡黑白灰配色
class HeatmapWidget extends ConsumerWidget {
  final String userId;

  const HeatmapWidget({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 獲取過去 90 天的統計數據
    final now = DateTime.now();
    final startDate = now.subtract(const Duration(days: 89));
    final stats = ref.watch(dailyStatsRangeProvider((
      userId: userId,
      startDate: startDate,
      endDate: now,
    )));

    // 轉換為熱力圖數據
    final heatmapData = _convertToHeatmapData(stats, startDate, now);

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
          // 熱力圖網格
          _buildHeatmapGrid(context, heatmapData, isDark),
          
          const SizedBox(height: 16),
          
          // 圖例
          _buildLegend(context, isDark),
        ],
      ),
    );
  }

  List<int> _convertToHeatmapData(
    List<dynamic> stats,
    DateTime startDate,
    DateTime endDate,
  ) {
    final data = <int>[];
    
    for (int i = 0; i < 90; i++) {
      final date = startDate.add(Duration(days: i));
      final dateKey = DateTime.utc(date.year, date.month, date.day);
      
      // 找到對應日期的統計數據
      final stat = stats.cast<dynamic>().firstWhere(
        (s) => s.date.year == dateKey.year && 
               s.date.month == dateKey.month && 
               s.date.day == dateKey.day,
        orElse: () => null,
      );
      
      data.add(stat != null ? stat.totalReviews : 0);
    }
    
    return data;
  }

  Widget _buildHeatmapGrid(BuildContext context, List<int> data, bool isDark) {
    const cellSize = 12.0;
    const cellSpacing = 4.0;
    const daysPerRow = 7;
    final rows = (data.length / daysPerRow).ceil();

    return SizedBox(
      height: rows * (cellSize + cellSpacing),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: daysPerRow,
          mainAxisSpacing: cellSpacing,
          crossAxisSpacing: cellSpacing,
          childAspectRatio: 1,
        ),
        itemCount: data.length,
        itemBuilder: (context, index) {
          final value = data[index];
          return _buildHeatmapCell(context, value, isDark);
        },
      ),
    );
  }

  Widget _buildHeatmapCell(BuildContext context, int value, bool isDark) {
    // 使用灰階表示活動強度
    Color color;
    if (value == 0) {
      // 無活動 - 最淺灰
      color = isDark ? AppTheme.gray850 : AppTheme.gray100;
    } else if (value < 5) {
      // 少量活動
      color = isDark ? AppTheme.gray700 : AppTheme.gray300;
    } else if (value < 10) {
      // 中等活動
      color = isDark ? AppTheme.gray600 : AppTheme.gray500;
    } else if (value < 15) {
      // 較多活動
      color = isDark ? AppTheme.gray500 : AppTheme.gray700;
    } else {
      // 大量活動 - 最深灰/黑
      color = isDark ? AppTheme.gray400 : AppTheme.gray800;
    }

    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildLegend(BuildContext context, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '少',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: isDark ? AppTheme.gray500 : AppTheme.gray500,
            fontSize: 11,
          ),
        ),
        const SizedBox(width: 8),
        _buildLegendCell(isDark ? AppTheme.gray850 : AppTheme.gray100),
        const SizedBox(width: 4),
        _buildLegendCell(isDark ? AppTheme.gray700 : AppTheme.gray300),
        const SizedBox(width: 4),
        _buildLegendCell(isDark ? AppTheme.gray600 : AppTheme.gray500),
        const SizedBox(width: 4),
        _buildLegendCell(isDark ? AppTheme.gray500 : AppTheme.gray700),
        const SizedBox(width: 4),
        _buildLegendCell(isDark ? AppTheme.gray400 : AppTheme.gray800),
        const SizedBox(width: 8),
        Text(
          '多',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: isDark ? AppTheme.gray500 : AppTheme.gray500,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildLegendCell(Color color) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
