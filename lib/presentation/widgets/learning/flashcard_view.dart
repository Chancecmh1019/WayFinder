
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../../domain/entities/vocabulary_entity.dart';
import '../audio_button.dart';

class FlashcardView extends StatefulWidget {
  final VocabularyEntity vocabulary;
  final bool isFlipped;
  final VoidCallback onFlip;
  
  // Optional: Pass current sense index if handling multiple senses
  final int currentSenseIndex;

  const FlashcardView({
    super.key,
    required this.vocabulary,
    required this.isFlipped,
    required this.onFlip,
    this.currentSenseIndex = 0,
  });

  @override
  State<FlashcardView> createState() => _FlashcardViewState();
}

class _FlashcardViewState extends State<FlashcardView> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _frontAnimation;
  late Animation<double> _backAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _frontAnimation = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -1.57), weight: 50),
      TweenSequenceItem(tween: ConstantTween(-1.57), weight: 50),
    ]).animate(_controller);

    _backAnimation = TweenSequence([
      TweenSequenceItem(tween: ConstantTween(1.57), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.57, end: 0.0), weight: 50),
    ]).animate(_controller);

    if (widget.isFlipped) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(FlashcardView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isFlipped != oldWidget.isFlipped) {
      if (widget.isFlipped) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onFlip,
      child: Stack(
        children: [
          // Front
          AnimatedBuilder(
            animation: _frontAnimation,
            builder: (context, child) {
              final angle = _frontAnimation.value;
              final transform = Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(angle);
              return Transform(
                transform: transform,
                alignment: Alignment.center,
                child: angle < -1.57 ? const SizedBox.shrink() : _buildFront(context),
              );
            },
          ),
          
          // Back
          AnimatedBuilder(
            animation: _backAnimation,
            builder: (context, child) {
              final angle = _backAnimation.value;
              final transform = Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(angle);
              return Transform(
                transform: transform,
                alignment: Alignment.center,
                child: angle > 1.57 ? const SizedBox.shrink() : _buildBack(context),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCardBase(BuildContext context, {required Widget child}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 320),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.gray900 : AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, 8),
            blurRadius: 24,
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildFront(BuildContext context) {
    final sense = widget.vocabulary.senses.isNotEmpty 
        ? widget.vocabulary.senses[widget.currentSenseIndex] 
        : null;
    
    final example = sense?.generatedExample;

    return _buildCardBase(
      context,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            widget.vocabulary.lemma,
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          if (example != null) ...[
            const SizedBox(height: 24),
            Text(
              example,
              style: TextStyle(
                fontSize: 15,
                height: 1.7,
                color: Theme.of(context).colorScheme.outline,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 32),
          AudioButton(text: widget.vocabulary.lemma, size: 28.0),
        ],
      ),
    );
  }

  Widget _buildBack(BuildContext context) {
    final sense = widget.vocabulary.senses.isNotEmpty 
        ? widget.vocabulary.senses[widget.currentSenseIndex] 
        : null;
    final totalSenses = widget.vocabulary.senses.length;

    if (sense == null) return _buildCardBase(context, child: const SizedBox());

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return _buildCardBase(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center, // Center vertically
        children: [
          // Word Meta
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                widget.vocabulary.lemma,
                style: const TextStyle(
                  fontSize: 28, // Slightly smaller than front
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                sense.pos,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ],
          ),
          
          if (totalSenses > 1)
             Padding(
               padding: const EdgeInsets.only(top: 4),
               child: Text(
                 "${widget.currentSenseIndex + 1}/$totalSenses",
                 style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5)),
               ),
             ),

          const SizedBox(height: 16),
          
          // VocabSense
          Text(
            sense.zhDef,
            style: const TextStyle(
              fontSize: 18,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),

          // Memory Tip
          if (widget.vocabulary.rootInfo != null && widget.vocabulary.rootInfo!.memoryStrategy.isNotEmpty) ...[
             const SizedBox(height: 16),
             Container(
               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
               decoration: BoxDecoration(
                 color: isDark ? AppTheme.gray850 : AppTheme.gray50,
                 borderRadius: BorderRadius.circular(8),
               ),
               child: Text(
                 widget.vocabulary.rootInfo!.memoryStrategy,
                 style: TextStyle(
                   fontSize: 13,
                   color: Theme.of(context).colorScheme.secondary,
                 ),
                 textAlign: TextAlign.center,
               ),
             ),
          ],

          // Example
          if (sense.generatedExample != null) ...[
            const SizedBox(height: 24),
            // We need a non-interactive highlight text for the card back usually, 
            // relying on our HighlightedText logic from the other component
            // But here we'll just style it simply for now to match the "HighlightedText" intent
             _buildHighlightedText(context, sense.generatedExample!, widget.vocabulary.lemma),
          ],
          
          const SizedBox(height: 24),
          
          Row(
             mainAxisAlignment: MainAxisAlignment.center,
             children: [
                AudioButton(text: widget.vocabulary.lemma, size: 28.0),
                if (sense.generatedExample != null) ...[
                   const SizedBox(width: 16),
                   AudioButton(text: sense.generatedExample!, size: 28.0),
                ]
             ],
          )
        ],
      ),
    );
  }

  // Reusing the logic from other component, but inline here for simplicity in this file for now
  Widget _buildHighlightedText(BuildContext context, String text, String highlight) {
    if (highlight.isEmpty) return Text(text, textAlign: TextAlign.center, style: TextStyle(height: 1.6, color: Theme.of(context).colorScheme.onSurfaceVariant));

    final lowerText = text.toLowerCase();
    final lowerHighlight = highlight.toLowerCase();
    
    if (!lowerText.contains(lowerHighlight)) {
       return Text(text, textAlign: TextAlign.center, style: TextStyle(height: 1.6, color: Theme.of(context).colorScheme.onSurfaceVariant));
    }

    final List<TextSpan> spans = [];
    int start = 0;
    int indexOfHighlight = lowerText.indexOf(lowerHighlight, start);

    while (indexOfHighlight != -1) {
      if (indexOfHighlight > start) {
        spans.add(TextSpan(text: text.substring(start, indexOfHighlight)));
      }
      
      final end = indexOfHighlight + lowerHighlight.length;
      spans.add(TextSpan(
        text: text.substring(indexOfHighlight, end),
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.amber, // Highlight color
        ),
      ));
      
      start = end;
      indexOfHighlight = lowerText.indexOf(lowerHighlight, start);
    }
    
    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }

    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: TextStyle(fontSize: 15, height: 1.6, color: Theme.of(context).colorScheme.onSurfaceVariant),
        children: spans,
      ),
    );
  }
}
