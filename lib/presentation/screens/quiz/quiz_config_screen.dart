import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../../domain/entities/quiz_skill.dart';
import '../../../core/providers/learning_progress_providers.dart';
import 'quiz_session_screen.dart';
import 'quiz_history_screen.dart';
import 'mistake_book_screen.dart';

/// 測驗設定頁面
/// 
/// 讓使用者選擇題型、題數等設定
class QuizConfigScreen extends ConsumerStatefulWidget {
  final String userId;

  const QuizConfigScreen({
    super.key,
    required this.userId,
  });

  @override
  ConsumerState<QuizConfigScreen> createState() => _QuizConfigScreenState();
}

class _QuizConfigScreenState extends ConsumerState<QuizConfigScreen> {
  final Set<QuizSkillType> _selectedTypes = {QuizSkillType.recognition};
  int _questionCount = 10;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final learnedCountAsync = ref.watch(learnedWordsCountProvider(widget.userId));
    final learningStatsAsync = ref.watch(learningStatsProvider(widget.userId));

    return Scaffold(
      backgroundColor: isDark ? AppTheme.pureBlack : AppTheme.offWhite,
      appBar: AppBar(
        backgroundColor: isDark ? AppTheme.pureBlack : AppTheme.offWhite,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: isDark ? AppTheme.pureWhite : AppTheme.pureBlack,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          '測驗設定',
          style: TextStyle(
            color: isDark ? AppTheme.pureWhite : AppTheme.pureBlack,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 學習進度卡片
                    learningStatsAsync.when(
                      data: (stats) => _buildLearningStatsCard(context, stats, isDark),
                      loading: () => const SizedBox.shrink(),
                      error: (_, _) => const SizedBox.shrink(),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // 快捷入口
                    Row(
                      children: [
                        Expanded(
                          child: _buildQuickAccessCard(
                            context,
                            '測驗歷史',
                            Icons.history,
                            isDark,
                            () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => QuizHistoryScreen(
                                    userId: widget.userId,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildQuickAccessCard(
                            context,
                            '錯題本',
                            Icons.book_outlined,
                            isDark,
                            () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => MistakeBookScreen(
                                    userId: widget.userId,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // 標題
                    Text(
                      '選擇題型',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '可以選擇多種題型混合練習',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDark ? AppTheme.gray400 : AppTheme.gray600,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 題型選擇
                    ...QuizSkillType.values.map((type) {
                      final skill = QuizSkill(type: type);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildSkillTypeCard(
                          context,
                          skill,
                          _selectedTypes.contains(type),
                          (selected) {
                            setState(() {
                              if (selected) {
                                _selectedTypes.add(type);
                              } else {
                                if (_selectedTypes.length > 1) {
                                  _selectedTypes.remove(type);
                                }
                              }
                            });
                          },
                        ),
                      );
                    }),

                    const SizedBox(height: 32),

                    // 題數選擇
                    Text(
                      '題目數量',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '$_questionCount 題',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ),
                        // 顯示可測驗單字數
                        learnedCountAsync.when(
                          data: (count) => Text(
                            '可測驗：$count 個單字',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isDark ? AppTheme.gray500 : AppTheme.gray500,
                            ),
                          ),
                          loading: () => const SizedBox.shrink(),
                          error: (_, _) => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    Slider(
                      value: _questionCount.toDouble(),
                      min: 5,
                      max: 50,
                      divisions: 9,
                      label: '$_questionCount 題',
                      onChanged: (value) {
                        setState(() {
                          _questionCount = value.toInt();
                        });
                      },
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            // 開始測驗按鈕
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.gray900 : AppTheme.pureWhite,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    offset: const Offset(0, -4),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 學習提示（如果沒有已學習的單字）
                  learnedCountAsync.when(
                    data: (count) {
                      if (count == 0) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.gray850 : AppTheme.gray100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 20,
                                color: isDark ? AppTheme.gray400 : AppTheme.gray600,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  '尚未學習任何單字，建議先完成學習',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: isDark ? AppTheme.gray400 : AppTheme.gray600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                  ),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _selectedTypes.isEmpty
                          ? null
                          : () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => QuizSessionScreen(
                                    userId: widget.userId,
                                    skillTypes: _selectedTypes.toList(),
                                    questionCount: _questionCount,
                                  ),
                                ),
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? AppTheme.pureWhite : AppTheme.pureBlack,
                        foregroundColor: isDark ? AppTheme.pureBlack : AppTheme.pureWhite,
                        disabledBackgroundColor: isDark ? AppTheme.gray800 : AppTheme.gray300,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        '開始測驗',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildLearningStatsCard(BuildContext context, LearningStats stats, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.gray900 : AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppTheme.gray800 : AppTheme.gray200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.school_outlined,
                size: 24,
                color: isDark ? AppTheme.pureWhite : AppTheme.pureBlack,
              ),
              const SizedBox(width: 12),
              Text(
                '學習進度',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  context,
                  '已學習',
                  stats.totalLearned.toString(),
                  isDark,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  context,
                  '今日',
                  stats.learnedToday.toString(),
                  isDark,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  context,
                  '本週',
                  stats.learnedThisWeek.toString(),
                  isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatItem(BuildContext context, String label, String value, bool isDark) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: isDark ? AppTheme.gray500 : AppTheme.gray500,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAccessCard(
    BuildContext context,
    String title,
    IconData icon,
    bool isDark,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.gray900 : AppTheme.pureWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppTheme.gray800 : AppTheme.gray300,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isDark ? AppTheme.pureWhite : AppTheme.pureBlack,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillTypeCard(
    BuildContext context,
    QuizSkill skill,
    bool isSelected,
    ValueChanged<bool> onChanged,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () => onChanged(!isSelected),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppTheme.gray800 : AppTheme.gray100)
              : (isDark ? AppTheme.gray900 : AppTheme.pureWhite),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? (isDark ? AppTheme.pureWhite : AppTheme.pureBlack)
                : (isDark ? AppTheme.gray800 : AppTheme.gray300),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // 選擇框
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark ? AppTheme.pureWhite : AppTheme.pureBlack)
                    : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? (isDark ? AppTheme.pureWhite : AppTheme.pureBlack)
                      : (isDark ? AppTheme.gray600 : AppTheme.gray400),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: isSelected
                  ? Icon(
                      Icons.check,
                      size: 16,
                      color: isDark ? AppTheme.pureBlack : AppTheme.pureWhite,
                    )
                  : null,
            ),

            const SizedBox(width: 16),

            // 題型資訊
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        skill.nameZh,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        skill.nameEn,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark ? AppTheme.gray500 : AppTheme.gray500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    skill.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDark ? AppTheme.gray400 : AppTheme.gray600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
