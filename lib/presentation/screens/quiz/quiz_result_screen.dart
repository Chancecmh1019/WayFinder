import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../../domain/entities/quiz_question.dart';
import 'mistake_book_screen.dart';

/// 測驗結果頁面
/// 
/// 顯示測驗成績和詳細結果
class QuizResultScreen extends StatelessWidget {
  final String userId;
  final List<QuizQuestion> questions;
  final Map<int, String> answers;
  final Map<int, bool> results;
  final Duration duration;

  const QuizResultScreen({
    super.key,
    required this.userId,
    required this.questions,
    required this.answers,
    required this.results,
    required this.duration,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final correctCount = results.values.where((r) => r).length;
    final totalCount = questions.length;
    final percentage = (correctCount / totalCount * 100).round();

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
            // 返回到主畫面，清除所有測驗相關頁面
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        ),
        title: Text(
          '測驗結果',
          style: TextStyle(
            color: isDark ? AppTheme.pureWhite : AppTheme.pureBlack,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // 成績卡片
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.gray900 : AppTheme.pureWhite,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    offset: const Offset(0, 4),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Column(
                children: [
                  // 分數
                  Text(
                    '$percentage%',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$correctCount / $totalCount 題正確',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: isDark ? AppTheme.gray400 : AppTheme.gray600,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 評語
                  Text(
                    _getScoreComment(percentage),
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // 用時
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 20,
                        color: isDark ? AppTheme.gray400 : AppTheme.gray600,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatDuration(duration),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isDark ? AppTheme.gray400 : AppTheme.gray600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // 詳細結果
            Text(
              '詳細結果',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            ...questions.asMap().entries.map((entry) {
              final index = entry.key;
              final question = entry.value;
              final isCorrect = results[index] ?? false;
              final userAnswer = answers[index] ?? '未作答';

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildResultItem(
                  context,
                  index + 1,
                  question,
                  userAnswer,
                  isCorrect,
                ),
              );
            }),

            const SizedBox(height: 32),

            // 按鈕
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // 導航到錯題本頁面
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => MistakeBookScreen(
                            userId: userId,
                          ),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(
                        color: isDark ? AppTheme.pureWhite : AppTheme.pureBlack,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('錯題本'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: isDark ? AppTheme.pureWhite : AppTheme.pureBlack,
                      foregroundColor: isDark ? AppTheme.pureBlack : AppTheme.pureWhite,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('完成'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultItem(
    BuildContext context,
    int number,
    QuizQuestion question,
    String userAnswer,
    bool isCorrect,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.gray900 : AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCorrect
              ? (isDark ? AppTheme.gray600 : AppTheme.gray700)
              : (isDark ? AppTheme.gray700 : AppTheme.gray400),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 題號和狀態
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.gray800 : AppTheme.gray200,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '第 $number 題',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
              const Spacer(),
              Icon(
                isCorrect ? Icons.check_circle : Icons.cancel,
                color: isDark ? AppTheme.pureWhite : AppTheme.pureBlack,
                size: 20,
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 題目
          Text(
            question.prompt,
            style: Theme.of(context).textTheme.bodyMedium,
          ),

          const SizedBox(height: 8),

          // 你的答案
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '你的答案：',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isDark ? AppTheme.gray500 : AppTheme.gray500,
                ),
              ),
              Expanded(
                child: Text(
                  userAnswer,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          // 正確答案（如果答錯）
          if (!isCorrect) ...[
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '正確答案：',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark ? AppTheme.gray500 : AppTheme.gray500,
                  ),
                ),
                Expanded(
                  child: Text(
                    question.getCorrectAnswer(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _getScoreComment(int percentage) {
    if (percentage >= 90) return '太棒了！你已經完全掌握了！';
    if (percentage >= 80) return '很好！繼續保持！';
    if (percentage >= 70) return '不錯！還有進步空間！';
    if (percentage >= 60) return '及格了！再加把勁！';
    return '需要多加練習喔！';
  }
  
  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    if (minutes > 0) {
      return '$minutes 分 $seconds 秒';
    }
    return '$seconds 秒';
  }
}
