import 'package:flutter/material.dart';
import '../../../domain/entities/entities.dart';
import '../../theme/app_theme.dart';
import 'quiz_choice_view.dart';
import 'quiz_spelling_view.dart';

/// Question Display - 問題顯示與互動
/// 
/// 根據問題類型顯示不同的 UI：
/// - 選擇題：極簡選項卡片
/// - 填空題：iOS 風格輸入框
/// - 拼字題：字母卡片
/// - 句子完成題：文字輸入
class QuestionDisplay extends StatelessWidget {
  final QuizQuestion question;
  final Function(String) onSubmit;

  const QuestionDisplay({
    super.key,
    required this.question,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Question prompt
        _buildPrompt(context),
        
        const SizedBox(height: AppTheme.space24),
        
        // Question type specific UI
        _buildQuestionUI(context),
      ],
    );
  }

  /// Build question prompt
  Widget _buildPrompt(BuildContext context) {
    return Text(
      question.prompt,
      style: Theme.of(context).textTheme.titleMedium,
      textAlign: TextAlign.center,
    );
  }

  /// Build question UI based on type
  Widget _buildQuestionUI(BuildContext context) {
    if (question.type == QuestionType.multipleChoice) {
        return QuizChoiceView(
            question: question,
            showFeedback: false, // Handled by parent usually, but QuestionDisplay might need update
            isCorrect: null,
            selectedAnswer: null,
            onSelect: onSubmit,
            onContinue: () {},
        );
    } else if (question.type == QuestionType.spelling) {
        return QuizSpellingView(
            question: question,
            showFeedback: false,
            isCorrect: null,
            onSubmit: onSubmit,
            onContinue: () {},
        );
    }
    
    // Fallback for others
    return Center(child: Text("此題型尚未支援: ${question.type}"));
  }
}
