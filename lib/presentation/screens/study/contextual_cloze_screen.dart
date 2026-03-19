import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../providers/contextual_enhancement_provider.dart';
import '../../../domain/entities/vocabulary_entity.dart';

/// 情境填空 - 使用今日+過去學過的單字
class ContextualClozeScreen extends ConsumerStatefulWidget {
  const ContextualClozeScreen({super.key});

  @override
  ConsumerState<ContextualClozeScreen> createState() => _ContextualClozeScreenState();
}

class _ContextualClozeScreenState extends ConsumerState<ContextualClozeScreen> {
  int _currentIndex = 0;
  String? _selectedAnswer;
  bool _showResult = false;
  int _correctCount = 0;
  List<VocabularyEntity> _words = [];
  List<String> _currentOptions = [];

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
        title: Text('情境填空', style: TextStyle(color: fg, fontSize: 18)),
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
            // 選擇有例句的單字
            final wordsWithExamples = words.where((w) => 
              w.senses.isNotEmpty && w.senses.first.examples.isNotEmpty
            ).toList();
            _words = wordsWithExamples.take(10).toList()..shuffle();
            _generateOptions(); // 初始化第一題的選項
          }
          
          if (_words.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.edit_outlined, size: 64, color: AppTheme.gray400),
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

  Widget _buildContent(BuildContext context, bool isDark, Color card, Color fg) {
    final currentWord = _words[_currentIndex];
    final sentence = _generateSentence(currentWord);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 句子顯示卡片
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              boxShadow: isDark ? null : AppTheme.cardShadow,
            ),
            child: Column(
              children: [
                Icon(
                  Icons.format_quote,
                  size: 32,
                  color: isDark ? AppTheme.gray700 : AppTheme.gray300,
                ),
                const SizedBox(height: 16),
                Text(
                  sentence,
                  style: TextStyle(
                    fontSize: 18,
                    height: 1.6,
                    color: fg,
                    fontWeight: AppTheme.weightMedium,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          Text(
            '選擇正確的單字填入空格',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.gray500,
              fontWeight: AppTheme.weightMedium,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 16),
          
          // 選項
          ..._buildOptions(currentWord, isDark, card, fg),
          
          const SizedBox(height: 24),
          
          // 確認按鈕
          ElevatedButton(
            onPressed: _selectedAnswer == null ? null : () {
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
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _generateOptions() {
    if (_currentIndex >= _words.length) return;
    
    final currentWord = _words[_currentIndex];
    final options = <String>[currentWord.lemma];
    
    // 從其他單字中隨機選擇3個作為干擾項
    final otherWords = _words.where((w) => w.lemma != currentWord.lemma).toList()..shuffle();
    options.addAll(otherWords.take(3).map((w) => w.lemma));
    
    _currentOptions = options..shuffle();
  }

  List<Widget> _buildOptions(VocabularyEntity word, bool isDark, Color card, Color fg) {
    return _currentOptions.map((option) {
      final isSelected = _selectedAnswer == option;
      final isCorrect = option == word.lemma;
      
      Color borderColor;
      Color bgColor;
      IconData? icon;
      
      if (_showResult) {
        if (isCorrect) {
          borderColor = Colors.green;
          bgColor = Colors.green.withValues(alpha: 0.1);
          icon = Icons.check_circle;
        } else if (isSelected) {
          borderColor = Colors.red;
          bgColor = Colors.red.withValues(alpha: 0.1);
          icon = Icons.cancel;
        } else {
          borderColor = isDark ? AppTheme.gray800 : AppTheme.gray200;
          bgColor = card;
        }
      } else {
        borderColor = isSelected
            ? (isDark ? AppTheme.pureWhite : AppTheme.pureBlack)
            : (isDark ? AppTheme.gray800 : AppTheme.gray200);
        bgColor = isSelected
            ? (isDark ? AppTheme.pureWhite.withValues(alpha: 0.1) : AppTheme.pureBlack.withValues(alpha: 0.05))
            : card;
      }
      
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: GestureDetector(
          onTap: _showResult ? null : () {
            HapticFeedback.lightImpact();
            setState(() => _selectedAnswer = option);
          },
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              border: Border.all(color: borderColor, width: 2),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    option,
                    style: TextStyle(
                      fontSize: 16,
                      color: fg,
                      fontWeight: isSelected ? AppTheme.weightSemiBold : AppTheme.weightRegular,
                    ),
                  ),
                ),
                if (icon != null)
                  Icon(
                    icon,
                    color: isCorrect ? Colors.green : Colors.red,
                    size: 24,
                  ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }



  void _checkAnswer() {
    HapticFeedback.mediumImpact();
    setState(() {
      _showResult = true;
      if (_selectedAnswer == _words[_currentIndex].lemma) {
        _correctCount++;
      }
    });
  }

  void _nextQuestion() {
    if (_currentIndex < _words.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedAnswer = null;
        _showResult = false;
        _generateOptions(); // 重新生成選項
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

  String _generateSentence(VocabularyEntity word) {
    // 從單字的例句中提取，並用 _____ 替換目標單字
    if (word.senses.isNotEmpty && word.senses.first.examples.isNotEmpty) {
      final example = word.senses.first.examples.first.text;
      return example.replaceAll(RegExp(word.lemma, caseSensitive: false), '_____');
    }
    
    // 如果沒有例句，生成簡單句子
    return 'The _____ is important.';
  }
}
