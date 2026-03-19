import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../providers/contextual_enhancement_provider.dart';
import '../../../domain/entities/vocabulary_entity.dart';

/// 情境造句 - 排列單字組成正確句子
class ContextualSentenceScreen extends ConsumerStatefulWidget {
  const ContextualSentenceScreen({super.key});

  @override
  ConsumerState<ContextualSentenceScreen> createState() => _ContextualSentenceScreenState();
}

class _ContextualSentenceScreenState extends ConsumerState<ContextualSentenceScreen> {
  int _currentIndex = 0;
  List<VocabularyEntity> _words = [];
  List<String> _shuffledWords = [];
  List<String> _selectedWords = [];
  String _correctSentence = '';
  bool _showResult = false;
  int _correctCount = 0;

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
        title: Text('情境造句', style: TextStyle(color: fg, fontSize: 18)),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '${_currentIndex + 1} / ${_words.length}',
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
                  Icon(Icons.school_outlined, size: 64, color: AppTheme.gray400),
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
    // 選擇有例句的單字
    final wordsWithExamples = words.where((w) => 
      w.senses.isNotEmpty && w.senses.first.examples.isNotEmpty
    ).toList();
    
    if (wordsWithExamples.isEmpty) return;
    
    _words = wordsWithExamples.take(5).toList()..shuffle();
    _loadCurrentQuestion();
  }

  void _loadCurrentQuestion() {
    if (_currentIndex >= _words.length) return;
    
    final currentWord = _words[_currentIndex];
    _correctSentence = currentWord.senses.first.examples.first.text;
    
    // 將句子分割成單字
    final words = _correctSentence
        .replaceAll(RegExp(r'[.,!?;:]'), '')
        .split(' ')
        .where((w) => w.isNotEmpty)
        .toList();
    
    _shuffledWords = List.from(words)..shuffle();
    _selectedWords = [];
    _showResult = false;
  }

  Widget _buildContent(BuildContext context, bool isDark, Color card, Color fg) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          
          // 提示區
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              boxShadow: isDark ? null : AppTheme.cardShadow,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.gray800 : AppTheme.gray100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.lightbulb_outline, size: 20, color: isDark ? AppTheme.gray300 : AppTheme.gray600),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '排列單字組成句子',
                            style: TextStyle(fontSize: 14, fontWeight: AppTheme.weightSemiBold, color: fg),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '包含單字：${_words[_currentIndex].lemma}',
                            style: TextStyle(fontSize: 12, color: AppTheme.gray500),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 已選擇的單字區域
          Container(
            constraints: const BoxConstraints(minHeight: 120),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              border: Border.all(
                color: _showResult
                    ? (_isCorrect() ? Colors.green : Colors.red)
                    : (isDark ? AppTheme.gray800 : AppTheme.gray200),
                width: 2,
              ),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _selectedWords.isEmpty
                  ? [
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            '點擊下方單字組成句子',
                            style: TextStyle(color: AppTheme.gray400, fontSize: 14),
                          ),
                        ),
                      ),
                    ]
                  : _selectedWords.asMap().entries.map((entry) {
                      return _buildSelectedWordChip(entry.key, entry.value, isDark, fg);
                    }).toList(),
            ),
          ),

          if (_showResult) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isCorrect() 
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border: Border.all(
                  color: _isCorrect() ? Colors.green : Colors.red,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _isCorrect() ? Icons.check_circle : Icons.cancel,
                        color: _isCorrect() ? Colors.green : Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isCorrect() ? '正確！' : '不正確',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: AppTheme.weightSemiBold,
                          color: _isCorrect() ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                  if (!_isCorrect()) ...[
                    const SizedBox(height: 12),
                    Text(
                      '正確答案：',
                      style: TextStyle(fontSize: 12, color: AppTheme.gray500),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _correctSentence,
                      style: TextStyle(fontSize: 14, color: fg),
                    ),
                  ],
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          // 可選單字區域
          if (!_showResult)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _shuffledWords.map((word) {
                return _buildWordChip(word, isDark, card, fg);
              }).toList(),
            ),

          const SizedBox(height: 24),
          
          // 按鈕區
          Row(
            children: [
              if (!_showResult && _selectedWords.isNotEmpty)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      setState(() {
                        _shuffledWords.addAll(_selectedWords);
                        _selectedWords.clear();
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: isDark ? AppTheme.gray700 : AppTheme.gray300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      ),
                    ),
                    child: Text('重置', style: TextStyle(fontSize: 16, color: fg)),
                  ),
                ),
              if (!_showResult && _selectedWords.isNotEmpty) const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _selectedWords.isEmpty && !_showResult ? null : () {
                    if (_showResult) {
                      _nextQuestion();
                    } else {
                      _checkAnswer();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? AppTheme.pureWhite : AppTheme.pureBlack,
                    foregroundColor: isDark ? AppTheme.pureBlack : AppTheme.pureWhite,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                  ),
                  child: Text(
                    _showResult ? '下一題' : '確認',
                    style: const TextStyle(fontSize: 16, fontWeight: AppTheme.weightSemiBold),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildWordChip(String word, bool isDark, Color card, Color fg) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          _selectedWords.add(word);
          _shuffledWords.remove(word);
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(color: isDark ? AppTheme.gray700 : AppTheme.gray300),
        ),
        child: Text(
          word,
          style: TextStyle(fontSize: 15, color: fg),
        ),
      ),
    );
  }

  Widget _buildSelectedWordChip(int index, String word, bool isDark, Color fg) {
    return GestureDetector(
      onTap: _showResult ? null : () {
        HapticFeedback.lightImpact();
        setState(() {
          _selectedWords.removeAt(index);
          _shuffledWords.add(word);
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.pureWhite : AppTheme.pureBlack,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        child: Text(
          word,
          style: TextStyle(
            fontSize: 15,
            color: isDark ? AppTheme.pureBlack : AppTheme.pureWhite,
            fontWeight: AppTheme.weightMedium,
          ),
        ),
      ),
    );
  }



  bool _isCorrect() {
    final userSentence = _selectedWords.join(' ').toLowerCase().trim();
    final correct = _correctSentence
        .replaceAll(RegExp(r'[.,!?;:]'), '')
        .toLowerCase()
        .trim();
    return userSentence == correct;
  }

  void _checkAnswer() {
    HapticFeedback.mediumImpact();
    setState(() {
      _showResult = true;
      if (_isCorrect()) {
        _correctCount++;
      }
    });
  }

  void _nextQuestion() {
    if (_currentIndex < _words.length - 1) {
      setState(() {
        _currentIndex++;
        _loadCurrentQuestion();
      });
    } else {
      _showResults();
    }
  }

  void _showResults() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('完成！'),
        content: Text('答對 $_correctCount / ${_words.length} 題'),
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
