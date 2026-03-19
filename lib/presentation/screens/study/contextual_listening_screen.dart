import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../providers/contextual_enhancement_provider.dart';
import '../../../data/models/vocab_models_enhanced.dart';
import '../../../core/providers/app_providers.dart';

/// 情境聽力 — 聽音選單字
class ContextualListeningScreen extends ConsumerStatefulWidget {
  const ContextualListeningScreen({super.key});
  @override
  ConsumerState<ContextualListeningScreen> createState() => _ContextualListeningScreenState();
}

class _ContextualListeningScreenState extends ConsumerState<ContextualListeningScreen> {
  int _currentIndex = 0;
  String? _selected;
  bool _showResult = false;
  int _correctCount = 0;
  List<WordEntryModel> _words = [];
  List<String> _options = [];
  bool _playing = false;
  bool _played = false;
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
        title: Text('情境聽力', style: TextStyle(color: fg, fontSize: 18, fontWeight: AppTheme.weightSemiBold)),
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
    if (allWords.length < kMinContextualWords) return;
    _words = (allWords.toList()..shuffle()).take(10).toList();
    _genOptions();
  }

  void _genOptions() {
    if (_currentIndex >= _words.length) return;
    final cur = _words[_currentIndex];
    final others = _words.where((w) => w.lemma != cur.lemma).toList()..shuffle();
    _options = [cur.lemma, ...others.take(3).map((w) => w.lemma)]..shuffle();
    _played = false;
  }

  Widget _buildEmpty(Color fg, int total) => Center(
    child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.headphones_rounded, size: 56, color: AppTheme.gray400), const SizedBox(height: 20),
      Text(total < kMinContextualWords ? '再學 ${kMinContextualWords - total} 個單字即可開始' : '還沒有學過的單字',
          style: TextStyle(color: fg, fontSize: 18, fontWeight: AppTheme.weightSemiBold), textAlign: TextAlign.center),
      const SizedBox(height: 8),
      Text('先去翻牌學習新單字吧！', style: TextStyle(color: AppTheme.gray500, fontSize: 14)),
    ])),
  );

  Widget _buildContent(bool isDark, Color card, Color fg) {
    final curWord = _words[_currentIndex];
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const SizedBox(height: 36),

        // 播放按鈕
        Center(child: GestureDetector(
          onTap: () => _play(curWord.lemma),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 130, height: 130,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: card,
              border: Border.all(
                color: _played ? (isDark ? AppTheme.pureWhite : AppTheme.pureBlack) : (isDark ? AppTheme.gray700 : AppTheme.gray300),
                width: _played ? 2 : 1.5,
              ),
              boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 4))],
            ),
            child: Stack(alignment: Alignment.center, children: [
              if (_playing) SizedBox(width: 130, height: 130,
                  child: CircularProgressIndicator(strokeWidth: 1.5,
                      valueColor: AlwaysStoppedAnimation(isDark ? AppTheme.gray500 : AppTheme.gray400))),
              Icon(_playing ? Icons.volume_up_rounded : Icons.play_arrow_rounded,
                  size: 52, color: isDark ? AppTheme.pureWhite : AppTheme.pureBlack),
            ]),
          ),
        )),

        const SizedBox(height: 24),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            key: ValueKey(_played),
            _played ? '選擇你聽到的單字' : '點擊播放發音',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, fontWeight: AppTheme.weightMedium, color: _played ? fg : AppTheme.gray500),
          ),
        ),
        const SizedBox(height: 28),

        // 結果提示（答對後顯示定義）
        if (_showResult && curWord.senses.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.gray850 : AppTheme.gray50,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(curWord.lemma, style: TextStyle(fontSize: 15, fontWeight: AppTheme.weightSemiBold, color: fg)),
              const SizedBox(height: 4),
              Text(curWord.senses.first.zhDef, style: TextStyle(fontSize: 13, color: AppTheme.gray500)),
            ]),
          ),

        ..._buildOptions(curWord, isDark, card, fg),
        const SizedBox(height: 20),

        SizedBox(height: 52, child: ElevatedButton(
          onPressed: (!_played || _selected == null) && !_showResult ? null
              : () => _showResult ? _next() : _check(),
          style: ElevatedButton.styleFrom(
            backgroundColor: isDark ? AppTheme.pureWhite : AppTheme.pureBlack,
            foregroundColor: isDark ? AppTheme.pureBlack : AppTheme.pureWhite,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
            elevation: 0,
          ),
          child: Text(_showResult ? '下一題' : '確認', style: const TextStyle(fontSize: 15, fontWeight: AppTheme.weightSemiBold)),
        )),
        const SizedBox(height: 32),
      ]),
    );
  }

  List<Widget> _buildOptions(WordEntryModel word, bool isDark, Color card, Color fg) {
    return _options.map((opt) {
      final isSelected = _selected == opt;
      final isCorrect  = opt == word.lemma;
      Color border; Color bg; IconData? icon;

      if (_showResult) {
        if (isCorrect)       { border = const Color(0xFF4CAF50); bg = const Color(0xFF4CAF50).withValues(alpha: 0.08); icon = Icons.check_circle_outline; }
        else if (isSelected) { border = const Color(0xFFE57373); bg = const Color(0xFFE57373).withValues(alpha: 0.08); icon = Icons.highlight_off; }
        else                 { border = isDark ? AppTheme.gray800 : AppTheme.gray200; bg = card; }
      } else {
        border = isSelected ? (isDark ? AppTheme.pureWhite : AppTheme.pureBlack) : (isDark ? AppTheme.gray800 : AppTheme.gray200);
        bg = isSelected ? (isDark ? AppTheme.gray800 : AppTheme.gray100) : card;
      }

      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: GestureDetector(
          onTap: (_showResult || !_played) ? null : () { HapticFeedback.lightImpact(); setState(() => _selected = opt); },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border: Border.all(color: border, width: isSelected ? 2 : 1.5)),
            child: Row(children: [
              Expanded(child: Text(opt, style: TextStyle(fontSize: 15, color: fg,
                  fontWeight: isSelected ? AppTheme.weightSemiBold : AppTheme.weightRegular))),
              if (icon != null) Icon(icon, color: isCorrect ? const Color(0xFF4CAF50) : const Color(0xFFE57373), size: 20),
            ]),
          ),
        ),
      );
    }).toList();
  }

  Future<void> _play(String word) async {
    if (_playing) return;
    setState(() => _playing = true);
    final tts = ref.read(ttsServiceProvider);
    await tts.speak(word);
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) setState(() { _playing = false; _played = true; });
  }

  void _check() {
    HapticFeedback.mediumImpact();
    setState(() { _showResult = true; if (_selected == _words[_currentIndex].lemma) _correctCount++; });
  }

  void _next() {
    if (_currentIndex < _words.length - 1) {
      setState(() { _currentIndex++; _selected = null; _showResult = false; _genOptions(); });
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
          TextButton(onPressed: () {
            Navigator.pop(ctx);
            setState(() { _currentIndex = 0; _selected = null; _showResult = false; _correctCount = 0; _words.shuffle(); _genOptions(); });
          }, child: const Text('再練一次')),
        ],
      ),
    );
  }
}
