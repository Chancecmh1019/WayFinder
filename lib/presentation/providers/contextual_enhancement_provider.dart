import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/vocabulary_entity.dart';
import '../../domain/usecases/get_contextual_words_usecase.dart';
import '../../core/providers/repository_providers.dart';
import '../../core/providers/app_providers.dart';

/// Provider for contextual words use case
final contextualWordsUseCaseProvider = Provider<GetContextualWordsUseCase>((ref) {
  final vocabRepo = ref.watch(vocabularyRepositoryProvider);
  final fsrsService = ref.watch(fsrsServiceProvider);
  
  return GetContextualWordsUseCase(
    vocabRepository: vocabRepo,
    fsrsService: fsrsService,
  );
});

/// Provider for all learned words (today + past)
/// 使用 autoDispose 確保每次重新進入頁面時都會重新載入
final learnedWordsProvider = FutureProvider.autoDispose<List<VocabularyEntity>>((ref) async {
  // 監聽刷新觸發器
  ref.watch(statsRefreshTriggerProvider);
  
  final useCase = ref.watch(contextualWordsUseCaseProvider);
  final result = await useCase.call();
  
  return result.fold(
    (failure) => [],
    (words) => words,
  );
});

/// Provider for today's learned words only
final todayLearnedWordsProvider = FutureProvider.autoDispose<List<VocabularyEntity>>((ref) async {
  // 監聽刷新觸發器
  ref.watch(statsRefreshTriggerProvider);
  
  final useCase = ref.watch(contextualWordsUseCaseProvider);
  final result = await useCase.getTodayWords();
  
  return result.fold(
    (failure) => [],
    (words) => words,
  );
});

/// Provider for contextual enhancement word count
final contextualWordCountProvider = Provider.autoDispose<int>((ref) {
  final learnedWords = ref.watch(learnedWordsProvider);
  return learnedWords.maybeWhen(
    data: (words) => words.length,
    orElse: () => 0,
  );
});
