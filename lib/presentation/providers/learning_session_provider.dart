import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/providers/repository_providers.dart';
import '../../core/providers/tts_providers.dart';
import '../../data/datasources/local/session_local_datasource.dart';
import '../../domain/services/quiz_engine.dart';
import '../../domain/usecases/get_next_item_usecase.dart';
import '../../domain/usecases/start_learning_session_usecase.dart';
import '../../domain/usecases/submit_answer_usecase.dart';
import 'learning_session_notifier.dart';
import 'learning_session_state.dart';

/// Provider for QuizEngine service
final quizEngineProvider = Provider<QuizEngine>((ref) {
  return QuizEngine();
});

/// Provider for UUID generator
final uuidProvider = Provider<Uuid>((ref) {
  return const Uuid();
});

/// Provider for SessionLocalDataSource
final sessionLocalDataSourceProvider = Provider<SessionLocalDataSource>((ref) {
  return SessionLocalDataSource();
});

/// Provider for StartLearningSessionUseCase
final startLearningSessionUseCaseProvider = Provider<StartLearningSessionUseCase>((ref) {
  final reviewSchedulerRepository = ref.watch(reviewSchedulerRepositoryProvider);
  return StartLearningSessionUseCase(reviewSchedulerRepository);
});

/// Provider for GetNextItemUseCase
final getNextItemUseCaseProvider = Provider<GetNextItemUseCase>((ref) {
  final reviewSchedulerRepository = ref.watch(reviewSchedulerRepositoryProvider);
  return GetNextItemUseCase(reviewSchedulerRepository);
});

/// Provider for SubmitAnswerUseCase
final submitAnswerUseCaseProvider = Provider<SubmitAnswerUseCase>((ref) {
  final reviewSchedulerRepository = ref.watch(reviewSchedulerRepositoryProvider);
  final sm2Algorithm = ref.watch(sm2AlgorithmProvider);
  return SubmitAnswerUseCase(
    repository: reviewSchedulerRepository,
    sm2Algorithm: sm2Algorithm,
  );
});

/// Main provider for LearningSessionNotifier
final learningSessionProvider = StateNotifierProvider<LearningSessionNotifier, LearningSessionState>((ref) {
  final reviewSchedulerRepository = ref.watch(reviewSchedulerRepositoryProvider);
  final vocabularyRepository = ref.watch(vocabularyRepositoryProvider);
  final quizEngine = ref.watch(quizEngineProvider);
  final startSessionUseCase = ref.watch(startLearningSessionUseCaseProvider);
  final getNextItemUseCase = ref.watch(getNextItemUseCaseProvider);
  final submitAnswerUseCase = ref.watch(submitAnswerUseCaseProvider);
  final sessionDataSource = ref.watch(sessionLocalDataSourceProvider);
  final uuid = ref.watch(uuidProvider);
  final audioPreloader = ref.watch(audioPreloaderProvider);

  return LearningSessionNotifier(
    reviewSchedulerRepository: reviewSchedulerRepository,
    vocabularyRepository: vocabularyRepository,
    quizEngine: quizEngine,
    startSessionUseCase: startSessionUseCase,
    getNextItemUseCase: getNextItemUseCase,
    submitAnswerUseCase: submitAnswerUseCase,
    sessionDataSource: sessionDataSource,
    uuid: uuid,
    audioPreloader: audioPreloader,
  );
});

/// Provider for checking if session is active
final isSessionActiveProvider = Provider<bool>((ref) {
  return ref.watch(learningSessionProvider.select((state) => state.isActive));
});

/// Provider for current learning item
final currentLearningItemProvider = Provider((ref) {
  return ref.watch(learningSessionProvider.select((state) => state.currentItem));
});

/// Provider for current question
final currentQuestionProvider = Provider((ref) {
  return ref.watch(learningSessionProvider.select((state) => state.currentQuestion));
});

/// Provider for session progress percentage
final sessionProgressProvider = Provider<double>((ref) {
  return ref.watch(learningSessionProvider.select((state) => state.progressPercentage));
});

/// Provider for session statistics
final sessionStatisticsProvider = Provider((ref) {
  return ref.watch(learningSessionProvider.select((state) => state.statistics));
});

/// Provider for checking if daily goal is met
final isDailyGoalMetProvider = Provider<bool>((ref) {
  return ref.watch(learningSessionProvider.select((state) => state.isGoalMet));
});

/// Provider for remaining items count
final remainingItemsCountProvider = Provider<int>((ref) {
  return ref.watch(learningSessionProvider.select((state) => state.remainingCount));
});

/// Provider for checking if there's a saved session
final hasSavedSessionProvider = FutureProvider<bool>((ref) async {
  final notifier = ref.watch(learningSessionProvider.notifier);
  return await notifier.hasSavedSession();
});
