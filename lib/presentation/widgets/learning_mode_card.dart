import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../../data/models/fsrs_card_model.dart';
import '../../data/models/vocab_models_enhanced.dart';
import '../../core/providers/app_providers.dart';
import '../../core/providers/tts_providers.dart';
import '../widgets/common/audio_button.dart';
import '../../domain/services/fsrs_algorithm.dart';

/// 學�?模�??��? Widget
/// 
/// ?��?不�??�學習模式顯示�??��?互�?介面
class LearningModeCard extends ConsumerStatefulWidget {
  final FSRSCardModel card;
  final String mode; // 'flashcard', 'recognition', 'reverse', 'fillBlank', 'spelling', 'distinguish'
  final bool isDark;
  final Function(FSRSRating rating) onRate;

  const LearningModeCard({
    super.key,
    required this.card,
    required this.mode,
    required this.isDark,
    required this.onRate,
  });

  @override
  ConsumerState<LearningModeCard> createState() => _LearningModeCardState();
}

class _LearningModeCardState extends ConsumerState<LearningModeCard> {
  String? _selectedAnswer;
  bool? _isCorrect;
  final _textController = TextEditingController();
  Future<Map<String, dynamic>>? _wordDataFuture;

  @override
  void initState() {
    super.initState();
    // ?�在?��??��??��?一次數??
    _wordDataFuture = _loadWordData();
  }

  @override
  void didUpdateWidget(LearningModeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // ?�卡?�改變�??�新?��??��?並�?置�???
    if (oldWidget.card.lemma != widget.card.lemma || 
        oldWidget.card.senseId != widget.card.senseId) {
      setState(() {
        _selectedAnswer = null;
        _isCorrect = null;
        _textController.clear();
        _wordDataFuture = _loadWordData();
      });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.mode) {
      case 'recognition':
        return _buildRecognitionMode();
      case 'reverse':
        return _buildReverseMode();
      case 'fillBlank':
        return _buildFillBlankMode();
      case 'spelling':
        return _buildSpellingMode();
      case 'distinguish':
        return _buildDistinguishMode();
      case 'flashcard':
      default:
        return _buildFlashcardMode();
    }
  }

  /// 翻卡模�?（已實現�?
  Widget _buildFlashcardMode() {
    // ?�個模式已經在 fsrs_learning_screen.dart 中實??
    return const SizedBox.shrink();
  }

  /// 識別模�?：�??��??�中??
  Widget _buildRecognitionMode() {
    return FutureBuilder(
      future: _wordDataFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data as Map<String, dynamic>;
        final sense = data['sense'] as VocabSenseModel;
        final options = data['options'] as List<String>;
        final correctAnswer = sense.zhDef;

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: widget.isDark ? AppTheme.gray900 : AppTheme.pureWhite,
            borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
            boxShadow: widget.isDark ? null : AppTheme.elevatedShadow,
          ),
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '選擇正確的中文意思',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: AppTheme.weightBold,
                  letterSpacing: 1.5,
                  color: AppTheme.gray400,
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.card.lemma,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamilyEnglish,
                        fontSize: 48,
                        fontWeight: AppTheme.weightSemiBold,
                        letterSpacing: -2,
                        height: 0.9,
                        color: widget.isDark ? AppTheme.pureWhite : AppTheme.pureBlack,
                      ),
                    ),
                  ),
                  AudioButton(text: widget.card.lemma, size: 20),
                ],
              ),
              const Spacer(),
              ...options.asMap().entries.map((entry) {
                final index = entry.key;
                final option = entry.value;
                final isSelected = _selectedAnswer == option;
                final isCorrectOption = option == correctAnswer;
                final showResult = _selectedAnswer != null;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _OptionButton(
                    label: option,
                    index: index,
                    isSelected: isSelected,
                    isCorrect: showResult && isCorrectOption,
                    isWrong: showResult && isSelected && !isCorrectOption,
                    enabled: !showResult,
                    isDark: widget.isDark,
                    onTap: () {
                      setState(() {
                        _selectedAnswer = option;
                        _isCorrect = option == correctAnswer;
                      });
                      
                      // 延遲後自?��???
                      Future.delayed(const Duration(milliseconds: 800), () {
                        if (mounted && _isCorrect != null) {
                          widget.onRate(_isCorrect! ? FSRSRating.good : FSRSRating.again);
                        }
                      });
                    },
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  /// ?��?模�?：�?中�??�英??
  Widget _buildReverseMode() {
    return FutureBuilder(
      future: _wordDataFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data as Map<String, dynamic>;
        final sense = data['sense'] as VocabSenseModel;
        final options = data['reverseOptions'] as List<String>;
        final correctAnswer = widget.card.lemma;

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: widget.isDark ? AppTheme.gray900 : AppTheme.pureWhite,
            borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
            boxShadow: widget.isDark ? null : AppTheme.elevatedShadow,
          ),
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '選擇正確的英文單字',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: AppTheme.weightBold,
                  letterSpacing: 1.5,
                  color: AppTheme.gray400,
                ),
              ),
              const Spacer(),
              Text(
                sense.zhDef,
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: AppTheme.weightSemiBold,
                  letterSpacing: -1,
                  color: widget.isDark ? AppTheme.pureWhite : AppTheme.pureBlack,
                ),
              ),
              if (sense.enDef != null) ...[
                const SizedBox(height: 8),
                Text(
                  sense.enDef!,
                  style: const TextStyle(
                    fontFamily: AppTheme.fontFamilyEnglish,
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: AppTheme.gray600,
                  ),
                ),
              ],
              const Spacer(),
              ...options.asMap().entries.map((entry) {
                final index = entry.key;
                final option = entry.value;
                final isSelected = _selectedAnswer == option;
                final isCorrectOption = option == correctAnswer;
                final showResult = _selectedAnswer != null;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _OptionButton(
                    label: option,
                    index: index,
                    isSelected: isSelected,
                    isCorrect: showResult && isCorrectOption,
                    isWrong: showResult && isSelected && !isCorrectOption,
                    enabled: !showResult,
                    isDark: widget.isDark,
                    onTap: () {
                      setState(() {
                        _selectedAnswer = option;
                        _isCorrect = option == correctAnswer;
                      });
                      
                      Future.delayed(const Duration(milliseconds: 800), () {
                        if (mounted && _isCorrect != null) {
                          widget.onRate(_isCorrect! ? FSRSRating.good : FSRSRating.again);
                        }
                      });
                    },
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  /// 填空模�?：根?��??�填�?
  Widget _buildFillBlankMode() {
    return FutureBuilder(
      future: _wordDataFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data as Map<String, dynamic>;
        final sense = data['sense'] as VocabSenseModel;
        final example = sense.examples.firstOrNull;
        
        if (example == null) {
          // 沒�?例句，�?級為識別模�?
          return _buildRecognitionMode();
        }

        // 將�??�中?�單字替?�為空格
        final sentenceWithBlank = example.text.replaceAll(
          RegExp(widget.card.lemma, caseSensitive: false),
          '______',
        );

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: widget.isDark ? AppTheme.gray900 : AppTheme.pureWhite,
            borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
            boxShadow: widget.isDark ? null : AppTheme.elevatedShadow,
          ),
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '填入正確的單字',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: AppTheme.weightBold,
                  letterSpacing: 1.5,
                  color: AppTheme.gray400,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: widget.isDark ? AppTheme.gray850 : AppTheme.gray50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  sentenceWithBlank,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamilyEnglish,
                    fontSize: 16,
                    height: 1.6,
                    color: widget.isDark ? AppTheme.gray200 : AppTheme.gray800,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '提示：${sense.zhDef}',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.gray500,
                ),
              ),
              const Spacer(),
              TextField(
                controller: _textController,
                enabled: _selectedAnswer == null,
                decoration: InputDecoration(
                  hintText: '輸入?��?...',
                  filled: true,
                  fillColor: widget.isDark ? AppTheme.gray850 : AppTheme.pureWhite,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onSubmitted: (value) => _checkAnswer(value.trim().toLowerCase()),
              ),
              const SizedBox(height: 12),
              if (_selectedAnswer == null)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => _checkAnswer(_textController.text.trim().toLowerCase()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.isDark ? AppTheme.pureWhite : AppTheme.pureBlack,
                      foregroundColor: widget.isDark ? AppTheme.pureBlack : AppTheme.pureWhite,
                    ),
                    child: const Text('提交'),
                  ),
                ),
              if (_selectedAnswer != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _isCorrect! 
                        ? (widget.isDark ? AppTheme.gray800 : AppTheme.gray100)
                        : (widget.isDark ? AppTheme.gray850 : AppTheme.gray50),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isCorrect! ? Icons.check_circle : Icons.cancel,
                        color: _isCorrect! ? const Color(0xFF3A3A3A) : const Color(0xFF888888),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _isCorrect! 
                              ? '正確！' 
                              : '正確答案：${widget.card.lemma}',
                          style: TextStyle(
                            fontSize: 14,
                            color: widget.isDark ? AppTheme.pureWhite : AppTheme.pureBlack,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// 拼寫模式：聽音拼寫
  Widget _buildSpellingMode() {
    return FutureBuilder(
      future: _wordDataFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data as Map<String, dynamic>;
        final sense = data['sense'] as VocabSenseModel;

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: widget.isDark ? AppTheme.gray900 : AppTheme.pureWhite,
            borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
            boxShadow: widget.isDark ? null : AppTheme.elevatedShadow,
          ),
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '聽音拼寫',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: AppTheme.weightBold,
                  letterSpacing: 1.5,
                  color: AppTheme.gray400,
                ),
              ),
              const Spacer(),
              // ?�放?��?
              GestureDetector(
                onTap: () {
                  // ?�放?�音
                  ref.read(activeTtsServiceProvider).speak(widget.card.lemma);
                },
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: widget.isDark ? AppTheme.gray800 : AppTheme.gray100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.volume_up_rounded,
                    size: 40,
                    color: widget.isDark ? AppTheme.pureWhite : AppTheme.pureBlack,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                sense.zhDef,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: AppTheme.weightMedium,
                  color: widget.isDark ? AppTheme.gray300 : AppTheme.gray700,
                ),
              ),
              const Spacer(),
              TextField(
                controller: _textController,
                enabled: _selectedAnswer == null,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: AppTheme.fontFamilyEnglish,
                  fontSize: 24,
                  letterSpacing: 2,
                ),
                decoration: InputDecoration(
                  hintText: '輸入拼寫...',
                  filled: true,
                  fillColor: widget.isDark ? AppTheme.gray850 : AppTheme.pureWhite,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onSubmitted: (value) => _checkAnswer(value.trim().toLowerCase()),
              ),
              const SizedBox(height: 12),
              if (_selectedAnswer == null)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => _checkAnswer(_textController.text.trim().toLowerCase()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.isDark ? AppTheme.pureWhite : AppTheme.pureBlack,
                      foregroundColor: widget.isDark ? AppTheme.pureBlack : AppTheme.pureWhite,
                    ),
                    child: const Text('提交'),
                  ),
                ),
              if (_selectedAnswer != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _isCorrect! 
                        ? (widget.isDark ? AppTheme.gray800 : AppTheme.gray100)
                        : (widget.isDark ? AppTheme.gray850 : AppTheme.gray50),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isCorrect! ? Icons.check_circle : Icons.cancel,
                        color: _isCorrect! ? const Color(0xFF3A3A3A) : const Color(0xFF888888),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _isCorrect! 
                            ? '正確！' 
                            : '正確答案：${widget.card.lemma}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: AppTheme.weightMedium,
                          color: widget.isDark ? AppTheme.pureWhite : AppTheme.pureBlack,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// 辨識模式：相似詞辨識
  Widget _buildDistinguishMode() {
    // ?�個模式�?要混淆�??��?，暫?��?級為識別模�?
    return _buildRecognitionMode();
  }

  void _checkAnswer(String answer) {
    final correctAnswer = widget.card.lemma.toLowerCase();
    final isCorrect = answer == correctAnswer;
    
    setState(() {
      _selectedAnswer = answer;
      _isCorrect = isCorrect;
    });
    
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        widget.onRate(isCorrect ? FSRSRating.good : FSRSRating.again);
      }
    });
  }

  Future<Map<String, dynamic>> _loadWordData() async {
    final vocabService = ref.read(localVocabServiceProvider);
    final db = await vocabService.loadDatabase();
    final word = db.words.where((w) => w.lemma == widget.card.lemma).firstOrNull;
    
    if (word == null) {
      throw Exception('Word not found: ${widget.card.lemma}');
    }
    
    final sense = word.senses
            .where((s) => s.senseId == widget.card.senseId)
            .firstOrNull ??
        word.senses.first;
    
    // ?��??��?（�??�模式�?
    final options = <String>[sense.zhDef];
    final otherWords = db.words.where((w) => w.lemma != widget.card.lemma).toList()..shuffle();
    for (var i = 0; i < 3 && i < otherWords.length; i++) {
      if (otherWords[i].senses.isNotEmpty) {
        options.add(otherWords[i].senses.first.zhDef);
      }
    }
    options.shuffle();
    
    // ?��??��?（�??�模式�?
    final reverseOptions = <String>[widget.card.lemma];
    for (var i = 0; i < 3 && i < otherWords.length; i++) {
      reverseOptions.add(otherWords[i].lemma);
    }
    reverseOptions.shuffle();
    
    return {
      'word': word,
      'sense': sense,
      'options': options,
      'reverseOptions': reverseOptions,
    };
  }
}

class _OptionButton extends StatelessWidget {
  final String label;
  final int index;
  final bool isSelected;
  final bool isCorrect;
  final bool isWrong;
  final bool enabled;
  final bool isDark;
  final VoidCallback onTap;

  const _OptionButton({
    required this.label,
    required this.index,
    required this.isSelected,
    required this.isCorrect,
    required this.isWrong,
    required this.enabled,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final letters = ['A', 'B', 'C', 'D'];

    Color bg;
    Color border;
    Color fg;

    if (isCorrect) {
      bg = isDark ? AppTheme.gray700 : AppTheme.gray200;
      border = const Color(0xFF3A3A3A);
      fg = isDark ? AppTheme.pureWhite : AppTheme.pureBlack;
    } else if (isWrong) {
      bg = isDark ? AppTheme.gray850 : AppTheme.gray50;
      border = const Color(0xFF888888);
      fg = isDark ? AppTheme.gray500 : AppTheme.gray400;
    } else if (isSelected) {
      bg = isDark ? AppTheme.gray800 : AppTheme.gray100;
      border = isDark ? AppTheme.pureWhite : AppTheme.pureBlack;
      fg = isDark ? AppTheme.pureWhite : AppTheme.pureBlack;
    } else {
      bg = isDark ? AppTheme.gray900 : AppTheme.pureWhite;
      border = isDark ? AppTheme.gray800 : AppTheme.gray200;
      fg = isDark ? AppTheme.pureWhite : AppTheme.pureBlack;
    }

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isDark ? AppTheme.gray800 : AppTheme.gray100,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Text(
                  index < letters.length ? letters[index] : '${index + 1}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: AppTheme.weightBold,
                    color: fg,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  color: fg,
                  fontWeight: isCorrect ? AppTheme.weightSemiBold : AppTheme.weightRegular,
                ),
              ),
            ),
            if (isCorrect)
              Icon(Icons.check_circle, color: Color(0xFF3A3A3A), size: 20),
            if (isWrong)
              Icon(Icons.cancel, color: Color(0xFF888888), size: 20),
          ],
        ),
      ),
    );
  }
}
