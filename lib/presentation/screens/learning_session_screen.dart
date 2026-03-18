import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../providers/unified_learning_provider.dart';
import '../../data/models/fsrs_card_model.dart';
import '../../domain/services/fsrs_algorithm.dart';
import '../../core/providers/vocab_providers.dart';

/// 學習模式 - FSRS 學習系統
/// 
/// 流程：
/// 1. 顯示卡片正面（問題）
/// 2. 用戶點擊翻轉或按空白鍵
/// 3. 顯示卡片背面（答案）+ FSRS 評分按鈕
/// 4. 用戶評分（Again/Hard/Good/Easy）或按1-4
/// 5. 系統使用 FSRS 演算法記錄並計算下次複習時間
/// 6. 切換下一張卡片
class LearningSessionScreen extends ConsumerStatefulWidget {
  final String userId;
  final int? newCardsLimit;
  final int? reviewCardsLimit;
  
  const LearningSessionScreen({
    super.key,
    required this.userId,
    this.newCardsLimit,
    this.reviewCardsLimit,
  });

  @override
  ConsumerState<LearningSessionScreen> createState() => _LearningSessionScreenState();
}

class _LearningSessionScreenState extends ConsumerState<LearningSessionScreen> {
  bool _isFlipped = false;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    // Initialize learning session on mount
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(unifiedLearningProvider(widget.userId).notifier).initialize();
    });
  }

  void _handleFlip() {
    if (_isAnimating) return;
    
    setState(() {
      _isAnimating = true;
      _isFlipped = !_isFlipped;
    });

    // Reset animation flag after flip completes
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() => _isAnimating = false);
      }
    });
  }

  void _handleRate(FSRSRating rating) async {
    if (_isAnimating) return;

    // Submit review with FSRS rating
    await ref.read(unifiedLearningProvider(widget.userId).notifier).submitReview(
      rating: rating,
      reviewTimeSeconds: 10, // Could track actual time
    );

    // Reset flip state for next card
    if (mounted) {
      setState(() {
        _isFlipped = false;
        _isAnimating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sessionState = ref.watch(unifiedLearningProvider(widget.userId));

    return Scaffold(
      backgroundColor: isDark ? AppTheme.pureBlack : AppTheme.offWhite,
      body: SafeArea(
        child: KeyboardListener(
          focusNode: FocusNode(),
          autofocus: true,
          onKeyEvent: (event) {
            if (event is KeyDownEvent) {
              // Space to flip/show answer
              if (event.logicalKey == LogicalKeyboardKey.space && !_isFlipped) {
                _handleFlip();
              }
              // 1-4 to rate (when flipped)
              else if (_isFlipped) {
                if (event.logicalKey == LogicalKeyboardKey.digit1) {
                  _handleRate(FSRSRating.again);
                } else if (event.logicalKey == LogicalKeyboardKey.digit2) {
                  _handleRate(FSRSRating.hard);
                } else if (event.logicalKey == LogicalKeyboardKey.digit3) {
                  _handleRate(FSRSRating.good);
                } else if (event.logicalKey == LogicalKeyboardKey.digit4) {
                  _handleRate(FSRSRating.easy);
                }
              }
            }
          },
          child: _buildContent(context, sessionState),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, UnifiedLearningState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return _buildError(context, state.error!);
    }

    if (!state.hasMore && state.currentIndex > 0) {
      return _buildCompletionScreen(context, state);
    }

    if (state.currentCard == null) {
      return _buildEmptyState(context);
    }

    return _buildSessionContent(context, state);
  }

  Widget _buildSessionContent(BuildContext context, UnifiedLearningState state) {
    return Column(
      children: [
        // Header with close button and stats
        _buildHeader(context, state),
        
        const SizedBox(height: 24),

        // Flashcard
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildCardPlaceholder(context, state.currentCard!),
            ),
          ),
        ),

        // Rating buttons (only when flipped)
        if (_isFlipped) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _buildRatingButtons(context),
          ),
          const SizedBox(height: 16),
        ],

        // Progress indicator
        _buildProgress(context, state),
        
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildRatingButtons(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Row(
      children: [
        Expanded(
          child: _buildRatingButton(
            context,
            '再來一次',
            'Again',
            () => _handleRate(FSRSRating.again),
            isDark,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildRatingButton(
            context,
            '困難',
            'Hard',
            () => _handleRate(FSRSRating.hard),
            isDark,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildRatingButton(
            context,
            '良好',
            'Good',
            () => _handleRate(FSRSRating.good),
            isDark,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildRatingButton(
            context,
            '簡單',
            'Easy',
            () => _handleRate(FSRSRating.easy),
            isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildRatingButton(
    BuildContext context,
    String label,
    String sublabel,
    VoidCallback onTap,
    bool isDark,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.gray900 : AppTheme.pureWhite,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark ? AppTheme.gray800 : AppTheme.gray200,
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              sublabel,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isDark ? AppTheme.gray500 : AppTheme.gray500,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardPlaceholder(BuildContext context, FSRSCardModel card) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: _handleFlip,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        constraints: const BoxConstraints(
          maxWidth: 600,
          maxHeight: 400,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.gray900 : AppTheme.pureWhite,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(
            color: _isFlipped 
                ? (isDark ? AppTheme.gray700 : AppTheme.gray300)
                : (isDark ? AppTheme.gray800 : AppTheme.gray200),
            width: 1,
          ),
          boxShadow: _isFlipped ? AppTheme.elevatedShadow : AppTheme.cardShadow,
        ),
        padding: const EdgeInsets.all(32),
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: animation,
                  child: child,
                ),
              );
            },
            child: _isFlipped 
                ? _buildAnswerSide(context, card, isDark)
                : _buildQuestionSide(context, card, isDark),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionSide(BuildContext context, FSRSCardModel card, bool isDark) {
    // 從 provider 獲取單字詳情
    final wordDetailAsync = ref.watch(wordDetailProvider(card.lemma));
    
    return wordDetailAsync.when(
      data: (wordEntry) {
        if (wordEntry == null) {
          return _buildQuestionSideFallback(context, card, isDark);
        }
        
        // 找到對應的義項
        final sense = wordEntry.senses.firstWhere(
          (s) => s.senseId == card.senseId,
          orElse: () => wordEntry.senses.first,
        );
        
        return Column(
          key: const ValueKey('question'),
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 單字
            Text(
              card.lemma,
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: -0.8,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 16),
            
            // 音標和詞性
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (sense.pos.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.gray850 : AppTheme.gray100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      sense.pos,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDark ? AppTheme.gray400 : AppTheme.gray600,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // 提示文字
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.gray850 : AppTheme.gray50,
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.touch_app,
                    size: 16,
                    color: isDark ? AppTheme.gray500 : AppTheme.gray400,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '點擊翻轉查看答案',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDark ? AppTheme.gray500 : AppTheme.gray400,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Tap to flip',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDark ? AppTheme.gray600 : AppTheme.gray500,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
      loading: () => _buildQuestionSideFallback(context, card, isDark),
      error: (error, stackTrace) => _buildQuestionSideFallback(context, card, isDark),
    );
  }
  
  Widget _buildQuestionSideFallback(BuildContext context, FSRSCardModel card, bool isDark) {
    return Column(
      key: const ValueKey('question'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 單字
        Text(
          card.lemma,
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: -0.8,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        
        // 提示文字
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.gray850 : AppTheme.gray50,
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.touch_app,
                size: 16,
                color: isDark ? AppTheme.gray500 : AppTheme.gray400,
              ),
              const SizedBox(width: 8),
              Text(
                '點擊翻轉查看答案',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isDark ? AppTheme.gray500 : AppTheme.gray400,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'Tap to flip',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isDark ? AppTheme.gray600 : AppTheme.gray500,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnswerSide(BuildContext context, FSRSCardModel card, bool isDark) {
    // 從 provider 獲取單字詳情
    final wordDetailAsync = ref.watch(wordDetailProvider(card.lemma));
    
    return wordDetailAsync.when(
      data: (wordEntry) {
        if (wordEntry == null) {
          return _buildAnswerSideFallback(context, card, isDark);
        }
        
        // 找到對應的義項
        final sense = wordEntry.senses.firstWhere(
          (s) => s.senseId == card.senseId,
          orElse: () => wordEntry.senses.first,
        );
        
        return SingleChildScrollView(
          key: const ValueKey('answer'),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 單字和詞性
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    card.lemma,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (sense.pos.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.gray850 : AppTheme.gray100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        sense.pos,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark ? AppTheme.gray400 : AppTheme.gray600,
                        ),
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // 中文定義
              if (sense.zhDef.isNotEmpty) ...[
                Text(
                  '定義',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isDark ? AppTheme.gray500 : AppTheme.gray500,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  sense.zhDef,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    height: 1.5,
                  ),
                  textAlign: TextAlign.left,
                ),
                const SizedBox(height: 16),
              ],
              
              // 英文定義（如果沒有中文定義）
              if (sense.zhDef.isEmpty && sense.enDef != null && sense.enDef!.isNotEmpty) ...[
                Text(
                  'Definition',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isDark ? AppTheme.gray500 : AppTheme.gray500,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  sense.enDef!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.5,
                    color: isDark ? AppTheme.gray300 : AppTheme.gray700,
                  ),
                  textAlign: TextAlign.left,
                ),
                const SizedBox(height: 16),
              ],
              
              // 例句
              if (sense.generatedExample != null && sense.generatedExample!.isNotEmpty) ...[
                Text(
                  '例句',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isDark ? AppTheme.gray500 : AppTheme.gray500,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.gray850 : AppTheme.gray50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    sense.generatedExample!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.5,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ] else if (sense.examples.isNotEmpty) ...[
                Text(
                  '例句',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isDark ? AppTheme.gray500 : AppTheme.gray500,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.gray850 : AppTheme.gray50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    sense.examples.first.text,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.5,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // 記憶技巧
              if (wordEntry.rootInfo?.memoryStrategy != null && 
                  wordEntry.rootInfo!.memoryStrategy.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark 
                        ? AppTheme.gray850.withValues(alpha: 0.5)
                        : AppTheme.gray50.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? AppTheme.gray700 : AppTheme.gray300,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        size: 18,
                        color: isDark ? AppTheme.gray400 : AppTheme.gray600,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          wordEntry.rootInfo?.memoryStrategy ?? '',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isDark ? AppTheme.gray400 : AppTheme.gray600,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // 提示文字
              Center(
                child: Text(
                  '請根據記憶程度評分',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark ? AppTheme.gray400 : AppTheme.gray600,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  'Rate your memory',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark ? AppTheme.gray500 : AppTheme.gray500,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => _buildAnswerSideFallback(context, card, isDark),
      error: (error, stackTrace) => _buildAnswerSideFallback(context, card, isDark),
    );
  }
  
  Widget _buildAnswerSideFallback(BuildContext context, FSRSCardModel card, bool isDark) {
    return Column(
      key: const ValueKey('answer'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 單字
        Text(
          card.lemma,
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        
        // 義項 ID（臨時顯示）
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.gray850 : AppTheme.gray100,
            borderRadius: BorderRadius.circular(AppTheme.radiusTiny),
          ),
          child: Text(
            '義項 ${card.senseId}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isDark ? AppTheme.gray400 : AppTheme.gray600,
              fontSize: 11,
            ),
          ),
        ),
        const SizedBox(height: 24),
        
        // 提示文字
        Text(
          '請根據記憶程度評分',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: isDark ? AppTheme.gray400 : AppTheme.gray600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Rate your memory',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: isDark ? AppTheme.gray500 : AppTheme.gray500,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, UnifiedLearningState state) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final streak = ref.watch(currentStreakProvider);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const Spacer(),
          // Show streak
          if (streak > 0) ...[
            Icon(
              Icons.local_fire_department,
              size: 20,
              color: isDark ? AppTheme.gray400 : AppTheme.gray600,
            ),
            const SizedBox(width: 4),
            Text(
              '$streak',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? AppTheme.gray400 : AppTheme.gray600,
              ),
            ),
            const SizedBox(width: 16),
          ],
          // Show completed count
          Text(
            'Completed: ${state.completedCount}',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppTheme.gray400 : AppTheme.gray600,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Accuracy: ${(state.accuracy * 100).toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppTheme.gray400 : AppTheme.gray600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgress(BuildContext context, UnifiedLearningState state) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final completed = state.currentIndex;
    final total = state.queue.length;

    return Column(
      children: [
        // Progress bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: state.progress,
              minHeight: 6,
              backgroundColor: isDark ? AppTheme.gray800 : AppTheme.gray200,
              valueColor: AlwaysStoppedAnimation(
                isDark ? AppTheme.pureWhite : AppTheme.pureBlack,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Counter
        Text(
          '$completed / $total',
          style: TextStyle(
            fontSize: 13,
            color: isDark ? AppTheme.gray400 : AppTheme.gray600,
          ),
        ),
      ],
    );
  }

  Widget _buildCompletionScreen(BuildContext context, UnifiedLearningState state) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final streak = ref.watch(currentStreakProvider);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 完成圖標
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: isDark ? AppTheme.gray900 : AppTheme.pureWhite,
                shape: BoxShape.circle,
                boxShadow: AppTheme.elevatedShadow,
              ),
              child: Icon(
                Icons.check_circle,
                size: 60,
                color: isDark ? AppTheme.pureWhite : AppTheme.pureBlack,
              ),
            ),
            const SizedBox(height: 32),
            
            // 主標題
            Text(
              '學習完成！',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Session Complete',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDark ? AppTheme.gray500 : AppTheme.gray500,
                fontSize: 13,
              ),
            ),
            
            const SizedBox(height: 40),
            
            // 統計卡片
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.gray900 : AppTheme.pureWhite,
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Column(
                children: [
                  _buildStatRow(
                    context,
                    '完成卡片',
                    'Cards Completed',
                    state.currentIndex.toString(),
                    isDark,
                  ),
                  const SizedBox(height: 16),
                  Divider(
                    height: 1,
                    color: isDark ? AppTheme.gray800 : AppTheme.gray200,
                  ),
                  const SizedBox(height: 16),
                  _buildStatRow(
                    context,
                    '新卡片',
                    'New Cards',
                    state.completedCount.toString(),
                    isDark,
                  ),
                  const SizedBox(height: 16),
                  Divider(
                    height: 1,
                    color: isDark ? AppTheme.gray800 : AppTheme.gray200,
                  ),
                  const SizedBox(height: 16),
                  _buildStatRow(
                    context,
                    '正確率',
                    'Accuracy',
                    '${(state.accuracy * 100).toStringAsFixed(0)}%',
                    isDark,
                  ),
                  if (streak > 0) ...[
                    const SizedBox(height: 16),
                    Divider(
                      height: 1,
                      color: isDark ? AppTheme.gray800 : AppTheme.gray200,
                    ),
                    const SizedBox(height: 16),
                    _buildStatRow(
                      context,
                      '連續天數',
                      'Streak',
                      '$streak 天',
                      isDark,
                      icon: Icons.local_fire_department,
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            
            // 返回按鈕
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // 繼續學習 - 重新初始化學習會話
                      ref.read(unifiedLearningProvider(widget.userId).notifier).initialize();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? AppTheme.pureWhite : AppTheme.pureBlack,
                      foregroundColor: isDark ? AppTheme.pureBlack : AppTheme.pureWhite,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      ),
                    ),
                    child: const Text(
                      '繼續學習',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // 返回前觸發首頁刷新
                      ref.read(unifiedStatsRefreshProvider.notifier).state++;
                      Navigator.of(context).pop();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? AppTheme.pureWhite : AppTheme.pureBlack,
                      side: BorderSide(
                        color: isDark ? AppTheme.gray700 : AppTheme.gray300,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      ),
                    ),
                    child: const Text(
                      '返回',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(
    BuildContext context,
    String label,
    String labelEn,
    String value,
    bool isDark, {
    IconData? icon,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 20,
                color: isDark ? AppTheme.gray400 : AppTheme.gray600,
              ),
              const SizedBox(width: 8),
            ],
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppTheme.pureWhite : AppTheme.pureBlack,
                    letterSpacing: -0.2,
                  ),
                ),
                Text(
                  labelEn,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppTheme.gray500 : AppTheme.gray500,
                  ),
                ),
              ],
            ),
          ],
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isDark ? AppTheme.pureWhite : AppTheme.pureBlack,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Center(
      child: Text(
        '沒有待學習的單字',
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: isDark ? AppTheme.gray400 : AppTheme.gray600,
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, String error) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: isDark ? AppTheme.gray600 : AppTheme.gray400,
          ),
          const SizedBox(height: 16),
          Text(
            '發生錯誤',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDark ? AppTheme.gray400 : AppTheme.gray600,
            ),
          ),
        ],
      ),
    );
  }
}
