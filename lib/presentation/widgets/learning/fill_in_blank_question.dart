import 'package:flutter/material.dart';
import '../../../domain/entities/entities.dart';
import '../../theme/app_theme.dart';

/// Fill In Blank Question Widget - 填空題 UI
/// 
/// 設計要點：
/// - iOS 風格輸入框
/// - 無邊框，聚焦時 1.5px 黑/白邊框
/// - 顯示句子中的空格
/// - 極簡設計
class FillInBlankQuestionWidget extends StatefulWidget {
  final FillInBlankQuestion question;
  final Function(String) onSubmit;

  const FillInBlankQuestionWidget({
    super.key,
    required this.question,
    required this.onSubmit,
  });

  @override
  State<FillInBlankQuestionWidget> createState() =>
      _FillInBlankQuestionWidgetState();
}

class _FillInBlankQuestionWidgetState
    extends State<FillInBlankQuestionWidget> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Sentence with blank
        _buildSentenceWithBlank(context),
        
        const SizedBox(height: AppTheme.space24),
        
        // Input field
        _buildInputField(context),
        
        const SizedBox(height: AppTheme.space24),
        
        // Submit button
        _buildSubmitButton(context),
      ],
    );
  }

  /// Build sentence with blank placeholder
  Widget _buildSentenceWithBlank(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final parts = widget.question.sentenceWithBlank.split('___');

    return Container(
      padding: const EdgeInsets.all(AppTheme.space20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.gray850 : AppTheme.gray50,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: Theme.of(context).textTheme.bodyLarge,
          children: [
            if (parts.isNotEmpty) TextSpan(text: parts[0]),
            // Blank placeholder
            WidgetSpan(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: AppTheme.space4),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.space16,
                  vertical: AppTheme.space4,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isDark ? AppTheme.gray600 : AppTheme.gray400,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  '     ',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ),
            if (parts.length > 1) TextSpan(text: parts[1]),
          ],
        ),
      ),
    );
  }

  /// Build input field
  Widget _buildInputField(BuildContext context) {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      autofocus: true,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodyLarge,
      decoration: InputDecoration(
        hintText: '輸入答案',
        hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppTheme.gray500
                  : AppTheme.gray400,
            ),
      ),
      onSubmitted: (_) => _handleSubmit(),
    );
  }

  /// Build submit button
  Widget _buildSubmitButton(BuildContext context) {
    return ElevatedButton(
      onPressed: _handleSubmit,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.space16),
      ),
      child: const Text('提交答案'),
    );
  }

  /// Handle submit
  void _handleSubmit() {
    final answer = _controller.text.trim();
    if (answer.isNotEmpty) {
      widget.onSubmit(answer);
    }
  }
}
