
import 'package:flutter/material.dart';
import '../../../domain/entities/quiz_question.dart';
import '../../theme/app_theme.dart';

class QuizChoiceView extends StatefulWidget {
  final QuizQuestion question;
  final bool showFeedback;
  final bool? isCorrect;
  final String? selectedAnswer;
  final Function(String) onSelect;
  final VoidCallback onContinue;

  const QuizChoiceView({
    super.key,
    required this.question,
    required this.showFeedback,
    required this.isCorrect,
    required this.selectedAnswer,
    required this.onSelect,
    required this.onContinue,
  });

  @override
  State<QuizChoiceView> createState() => _QuizChoiceViewState();
}

class _QuizChoiceViewState extends State<QuizChoiceView> {
  // Define helper getters
  bool get _isFillType => widget.question.type == QuestionType.fillInBlank;
  
  // Note: VocabularyEntity structure in QuizQuestion might differ slightly, assuming QuizQuestion structure matches
  // Let's assume QuizQuestion has similar fields to the Svelte version:
  // lemma, sentence_context, type, options, etc. 
  // IMPORTANT: The existing QuizQuestion in Dart might need update if it lacks these fields.
  // For now I will assume the structure passed in `question` is compatible or I will access dynamic props if needed.

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
       child: Column(
          children: [
             // Card
             Container(
               width: double.infinity,
               padding: const EdgeInsets.all(24),
               decoration: BoxDecoration(
                 color: isDark ? AppTheme.gray900 : AppTheme.pureWhite,
                 borderRadius: BorderRadius.circular(16),
                 border: Border.all(color: isDark ? AppTheme.gray800 : AppTheme.gray200),
                 boxShadow: [
                   BoxShadow(
                     color: Colors.black.withValues(alpha: 0.05),
                     offset: const Offset(0, 4),
                     blurRadius: 12,
                   )
                 ]
               ),
               child: Column(
                 children: [
                   // Prompt Area
                   _buildPromptArea(context),
                   
                   const SizedBox(height: 32),
                   
                   // Options Area
                   _buildOptionsList(context),
                 ],
               ),
             ),
             
             // Continue Button (Only in feedback mode)
             if (widget.showFeedback)
               Padding(
                 padding: const EdgeInsets.only(top: 24),
                 child: SizedBox(
                   width: double.infinity,
                   child: ElevatedButton(
                     onPressed: widget.onContinue,
                     style: ElevatedButton.styleFrom(
                       padding: const EdgeInsets.symmetric(vertical: 16),
                       backgroundColor: widget.isCorrect == true ? const Color(0xFF3A3A3A) : const Color(0xFF888888),
                       foregroundColor: Colors.white,
                       elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                     ),
                     child: Text(widget.isCorrect == true ? "答對了！繼續" : "答錯了！繼續"),
                   ),
                 ),
               )
          ],
       ),
    );
  }
  
  Widget _buildPromptArea(BuildContext context) {
      if (_isFillType && widget.question is FillInBlankQuestion) {
          final fillQuestion = widget.question as FillInBlankQuestion;
          final sentence = fillQuestion.sentenceWithBlank;
          return Column(
              children: [
                  Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark ? AppTheme.gray850 : AppTheme.gray50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                               // Using dummy HighlightedText logic for blank
                               _buildSentenceWithBlank(context, sentence, widget.question.word),
                          ],
                      ),
                  ),
              ],
          );
      } else {
         // Recognition or Reverse
         // Assuming simple recognition for now: Show Word -> Pick Def
         return Column(
             children: [
                 Text(
                     widget.question.word,
                     style: Theme.of(context).textTheme.headlineMedium,
                 ),
             ],
         );
      }
  }

  Widget _buildSentenceWithBlank(BuildContext context, String sentence, String target) {
      // Very basic blank replacement
      // In Svelte: sentence_context.replace(/_+/g, lemma)
      // Here we might receive "This is a ____."
      // We want to highlight or blank out.
      
      // If showing feedback, show filled word. If not, show blank.
      
      final displaySentence = widget.showFeedback 
           ? sentence.replaceAll("____", target).replaceAll("___", target) // weak regex replacement
           : sentence;
      
      return Text(
          displaySentence,
          style: const TextStyle(fontSize: 18, height: 1.6, fontFamily: 'Serif'), 
      );
  }

  Widget _buildOptionsList(BuildContext context) {
      if (widget.question is! MultipleChoiceQuestion) {
        return const SizedBox.shrink();
      }
      
      final mcQuestion = widget.question as MultipleChoiceQuestion;
      return Column(
          children: mcQuestion.options.asMap().entries.map((entry) {
              final idx = entry.key;
              final option = entry.value;
              final isSelected = widget.selectedAnswer == option;
              final correctAnswer = mcQuestion.getCorrectAnswer();
              final isCorrectOpt = option == correctAnswer; 
              
              // Status logic
              bool isCorrectState = false;
              bool isWrongState = false;
              bool isFaded = false;
              
              if (widget.showFeedback) {
                  if (isCorrectOpt) {
                    isCorrectState = true;
                  } else if (isSelected) {
                    isWrongState = true;
                  } else {
                    isFaded = true;
                  }
              }
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                    onTap: widget.showFeedback ? null : () => widget.onSelect(option),
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                        decoration: BoxDecoration(
                            color: isCorrectState ? const Color(0xFF3A3A3A).withValues(alpha: 0.1) 
                                 : isWrongState ? const Color(0xFF888888).withValues(alpha: 0.1)
                                 : Theme.of(context).brightness == Brightness.dark ? AppTheme.gray850 : AppTheme.pureWhite, // Bg
                            border: Border.all(
                                color: isCorrectState ? const Color(0xFF3A3A3A) 
                                     : isWrongState ? const Color(0xFF888888)
                                     : Theme.of(context).dividerColor,
                                width: (isCorrectState || isWrongState) ? 2 : 1
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: isSelected && !widget.showFeedback ? [
                                BoxShadow(color: Theme.of(context).primaryColor.withValues(alpha: 0.2), blurRadius: 8)
                            ] : [],
                        ),
                        child: Row(
                            children: [
                                Container(
                                    width: 28, height: 28,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                        color: isCorrectState ? const Color(0xFF3A3A3A) 
                                             : isWrongState ? const Color(0xFF888888) 
                                             : Colors.grey.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                        "${idx + 1}",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: (isCorrectState || isWrongState) ? Colors.white : Colors.grey,
                                        ),
                                    ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                    child: Text(
                                        option,
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: isFaded ? Theme.of(context).colorScheme.outline.withValues(alpha: 0.5) : Theme.of(context).colorScheme.onSurface,
                                        ),
                                    ),
                                ),
                                if (isCorrectState)
                                    Icon(Icons.check_circle, color: Color(0xFF3A3A3A)),
                                if (isWrongState)
                                    Icon(Icons.cancel, color: Color(0xFF888888)),
                            ],
                        ),
                    ),
                ),
              );
          }).toList(),
      );
  }

}
