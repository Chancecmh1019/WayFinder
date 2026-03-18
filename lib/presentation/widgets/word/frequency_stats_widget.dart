import 'package:flutter/material.dart';
import '../../../domain/entities/vocabulary_entity.dart';

/// 頻率統計組件
/// 顯示 tested_count、year_spread、importance_score、年份分布等統計資訊
class FrequencyStatsWidget extends StatelessWidget {
  final FrequencyData frequency;
  final List<VocabSense>? senses;

  const FrequencyStatsWidget({
    super.key,
    required this.frequency,
    this.senses,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 核心統計指標
        _buildCoreStats(context),
        
        const SizedBox(height: 16),
        
        // 年份分布
        if (frequency.years.isNotEmpty) ...[
          _buildYearDistribution(context),
          const SizedBox(height: 16),
        ],
        
        // 按角色分布
        if (frequency.byRole.isNotEmpty) ...[
          _buildDistributionSection(
            context,
            title: '按題目角色',
            icon: Icons.assignment,
            data: frequency.byRole,
          ),
          const SizedBox(height: 16),
        ],
        
        // 按題型分布
        if (frequency.bySection.isNotEmpty) ...[
          _buildDistributionSection(
            context,
            title: '按題型',
            icon: Icons.category,
            data: frequency.bySection,
          ),
          const SizedBox(height: 16),
        ],
        
        // 按考試類型分布
        if (frequency.byExamType.isNotEmpty) ...[
          _buildDistributionSection(
            context,
            title: '按考試類型',
            icon: Icons.school,
            data: frequency.byExamType,
          ),
        ],
      ],
    );
  }

  Widget _buildCoreStats(BuildContext context) {
    final importancePercentage = (frequency.importanceScore * 100).round();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          // 重要性分數
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '重要性',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '$importancePercentage',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                        Text(
                          '%',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              Expanded(
                child: _buildStatItem(
                  context,
                  label: '出現次數',
                  value: frequency.totalAppearances.toString(),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          Divider(color: Theme.of(context).colorScheme.outlineVariant),
          const SizedBox(height: 12),
          
          // 其他統計
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  context,
                  label: '考過次數',
                  value: frequency.testedCount.toString(),
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  context,
                  label: '年份跨度',
                  value: frequency.yearSpread.toString(),
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  context,
                  label: '活躍考題',
                  value: frequency.activeTestedCount.toString(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, {required String label, required String value}) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildYearDistribution(BuildContext context) {
    final sortedYears = List<int>.from(frequency.years)..sort();
    final minYear = sortedYears.first;
    final maxYear = sortedYears.last;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.calendar_today,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              '年份分布',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Spacer(),
            Text(
              '$minYear - $maxYear',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: sortedYears.map((year) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  year.toString(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSecondaryContainer,
                      ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDistributionSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Map<String, int> data,
  }) {
    final sortedEntries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: sortedEntries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _formatLabel(entry.key),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        entry.value.toString(),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  String _formatLabel(String key) {
    // 格式化標籤顯示
    final labelMap = {
      'gsat': '學測',
      'gsat_makeup': '學測補考',
      'ast': '指考',
      'ast_makeup': '指考補考',
      'gsat_trial': '學測試辦',
      'gsat_ref': '學測參考',
      'vocabulary': '詞彙',
      'cloze': '綜合測驗',
      'discourse': '文意選填',
      'structure': '篇章結構',
      'reading': '閱讀測驗',
      'translation': '翻譯',
      'mixed': '混合',
      'tested': '考題',
      'option': '選項',
      'article': '文章',
    };
    
    return labelMap[key] ?? key;
  }
}
