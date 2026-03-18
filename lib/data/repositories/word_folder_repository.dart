import 'package:hive/hive.dart';
import 'package:logger/logger.dart';
import '../models/word_folder_model.dart';

/// 單字資料夾資料庫
/// 
/// 管理用戶的單字收藏資料夾
class WordFolderRepository {
  final Logger _logger = Logger();
  static const String _boxName = 'word_folders';
  
  Box<WordFolderModel>? _box;

  /// 初始化
  Future<void> initialize() async {
    try {
      _box = await Hive.openBox<WordFolderModel>(_boxName);
      _logger.i('單字資料夾資料庫初始化完成');
    } catch (e, stackTrace) {
      _logger.e('初始化單字資料夾資料庫失敗: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  /// 確保 box 已初始化
  Box<WordFolderModel> _ensureBox() {
    if (_box == null || !_box!.isOpen) {
      throw StateError('WordFolderRepository 尚未初始化');
    }
    return _box!;
  }

  /// 創建資料夾
  Future<WordFolderModel> createFolder(WordFolderModel folder) async {
    try {
      final box = _ensureBox();
      await box.put(folder.id, folder);
      _logger.i('創建資料夾: ${folder.name}');
      return folder;
    } catch (e, stackTrace) {
      _logger.e('創建資料夾失敗: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  /// 更新資料夾
  Future<WordFolderModel> updateFolder(WordFolderModel folder) async {
    try {
      final box = _ensureBox();
      await box.put(folder.id, folder);
      _logger.i('更新資料夾: ${folder.name}');
      return folder;
    } catch (e, stackTrace) {
      _logger.e('更新資料夾失敗: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  /// 刪除資料夾
  Future<void> deleteFolder(String folderId) async {
    try {
      final box = _ensureBox();
      await box.delete(folderId);
      _logger.i('刪除資料夾: $folderId');
    } catch (e, stackTrace) {
      _logger.e('刪除資料夾失敗: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  /// 取得資料夾
  Future<WordFolderModel?> getFolder(String folderId) async {
    try {
      final box = _ensureBox();
      return box.get(folderId);
    } catch (e, stackTrace) {
      _logger.e('取得資料夾失敗: $e', stackTrace: stackTrace);
      return null;
    }
  }

  /// 取得所有資料夾
  Future<List<WordFolderModel>> getAllFolders() async {
    try {
      final box = _ensureBox();
      final folders = box.values.toList();
      // 按排序順序和創建時間排序
      folders.sort((a, b) {
        final sortCompare = a.sortOrder.compareTo(b.sortOrder);
        if (sortCompare != 0) return sortCompare;
        return b.createdAt.compareTo(a.createdAt);
      });
      return folders;
    } catch (e, stackTrace) {
      _logger.e('取得所有資料夾失敗: $e', stackTrace: stackTrace);
      return [];
    }
  }

  /// 添加單字到資料夾
  Future<WordFolderModel> addWordToFolder(String folderId, String lemma) async {
    try {
      final folder = await getFolder(folderId);
      if (folder == null) {
        throw Exception('資料夾不存在: $folderId');
      }
      
      final updatedFolder = folder.addWord(lemma);
      await updateFolder(updatedFolder);
      _logger.i('添加單字 $lemma 到資料夾 ${folder.name}');
      return updatedFolder;
    } catch (e, stackTrace) {
      _logger.e('添加單字到資料夾失敗: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  /// 從資料夾移除單字
  Future<WordFolderModel> removeWordFromFolder(String folderId, String lemma) async {
    try {
      final folder = await getFolder(folderId);
      if (folder == null) {
        throw Exception('資料夾不存在: $folderId');
      }
      
      final updatedFolder = folder.removeWord(lemma);
      await updateFolder(updatedFolder);
      _logger.i('從資料夾 ${folder.name} 移除單字 $lemma');
      return updatedFolder;
    } catch (e, stackTrace) {
      _logger.e('從資料夾移除單字失敗: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  /// 檢查單字是否在資料夾中
  Future<bool> isWordInFolder(String folderId, String lemma) async {
    try {
      final folder = await getFolder(folderId);
      return folder?.containsWord(lemma) ?? false;
    } catch (e) {
      return false;
    }
  }

  /// 取得包含指定單字的所有資料夾
  Future<List<WordFolderModel>> getFoldersContainingWord(String lemma) async {
    try {
      final allFolders = await getAllFolders();
      return allFolders.where((folder) => folder.containsWord(lemma)).toList();
    } catch (e, stackTrace) {
      _logger.e('取得包含單字的資料夾失敗: $e', stackTrace: stackTrace);
      return [];
    }
  }

  /// 搜尋資料夾
  Future<List<WordFolderModel>> searchFolders(String query) async {
    try {
      final allFolders = await getAllFolders();
      final lowerQuery = query.toLowerCase();
      return allFolders.where((folder) {
        return folder.name.toLowerCase().contains(lowerQuery) ||
            (folder.description?.toLowerCase().contains(lowerQuery) ?? false);
      }).toList();
    } catch (e, stackTrace) {
      _logger.e('搜尋資料夾失敗: $e', stackTrace: stackTrace);
      return [];
    }
  }

  /// 取得統計資訊
  Future<Map<String, dynamic>> getStatistics() async {
    try {
      final folders = await getAllFolders();
      final totalWords = folders.fold<int>(0, (sum, folder) => sum + folder.wordCount);
      
      return {
        'totalFolders': folders.length,
        'totalWords': totalWords,
        'averageWordsPerFolder': folders.isEmpty ? 0 : totalWords / folders.length,
        'largestFolder': folders.isEmpty 
            ? null 
            : folders.reduce((a, b) => a.wordCount > b.wordCount ? a : b).name,
      };
    } catch (e, stackTrace) {
      _logger.e('取得統計資訊失敗: $e', stackTrace: stackTrace);
      return {};
    }
  }

  /// 關閉資料庫
  Future<void> close() async {
    await _box?.close();
    _logger.i('單字資料夾資料庫已關閉');
  }
}
