import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../../core/providers/vocab_providers.dart';

/// 字根字首學習畫面
/// 
/// 透過字根字首來學習和記憶單字
class RootLearningScreen extends ConsumerStatefulWidget {
  const RootLearningScreen({super.key});

  @override
  ConsumerState<RootLearningScreen> createState() => _RootLearningScreenState();
}

class _RootLearningScreenState extends ConsumerState<RootLearningScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allWordsAsync = ref.watch(allWordsProvider);

    return Scaffold(
      backgroundColor: isDark ? AppTheme.pureBlack : AppTheme.offWhite,
      body: SafeArea(
        child: Column(
          children: [
            // App Bar
            Container(
              padding: const EdgeInsets.all(AppTheme.space16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Text(
                      '字根字首學習',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.space24),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: '搜尋字根、字首...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: isDark ? AppTheme.gray900 : AppTheme.gray50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppTheme.space16),

            // Content
            Expanded(
              child: allWordsAsync.when(
                data: (words) {
                  // 過濾有字根資訊的單字
                  final wordsWithRoots = words.where((word) => 
                    word.rootInfo != null && 
                    word.rootInfo!.rootBreakdown.isNotEmpty
                  ).toList();

                  if (_searchQuery.isNotEmpty) {
                    final lowerQuery = _searchQuery.toLowerCase();
                    wordsWithRoots.retainWhere((word) =>
                      word.rootInfo!.rootBreakdown.toLowerCase().contains(lowerQuery) ||
                      word.lemma.toLowerCase().contains(lowerQuery)
                    );
                  }

                  if (wordsWithRoots.isEmpty) {
                    return Center(
                      child: Text(
                        _searchQuery.isEmpty ? '沒有字根資料' : '找不到相關字根',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: AppTheme.space24),
                    itemCount: wordsWithRoots.length,
                    itemBuilder: (context, index) {
                      final word = wordsWithRoots[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppTheme.space12),
                        child: _buildRootCard(context, isDark, word),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(child: Text('載入失敗: $error')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRootCard(BuildContext context, bool isDark, dynamic word) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.gray900 : AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: isDark ? null : AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 單字
          Text(
            word.lemma,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontFamily: AppTheme.fontFamilyEnglish,
            ),
          ),
          const SizedBox(height: AppTheme.space8),
          
          // 字根拆解
          Container(
            padding: const EdgeInsets.all(AppTheme.space12),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.gray800 : AppTheme.gray50,
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '字根拆解',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  word.rootInfo!.rootBreakdown,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          
          // 記憶策略
          if (word.rootInfo!.memoryStrategy.isNotEmpty) ...[
            const SizedBox(height: AppTheme.space12),
            Container(
              padding: const EdgeInsets.all(AppTheme.space12),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.gray800 : AppTheme.gray50,
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        size: 16,
                        color: isDark ? AppTheme.gray400 : AppTheme.gray600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '記憶技巧',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    word.rootInfo!.memoryStrategy,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
          
          // 定義
          if (word.senses.isNotEmpty) ...[
            const SizedBox(height: AppTheme.space12),
            Text(
              word.senses.first.zhDef,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDark ? AppTheme.gray300 : AppTheme.gray700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
