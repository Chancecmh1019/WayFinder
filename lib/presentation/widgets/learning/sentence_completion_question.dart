import 'package:flutter/material.dart';
import '../../../domain/entities/entities.dart';
import '../../theme/app_theme.dart';

/// Sentence Completion Question Widget - 句子完成題 UI
/// 
/// 設計要點：
/// - 顯示句子開頭和結尾
/// - 文字輸入框
/// - 極簡設計
class SentenceCompletionQuestionWidget extends StatefulWidget {
  final SentenceCompletionQuestion question;
  final Function(String) onSubmit;

  const SentenceCompletionQuestionWidget({
    super.key,
    required this.question,
    required this.onSubmit,
  });

  @override
  State<SentenceCompletionQuestionWidget> createState() =>
      _SentenceCompletionQuestionWidgetState();
}

class _SentenceCompletionQuestionWidgetState
    extends State<SentenceCompletionQuestionWidget> {
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
        // Sentence template
        _buildSentenceTemplate(context),
        
        const SizedBox(height: AppTheme.space24),
        
        // Input field
        _buildInputField(context),
        
        const SizedBox(height: AppTheme.space24),
        
        // Submit button
        _buildSubmitButton(context),
      ],
    );
  }

  /// Build sentence template
  Widget _buildSentenceTemplate(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppTheme.space20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.gray850 : AppTheme.gray50,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sentence start
          if (widget.question.sentenceStart.isNotEmpty)
            Text(
              widget.question.sentenceStart,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          
          // Blank indicator
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppTheme.space8),
            child: Container(
              height: 2,
              width: 100,
              color: isDark ? AppTheme.gray600 : AppTheme.gray400,
            ),
          ),
          
          // Sentence end
          if (widget.question.sentenceEnd.isNotEmpty)
            Text(
              widget.question.sentenceEnd,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
        ],
      ),
    );
  }

  /// Build input field
  Widget _buildInputField(BuildContext context) {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      autofocus: true,
      maxLines: 3,
      style: Theme.of(context).textTheme.bodyLarge,
      decoration: InputDecoration(
        hintText: '完成句子...',
        hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppTheme.gray500
                  : AppTheme.gray400,
            ),
        alignLabelWithHint: true,
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
