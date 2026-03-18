import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/errors/failures.dart';
import '../../data/datasources/local/session_local_datasource.dart';
import '../../data/mappers/learning_session_mapper.dart';
import '../../data/services/audio_preloader.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/review_scheduler_repository.dart';
import '../../domain/repositories/vocabulary_repository.dart';
import '../../domain/services/quiz_engine.dart';
import '../../domain/usecases/get_next_item_usecase.dart';
import '../../domain/usecases/start_learning_session_usecase.dart';
import '../../domain/usecases/submit_answer_usecase.dart';
import 'learning_session_state.dart';

/// Notifier for managing learning session state
class LearningSessionNotifier extends StateNotifier<LearningSessionState> {
  final VocabularyRepository _vocabularyRepository;
  final QuizEngine _quizEngine;
  final StartLearningSessionUseCase _startSessionUseCase;
  final SubmitAnswerUseCase _submitAnswerUseCase;
  final SessionLocalDataSource _sessionDataSource;
  final Uuid _uuid;
  final AudioPreloader? _audioPreloader;

  /// Stopwatch for tracking time spent on current item
  final Stopwatch _itemStopwatch = Stopwatch();

  /// Timer for auto-saving session state
  Timer? _autoSaveTimer;

  LearningSessionNotifier({
    required ReviewSchedulerRepository reviewSchedulerRepository,
    required VocabularyRepository vocabularyRepository,
    required QuizEngine quizEngine,
    required StartLearningSessionUseCase startSessionUseCase,
    required GetNextItemUseCase getNextItemUseCase,
    required SubmitAnswerUseCase submitAnswerUseCase,
    SessionLocalDataSource? sessionDataSource,
    Uuid? uuid,
    AudioPreloader? audioPreloader,
  })  : _vocabularyRepository = vocabularyRepository,
        _quizEngine = quizEngine,
        _startSessionUseCase = startSessionUseCase,
        _submitAnswerUseCase = submitAnswerUseCase,
        _sessionDataSource = sessionDataSource ?? SessionLocalDataSource(),
        _uuid = uuid ?? const Uuid(),
        _audioPreloader = audioPreloader,
        super(LearningSessionState.initial()) {
    // Start auto-save timer (save every 10 seconds when session is active)
    _autoSaveTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _autoSaveSession(),
    );
  }

  /// Start a new learning session
  Future<void> startSession({int? dailyGoal}) async {
    // Set loading state
    state = state.copyWith(
      isLoading: true,
      error: null,
    );

    final goal = dailyGoal ?? state.dailyGoal;

    try {
      // Call the use case to get session data
      final result = await _startSessionUseCase(
        StartLearningSessionParams(dailyGoal: goal),
      );

      await result.fold(
        (failure) async {
          // Handle failure - 如果沒有待學習項目，創建一個空會話
          if (failure is NotFoundFailure) {
            state = state.copyWith(
              queue: [],
              totalCount: 0,
              completedCount: 0,
              sessionId: _uuid.v4(),
              startTime: DateTime.now(),
              isActive: true,
              isLoading: false,
              dailyGoal: goal,
              statistics: SessionStatistics.empty(),
              error: null,
            );
          } else {
            state = state.copyWith(
              isLoading: false,
              error: _getErrorMessage(failure),
            );
          }
        },
        (session) async {
          // Build the queue: due reviews first, then new words
          final queue = <LearningItem>[];

          // Add due reviews
          for (final review in session.dueReviews) {
            // Get vocabulary for each review
            final vocabResult = await _vocabularyRepository.getVocabularyByWord(
              review.word,
            );

            vocabResult.fold(
              (failure) {
                // Skip this item if vocabulary not found
              },
              (vocab) {
                queue.add(LearningItem.review(
                  vocabulary: vocab,
                  progress: review,
                ));
              },
            );
          }

          // Add new words
          for (final vocab in session.newWords) {
            queue.add(LearningItem.newWord(vocabulary: vocab));
          }

          // Update state with session data
          state = state.copyWith(
            queue: queue,
            totalCount: queue.length,
            completedCount: 0,
            sessionId: _uuid.v4(),
            startTime: DateTime.now(),
            isActive: true,
            isLoading: false,
            dailyGoal: goal,
            statistics: SessionStatistics.empty(),
            error: null,
          );

          // Save initial session state
          await _saveSessionState();

          // Get the first item
          if (queue.isNotEmpty) {
            await getNextItem();
          }
        },
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '啟動會話失敗: $e',
      );
    }
  }

  /// Get the next item in the session (prioritizes due reviews)
  Future<void> getNextItem() async {
    if (!state.isActive) {
      state = state.copyWith(
        error: 'Session is not active. Please start a session first.',
      );
      return;
    }

    // Check if we've completed all items
    if (state.completedCount >= state.totalCount) {
      await endSession();
      return;
    }

    // Get the next item from the queue
    if (state.completedCount < state.queue.length) {
      final nextItem = state.queue[state.completedCount];

      // Generate a question for this item
      final question = await _generateQuestion(nextItem);

      // Start timing for this item
      _itemStopwatch.reset();
      _itemStopwatch.start();

      state = state.copyWith(
        currentItem: nextItem,
        currentQuestion: question,
        error: null,
      );

      // Preload audio for upcoming items (3-5 items ahead)
      _preloadUpcomingAudio();
    } else {
      // No more items
      await endSession();
    }
  }

  /// Preload audio for upcoming items in the queue
  /// 
  /// This method runs in the background and preloads audio for the next 3-5 items
  /// to ensure smooth playback during the learning session.
  void _preloadUpcomingAudio() {
    if (_audioPreloader == null) return;

    try {
      // Get the next 3-5 items from the queue
      final currentIndex = state.completedCount;
      final remainingItems = state.queue.length - currentIndex;
      
      if (remainingItems <= 1) {
        // No upcoming items to preload
        return;
      }

      // Calculate how many items to preload (3-5, but not more than remaining)
      final preloadCount = remainingItems > 5 ? 5 : remainingItems;
      
      // Get upcoming items (skip current item at index 0)
      final upcomingItems = state.queue
          .skip(currentIndex + 1)
          .take(preloadCount)
          .map((item) => item.vocabulary)
          .toList();

      // Preload in the background (non-blocking)
      _audioPreloader.preloadUpcoming(upcomingItems);
    } catch (e) {
      // Log error but don't interrupt the session
      // In production, use proper logging
      // logger.warning('Failed to preload audio: $e');
    }
  }

  /// Generate a question for a learning item
  Future<QuizQuestion> _generateQuestion(LearningItem item) async {
    // Determine proficiency level
    final proficiency = item.progress?.proficiencyLevel ?? ProficiencyLevel.beginner;

    // Get distractors for multiple choice questions
    final distractorsResult = await _vocabularyRepository.getAllVocabulary();

    final distractors = distractorsResult.fold(
      (failure) => <VocabularyEntity>[],
      (allVocab) {
        return _quizEngine.generateDistractors(
          targetWord: item.vocabulary,
          vocabularyPool: allVocab,
          count: 3,
        );
      },
    );

    // Generate the question
    return _quizEngine.generateQuestion(
      word: item.vocabulary,
      proficiency: proficiency,
      distractors: distractors,
    );
  }

  /// Submit an answer for the current item
  Future<void> submitAnswer({
    required String userAnswer,
    required int quality,
  }) async {
    if (state.currentItem == null || state.currentQuestion == null) {
      state = state.copyWith(
        error: 'No current item to submit answer for',
      );
      return;
    }

    // Stop timing
    _itemStopwatch.stop();
    final timeSpent = _itemStopwatch.elapsed;

    final currentItem = state.currentItem!;
    final currentQuestion = state.currentQuestion!;

    // Check if answer is correct
    final isCorrect = currentQuestion.checkAnswer(userAnswer);

    // Adjust quality based on correctness if not manually set
    final adjustedQuality = quality >= 0 ? quality : (isCorrect ? 4 : 2);

    // Submit the answer using the use case
    final result = await _submitAnswerUseCase(
      SubmitAnswerParams(
        word: currentItem.vocabulary.lemma,
        quality: adjustedQuality,
        timeSpent: timeSpent,
        userAnswer: userAnswer,
        questionType: currentQuestion.type.name,
      ),
    );

    result.fold(
      (failure) {
        state = state.copyWith(
          error: _getErrorMessage(failure),
        );
      },
      (answerResult) {
        // Update statistics
        final updatedStats = _updateStatistics(
          isCorrect: answerResult.isCorrect,
          timeSpent: timeSpent,
          questionType: currentQuestion.type.name,
          isNewWord: currentItem.isNewWord,
        );

        // Increment completed count
        final newCompletedCount = state.completedCount + 1;

        state = state.copyWith(
          completedCount: newCompletedCount,
          statistics: updatedStats,
          error: null,
        );

        // Automatically get next item after a short delay
        // (In a real app, you might want to show feedback first)
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            getNextItem();
          }
        });
      },
    );
  }

  /// Update session statistics
  SessionStatistics _updateStatistics({
    required bool isCorrect,
    required Duration timeSpent,
    required String questionType,
    required bool isNewWord,
  }) {
    final currentStats = state.statistics;

    // Update question type distribution
    final updatedDistribution = Map<String, int>.from(
      currentStats.questionTypeDistribution,
    );
    updatedDistribution[questionType] = (updatedDistribution[questionType] ?? 0) + 1;

    return currentStats.copyWith(
      totalReviews: currentStats.totalReviews + 1,
      correctReviews: currentStats.correctReviews + (isCorrect ? 1 : 0),
      newWordsCount: currentStats.newWordsCount + (isNewWord ? 1 : 0),
      totalTime: currentStats.totalTime + timeSpent,
      questionTypeDistribution: updatedDistribution,
    );
  }

  /// End the current session
  Future<void> endSession() async {
    if (!state.isActive) {
      return;
    }

    // Stop any running timers
    _itemStopwatch.stop();

    // Clear preloaded audio
    _audioPreloader?.clearPreloaded();

    state = state.copyWith(
      isActive: false,
      endTime: DateTime.now(),
      currentItem: null,
      currentQuestion: null,
    );

    // Save completed session to history
    await _saveSessionToHistory();
    
    // Clear active session from storage
    await clearSavedSession();
  }

  /// Pause the current session (save state for later)
  Future<void> pauseSession() async {
    if (!state.isActive) {
      return;
    }

    // Stop timing
    _itemStopwatch.stop();

    // Save session state to storage
    await _saveSessionState();

    // Mark as inactive
    state = state.copyWith(
      isActive: false,
    );
  }

  /// Resume a paused session
  Future<void> resumeSession() async {
    if (state.isActive) {
      return;
    }

    // Resume timing if there's a current item
    if (state.currentItem != null) {
      _itemStopwatch.start();
    }

    state = state.copyWith(
      isActive: true,
    );
  }

  /// Reset the session to initial state
  Future<void> resetSession() async {
    _itemStopwatch.stop();
    _itemStopwatch.reset();
    
    // Clear preloaded audio
    _audioPreloader?.clearPreloaded();
    
    // Clear saved session
    await clearSavedSession();
    
    state = LearningSessionState.initial();
  }

  /// Get error message from failure
  String _getErrorMessage(Failure failure) {
    if (failure is DatabaseFailure) {
      return '資料庫錯誤: ${failure.message}';
    } else if (failure is NotFoundFailure) {
      return '找不到資料: ${failure.message}';
    } else if (failure is ValidationFailure) {
      return '驗證錯誤: ${failure.message}';
    } else if (failure is NetworkFailure) {
      return '網路錯誤: ${failure.message}';
    } else {
      return '發生錯誤: ${failure.message}';
    }
  }

  /// Auto-save session state periodically
  Future<void> _autoSaveSession() async {
    if (state.isActive && state.sessionId != null) {
      await _saveSessionState();
    }
  }

  /// Save current session state to local storage
  Future<void> _saveSessionState() async {
    try {
      final currentItemTimeMs = _itemStopwatch.isRunning 
          ? _itemStopwatch.elapsedMilliseconds 
          : 0;
      
      final sessionModel = LearningSessionMapper.toModel(
        state,
        currentItemTimeMs,
      );
      
      await _sessionDataSource.saveActiveSession(sessionModel);
    } catch (e) {
      // Log error but don't interrupt the session
      // In production, use proper logging service instead of print
      // logger.error('Error saving session state: $e');
    }
  }

  /// Check if there's a saved session that can be restored
  Future<bool> hasSavedSession() async {
    try {
      return await _sessionDataSource.hasActiveSession();
    } catch (e) {
      // logger.error('Error checking for saved session: $e');
      return false;
    }
  }

  /// Restore a previously saved session
  Future<void> restoreSession() async {
    try {
      // Set loading state
      state = state.copyWith(
        isLoading: true,
        error: null,
      );

      // Get saved session
      final savedSession = await _sessionDataSource.getActiveSession();
      
      if (savedSession == null) {
        state = state.copyWith(
          isLoading: false,
          error: '沒有找到已保存的會話',
        );
        return;
      }

      // Reconstruct the queue by fetching vocabulary entities
      final queue = <LearningItem>[];
      
      for (final itemModel in savedSession.queue) {
        final vocabResult = await _vocabularyRepository.getVocabularyByWord(
          itemModel.word,
        );

        await vocabResult.fold(
          (failure) async {
            // Skip this item if vocabulary not found
            // logger.warning('Failed to load vocabulary for ${itemModel.word}');
          },
          (vocab) async {
            if (itemModel.isNewWord) {
              queue.add(LearningItem.newWord(vocabulary: vocab));
            } else {
              // For reviews, we need to get the progress
              // This is a simplified version - in production you might want to
              // fetch the actual progress from the repository
              queue.add(LearningItem.newWord(vocabulary: vocab));
            }
          },
        );
      }

      // Restore statistics
      final statistics = LearningSessionMapper.toStatisticsEntity(
        savedSession.statistics,
      );

      // Restore state
      state = state.copyWith(
        queue: queue,
        totalCount: savedSession.totalCount,
        completedCount: savedSession.completedCount,
        sessionId: savedSession.sessionId,
        startTime: savedSession.startTime,
        endTime: savedSession.endTime,
        isActive: savedSession.isActive,
        dailyGoal: savedSession.dailyGoal,
        statistics: statistics,
        isLoading: false,
      );

      // Restore current item if there was one
      if (savedSession.currentItemIndex != null &&
          savedSession.currentItemIndex! < queue.length) {
        final currentItem = queue[savedSession.currentItemIndex!];
        
        // Generate a new question for the current item
        final question = await _generateQuestion(currentItem);
        
        state = state.copyWith(
          currentItem: currentItem,
          currentQuestion: question,
        );

        // Restore the stopwatch time
        if (savedSession.currentItemTimeMs > 0) {
          _itemStopwatch.reset();
          // Note: We can't perfectly restore the stopwatch, but we can track
          // the elapsed time separately if needed
        }
        
        // Start timing for the restored item
        _itemStopwatch.start();
      } else {
        // No current item, get the next one
        await getNextItem();
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '恢復會話失敗: $e',
      );
    }
  }

  /// Clear saved session from storage
  Future<void> clearSavedSession() async {
    try {
      await _sessionDataSource.clearActiveSession();
    } catch (e) {
      // logger.error('Error clearing saved session: $e');
    }
  }

  /// Save completed session to history
  Future<void> _saveSessionToHistory() async {
    try {
      if (state.sessionId != null) {
        final sessionModel = LearningSessionMapper.toModel(state, 0);
        await _sessionDataSource.saveSessionToHistory(sessionModel);
      }
    } catch (e) {
      // logger.error('Error saving session to history: $e');
    }
  }

  @override
  void dispose() {
    _itemStopwatch.stop();
    _autoSaveTimer?.cancel();
    _audioPreloader?.dispose();
    super.dispose();
  }
}
