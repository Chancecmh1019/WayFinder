import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../providers/contextual_enhancement_provider.dart';
import '../../../data/models/vocab_models_enhanced.dart';

/// 情境造句 — 排列單字組成正確句子
class ContextualSentenceScreen extends ConsumerStatefulWidget {
  const ContextualSentenceScreen({super.key});
  @override
  ConsumerState<ContextualSentenceScreen> createState() => _ContextualSentenceScreenState();
}

class _ContextualSentenceScreenState extends ConsumerState<ContextualSentenceScreen> {
  int _currentIndex = 0;
  List<WordEntryModel> _words = [];
  List<String> _bank = [];        // 未選的單字
  List<String> _selected = [];    // 已選的單字
  String _correctSentence = '';
  bool _showResult = false;
  int _correctCount = 0;
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
        backgroundColor: bg, elevation: 0,
        leading: IconButton(icon: Icon(Icons.close, color: fg), onPressed: () => Navigator.pop(context)),
        title: Text('情境造句', style: TextStyle(color: fg, fontSize: 18, fontWeight: AppTheme.weightSemiBold)),
        centerTitle: true,
        actions: [
          if (_words.isNotEmpty)
            Padding(padding: const EdgeInsets.only(right: 16),
              child: Center(child: Text('${_currentIndex + 1} / ${_words.length}',
                  style: TextStyle(color: AppTheme.gray500, fontSize: 14)))),
        ],
      ),
      body: learnedAsync.when(
        data: (allWords) {
          if (!_initialized && allWords.isNotEmpty) _initSession(allWords);
          if (_words.isEmpty) return _buildEmpty(fg, allWords.length);
          return _buildContent(isDark, card, fg);
        },
        loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        error: (_, __) => Center(child: Text('載入失敗', style: TextStyle(color: AppTheme.gray500))),
      ),
    );
  }

  void _initSession(List<WordEntryModel> allWords) {
    _initialized = true;
    final withEx = allWords.where((w) => w.senses.isNotEmpty && w.senses.first.examples.isNotEmpty).toList();
    if (withEx.length < kMinContextualWords) return;
    _words = (withEx..shuffle()).take(5).toList();
    _loadQ();
  }

  void _loadQ() {
    if (_currentIndex >= _words.length) return;
    final w = _words[_currentIndex];
    _correctSentence = w.senses.first.examples.first.text;
    final tokens = _correctSentence.replaceAll(RegExp(r'[.,!?;:]'), '').split(' ').where((s) => s.isNotEmpty).toList();
    _bank = List.from(tokens)..shuffle();
    _selected = [];
    _showResult = false;
  }

  Widget _buildEmpty(Color fg, int total) => Center(
    child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.sort_by_alpha_rounded, size: 56, color: AppTheme.gray400), const SizedBox(height: 20),
      Text(total < kMinContextualWords ? '再學 ${kMinContextualWords - total} 個單字即可開始' : '沒有有例句的單字',
          style: TextStyle(color: fg, fontSize: 18, fontWeight: AppTheme.weightSemiBold), textAlign: TextAlign.center),
      const SizedBox(height: 8),
      Text('先去翻牌學習新單字吧！', style: TextStyle(color: AppTheme.gray500, fontSize: 14)),
    ])),
  );

  Widget _buildContent(bool isDark, Color card, Color fg) {
    final targetWord = _words[_currentIndex].lemma;
    final isOk = _isCorrect();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const SizedBox(height: 20),

        // 提示區
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              boxShadow: isDark ? null : AppTheme.cardShadow),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: isDark ? AppTheme.gray800 : AppTheme.gray100, borderRadius: BorderRadius.circular(8)),
              child: Icon(Icons.auto_fix_high_outlined, size: 18, color: isDark ? AppTheme.gray400 : AppTheme.gray600),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('排列單字組成句子', style: TextStyle(fontSize: 13, fontWeight: AppTheme.weightSemiBold, color: fg)),
              const SizedBox(height: 2),
              Text('包含單字：$targetWord', style: TextStyle(fontSize: 12, color: AppTheme.gray500)),
            ])),
          ]),
        ),
        const SizedBox(height: 16),

        // 已選區
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          constraints: const BoxConstraints(minHeight: 80),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(
              color: _showResult
                  ? (isOk ? const Color(0xFF4CAF50) : const Color(0xFFE57373))
                  : (isDark ? AppTheme.gray800 : AppTheme.gray200),
              width: 1.5,
            ),
          ),
          child: _selected.isEmpty
              ? Center(child: Text('點擊下方單字組成句子', style: TextStyle(color: AppTheme.gray400, fontSize: 13)))
              : Wrap(spacing: 6, runSpacing: 6,
                  children: _selected.asMap().entries.map((e) => _selectedChip(e.key, e.value, isDark, fg)).toList()),
        ),

        // 結果提示
        if (_showResult) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isOk ? const Color(0xFF4CAF50).withValues(alpha: 0.08) : const Color(0xFFE57373).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              border: Border.all(color: isOk ? const Color(0xFF4CAF50) : const Color(0xFFE57373), width: 1),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(isOk ? Icons.check_circle_outline : Icons.highlight_off,
                    color: isOk ? const Color(0xFF4CAF50) : const Color(0xFFE57373), size: 18),
                const SizedBox(width: 8),
                Text(isOk ? '正確！' : '不正確',
                    style: TextStyle(fontSize: 13, fontWeight: AppTheme.weightSemiBold,
                        color: isOk ? const Color(0xFF4CAF50) : const Color(0xFFE57373))),
              ]),
              if (!isOk) ...[
                const SizedBox(height: 8),
                Text('正確答案：', style: TextStyle(fontSize: 11, color: AppTheme.gray500)),
                const SizedBox(height: 3),
                Text(_correctSentence, style: TextStyle(fontSize: 14, color: fg)),
              ],
            ]),
          ),
        ],
        const SizedBox(height: 16),

        // 單字庫
        if (!_showResult)
          Wrap(spacing: 8, runSpacing: 8,
              children: _bank.map((w) => _bankChip(w, isDark, card, fg)).toList()),

        const SizedBox(height: 20),

        // 按鈕列
        Row(children: [
          if (!_showResult && _selected.isNotEmpty) ...[
            Expanded(
              child: SizedBox(height: 48, child: OutlinedButton(
                onPressed: () { HapticFeedback.lightImpact(); setState(() { _bank.addAll(_selected); _selected.clear(); }); },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: isDark ? AppTheme.gray700 : AppTheme.gray300),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
                ),
                child: Text('重置', style: TextStyle(fontSize: 15, color: fg)),
              )),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            flex: 2,
            child: SizedBox(height: 48, child: ElevatedButton(
              onPressed: (_selected.isEmpty && !_showResult) ? null : () => _showResult ? _next() : _check(),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? AppTheme.pureWhite : AppTheme.pureBlack,
                foregroundColor: isDark ? AppTheme.pureBlack : AppTheme.pureWhite,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
                elevation: 0,
              ),
              child: Text(_showResult ? '下一題' : '確認', style: const TextStyle(fontSize: 15, fontWeight: AppTheme.weightSemiBold)),
            )),
          ),
        ]),
        const SizedBox(height: 32),
      ]),
    );
  }

  Widget _bankChip(String word, bool isDark, Color card, Color fg) => GestureDetector(
    onTap: () { HapticFeedback.lightImpact(); setState(() { _selected.add(word); _bank.remove(word); }); },
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(color: isDark ? AppTheme.gray700 : AppTheme.gray200, width: 1.5)),
      child: Text(word, style: TextStyle(fontSize: 14, color: fg)),
    ),
  );

  Widget _selectedChip(int i, String word, bool isDark, Color fg) => GestureDetector(
    onTap: _showResult ? null : () { HapticFeedback.lightImpact(); setState(() { _bank.add(_selected.removeAt(i)); }); },
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.pureWhite : AppTheme.pureBlack,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Text(word, style: TextStyle(fontSize: 14, fontWeight: AppTheme.weightMedium,
          color: isDark ? AppTheme.pureBlack : AppTheme.pureWhite)),
    ),
  );

  bool _isCorrect() {
    final user    = _selected.join(' ').toLowerCase().trim();
    final correct = _correctSentence.replaceAll(RegExp(r'[.,!?;:]'), '').toLowerCase().trim();
    return user == correct;
  }

  void _check() {
    HapticFeedback.mediumImpact();
    setState(() { _showResult = true; if (_isCorrect()) _correctCount++; });
  }

  void _next() {
    if (_currentIndex < _words.length - 1) {
      setState(() { _currentIndex++; _loadQ(); });
    } else {
      _showFinal();
    }
  }

  void _showFinal() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context, barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLarge)),
        title: Row(children: [
          Icon(Icons.check_circle_outline, color: isDark ? AppTheme.gray400 : AppTheme.gray600, size: 22),
          const SizedBox(width: 8),
          const Text('完成'),
        ]),
        content: Text('答對 $_correctCount / ${_words.length} 題\n正確率 ${(_correctCount / _words.length * 100).round()}%'),
        actions: [
          TextButton(onPressed: () { Navigator.pop(ctx); Navigator.pop(context); }, child: const Text('完成')),
          TextButton(
            onPressed: () { Navigator.pop(ctx); setState(() { _currentIndex = 0; _correctCount = 0; _words.shuffle(); _loadQ(); }); },
            child: const Text('再練一次'),
          ),
        ],
      ),
    );
  }
}
