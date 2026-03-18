import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/translation_providers.dart';
import '../../core/providers/connectivity_providers.dart';
import '../../domain/entities/vocabulary_entity.dart';
import 'audio_button.dart';

/// Example Sentence Widget with translation support
class ExampleSentenceWidget extends ConsumerStatefulWidget {
  final ExamExample example;
  final String lemma;
  final String? sourceTag;
  final bool showTranslation;
  final VoidCallback? onTap;

  const ExampleSentenceWidget({
    super.key,
    required this.example,
    required this.lemma,
    this.sourceTag,
    this.showTranslation = true,
    this.onTap,
  });

  @override
  ConsumerState<ExampleSentenceWidget> createState() => _ExampleSentenceWidgetState();
}

class _ExampleSentenceWidgetState extends ConsumerState<ExampleSentenceWidget> {
  bool _showTranslation = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sentence with highlighting
          _buildHighlightedText(context, widget.example.text, widget.lemma),
          
          const SizedBox(height: 8),
          
          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Source tag
              if (widget.sourceTag != null)
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      widget.sourceTag!,
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              
              const Spacer(),
              
              // Translation button
              if (widget.showTranslation)
                InkWell(
                  onTap: () {
                    setState(() {
                      _showTranslation = !_showTranslation;
                    });
                  },
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _showTranslation ? Icons.translate : Icons.translate_outlined,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _showTranslation ? '隱藏翻譯' : '顯示翻譯',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              
              const SizedBox(width: 8),
              
              // Audio button
              AudioButton(text: widget.example.text, size: 18),
            ],
          ),
          
          // Translation section
          if (_showTranslation) ...[
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),
            _buildTranslationSection(),
          ],
        ],
      ),
    );
  }

  Widget _buildTranslationSection() {
    // Check connectivity status
    final isOffline = ref.watch(isOfflineProvider);
    
    // If offline, show offline message immediately
    if (isOffline) {
      return _buildOfflineMessage();
    }
    
    final translationAsync = ref.watch(
      translationStateProvider(widget.example.text),
    );

    return translationAsync.when(
      data: (translation) => Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.translate,
              size: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                translation,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
      loading: () => Container(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '翻譯中...',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      error: (error, stack) => _buildErrorMessage(error),
    );
  }

  Widget _buildOfflineMessage() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.wifi_off,
            size: 16,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '翻譯功能需要網路連線',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage(Object error) {
    // Check if it's a rate limit error
    final errorString = error.toString();
    final isRateLimitError = errorString.contains('每日翻譯次數上限') ||
        errorString.contains('QUOTA') ||
        errorString.contains('1000次');
    
    final isNetworkError = errorString.contains('網路') ||
        errorString.contains('連線');

    IconData icon;
    Color iconColor;
    String title;
    String message;
    bool showRetryButton;

    if (isRateLimitError) {
      icon = Icons.hourglass_empty;
      iconColor = Theme.of(context).colorScheme.tertiary;
      title = '已達每日翻譯上限';
      message = '免費翻譯服務每日限制 1000 次\n請明天再試，或使用已快取的翻譯';
      showRetryButton = false;
    } else if (isNetworkError) {
      icon = Icons.signal_wifi_off;
      iconColor = Theme.of(context).colorScheme.error;
      title = '網路連線問題';
      message = errorString;
      showRetryButton = true;
    } else {
      icon = Icons.error_outline;
      iconColor = Theme.of(context).colorScheme.error;
      title = '翻譯失敗';
      message = errorString;
      showRetryButton = true;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isRateLimitError
            ? Theme.of(context).colorScheme.tertiaryContainer.withValues(alpha: 0.3)
            : Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isRateLimitError
              ? Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.3)
              : Theme.of(context).colorScheme.error.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                size: 16,
                color: iconColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: iconColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (showRetryButton) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  ref.read(translationStateProvider(widget.example.text).notifier).retry();
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('重試'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHighlightedText(BuildContext context, String text, String highlight) {
    if (highlight.isEmpty) {
      return Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
      );
    }

    final lowerText = text.toLowerCase();
    final lowerHighlight = highlight.toLowerCase();
    
    if (!lowerText.contains(lowerHighlight)) {
      return Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
      );
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
          color: Colors.amber,
        ),
      ));
      
      start = end;
      indexOfHighlight = lowerText.indexOf(lowerHighlight, start);
    }
    
    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }

    return RichText(
      text: TextSpan(
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          height: 1.5,
          color: Theme.of(context).colorScheme.onSurface,
        ),
        children: spans,
      ),
    );
  }
}
