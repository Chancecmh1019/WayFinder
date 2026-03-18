
import 'package:flutter/material.dart';
import '../../../domain/entities/quiz_question.dart';
import '../../theme/app_theme.dart';

class QuizSpellingView extends StatefulWidget {
  final QuizQuestion question;
  final bool showFeedback;
  final bool? isCorrect;
  final Function(String) onSubmit;
  final VoidCallback onContinue;

  const QuizSpellingView({
    super.key,
    required this.question,
    required this.showFeedback,
    required this.isCorrect,
    required this.onSubmit,
    required this.onContinue,
  });

  @override
  State<QuizSpellingView> createState() => _QuizSpellingViewState();
}

class _QuizSpellingViewState extends State<QuizSpellingView> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  
  // Tiles logic
  List<String> _shuffledLetters = [];
  List<String?> _answerSlots = [];
  List<int?> _slotToSourceIndex = [];
  Set<int> _usedIndices = {};

  @override
  void initState() {
    super.initState();
    _initQuestion();
  }

  void _initQuestion() {
      // Logic from Svelte: initQuestion()
      final word = widget.question.word;
      // Simple scramble for now
      final letters = word.split('')..shuffle();
      _shuffledLetters = letters;
      _answerSlots = List.filled(letters.length, null);
      _slotToSourceIndex = List.filled(letters.length, null);
      _usedIndices = {};
      _controller.text = "";
      
      // Auto focus on desktop/web, maybe not mobile to avoid keyboard popup immediately?
      // Svelte says: if (window.matchMedia("(min-width: 768px)").matches) focus
      // We'll focus if user taps input.
  }

  void _selectLetter(String letter, int index) {
      if (widget.showFeedback || _usedIndices.contains(index)) return;
      
      final emptyIndex = _answerSlots.indexOf(null);
      if (emptyIndex != -1) {
          setState(() {
             _answerSlots[emptyIndex] = letter;
             _slotToSourceIndex[emptyIndex] = index;
             _usedIndices.add(index);
             _updateInputFromSlots();
          });
      }
  }

  void _removeLetterAt(int index) {
      if (widget.showFeedback) return;
      if (_answerSlots[index] == null) return;

      final sourceIndex = _slotToSourceIndex[index];
      setState(() {
          if (sourceIndex != null) _usedIndices.remove(sourceIndex);
          _answerSlots[index] = null;
          _slotToSourceIndex[index] = null;
          _updateInputFromSlots();
      });
  }

  void _updateInputFromSlots() {
      _controller.text = _answerSlots.where((s) => s != null).join("");
  }

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
                    ),
                    child: Column(
                        children: [
                            // Header Audio
                            Center(
                                child: InkWell(
                                    onTap: () {}, // Play audio logic
                                    borderRadius: BorderRadius.circular(50),
                                    child: Container(
                                        width: 64, height: 64,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                            color: Theme.of(context).primaryColor,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                                BoxShadow(color: Theme.of(context).primaryColor.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))
                                            ]
                                        ),
                                        child: const Icon(Icons.volume_up_rounded, color: Colors.white, size: 32),
                                    ),
                                ),
                            ),
                            const SizedBox(height: 24),

                            // Sentence Context if available (for SpellingQuestion)
                            if (widget.question is SpellingQuestion)
                                Container(
                                    padding: const EdgeInsets.all(16),
                                    margin: const EdgeInsets.only(bottom: 24),
                                    decoration: BoxDecoration(
                                        color: isDark ? AppTheme.gray850 : AppTheme.gray50,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.3)),
                                    ),
                                    child: Text(
                                        (widget.question as SpellingQuestion).definition,
                                        style: const TextStyle(fontSize: 16, height: 1.6, fontFamily: 'Serif'),
                                    ),
                                ),
                            
                            // VocabSense Prompt
                            // Assuming we have definition in question entity, likely distinct from word
                             Text(
                                "VocabSense here...", // Placeholder as QuizQuestion structure needs checking
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                             ),
                             
                             const SizedBox(height: 32),

                             // Input Field (Hidden or Visible?)
                             // Svelte allows both typing and tiles.
                             TextField(
                                 controller: _controller,
                                 focusNode: _focusNode,
                                 textAlign: TextAlign.center,
                                 style: const TextStyle(fontSize: 24, letterSpacing: 2, fontFamily: 'Monospace'),
                                 decoration: InputDecoration(
                                     filled: true,
                                     fillColor: isDark ? AppTheme.gray850 : AppTheme.gray50,
                                     border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                                     hintText: '輸入單字...',
                                 ),
                                 readOnly: widget.showFeedback,
                                 onSubmitted: widget.showFeedback ? null : (val) => widget.onSubmit(val),
                             ),

                             const SizedBox(height: 24),
                             
                             // Tiles (Only if not feedback)
                             if (!widget.showFeedback) ...[
                                 // Slots
                                 Wrap(
                                     spacing: 8, runSpacing: 8,
                                     alignment: WrapAlignment.center,
                                     children: List.generate(_answerSlots.length, (i) {
                                         final char = _answerSlots[i];
                                         return InkWell(
                                             onTap: () => _removeLetterAt(i),
                                             child: Container(
                                                 width: 40, height: 48,
                                                 alignment: Alignment.center,
                                                 decoration: BoxDecoration(
                                                     border: Border.all(color: char != null ? Theme.of(context).primaryColor : Theme.of(context).dividerColor),
                                                     borderRadius: BorderRadius.circular(6),
                                                     color: char != null ? Theme.of(context).canvasColor : Colors.transparent,
                                                 ),
                                                 child: Text(char ?? "", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                             ),
                                         );
                                     }),
                                 ),
                                 const SizedBox(height: 24),
                                 // Letter Grid
                                 Wrap(
                                     spacing: 8, runSpacing: 8,
                                     alignment: WrapAlignment.center,
                                     children: List.generate(_shuffledLetters.length, (i) {
                                         final char = _shuffledLetters[i];
                                         final isUsed = _usedIndices.contains(i);
                                         return IgnorePointer(
                                             ignoring: isUsed,
                                             child: InkWell(
                                                 onTap: () => _selectLetter(char, i),
                                                 child: Opacity(
                                                     opacity: isUsed ? 0.3 : 1.0,
                                                     child: Container(
                                                         width: 40, height: 40,
                                                         alignment: Alignment.center,
                                                         decoration: BoxDecoration(
                                                             color: isDark ? AppTheme.gray800 : Colors.white,
                                                             border: Border.all(color: Theme.of(context).dividerColor),
                                                             borderRadius: BorderRadius.circular(6),
                                                             boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), offset: const Offset(0, 2))]
                                                         ),
                                                         child: Text(char, style: const TextStyle(fontSize: 18)),
                                                     ),
                                                 ),
                                             ),
                                         );
                                     }),
                                 ),
                             ],
                             
                             const SizedBox(height: 32),
                             
                             // Submit Button
                             if (!widget.showFeedback)
                                 SizedBox(
                                     width: double.infinity,
                                     child: ElevatedButton(
                                         onPressed: () => widget.onSubmit(_controller.text),
                                         style: ElevatedButton.styleFrom(
                                             padding: const EdgeInsets.symmetric(vertical: 16),
                                             backgroundColor: Theme.of(context).primaryColor,
                                             foregroundColor: Colors.white,
                                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                         ),
                                         child: const Text("送出答案"),
                                     ),
                                 ),
                        ],
                    ),
                ),
                
                // Continue Button (Feedback)
                if (widget.showFeedback)
                   Padding(
                 padding: const EdgeInsets.only(top: 24),
                 child: SizedBox(
                   width: double.infinity,
                   child: ElevatedButton(
                     onPressed: widget.onContinue,
                     style: ElevatedButton.styleFrom(
                       padding: const EdgeInsets.symmetric(vertical: 16),
                       backgroundColor: widget.isCorrect == true ? Colors.green : Colors.red,
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
}
