import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../providers/contextual_enhancement_provider.dart';
import '../../../domain/entities/vocabulary_entity.dart';

/// 情境配對 - 單字與定義配對
class ContextualMatchingScreen extends ConsumerStatefulWidget {
  const ContextualMatchingScreen({super.key});

  @override
  ConsumerState<ContextualMatchingScreen> createState() => _ContextualMatchingScreenState();
}

class _ContextualMatchingScreenState extends ConsumerState<ContextualMatchingScreen> {
  List<VocabularyEntity> _words = [];
  List<_MatchItem> _items = [];
  int? _selectedIndex;
  Set<int> _matchedIndices = {};
  int _matchedCount = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.pureBlack : AppTheme.offWhite;
    final card = isDark ? AppTheme.gray900 : AppTheme.pureWhite;
    final fg = isDark ? AppTheme.pureWhite : AppTheme.pureBlack;

    final learnedWords = ref.watch(learnedWordsProvider);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: fg),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('情境配對', style: TextStyle(color: fg, fontSize: 18)),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '$_matchedCount / ${_words.length}',
                style: TextStyle(color: AppTheme.gray500, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
      body: learnedWords.when(
        data: (words) {
          if (_words.isEmpty && words.isNotEmpty) {
            _initializeGame(words);
          }
          
          if (_words.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.link_rounded, size: 64, color: AppTheme.gray400),
                  const SizedBox(height: 16),
                  Text(
                    '還沒有學過的單字',
                    style: TextStyle(color: fg, fontSize: 18, fontWeight: AppTheme.weightSemiBold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '先去學習一些新單字吧！',
                    style: TextStyle(color: AppTheme.gray500, fontSize: 14),
                  ),
                ],
              ),
            );
          }

          return _buildContent(context, isDark, card, fg);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Text('載入失敗', style: TextStyle(color: AppTheme.gray500)),
        ),
      ),
    );
  }

  void _initializeGame(List<VocabularyEntity> words) {
    _words = words.take(6).toList();
    
    // 創建配對項目
    _items = [];
    for (int i = 0; i < _words.length; i++) {
      final word = _words[i];
      final definition = word.senses.isNotEmpty ? word.senses.first.zhDef : '定義';
      
      _items.add(_MatchItem(
        id: i,
        word: word.lemma,
        definition: definition,
        isWord: true,
      ));
      
      _items.add(_MatchItem(
        id: i,
        word: word.lemma,
        definition: definition,
        isWord: false,
      ));
    }
    
    // 打亂順序
    _items.shuffle();
  }

  Widget _buildContent(BuildContext context, bool isDark, Color card, Color fg) {
    return Column(
      children: [
        // 說明卡片
        Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(color: isDark ? AppTheme.gray800 : AppTheme.gray200),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.gray800 : AppTheme.gray100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.touch_app, size: 20, color: isDark ? AppTheme.gray300 : AppTheme.gray600),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '點擊兩個相關的卡片進行配對',
                  style: TextStyle(fontSize: 14, color: AppTheme.gray500),
                ),
              ),
            ],
          ),
        ),
        
        // 配對卡片網格
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.5, // 增加寬高比，讓卡片更扁平
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _items.length,
            itemBuilder: (context, index) {
              return _buildMatchCard(index, isDark, card, fg);
            },
          ),
        ),
        
        // 完成按鈕
        if (_matchedCount == _words.length)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: card,
              boxShadow: isDark ? null : AppTheme.cardShadow,
            ),
            child: SafeArea(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? AppTheme.pureWhite : AppTheme.pureBlack,
                  foregroundColor: isDark ? AppTheme.pureBlack : AppTheme.pureWhite,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                ),
                child: const Text('完成', style: TextStyle(fontSize: 16, fontWeight: AppTheme.weightSemiBold)),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMatchCard(int index, bool isDark, Color card, Color fg) {
    final item = _items[index];
    final isMatched = _matchedIndices.contains(index);
    final isSelected = _selectedIndex == index;
    
    Color borderColor;
    Color bgColor;
    
    if (isMatched) {
      borderColor = Colors.green;
      bgColor = Colors.green.withOpacity(0.1);
    } else if (isSelected) {
      borderColor = isDark ? AppTheme.pureWhite : AppTheme.pureBlack;
      bgColor = isDark ? AppTheme.pureWhite.withOpacity(0.1) : AppTheme.pureBlack.withOpacity(0.05);
    } else {
      borderColor = isDark ? AppTheme.gray800 : AppTheme.gray200;
      bgColor = card;
    }
    
    return GestureDetector(
      onTap: isMatched ? null : () => _onCardTap(index),
      child: Container(
        padding: const EdgeInsets.all(12), // 減少內距
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isMatched)
              Icon(Icons.check_circle, color: Colors.green, size: 18), // 稍微縮小圖標
            if (isMatched) const SizedBox(height: 6),
            Expanded(
              child: Center(
                child: Text(
                  item.isWord ? item.word : item.definition,
                  style: TextStyle(
                    fontSize: item.isWord ? 15 : 12, // 稍微縮小字體
                    color: isMatched ? Colors.green : fg,
                    fontWeight: item.isWord ? AppTheme.weightSemiBold : AppTheme.weightRegular,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onCardTap(int index) {
    HapticFeedback.lightImpact();
    
    if (_selectedIndex == null) {
      // 第一次選擇
      setState(() => _selectedIndex = index);
    } else if (_selectedIndex == index) {
      // 取消選擇
      setState(() => _selectedIndex = null);
    } else {
      // 第二次選擇，檢查配對
      final first = _items[_selectedIndex!];
      final second = _items[index];
      
      if (first.id == second.id && first.isWord != second.isWord) {
        // 配對成功
        HapticFeedback.heavyImpact();
        setState(() {
          _matchedIndices.add(_selectedIndex!);
          _matchedIndices.add(index);
          _selectedIndex = null;
          _matchedCount++;
        });
        
        // 檢查是否全部完成
        if (_matchedCount == _words.length) {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              _showCompletionDialog();
            }
          });
        }
      } else {
        // 配對失敗
        HapticFeedback.lightImpact();
        setState(() => _selectedIndex = null);
      }
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('完成！'),
        content: const Text('你已完成所有配對'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('完成'),
          ),
        ],
      ),
    );
  }
}

class _MatchItem {
  final int id;
  final String word;
  final String definition;
  final bool isWord;

  _MatchItem({
    required this.id,
    required this.word,
    required this.definition,
    required this.isWord,
  });
}
