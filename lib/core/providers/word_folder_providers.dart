import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/word_folder_model.dart';
import '../../data/repositories/word_folder_repository.dart';

/// WordFolderRepository Provider
final wordFolderRepositoryProvider = Provider<WordFolderRepository>((ref) {
  return WordFolderRepository();
});

/// 初始化 Provider
final wordFolderInitProvider = FutureProvider<void>((ref) async {
  final repository = ref.watch(wordFolderRepositoryProvider);
  await repository.initialize();
});

/// 所有資料夾 Provider
final allFoldersProvider = FutureProvider<List<WordFolderModel>>((ref) async {
  // 確保已初始化
  await ref.watch(wordFolderInitProvider.future);
  
  final repository = ref.watch(wordFolderRepositoryProvider);
  return await repository.getAllFolders();
});

/// 單個資料夾 Provider
final folderProvider = FutureProvider.family<WordFolderModel?, String>((ref, folderId) async {
  await ref.watch(wordFolderInitProvider.future);
  
  final repository = ref.watch(wordFolderRepositoryProvider);
  return await repository.getFolder(folderId);
});

/// 包含指定單字的資料夾 Provider
final foldersContainingWordProvider = FutureProvider.family<List<WordFolderModel>, String>(
  (ref, lemma) async {
    await ref.watch(wordFolderInitProvider.future);
    
    final repository = ref.watch(wordFolderRepositoryProvider);
    return await repository.getFoldersContainingWord(lemma);
  },
);

/// 資料夾統計 Provider
final folderStatisticsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  await ref.watch(wordFolderInitProvider.future);
  
  final repository = ref.watch(wordFolderRepositoryProvider);
  return await repository.getStatistics();
});
