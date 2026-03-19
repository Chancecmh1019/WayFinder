import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../../core/providers/vocab_providers.dart';
import '../../data/models/vocab_models_enhanced.dart';
import 'browse/word_detail_screen.dart';

/// 字根字首字典畫面（v8.0.0）
/// 
/// 使用結構化的 analysis 資料建立完整的字根字首字典
class RootDictionaryScreen extends ConsumerStatefulWidget {
  const RootDictionaryScreen({super.key});

  @override
  ConsumerState<RootDictionaryScreen> createState() => _RootDictionaryScreenState();
}

class _RootDictionaryScreenState extends ConsumerState<RootDictionaryScreen> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
                      '字根字首字典',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                ],
              ),
            ),

            // Tab Bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: AppTheme.space16),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.gray900 : AppTheme.gray100,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: isDark ? AppTheme.gray800 : AppTheme.pureWhite,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                labelColor: isDark ? AppTheme.pureWhite : AppTheme.pureBlack,
                unselectedLabelColor: isDark ? AppTheme.gray400 : AppTheme.gray600,
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: '字首'),
                  Tab(text: '字根'),
                  Tab(text: '字尾'),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.space16),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: '搜尋字根、字首、字尾...',
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
                  return TabBarView(
                    controller: _tabController,
                    children: [
                      _buildElementList(context, isDark, words, 'prefix'),
                      _buildElementList(context, isDark, words, 'root'),
                      _buildElementList(context, isDark, words, 'suffix'),
                    ],
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

  Widget _buildElementList(
    BuildContext context,
    bool isDark,
    List<dynamic> words,
    String elementType,
  ) {
    // 收集所有字根元素
    final Map<String, _ElementInfo> elementMap = {};
    
    for (final word in words) {
      if (word.rootInfo?.analysis == null) continue;
      
      List<RootElementModel> elements = [];
      switch (elementType) {
        case 'prefix':
          elements = word.rootInfo!.analysis!.prefixes;
          break;
        case 'root':
          elements = word.rootInfo!.analysis!.roots;
          break;
        case 'suffix':
          elements = word.rootInfo!.analysis!.suffixes;
          break;
      }
      
      for (final element in elements) {
        final key = element.element;
        if (!elementMap.containsKey(key)) {
          elementMap[key] = _ElementInfo(
            element: element,
            words: [],
          );
        }
        elementMap[key]!.words.add(word);
      }
    }

    // 過濾搜尋結果
    var filteredElements = elementMap.entries.toList();
    if (_searchQuery.isNotEmpty) {
      final lowerQuery = _searchQuery.toLowerCase();
      filteredElements = filteredElements.where((entry) {
        final element = entry.value.element;
        return element.element.toLowerCase().contains(lowerQuery) ||
            element.zhMeaning.toLowerCase().contains(lowerQuery) ||
            element.enMeaning.toLowerCase().contains(lowerQuery);
      }).toList();
    }

    // 排序
    filteredElements.sort((a, b) => a.key.compareTo(b.key));

    if (filteredElements.isEmpty) {
      return Center(
        child: Text(
          _searchQuery.isEmpty ? '沒有資料' : '找不到相關結果',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16),
      itemCount: filteredElements.length,
      itemBuilder: (context, index) {
        final entry = filteredElements[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.space12),
          child: _buildElementCard(context, isDark, entry.value),
        );
      },
    );
  }

  Widget _buildElementCard(
    BuildContext context,
    bool isDark,
    _ElementInfo info,
  ) {
    final element = info.element;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.gray900 : AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: isDark ? null : AppTheme.cardShadow,
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(
            horizontal: AppTheme.space16,
            vertical: AppTheme.space8,
          ),
          childrenPadding: const EdgeInsets.only(
            left: AppTheme.space16,
            right: AppTheme.space16,
            bottom: AppTheme.space16,
          ),
          title: Row(
            children: [
              // 字根元素
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.space12,
                  vertical: AppTheme.space6,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Text(
                  element.element,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                    fontFamily: AppTheme.fontFamilyEnglish,
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.space12),
              // 中文意義
              Expanded(
                child: Text(
                  element.zhMeaning,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: AppTheme.space4),
            child: Text(
              '${element.enMeaning} • ${element.language} • ${info.words.length} 個單字',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isDark ? AppTheme.gray400 : AppTheme.gray600,
              ),
            ),
          ),
          children: [
            // 相關例字
            if (element.familyExamples.isNotEmpty) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '相關例字',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: isDark ? AppTheme.gray400 : AppTheme.gray600,
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.space8),
              Wrap(
                spacing: AppTheme.space8,
                runSpacing: AppTheme.space8,
                children: element.familyExamples.map((example) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.space12,
                      vertical: AppTheme.space6,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.gray800 : AppTheme.gray100,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                    child: Text(
                      example,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamilyEnglish,
                        color: isDark ? AppTheme.gray300 : AppTheme.gray700,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppTheme.space16),
            ],
            
            // 本字典中的單字
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '本字典中的單字 (${info.words.length})',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: isDark ? AppTheme.gray400 : AppTheme.gray600,
                ),
              ),
            ),
            const SizedBox(height: AppTheme.space8),
            ...info.words.take(10).map((word) {
              return InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => WordDetailScreen(lemma: word.lemma),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppTheme.space8,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: isDark ? AppTheme.gray800 : AppTheme.gray200,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          word.lemma,
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamilyEnglish,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (word.senses.isNotEmpty)
                        Expanded(
                          flex: 2,
                          child: Text(
                            word.senses.first.zhDef,
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: isDark ? AppTheme.gray500 : AppTheme.gray400,
                      ),
                    ],
                  ),
                ),
              );
            }),
            if (info.words.length > 10)
              Padding(
                padding: const EdgeInsets.only(top: AppTheme.space8),
                child: Text(
                  '還有 ${info.words.length - 10} 個單字...',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark ? AppTheme.gray500 : AppTheme.gray500,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ElementInfo {
  final RootElementModel element;
  final List<dynamic> words;

  _ElementInfo({
    required this.element,
    required this.words,
  });
}
