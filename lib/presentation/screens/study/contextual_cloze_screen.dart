import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../providers/contextual_enhancement_provider.dart';
import '../../../data/models/vocab_models_enhanced.dart';

/// 情境填空 - 使用今日+過去學過的單字（多選一）
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
  List<WordEntryModel> _words = [];
  List<String> _currentOptions = [];
  bool _initialized = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg   = isDark ? AppTheme.pureBlack : AppTheme.offWhite;
    final card = isDark ? AppTheme.gray900 : AppTheme.pureWhite;
    final fg   = isDark ? AppTheme.pureWhite : AppTheme.pureBlack;

    final learnedAsync = ref.watch(learnedWordsProvider);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: fg),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('情境填空', style: TextStyle(color: fg, fontSize: 18, fontWeight: AppTheme.weightSemiBold)),
        centerTitle: true,
        actions: [
          if (_words.isNotEmpty)
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
      body: learnedAsync.when(
        data: (allWords) {
          if (!_initialized && allWords.isNotEmpty) {
            _initSession(allWords);
          }

          if (_words.isEmpty) {
            return _buildEmptyState(fg, allWords.length);
          }
          return _buildContent(context, isDark, card, fg);
        },
        loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        error: (_, __) => Center(child: Text('載入失敗', style: TextStyle(color: AppTheme.gray500))),
      ),
    );
  }

  void _initSession(List<WordEntryModel> allWords) {
    _initialized = true;
    // 只選有例句的單字
    final withExamples = allWords.where((w) =>
        w.senses.isNotEmpty && w.senses.first.examples.isNotEmpty).toList();
    if (withExamples.length < kMinContextualWords) return;
    _words = (withExamples..shuffle()).take(10).toList();
    _generateOptions();
  }

  void _generateOptions() {
    if (_currentIndex >= _words.length) return;
    final cur = _words[_currentIndex];
    final distractors = _words.where((w) => w.lemma != cur.lemma).toList()..shuffle();
    final opts = [cur.lemma, ...distractors.take(3).map((w) => w.lemma)]..shuffle();
    _currentOptions = opts;
  }

  Widget _buildEmptyState(Color fg, int totalLearned) {
    final needed = kMinContextualWords - totalLearned;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.edit_outlined, size: 56, color: AppTheme.gray400),
            const SizedBox(height: 20),
            Text(
              totalLearned < kMinContextualWords
                  ? '再學 $needed 個單字即可開始'
                  : '還沒有有例句的單字',
              style: TextStyle(color: fg, fontSize: 18, fontWeight: AppTheme.weightSemiBold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '先去翻牌學習新單字吧！',
              style: TextStyle(color: AppTheme.gray500, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, bool isDark, Color card, Color fg) {
    final currentWord = _words[_currentIndex];
    final sentence = _makeCloze(currentWord);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 句子卡片
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              boxShadow: isDark ? null : AppTheme.cardShadow,
            ),
            child: Column(
              children: [
                Icon(Icons.format_quote, size: 28,
                    color: isDark ? AppTheme.gray700 : AppTheme.gray300),
                const SizedBox(height: 16),
                Text(
                  sentence,
                  style: TextStyle(fontSize: 17, height: 1.7, color: fg,
                      fontWeight: AppTheme.weightMedium),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          Text('選擇正確的單字填入空格',
              style: TextStyle(fontSize: 13, color: AppTheme.gray500),
              textAlign: TextAlign.center),
          const SizedBox(height: 14),

          ..._buildOptions(currentWord, isDark, card, fg),
          const SizedBox(height: 20),

          // 確認 / 下一題
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _selectedAnswer == null ? null : () {
                _showResult ? _nextQuestion() : _checkAnswer();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? AppTheme.pureWhite : AppTheme.pureBlack,
                foregroundColor: isDark ? AppTheme.pureBlack : AppTheme.pureWhite,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
                elevation: 0,
              ),
              child: Text(_showResult ? '下一題' : '確認',
                  style: const TextStyle(fontSize: 16, fontWeight: AppTheme.weightSemiBold)),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  List<Widget> _buildOptions(WordEntryModel word, bool isDark, Color card, Color fg) {
    return _currentOptions.map((option) {
      final isSelected = _selectedAnswer == option;
      final isCorrect  = option == word.lemma;

      Color borderColor;
      Color bgColor;
      IconData? icon;

      if (_showResult) {
        if (isCorrect)        { borderColor = Colors.green; bgColor = Colors.green.withValues(alpha: 0.08); icon = Icons.check_circle_outline; }
        else if (isSelected)  { borderColor = Colors.red;   bgColor = Colors.red.withValues(alpha: 0.08);   icon = Icons.highlight_off; }
        else                  { borderColor = isDark ? AppTheme.gray800 : AppTheme.gray200; bgColor = card; }
      } else {
        borderColor = isSelected
            ? (isDark ? AppTheme.pureWhite : AppTheme.pureBlack)
            : (isDark ? AppTheme.gray800 : AppTheme.gray200);
        bgColor = isSelected
            ? (isDark ? AppTheme.gray800 : AppTheme.gray100)
            : card;
      }

      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: GestureDetector(
          onTap: _showResult ? null : () {
            HapticFeedback.lightImpact();
            setState(() => _selectedAnswer = option);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              border: Border.all(color: borderColor, width: 1.5),
            ),
            child: Row(
              children: [
                Expanded(child: Text(option,
                    style: TextStyle(fontSize: 16, color: fg,
                        fontWeight: isSelected ? AppTheme.weightSemiBold : AppTheme.weightRegular))),
                if (icon != null)
                  Icon(icon, color: isCorrect ? Colors.green : Colors.red, size: 22),
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
      if (_selectedAnswer == _words[_currentIndex].lemma) _correctCount++;
    });
  }

  void _nextQuestion() {
    if (_currentIndex < _words.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedAnswer = null;
        _showResult = false;
        _generateOptions();
      });
    } else {
      _showFinalResult();
    }
  }

  void _showFinalResult() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLarge)),
        title: Row(children: [
          Icon(Icons.check_circle_outline, color: isDark ? AppTheme.gray400 : AppTheme.gray600, size: 22),
          const SizedBox(width: 8),
          const Text('完成'),
        ]),
        content: Text('答對 $_correctCount / ${_words.length} 題\n'
            '正確率 ${(_correctCount / _words.length * 100).round()}%'),
        actions: [
          TextButton(
            onPressed: () { Navigator.pop(ctx); Navigator.pop(context); },
            child: const Text('完成'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _currentIndex = 0;
                _selectedAnswer = null;
                _showResult = false;
                _correctCount = 0;
                _words.shuffle();
                _generateOptions();
              });
            },
            child: const Text('再練一次'),
          ),
        ],
      ),
    );
  }

  String _makeCloze(WordEntryModel word) {
    if (word.senses.isNotEmpty && word.senses.first.examples.isNotEmpty) {
      final text = word.senses.first.examples.first.text;
      return text.replaceAll(RegExp(word.lemma, caseSensitive: false), '_____');
    }
    return 'The _____ is important.';
  }
}

