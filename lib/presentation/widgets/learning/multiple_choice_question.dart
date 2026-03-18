import 'package:flutter/material.dart';
import '../../../domain/entities/entities.dart';
import '../../theme/app_theme.dart';

/// Multiple Choice Question Widget - 選擇題 UI
/// 
/// 設計要點：
/// - 選項卡片：gray50/gray850 背景，radiusMedium
/// - 選中狀態：pureBlack/pureWhite 背景
/// - 選項間距 space12
/// - 懸停效果：subtleShadow
/// - 過渡 200ms ease-out
class MultipleChoiceQuestionWidget extends StatefulWidget {
  final MultipleChoiceQuestion question;
  final Function(String) onSubmit;

  const MultipleChoiceQuestionWidget({
    super.key,
    required this.question,
    required this.onSubmit,
  });

  @override
  State<MultipleChoiceQuestionWidget> createState() =>
      _MultipleChoiceQuestionWidgetState();
}

class _MultipleChoiceQuestionWidgetState
    extends State<MultipleChoiceQuestionWidget> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Options
        ...List.generate(
          widget.question.options.length,
          (index) => Padding(
            padding: EdgeInsets.only(
              bottom: index < widget.question.options.length - 1
                  ? AppTheme.space12
                  : 0,
            ),
            child: _buildOptionCard(
              context,
              index,
              widget.question.options[index],
            ),
          ),
        ),
        
        const SizedBox(height: AppTheme.space24),
        
        // Submit button
        _buildSubmitButton(context),
      ],
    );
  }

  /// Build option card
  Widget _buildOptionCard(BuildContext context, int index, String option) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _selectedIndex == index;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: isSelected
            ? (isDark ? AppTheme.pureWhite : AppTheme.pureBlack)
            : (isDark ? AppTheme.gray850 : AppTheme.gray50),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: isSelected ? AppTheme.subtleShadow : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _selectedIndex = index),
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.space20,
              vertical: AppTheme.space16,
            ),
            child: Row(
              children: [
                // Option letter (A, B, C, D)
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isDark
                            ? AppTheme.pureBlack.withValues(alpha: 0.1)
                            : AppTheme.pureWhite.withValues(alpha: 0.2))
                        : (isDark ? AppTheme.gray800 : AppTheme.gray100),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      String.fromCharCode(65 + index), // A, B, C, D
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: isSelected
                                ? (isDark
                                    ? AppTheme.pureBlack
                                    : AppTheme.pureWhite)
                                : (isDark
                                    ? AppTheme.pureWhite
                                    : AppTheme.pureBlack),
                          ),
                    ),
                  ),
                ),
                
                const SizedBox(width: AppTheme.space16),
                
                // Option text
                Expanded(
                  child: Text(
                    option,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: isSelected
                              ? (isDark
                                  ? AppTheme.pureBlack
                                  : AppTheme.pureWhite)
                              : (isDark
                                  ? AppTheme.pureWhite
                                  : AppTheme.pureBlack),
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build submit button
  Widget _buildSubmitButton(BuildContext context) {
    final canSubmit = _selectedIndex != null;

    return ElevatedButton(
      onPressed: canSubmit ? _handleSubmit : null,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.space16),
        disabledBackgroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppTheme.gray800
            : AppTheme.gray200,
        disabledForegroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppTheme.gray600
            : AppTheme.gray400,
      ),
      child: const Text('提交答案'),
    );
  }

  /// Handle submit
  void _handleSubmit() {
    if (_selectedIndex != null) {
      widget.onSubmit(widget.question.options[_selectedIndex!]);
    }
  }
}
