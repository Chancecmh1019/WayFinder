import 'package:flutter/material.dart';
import '../../../data/models/vocab_models_enhanced.dart';
import '../../theme/app_theme.dart';

/// 單字學習輔助資訊區塊
/// 顯示 v6.1.0 新增的欄位：collocations, usage_notes, grammar_notes, common_mistakes
class WordLearningAidsSection extends StatelessWidget {
  final List<CollocationModel> collocations;
  final String? usageNotes;
  final String? grammarNotes;
  final String? commonMistakes;
  final bool isDark;

  const WordLearningAidsSection({
    super.key,
    required this.collocations,
    this.usageNotes,
    this.grammarNotes,
    this.commonMistakes,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    // 如果所有欄位都是空的，不顯示
    if (collocations.isEmpty &&
        usageNotes == null &&
        grammarNotes == null &&
        commonMistakes == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Collocations
        if (collocations.isNotEmpty) ...[
          _SectionLabel('常見搭配'),
          _buildCollocations(),
          const SizedBox(height: 16),
        ],

        // Usage Notes
        if (usageNotes != null) ...[
          _SectionLabel('用法說明'),
          _buildInfoCard(usageNotes!, Icons.info_outline),
          const SizedBox(height: 16),
        ],

        // Grammar Notes
        if (grammarNotes != null) ...[
          _SectionLabel('文法規則'),
          _buildInfoCard(grammarNotes!, Icons.menu_book_outlined),
          const SizedBox(height: 16),
        ],

        // Common Mistakes
        if (commonMistakes != null) ...[
          _SectionLabel('常見錯誤'),
          _buildMistakesCard(commonMistakes!),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _buildCollocations() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: collocations.map((collocation) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.gray900 : AppTheme.pureWhite,
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            border: Border.all(
              color: isDark ? AppTheme.gray800 : AppTheme.gray200,
            ),
            boxShadow: isDark ? null : AppTheme.subtleShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                collocation.english,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamilyEnglish,
                  fontSize: 14,
                  fontWeight: AppTheme.weightMedium,
                  color: isDark ? AppTheme.pureWhite : AppTheme.pureBlack,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                collocation.chinese,
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.gray600,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInfoCard(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.gray900 : AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: isDark ? null : AppTheme.subtleShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: isDark ? AppTheme.gray400 : AppTheme.gray600,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppTheme.gray300 : AppTheme.gray700,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMistakesCard(String text) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.gray950 : AppTheme.gray950,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 20,
            color: AppTheme.gray400,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.gray300,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(
            text,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: AppTheme.weightSemiBold,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(height: 0.5, color: AppTheme.dividerGray),
          ),
        ],
      ),
    );
  }
}
