import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/local/progress_local_datasource.dart';
import '../../data/datasources/local/vocabulary_local_datasource.dart';
import '../../data/repositories/review_scheduler_repository_impl.dart';
import '../../data/repositories/vocabulary_repository_impl.dart';
import '../../data/services/export_service.dart';
import '../../data/services/import_service.dart';
import '../../domain/repositories/review_scheduler_repository.dart';
import '../../domain/repositories/vocabulary_repository.dart';
import '../../domain/services/sm2_algorithm.dart';
import '../../presentation/providers/unified_learning_provider.dart';

/// Provider for ProgressLocalDataSource
final progressLocalDataSourceProvider = Provider<ProgressLocalDataSource>((ref) {
  return ProgressLocalDataSource();
});

/// Provider for VocabularyLocalDataSource  
final vocabularyLocalDataSourceProvider = Provider<VocabularyLocalDataSource>((ref) {
  return VocabularyLocalDataSource();
});

/// Provider for SM2Algorithm
final sm2AlgorithmProvider = Provider<SM2Algorithm>((ref) {
  return SM2Algorithm();
});

/// Provider to ensure data sources are initialized
final dataSourcesInitializedProvider = FutureProvider<bool>((ref) async {
  final progressDataSource = ref.watch(progressLocalDataSourceProvider);
  final vocabularyDataSource = ref.watch(vocabularyLocalDataSourceProvider);
  
  try {
    await progressDataSource.initialize();
    await vocabularyDataSource.initialize();
    return true;
  } catch (e) {
    return false;
  }
});

/// Provider for ReviewSchedulerRepository
final reviewSchedulerRepositoryProvider = Provider<ReviewSchedulerRepository>((ref) {
  final progressDataSource = ref.watch(progressLocalDataSourceProvider);
  final vocabularyDataSource = ref.watch(vocabularyLocalDataSourceProvider);
  final sm2Algorithm = ref.watch(sm2AlgorithmProvider);

  final repository = ReviewSchedulerRepositoryImpl(
    progressDataSource: progressDataSource,
    vocabularyDataSource: vocabularyDataSource,
    sm2Algorithm: sm2Algorithm,
  );
  
  // 設置默認的 local user ID
  repository.setUserId('local_user');
  
  return repository;
});

/// Provider for VocabularyRepository
final vocabularyRepositoryProvider = Provider<VocabularyRepository>((ref) {
  final localDataSource = ref.watch(vocabularyLocalDataSourceProvider);
  
  return VocabularyRepositoryImpl(
    localDataSource: localDataSource,
  );
});

/// Provider for ExportService
final exportServiceProvider = Provider<ExportService>((ref) {
  final reviewSchedulerRepository = ref.watch(reviewSchedulerRepositoryProvider);
  
  return ExportService(
    reviewSchedulerRepository: reviewSchedulerRepository,
  );
});

/// Provider for ImportService
final importServiceProvider = Provider<ImportService?>((ref) {
  final learningUseCase = ref.watch(unifiedLearningUseCaseProvider);
  
  if (learningUseCase == null) {
    return null;
  }
  
  return ImportService(
    learningUseCase: learningUseCase,
  );
});
