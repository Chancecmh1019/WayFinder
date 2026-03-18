import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// 快速操作按鈕組件
/// 
/// 包含三種按鈕樣式：
/// 1. 主要按鈕（Primary）- 黑底白字
/// 2. 次要按鈕（Secondary）- 白底黑字帶邊框
/// 3. 文字按鈕（Text）- 純文字
class QuickActionButtons extends StatelessWidget {
  final VoidCallback? onStartLearning;
  final VoidCallback? onBrowseWords;
  final VoidCallback? onViewStatistics;

  const QuickActionButtons({
    super.key,
    this.onStartLearning,
    this.onBrowseWords,
    this.onViewStatistics,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 主要按鈕 - 開始學習
        _PrimaryButton(
          onPressed: onStartLearning,
          label: '開始學習',
          icon: Icons.play_arrow_rounded,
        ),
        const SizedBox(height: AppTheme.space12),

        // 次要按鈕 - 瀏覽單字
        _SecondaryButton(
          onPressed: onBrowseWords,
          label: '瀏覽單字',
          icon: Icons.book_outlined,
        ),
        const SizedBox(height: AppTheme.space12),

        // 文字按鈕 - 查看統計
        _TextButton(
          onPressed: onViewStatistics,
          label: '查看統計',
          icon: Icons.bar_chart_outlined,
        ),
      ],
    );
  }
}

/// 主要按鈕 - 黑底白字
class _PrimaryButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final String label;
  final IconData? icon;

  const _PrimaryButton({
    required this.onPressed,
    required this.label,
    this.icon,
  });

  @override
  State<_PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<_PrimaryButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.space24,
            vertical: AppTheme.space14,
          ),
          decoration: BoxDecoration(
            color: AppTheme.pureBlack,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(
                  widget.icon,
                  color: AppTheme.pureWhite,
                  size: 20,
                ),
                const SizedBox(width: AppTheme.space8),
              ],
              Text(
                widget.label,
                style: const TextStyle(
                  fontSize: AppTheme.fontSize16,
                  fontWeight: AppTheme.weightSemiBold,
                  color: AppTheme.pureWhite,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 次要按鈕 - 白底黑字帶邊框
class _SecondaryButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final String label;
  final IconData? icon;

  const _SecondaryButton({
    required this.onPressed,
    required this.label,
    this.icon,
  });

  @override
  State<_SecondaryButton> createState() => _SecondaryButtonState();
}

class _SecondaryButtonState extends State<_SecondaryButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.space24,
            vertical: AppTheme.space14,
          ),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(
              color: AppTheme.gray300,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(
                  widget.icon,
                  color: AppTheme.pureBlack,
                  size: 20,
                ),
                const SizedBox(width: AppTheme.space8),
              ],
              Text(
                widget.label,
                style: const TextStyle(
                  fontSize: AppTheme.fontSize16,
                  fontWeight: AppTheme.weightMedium,
                  color: AppTheme.pureBlack,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 文字按鈕 - 純文字
class _TextButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final String label;
  final IconData? icon;

  const _TextButton({
    required this.onPressed,
    required this.label,
    this.icon,
  });

  @override
  State<_TextButton> createState() => _TextButtonState();
}

class _TextButtonState extends State<_TextButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onPressed,
      child: AnimatedOpacity(
        opacity: _isPressed ? 0.6 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.space24,
            vertical: AppTheme.space14,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(
                  widget.icon,
                  color: AppTheme.pureBlack,
                  size: 20,
                ),
                const SizedBox(width: AppTheme.space8),
              ],
              Text(
                widget.label,
                style: const TextStyle(
                  fontSize: AppTheme.fontSize16,
                  fontWeight: AppTheme.weightMedium,
                  color: AppTheme.pureBlack,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
