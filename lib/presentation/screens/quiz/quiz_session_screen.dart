import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../../domain/entities/quiz_skill.dart';
import '../../../domain/entities/quiz_question.dart';
import '../../../core/providers/quiz_providers.dart';
import '../../../core/providers/tts_providers.dart';
import 'quiz_result_screen.dart';

/// 測驗進行頁面
/// 
/// 顯示題目並收集答案
class QuizSessionScreen extends ConsumerStatefulWidget {
  final String userId;
  final List<QuizSkillType> skillTypes;
  final int questionCount;
  final List<String>? wordIds;

  const QuizSessionScreen({
    super.key,
    required this.userId,
    required this.skillTypes,
    required this.questionCount,
    this.wordIds,
  });

  @override
  ConsumerState<QuizSessionScreen> createState() => _QuizSessionScreenState();
}

class _QuizSessionScreenState extends ConsumerState<QuizSessionScreen> {
  int _currentIndex = 0;
  final Map<int, String> _answers = {};
  final Map<int, bool> _results = {};
  final Map<int, TextEditingController> _controllers = {};
  DateTime? _startTime;
  List<QuizQuestion>? _questions;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _loadQuestions();
  }

  @override
  void dispose() {
    // 清理所有 TextEditingController
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TextEditingController _getController(int index) {
    if (!_controllers.containsKey(index)) {
      _controllers[index] = TextEditingController();
    }
    return _controllers[index]!;
  }

  Future<void> _loadQuestions() async {
    try {
      final config = QuizConfig(
        userId: widget.userId,
        skillTypes: widget.skillTypes,
        questionCount: widget.questionCount,
        wordIds: widget.wordIds,
      );
      
      final questions = await ref.read(generateQuizQuestionsProvider(config).future);
      
      if (mounted) {
        setState(() {
          _questions = questions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('載入題目失敗: $e')),
        );
      }
    }
  }

  void _submitAnswer(String answer) {
    if (_questions == null || _questions!.isEmpty) return;
    
    setState(() {
      _answers[_currentIndex] = answer;
      // 檢查答案
      final isCorrect = _questions![_currentIndex].checkAnswer(answer);
      _results[_currentIndex] = isCorrect;
    });

    // 延遲後自動進入下一題
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      
      if (_currentIndex < _questions!.length - 1) {
        setState(() {
          _currentIndex++;
        });
      } else {
        _showResults();
      }
    });
  }

  void _showResults() {
    final duration = DateTime.now().difference(_startTime!);
    
    // 保存測驗結果
    final result = QuizResult(
      userId: widget.userId,
      questions: _questions!,
      answers: _answers,
      results: _results,
      skillTypes: widget.skillTypes,
      duration: duration,
    );
    
    // 異步保存結果
    ref.read(saveQuizResultProvider(result));
    
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => QuizResultScreen(
          userId: widget.userId,
          questions: _questions!,
          answers: _answers,
          results: _results,
          duration: duration,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // 載入中
    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark ? AppTheme.pureBlack : AppTheme.offWhite,
        appBar: AppBar(
          backgroundColor: isDark ? AppTheme.pureBlack : AppTheme.offWhite,
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    // 如果沒有題目，顯示空狀態
    if (_questions == null || _questions!.isEmpty) {
      return Scaffold(
        backgroundColor: isDark ? AppTheme.pureBlack : AppTheme.offWhite,
        appBar: AppBar(
          backgroundColor: isDark ? AppTheme.pureBlack : AppTheme.offWhite,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.close,
              color: isDark ? AppTheme.pureWhite : AppTheme.pureBlack,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: isDark ? AppTheme.gray600 : AppTheme.gray400,
              ),
              const SizedBox(height: 16),
              Text(
                '無法生成測驗題目',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                '請確認已載入單字資料',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark ? AppTheme.gray400 : AppTheme.gray600,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('返回'),
              ),
            ],
          ),
        ),
      );
    }
    
    final question = _questions![_currentIndex];
    final hasAnswered = _answers.containsKey(_currentIndex);

    return Scaffold(
      backgroundColor: isDark ? AppTheme.pureBlack : AppTheme.offWhite,
      appBar: AppBar(
        backgroundColor: isDark ? AppTheme.pureBlack : AppTheme.offWhite,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.close,
            color: isDark ? AppTheme.pureWhite : AppTheme.pureBlack,
          ),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('確定要離開嗎？'),
                content: const Text('測驗進度將不會被保存'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('取消'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                    },
                    child: const Text('離開'),
                  ),
                ],
              ),
            );
          },
        ),
        title: Text(
          '${_currentIndex + 1}/${_questions!.length}',
          style: TextStyle(
            color: isDark ? AppTheme.pureWhite : AppTheme.pureBlack,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 進度條
          LinearProgressIndicator(
            value: (_currentIndex + 1) / _questions!.length,
            backgroundColor: isDark ? AppTheme.gray800 : AppTheme.gray200,
            valueColor: AlwaysStoppedAnimation<Color>(
              isDark ? AppTheme.pureWhite : AppTheme.pureBlack,
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 題型標籤
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.gray800 : AppTheme.gray200,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      question.type.displayName,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 題目
                  Text(
                    question.prompt,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 拼寫題的語音播放按鈕
                  if (question is SpellingQuestion)
                    Center(
                      child: Column(
                        children: [
                          IconButton(
                            onPressed: () {
                              // 使用 TTS 播放單字發音
                              ref.read(activeTtsServiceProvider).speak(question.word);
                            },
                            icon: Icon(
                              Icons.volume_up_rounded,
                              size: 64,
                              color: isDark ? AppTheme.pureWhite : AppTheme.pureBlack,
                            ),
                            style: IconButton.styleFrom(
                              backgroundColor: isDark ? AppTheme.gray800 : AppTheme.gray200,
                              padding: const EdgeInsets.all(24),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '點擊播放發音',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isDark ? AppTheme.gray500 : AppTheme.gray500,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),

                  // 選項（如果是選擇題）
                  if (question is MultipleChoiceQuestion)
                    ...question.options.asMap().entries.map((entry) {
                      final index = entry.key;
                      final option = entry.value;
                      final isSelected = _answers[_currentIndex] == option;
                      final isCorrect = index == question.correctIndex;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildOptionButton(
                          context,
                          option,
                          index,
                          isSelected,
                          hasAnswered && isCorrect,
                          hasAnswered && isSelected && !isCorrect,
                          () => !hasAnswered ? _submitAnswer(option) : null,
                        ),
                      );
                    }),

                  // 填空或拼寫題的輸入框
                  if (question is! MultipleChoiceQuestion) ...[
                    TextField(
                      controller: _getController(_currentIndex),
                      enabled: !hasAnswered,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: '請輸入答案',
                        filled: true,
                        fillColor: isDark ? AppTheme.gray900 : AppTheme.pureWhite,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark ? AppTheme.gray800 : AppTheme.gray300,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark ? AppTheme.gray800 : AppTheme.gray300,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark ? AppTheme.pureWhite : AppTheme.pureBlack,
                            width: 2,
                          ),
                        ),
                      ),
                      style: Theme.of(context).textTheme.bodyLarge,
                      onSubmitted: (value) {
                        if (!hasAnswered && value.trim().isNotEmpty) {
                          _submitAnswer(value.trim());
                        }
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // 提交按鈕
                    if (!hasAnswered)
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () {
                            final text = _getController(_currentIndex).text.trim();
                            if (text.isNotEmpty) {
                              _submitAnswer(text);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? AppTheme.pureWhite : AppTheme.pureBlack,
                            foregroundColor: isDark ? AppTheme.pureBlack : AppTheme.pureWhite,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            '提交答案',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    
                    // 顯示答案反饋
                    if (hasAnswered) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _results[_currentIndex] == true
                              ? (isDark ? AppTheme.gray700 : AppTheme.gray300)
                              : (isDark ? AppTheme.gray850 : AppTheme.gray200),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _results[_currentIndex] == true
                                ? (isDark ? AppTheme.gray600 : AppTheme.gray700)
                                : (isDark ? AppTheme.gray700 : AppTheme.gray400),
                            width: 2,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _results[_currentIndex] == true
                                      ? Icons.check_circle
                                      : Icons.cancel,
                                  color: isDark ? AppTheme.pureWhite : AppTheme.pureBlack,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _results[_currentIndex] == true ? '答對了！' : '答錯了',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            if (_results[_currentIndex] == false) ...[
                              const SizedBox(height: 12),
                              Text(
                                '你的答案: ${_answers[_currentIndex]}',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: isDark ? AppTheme.gray400 : AppTheme.gray600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '正確答案: ${question.getCorrectAnswer()}',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            Text(
                              question.getExplanation(),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: isDark ? AppTheme.gray400 : AppTheme.gray600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionButton(
    BuildContext context,
    String option,
    int index,
    bool isSelected,
    bool isCorrect,
    bool isWrong,
    VoidCallback? onTap,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labels = ['A', 'B', 'C', 'D'];

    Color? backgroundColor;
    Color? borderColor;
    Color? textColor;
    IconData? icon;

    if (isCorrect) {
      // 正確答案使用深灰色並加粗
      backgroundColor = isDark 
          ? AppTheme.gray700
          : AppTheme.gray300;
      borderColor = isDark ? AppTheme.gray600 : AppTheme.gray700;
      textColor = isDark ? AppTheme.pureWhite : AppTheme.pureBlack;
      icon = Icons.check_circle;
    } else if (isWrong) {
      // 錯誤答案使用淺灰色
      backgroundColor = isDark 
          ? AppTheme.gray850
          : AppTheme.gray200;
      borderColor = isDark ? AppTheme.gray700 : AppTheme.gray400;
      textColor = isDark ? AppTheme.gray400 : AppTheme.gray600;
      icon = Icons.cancel;
    } else if (isSelected) {
      backgroundColor = isDark ? AppTheme.gray800 : AppTheme.gray100;
      borderColor = isDark ? AppTheme.pureWhite : AppTheme.pureBlack;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor ?? (isDark ? AppTheme.gray900 : AppTheme.pureWhite),
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(
            color: borderColor ?? (isDark ? AppTheme.gray800 : AppTheme.gray300),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            // 選項標籤
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: textColor != null
                    ? (isDark ? AppTheme.gray700 : AppTheme.gray300)
                    : (isDark ? AppTheme.gray800 : AppTheme.gray200),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Center(
                child: Text(
                  labels[index],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: textColor ?? (isDark ? AppTheme.pureWhite : AppTheme.pureBlack),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 16),

            // 選項文字
            Expanded(
              child: Text(
                option,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: textColor,
                  fontWeight: isCorrect ? FontWeight.w600 : null,
                ),
              ),
            ),

            // 正確/錯誤圖示
            if (icon != null)
              Icon(
                icon,
                color: textColor ?? (isDark ? AppTheme.pureWhite : AppTheme.pureBlack),
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}
