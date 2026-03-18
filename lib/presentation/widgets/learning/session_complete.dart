import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../domain/entities/entities.dart';
import '../../theme/app_theme.dart';

/// Session Complete Widget - 會話完成畫面
/// 
/// 設計要點：
/// - 顯示會話統計（大數字 + 小標籤）
/// - 顯示正確率（環形進度圖 - 灰階）
/// - 顯示學習時間
/// - 繼續學習按鈕
/// - 統計數字使用 displayLarge (40px, bold)
/// - 標籤使用 labelMedium (13px, medium)
/// - 環形圖使用 gray200/gray800 背景
/// - 進度使用 pureBlack/pureWhite
/// - 卡片使用 elevatedShadow
/// - 充足留白 space32, space40
class SessionCompleteWidget extends StatelessWidget {
  final SessionStatistics statistics;
  final VoidCallback onContinue;
  final VoidCallback onExit;

  const SessionCompleteWidget({
    super.key,
    required this.statistics,
    required this.onContinue,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.space24),
      child: Column(
        children: [
          const SizedBox(height: AppTheme.space40),
          
          // Completion icon
          _buildCompletionIcon(context, isDark),
          
          const SizedBox(height: AppTheme.space24),
          
          // Title
          Text(
            '完成學習！',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          
          const SizedBox(height: AppTheme.space40),
          
          // Circular progress chart
          _buildCircularProgress(context, isDark),
          
          const SizedBox(height: AppTheme.space40),
          
          // Statistics cards
          _buildStatisticsCards(context, isDark),
          
          const SizedBox(height: AppTheme.space40),
          
          // Action buttons
          _buildActionButtons(context),
        ],
      ),
    );
  }

  /// Build completion icon
  Widget _buildCompletionIcon(BuildContext context, bool isDark) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.gray850 : AppTheme.gray50,
        shape: BoxShape.circle,
        boxShadow: AppTheme.cardShadow,
      ),
      child: Icon(
        Icons.check_circle,
        size: 48,
        color: isDark ? AppTheme.pureWhite : AppTheme.pureBlack,
      ),
    );
  }

  /// Build circular progress chart
  Widget _buildCircularProgress(BuildContext context, bool isDark) {
    final accuracy = statistics.totalReviews > 0
        ? (statistics.correctReviews / statistics.totalReviews)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(AppTheme.space32),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.gray900 : AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: AppTheme.elevatedShadow,
      ),
      child: Column(
        children: [
          // Circular chart
          SizedBox(
            width: 160,
            height: 160,
            child: CustomPaint(
              painter: CircularProgressPainter(
                progress: accuracy,
                backgroundColor: isDark ? AppTheme.gray800 : AppTheme.gray200,
                progressColor: isDark ? AppTheme.pureWhite : AppTheme.pureBlack,
                strokeWidth: 12,
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${(accuracy * 100).toInt()}%',
                      style: Theme.of(context).textTheme.displayLarge,
                    ),
                    Text(
                      '正確率',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build statistics cards
  Widget _buildStatisticsCards(BuildContext context, bool isDark) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                isDark,
                '${statistics.totalReviews}',
                '總複習數',
              ),
            ),
            const SizedBox(width: AppTheme.space16),
            Expanded(
              child: _buildStatCard(
                context,
                isDark,
                '${statistics.correctReviews}',
                '正確數',
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.space16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                isDark,
                '${statistics.newWordsCount}',
                '新單字',
              ),
            ),
            const SizedBox(width: AppTheme.space16),
            Expanded(
              child: _buildStatCard(
                context,
                isDark,
                _formatDuration(statistics.totalTime),
                '學習時間',
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Build individual stat card
  Widget _buildStatCard(
    BuildContext context,
    bool isDark,
    String value,
    String label,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.gray900 : AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: AppTheme.space4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ],
      ),
    );
  }

  /// Build action buttons
  Widget _buildActionButtons(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(
          onPressed: onContinue,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: AppTheme.space16),
          ),
          child: const Text('繼續學習'),
        ),
        const SizedBox(height: AppTheme.space12),
        TextButton(
          onPressed: onExit,
          child: const Text('返回'),
        ),
      ],
    );
  }

  /// Format duration to readable string
  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    if (minutes > 0) {
      return '$minutes分$seconds秒';
    }
    return '$seconds秒';
  }
}

/// Circular Progress Painter - 環形進度圖繪製器
class CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final Color progressColor;
  final double strokeWidth;

  CircularProgressPainter({
    required this.progress,
    required this.backgroundColor,
    required this.progressColor,
    this.strokeWidth = 12,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Draw background circle
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Draw progress arc
    final progressPaint = Paint()
      ..color = progressColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // Start from top
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
