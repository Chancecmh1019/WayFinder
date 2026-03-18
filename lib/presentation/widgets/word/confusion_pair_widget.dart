import 'package:flutter/material.dart';
import '../../../domain/entities/vocabulary_entity.dart';

/// 易混淆詞組件
/// 並排對比顯示易混淆詞、辨析說明和記憶技巧
class ConfusionPairWidget extends StatelessWidget {
  final String currentLemma;
  final List<ConfusionNote> confusionNotes;
  final Function(String)? onWordTap;

  const ConfusionPairWidget({
    super.key,
    required this.currentLemma,
    required this.confusionNotes,
    this.onWordTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: confusionNotes.asMap().entries.map((entry) {
        final index = entry.key;
        final note = entry.value;
        
        return Column(
          children: [
            if (index > 0) const SizedBox(height: 16),
            _buildConfusionItem(context, note),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildConfusionItem(BuildContext context, ConfusionNote note) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 對比標題
          Row(
            children: [
              Expanded(
                child: _buildWordChip(
                  context,
                  currentLemma,
                  isPrimary: true,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(
                  Icons.compare_arrows,
                  size: 20,
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              Expanded(
                child: _buildWordChip(
                  context,
                  note.confusedWith,
                  isPrimary: false,
                  onTap: onWordTap != null
                      ? () => onWordTap!(note.confusedWith)
                      : null,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // 辨析說明
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '辨析',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  note.distinction,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        height: 1.5,
                      ),
                ),
              ],
            ),
          ),
          
          // 記憶技巧
          if (note.memoryTip != null && note.memoryTip!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.amber.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 16,
                    color: Colors.amber.shade700,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      note.memoryTip!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                            height: 1.5,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWordChip(
    BuildContext context,
    String word, {
    required bool isPrimary,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isPrimary
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              word,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isPrimary
                        ? Theme.of(context).colorScheme.onPrimaryContainer
                        : Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_forward,
                size: 14,
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
