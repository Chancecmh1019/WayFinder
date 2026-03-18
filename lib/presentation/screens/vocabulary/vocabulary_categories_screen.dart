import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/vocab_providers.dart';

/// 詞彙分類頁面
/// 
/// 顯示三個主要分類：
/// - 單字 (Words)
/// - 片語 (Phrases)
/// - 文法句型 (Grammar Patterns)
class VocabularyCategoriesScreen extends ConsumerWidget {
  const VocabularyCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(vocabStatisticsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('詞彙分類'),
        elevation: 0,
      ),
      body: statsAsync.when(
        data: (stats) => _buildContent(context, stats),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('載入失敗: $error'),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Map<String, dynamic> stats) {
    final wordCount = stats['words'] as int? ?? 0;
    final phraseCount = stats['phrases'] as int? ?? 0;
    final patternCount = stats['patterns'] as int? ?? 0;
    final officialCount = stats['official'] as int? ?? 0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildCategoryCard(
          context,
          title: '單字',
          subtitle: '$wordCount 個單字',
          icon: Icons.book,
          color: Colors.blue,
          onTap: () {
            Navigator.pushNamed(context, '/words');
          },
        ),
        const SizedBox(height: 16),
        _buildCategoryCard(
          context,
          title: '片語',
          subtitle: '$phraseCount 個片語',
          icon: Icons.chat_bubble,
          color: Colors.green,
          onTap: () {
            Navigator.pushNamed(context, '/phrases');
          },
        ),
        const SizedBox(height: 16),
        _buildCategoryCard(
          context,
          title: '文法句型',
          subtitle: '$patternCount 個句型',
          icon: Icons.school,
          color: Colors.orange,
          onTap: () {
            Navigator.pushNamed(context, '/patterns');
          },
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '統計資訊',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildStatRow('總詞彙數', '${stats['total']}'),
                _buildStatRow('官方字彙表', '$officialCount'),
                if (stats.containsKey('byLevel')) ...[
                  const Divider(height: 24),
                  const Text(
                    '按級別分布',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  ..._buildLevelStats(stats['byLevel'] as Map<dynamic, dynamic>),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildLevelStats(Map<dynamic, dynamic> levelCounts) {
    final sortedLevels = levelCounts.keys.toList()..sort();
    return sortedLevels.map((level) {
      final count = levelCounts[level];
      return _buildStatRow('Level $level', '$count');
    }).toList();
  }
}
