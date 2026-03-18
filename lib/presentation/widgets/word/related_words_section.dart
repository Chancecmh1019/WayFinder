import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../theme/text_theme_extensions.dart';

/// Related words section with chips
class RelatedWordsSection extends StatelessWidget {
  final String title;
  final List<String> words;
  final VoidCallback? onWordTap;

  const RelatedWordsSection({
    super.key,
    required this.title,
    required this.words,
    this.onWordTap,
  });

  @override
  Widget build(BuildContext context) {
    if (words.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.titleMedium,
        ),
        const SizedBox(height: AppTheme.space12),
        Wrap(
          spacing: AppTheme.space8,
          runSpacing: AppTheme.space8,
          children: words.map((word) {
            return _WordChip(
              word: word,
              onTap: onWordTap,
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _WordChip extends StatelessWidget {
  final String word;
  final VoidCallback? onTap;

  const _WordChip({
    required this.word,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: AppTheme.gray100,
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        ),
        child: Text(
          word,
          style: AppTextStyles.labelMedium,
        ),
      ),
    );
  }
}
