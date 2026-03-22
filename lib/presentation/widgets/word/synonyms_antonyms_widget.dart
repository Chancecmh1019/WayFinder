import 'package:flutter/material.dart';

/// 同反義詞組件
/// 顯示同義詞和反義詞，支援點擊跳轉
class SynonymsAntonymsWidget extends StatelessWidget {
  final List<String> synonyms;
  final List<String> antonyms;
  final Function(String)? onWordTap;

  const SynonymsAntonymsWidget({
    super.key,
    this.synonyms = const [],
    this.antonyms = const [],
    this.onWordTap,
  });

  @override
  Widget build(BuildContext context) {
    if (synonyms.isEmpty && antonyms.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 同義詞
        if (synonyms.isNotEmpty) ...[
          _buildSection(
            context,
            title: '同義詞',
            icon: Icons.link,
            words: synonyms,
            color: const Color(0xFF3A3A3A),
          ),
        ],
        
        // 反義詞
        if (antonyms.isNotEmpty) ...[
          if (synonyms.isNotEmpty) const SizedBox(height: 16),
          _buildSection(
            context,
            title: '反義詞',
            icon: Icons.compare_arrows,
            words: antonyms,
            color: const Color(0xFF888888),
          ),
        ],
      ],
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<String> words,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: color,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${words.length}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: words.map((word) {
            return _buildWordChip(context, word, color);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildWordChip(BuildContext context, String word, Color color) {
    final hasCallback = onWordTap != null;
    
    return InkWell(
      onTap: hasCallback ? () => onWordTap!(word) : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              word,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
            if (hasCallback) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_forward,
                size: 14,
                color: color,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
