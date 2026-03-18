import 'package:flutter/material.dart';
import '../../../domain/entities/entities.dart';
import '../../theme/app_theme.dart';
import 'flip_card.dart';

/// Answer Feedback Widget - 答案反饋 UI
/// 
/// 設計要點：
/// - 顯示正確答案（使用 headlineSmall）
/// - 顯示解釋（使用 bodyMedium）
/// - 品質評分按鈕（0-5 - 極簡圓形按鈕）
/// - 下一題按鈕
/// - 評分按鈕：40px 圓形，gray100/gray800 背景
/// - 選中狀態：pureBlack/pureWhite 背景
/// - 數字使用 labelLarge (15px, medium)
/// - 按鈕間距 space8
/// - 解釋文字 gray600/gray400
/// - 使用 subtleShadow
class AnswerFeedbackWidget extends StatefulWidget {
  final QuizQuestion question;
  final String userAnswer;
  final bool isCorrect;
  final Function(int quality) onQualityRating;
  final VoidCallback onNext;

  const AnswerFeedbackWidget({
    super.key,
    required this.question,
    required this.userAnswer,
    required this.isCorrect,
    required this.onQualityRating,
    required this.onNext,
  });

  @override
  State<AnswerFeedbackWidget> createState() => _AnswerFeedbackWidgetState();
}

class _AnswerFeedbackWidgetState extends State<AnswerFeedbackWidget> {
  int? _selectedQuality;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnswerRevealAnimation(
      child: Container(
        padding: const EdgeInsets.all(AppTheme.space24),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.gray900 : AppTheme.pureWhite,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Result indicator
            _buildResultIndicator(context, isDark),
            
            const SizedBox(height: AppTheme.space20),
            
            // Correct answer
            _buildCorrectAnswer(context, isDark),
            
            const SizedBox(height: AppTheme.space16),
            
            // Explanation
            _buildExplanation(context, isDark),
            
            const SizedBox(height: AppTheme.space24),
            
            // Quality rating
            _buildQualityRating(context, isDark),
            
            const SizedBox(height: AppTheme.space24),
            
            // Next button
            _buildNextButton(context),
          ],
        ),
      ),
    );
  }

  /// Build result indicator (correct/incorrect)
  Widget _buildResultIndicator(BuildContext context, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          widget.isCorrect ? Icons.check_circle : Icons.cancel,
          color: widget.isCorrect
              ? (isDark ? AppTheme.gray300 : AppTheme.gray700)
              : (isDark ? AppTheme.gray500 : AppTheme.gray600),
          size: 32,
        ),
        const SizedBox(width: AppTheme.space12),
        Text(
          widget.isCorrect ? '正確！' : '不正確',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ],
    );
  }

  /// Build correct answer display
  Widget _buildCorrectAnswer(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '正確答案',
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: AppTheme.space8),
        Text(
          widget.question.getCorrectAnswer(),
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ],
    );
  }

  /// Build explanation
  Widget _buildExplanation(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.gray850 : AppTheme.gray50,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Text(
        widget.question.getExplanation(),
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDark ? AppTheme.gray400 : AppTheme.gray600,
            ),
      ),
    );
  }

  /// Build quality rating buttons (0-5)
  Widget _buildQualityRating(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '回想難度',
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: AppTheme.space12),
        
        // Rating buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(
            6,
            (index) => _buildQualityButton(context, index, isDark),
          ),
        ),
        
        const SizedBox(height: AppTheme.space8),
        
        // Rating labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '完全忘記',
              style: Theme.of(context).textTheme.labelSmall,
            ),
            Text(
              '輕鬆回想',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ],
    );
  }

  /// Build individual quality button
  Widget _buildQualityButton(BuildContext context, int quality, bool isDark) {
    final isSelected = _selectedQuality == quality;

    return GestureDetector(
      onTap: () => setState(() => _selectedQuality = quality),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppTheme.pureWhite : AppTheme.pureBlack)
              : (isDark ? AppTheme.gray800 : AppTheme.gray100),
          shape: BoxShape.circle,
          boxShadow: isSelected ? AppTheme.subtleShadow : null,
        ),
        child: Center(
          child: Text(
            quality.toString(),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: isSelected
                      ? (isDark ? AppTheme.pureBlack : AppTheme.pureWhite)
                      : (isDark ? AppTheme.pureWhite : AppTheme.pureBlack),
                ),
          ),
        ),
      ),
    );
  }

  /// Build next button
  Widget _buildNextButton(BuildContext context) {
    final canProceed = _selectedQuality != null;

    return ElevatedButton(
      onPressed: canProceed ? _handleNext : null,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.space16),
        disabledBackgroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppTheme.gray800
            : AppTheme.gray200,
        disabledForegroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppTheme.gray600
            : AppTheme.gray400,
      ),
      child: const Text('下一題'),
    );
  }

  /// Handle next button press
  void _handleNext() {
    if (_selectedQuality != null) {
      widget.onQualityRating(_selectedQuality!);
      widget.onNext();
    }
  }
}
