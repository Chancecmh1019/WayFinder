import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../providers/contextual_enhancement_provider.dart';
import '../../../data/models/vocab_models_enhanced.dart';

/// 情境配對 — 單字 ↔ 中文定義
class ContextualMatchingScreen extends ConsumerStatefulWidget {
  const ContextualMatchingScreen({super.key});
  @override
  ConsumerState<ContextualMatchingScreen> createState() => _ContextualMatchingScreenState();
}

class _ContextualMatchingScreenState extends ConsumerState<ContextualMatchingScreen> {
  List<_MatchTile> _tiles = [];
  int? _selectedIndex;
  final Set<int> _matched = {};
  int _errors = 0;
  bool _initialized = false;
  List<WordEntryModel> _sourceWords = [];

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
        title: Text('情境配對', style: TextStyle(color: fg, fontSize: 18, fontWeight: AppTheme.weightSemiBold)),
        centerTitle: true,
        actions: [
          if (_sourceWords.isNotEmpty)
            Padding(padding: const EdgeInsets.only(right: 16),
              child: Center(child: Text('${_matched.length ~/ 2} / ${_sourceWords.length}',
                  style: TextStyle(color: AppTheme.gray500, fontSize: 14)))),
        ],
      ),
      body: learnedAsync.when(
        data: (allWords) {
          if (!_initialized && allWords.isNotEmpty) _initGame(allWords);
          if (_sourceWords.isEmpty) return _buildEmpty(fg, allWords.length);
          return _buildGame(isDark, card, fg);
        },
        loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        error: (_, __) => Center(child: Text('載入失敗', style: TextStyle(color: AppTheme.gray500))),
      ),
    );
  }

  void _initGame(List<WordEntryModel> allWords) {
    _initialized = true;
    if (allWords.length < kMinContextualWords) return;
    _sourceWords = (allWords.toList()..shuffle()).take(6).toList();
    _buildTiles();
  }

  void _buildTiles() {
    _tiles = [];
    for (int i = 0; i < _sourceWords.length; i++) {
      final w = _sourceWords[i];
      final def = w.senses.isNotEmpty ? w.senses.first.zhDef : w.lemma;
      _tiles.add(_MatchTile(id: i, content: w.lemma, isWord: true));
      _tiles.add(_MatchTile(id: i, content: def, isWord: false));
    }
    _tiles.shuffle();
    _matched.clear(); _selectedIndex = null; _errors = 0;
  }

  Widget _buildEmpty(Color fg, int total) => Center(
    child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.link_rounded, size: 56, color: AppTheme.gray400), const SizedBox(height: 20),
      Text(total < kMinContextualWords ? '再學 ${kMinContextualWords - total} 個單字即可開始' : '沒有可配對的單字',
          style: TextStyle(color: fg, fontSize: 18, fontWeight: AppTheme.weightSemiBold), textAlign: TextAlign.center),
      const SizedBox(height: 8),
      Text('先去翻牌學習新單字吧！', style: TextStyle(color: AppTheme.gray500, fontSize: 14)),
    ])),
  );

  Widget _buildGame(bool isDark, Color card, Color fg) {
    final progress = _sourceWords.isEmpty ? 0.0 : _matched.length / 2 / _sourceWords.length;
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ClipRRect(borderRadius: BorderRadius.circular(999), child: LinearProgressIndicator(
            value: progress, minHeight: 3,
            backgroundColor: isDark ? AppTheme.gray800 : AppTheme.gray100,
            valueColor: AlwaysStoppedAnimation(isDark ? AppTheme.pureWhite : AppTheme.pureBlack),
          )),
          const SizedBox(height: 8),
          Text('點擊兩個對應的卡片  ·  錯誤 $_errors 次',
              style: TextStyle(fontSize: 12, color: AppTheme.gray500)),
        ]),
      ),
      Expanded(
        child: GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, childAspectRatio: 1.4, crossAxisSpacing: 10, mainAxisSpacing: 10),
          itemCount: _tiles.length,
          itemBuilder: (_, i) => _buildTile(i, isDark, card, fg),
        ),
      ),
    ]);
  }

  Widget _buildTile(int index, bool isDark, Color card, Color fg) {
    final tile = _tiles[index];
    final isMatched  = _matched.contains(index);
    final isSelected = _selectedIndex == index;
    final border = isMatched ? (isDark ? const Color(0xFF2A2A2A) : AppTheme.gray200)
        : isSelected ? (isDark ? AppTheme.pureWhite : AppTheme.pureBlack)
        : (isDark ? AppTheme.gray800 : AppTheme.gray200);
    final bg = isMatched ? (isDark ? const Color(0xFF1A1A1A) : AppTheme.gray50)
        : isSelected ? (isDark ? AppTheme.gray800 : AppTheme.gray100)
        : card;
    final textColor = isMatched ? AppTheme.gray500 : fg;

    return GestureDetector(
      onTap: isMatched ? null : () => _onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(color: border, width: isSelected ? 2 : 1.5),
        ),
        padding: const EdgeInsets.all(10),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (isMatched) ...[Icon(Icons.check, size: 13, color: AppTheme.gray500), const SizedBox(height: 3)],
          Flexible(child: Text(tile.content, textAlign: TextAlign.center, maxLines: 3, overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: tile.isWord ? 15 : 12, fontWeight: tile.isWord ? AppTheme.weightSemiBold : AppTheme.weightRegular, color: textColor))),
        ]),
      ),
    );
  }

  void _onTap(int index) {
    HapticFeedback.lightImpact();
    if (_selectedIndex == null) { setState(() => _selectedIndex = index); return; }
    if (_selectedIndex == index) { setState(() => _selectedIndex = null); return; }
    final a = _tiles[_selectedIndex!], b = _tiles[index];
    if (a.id == b.id && a.isWord != b.isWord) {
      HapticFeedback.mediumImpact();
      setState(() { _matched.add(_selectedIndex!); _matched.add(index); _selectedIndex = null; });
      if (_matched.length == _tiles.length) Future.delayed(const Duration(milliseconds: 400), _showComplete);
    } else {
      setState(() { _errors++; _selectedIndex = index; });
    }
  }

  void _showComplete() {
    final acc = _sourceWords.isEmpty ? 100
        : ((_sourceWords.length / (_sourceWords.length + _errors)) * 100).round().clamp(0, 100);
    showDialog(
      context: context, barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLarge)),
        title: const Text('全部配對完成'),
        content: Text('配對 ${_sourceWords.length} 組 · 錯誤 $_errors 次\n準確率 $acc%'),
        actions: [
          TextButton(onPressed: () { Navigator.pop(ctx); Navigator.pop(context); }, child: const Text('完成')),
          TextButton(onPressed: () { Navigator.pop(ctx); setState(() => _buildTiles()); }, child: const Text('再練一次')),
        ],
      ),
    );
  }
}

class _MatchTile {
  final int id; final String content; final bool isWord;
  _MatchTile({required this.id, required this.content, required this.isWord});
}
