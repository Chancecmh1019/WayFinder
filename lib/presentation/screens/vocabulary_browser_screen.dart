
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/vocabulary_entity.dart';
import '../theme/app_theme.dart';
import '../providers/vocabulary_browser_provider.dart';
import '../widgets/skeleton_loader.dart';
import 'browse/word_detail_screen.dart';
import '../widgets/advanced_filter_sheet.dart';
import 'root_dictionary_screen.dart';

/// Helper function to get CEFR level name
String getLevelName(int level) {
  switch (level) {
    case 1: return 'A1';
    case 2: return 'A2';
    case 3: return 'B1';
    case 4: return 'B2';
    case 5: return 'C1';
    case 6: return 'C2';
    default: return 'Unknown';
  }
}

/// 單字瀏覽畫面 - 極簡設計
/// 
/// 中文為主、英文為輔
class VocabularyBrowserScreen extends ConsumerStatefulWidget {
  const VocabularyBrowserScreen({super.key});

  @override
  ConsumerState<VocabularyBrowserScreen> createState() =>
      _VocabularyBrowserScreenState();
}

class _VocabularyBrowserScreenState
    extends ConsumerState<VocabularyBrowserScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Set<int> _expandedLevels = {};

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    // 預設不展開任何級別，讓使用者自行選擇
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    ref
        .read(vocabularyBrowserProvider.notifier)
        .setSearchQuery(_searchController.text);
  }
  
  void _openFilterSheet() {
      showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) {
              return Consumer(builder: (context, ref, _) {
                  final state = ref.watch(vocabularyBrowserProvider);
                  final notifier = ref.read(vocabularyBrowserProvider.notifier);
                  
                  // CEFR levels are now just ints: 1=A1, 2=A2, 3=B1, 4=B2, 5=C1, 6=C2
                  Set<int> currentLevels = state.selectedLevels;

                  return AdvancedFilterSheet(
                      selectedLevels: currentLevels,
                      selectedType: state.vocabType ?? 'all',
                      selectedPos: state.selectedPartsOfSpeech.isEmpty 
                           ? 'all' 
                           : state.selectedPartsOfSpeech.first, // Simplification
                      officialOnly: state.officialOnly,
                      testedOnly: state.testedOnly,
                      onLevelToggle: (l) => notifier.toggleLevel(l),
                      onTypeSelect: (t) => notifier.setVocabType(t),
                      onPosSelect: (p) => notifier.setPosFilter(p),
                      onOfficialToggle: (v) => notifier.setOfficialOnly(v),
                      onTestedToggle: (v) => notifier.setTestedOnly(v),
                      onReset: () => notifier.clearFilters(),
                  );
              });
          }
      );
  }

  @override
  Widget build(BuildContext context) {
    final browserState = ref.watch(vocabularyBrowserProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.pureBlack : AppTheme.offWhite,
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(isDark),
            _buildFilterChips(isDark),
            Expanded(
              child: _buildWordList(browserState, isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppTheme.space16,
        AppTheme.space12,
        AppTheme.space16,
        AppTheme.space8,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space16,
        vertical: AppTheme.space4,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.gray850 : AppTheme.gray50,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        // 移除黑色邊框
      ),
      child: Row(
        children: [
          Icon(
            Icons.search_rounded,
            color: isDark ? AppTheme.gray500 : AppTheme.gray400,
            size: 20,
          ),
          const SizedBox(width: AppTheme.space12),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: Theme.of(context).textTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: '搜尋單字...',
                hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDark ? AppTheme.gray500 : AppTheme.gray400,
                    ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: AppTheme.space12,
                ),
              ),
            ),
          ),
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: Icon(
                Icons.clear_rounded,
                color: isDark ? AppTheme.gray500 : AppTheme.gray400,
                size: 20,
              ),
              onPressed: () {
                _searchController.clear();
              },
            ),
          // Filter Button Icon
          IconButton(
               icon: const Icon(Icons.tune_rounded),
               color: isDark ? AppTheme.gray500 : AppTheme.gray600,
               onPressed: _openFilterSheet,
          ),
          // Root Dictionary Button - 更顯眼的位置
          IconButton(
               icon: const Icon(Icons.book_outlined),
               color: isDark ? AppTheme.gray500 : AppTheme.gray600,
               tooltip: '字根字首字典',
               onPressed: () {
                 Navigator.of(context).push(
                   MaterialPageRoute(builder: (_) => const RootDictionaryScreen())
                 );
               },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(bool isDark) {
    // 移除 A1-C2 快速篩選按鈕，只保留清除按鈕
    final browserState = ref.watch(vocabularyBrowserProvider);
    final hasFilters = browserState.selectedLevels.isNotEmpty ||
        browserState.selectedPartsOfSpeech.isNotEmpty || browserState.vocabType != null;

    if (!hasFilters) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space16,
        vertical: AppTheme.space8,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () {
              ref.read(vocabularyBrowserProvider.notifier).clearFilters();
              _searchController.clear();
            },
            child: Text(
              '清除篩選',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: isDark ? AppTheme.gray400 : AppTheme.gray600,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWordList(VocabularyBrowserState browserState, bool isDark) {
    if (browserState.isLoading) {
      return _buildSkeletonLoading();
    }

    if (browserState.error != null) {
      return Center(
        child: Text(
          '錯誤: ${browserState.error}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    if (browserState.filteredWords.isEmpty) {
      return Center(
        child: Text(
          '沒有找到單字',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    final groupedWords = browserState.groupedWords;

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(bottom: AppTheme.space24),
      itemCount: 6, // 6 CEFR levels
      itemBuilder: (context, index) {
        final level = index + 1; // 1-6 for A1-C2
        final words = groupedWords[level] ?? [];

        if (words.isEmpty) {
          return const SizedBox.shrink();
        }

        return _buildLevelSection(level, words, isDark);
      },
    );
  }

  Widget _buildLevelSection(int level, List<VocabularyEntity> words, bool isDark) {
    final isExpanded = _expandedLevels.contains(level);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 可點擊的標題列
        InkWell(
          onTap: () {
            setState(() {
              if (isExpanded) {
                _expandedLevels.remove(level);
              } else {
                _expandedLevels.add(level);
              }
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.space16,
              vertical: AppTheme.space12,
            ),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.gray900 : AppTheme.pureWhite,
            ),
            child: Row(
              children: [
                // 展開/收起圖標
                Icon(
                  isExpanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  size: 20,
                  color: isDark ? AppTheme.gray400 : AppTheme.gray600,
                ),
                const SizedBox(width: AppTheme.space8),
                
                // 級別名稱
                Text(
                  getLevelName(level),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(width: AppTheme.space8),
                
                // 單字數量
                Text(
                  '(${words.length})',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: isDark ? AppTheme.gray400 : AppTheme.gray600,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // 單字列表（可展開/收起）
        if (isExpanded)
          ...words.map((word) => _buildWordItem(word, isDark)),
        
        // 分隔線
        Container(
          height: 1,
          margin: const EdgeInsets.symmetric(horizontal: AppTheme.space16),
          color: isDark ? AppTheme.gray800 : AppTheme.dividerGray,
        ),
      ],
    );
  }

  Widget _buildWordItem(VocabularyEntity word, bool isDark) {
    return InkWell(
      onTap: () {
        // 直接傳遞 VocabularyEntity
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => WordDetailScreen(lemma: word.lemma),
          ),
        );
      },
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.space16,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    word.lemma,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  if (word.lemma.isNotEmpty)
                    Text(
                      word.lemma,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isDark ? AppTheme.gray500 : AppTheme.gray400,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonLoading() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space16,
        vertical: AppTheme.space8,
      ),
      itemCount: 10,
      itemBuilder: (context, index) {
        return const Padding(
          padding: EdgeInsets.only(bottom: AppTheme.space12),
          child: SkeletonListTile(),
        );
      },
    );
  }
}
