import 'package:flutter/material.dart';
import '../../../domain/entities/vocabulary_entity.dart';

/// 詞根分析組件
/// 顯示詞根拆解、記憶策略和衍生詞
class RootAnalysisWidget extends StatelessWidget {
  final RootInfo rootInfo;
  final List<String> derivedForms;

  const RootAnalysisWidget({
    super.key,
    required this.rootInfo,
    this.derivedForms = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 詞根拆解
        _buildSection(
          context,
          icon: Icons.account_tree,
          title: '詞根拆解',
          content: rootInfo.rootBreakdown,
        ),
        
        const SizedBox(height: 16),
        
        // 記憶策略
        _buildSection(
          context,
          icon: Icons.lightbulb_outline,
          title: '記憶策略',
          content: rootInfo.memoryStrategy,
          iconColor: Colors.amber,
        ),
        
        // 衍生詞
        if (derivedForms.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildDerivedForms(context),
        ],
      ],
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String content,
    Color? iconColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: iconColor ?? Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
        ),
      ],
    );
  }

  Widget _buildDerivedForms(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.format_list_bulleted,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              '衍生詞',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: derivedForms.map((word) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: Text(
                word,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
