import 'dart:convert';
import 'dart:io';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../domain/repositories/review_scheduler_repository.dart';
import '../../core/utils/logger.dart';
import '../models/fsrs_card_model.dart';
import '../models/fsrs_review_log_model.dart';
import '../models/fsrs_daily_stats_model.dart';
import '../datasources/local/user_local_datasource.dart';
import '../repositories/word_folder_repository.dart';

/// 匯出學習資料服務
/// 
/// 提供多種格式的資料匯出功能：
/// - JSON: 完整資料結構（包含所有應用程式資料）
/// - CSV: 簡化的表格格式（僅學習進度）
class ExportService {
  final ReviewSchedulerRepository _reviewSchedulerRepository;
  final UserLocalDataSource _userLocalDataSource;
  final WordFolderRepository _wordFolderRepository;

  ExportService({
    required ReviewSchedulerRepository reviewSchedulerRepository,
    required UserLocalDataSource userLocalDataSource,
    required WordFolderRepository wordFolderRepository,
  }) : _reviewSchedulerRepository = reviewSchedulerRepository,
       _userLocalDataSource = userLocalDataSource,
       _wordFolderRepository = wordFolderRepository;

  /// 匯出所有應用程式資料為 JSON（包含設定、學習資料、資料夾等）
  Future<String> exportToJson() async {
    try {
      AppLogger.info('開始匯出完整應用程式資料');

      // 1. 獲取使用者設定
      final userModel = await _userLocalDataSource.getUser();
      final userSettings = userModel?.settings.toEntity();

      // 2. 獲取 FSRS 卡片資料
      final cardsBox = await Hive.openBox<FSRSCardModel>('fsrs_cards');
      final cards = cardsBox.values.map((card) => card.toJson()).toList();

      // 3. 獲取複習記錄
      final reviewLogsBox = await Hive.openBox<FSRSReviewLogModel>('fsrs_review_logs');
      final reviewLogs = reviewLogsBox.values.map((log) => log.toJson()).toList();

      // 4. 獲取每日統計
      final dailyStatsBox = await Hive.openBox<FSRSDailyStatsModel>('fsrs_daily_stats');
      final dailyStats = dailyStatsBox.values.map((stats) => stats.toJson()).toList();

      // 5. 獲取單字資料夾
      final folders = await _wordFolderRepository.getAllFolders();
      final foldersData = folders.map((folder) => folder.toJson()).toList();

      // 6. 計算統計資料
      final learnedCountResult = await _reviewSchedulerRepository.getLearnedWordsCount();
      final learnedCount = learnedCountResult.fold((failure) => 0, (count) => count);

      final masteredCountResult = await _reviewSchedulerRepository.getMasteredWordsCount();
      final masteredCount = masteredCountResult.fold((failure) => 0, (count) => count);

      final streakResult = await _reviewSchedulerRepository.getLearningStreak();
      final streak = streakResult.fold((failure) => 0, (count) => count);

      // 組合完整匯出資料
      final exportData = {
        'exportDate': DateTime.now().toIso8601String(),
        'exportVersion': '2.0', // 升級版本號
        'appName': 'WayFinder',
        'appVersion': '1.0.0',
        
        // 使用者設定
        'userSettings': userSettings != null ? {
          'targetLevel': userSettings.targetLevel,
          'focusAreas': userSettings.focusAreas,
          'learningStyle': userSettings.learningStyle.toString().split('.').last,
          'includePhrasesInStudy': userSettings.includePhrasesInStudy,
          'dailyGoal': userSettings.dailyGoal,
          'preferredPronunciation': userSettings.preferredPronunciation.toString().split('.').last,
          'autoPlayAudio': userSettings.autoPlayAudio,
          'ttsEngine': userSettings.ttsEngine.toString().split('.').last,
          'speechRate': userSettings.speechRate,
          'hasCompletedOnboarding': userSettings.hasCompletedOnboarding,
        } : null,

        // 統計資料
        'statistics': {
          'totalCards': cards.length,
          'learnedWords': learnedCount,
          'masteredWords': masteredCount,
          'totalReviews': reviewLogs.length,
          'learningStreak': streak,
          'totalFolders': folders.length,
          'totalWordsInFolders': folders.fold<int>(0, (sum, f) => sum + f.totalCount),
        },

        // FSRS 資料
        'fsrsData': {
          'cards': cards,
          'reviewLogs': reviewLogs,
          'dailyStats': dailyStats,
        },

        // 單字資料夾
        'wordFolders': foldersData,
      };

      AppLogger.info('匯出資料完成：${cards.length} 張卡片，${reviewLogs.length} 筆複習記錄，${folders.length} 個資料夾');
      return const JsonEncoder.withIndent('  ').convert(exportData);
      
    } catch (e, stackTrace) {
      AppLogger.error('匯出資料失敗', e, stackTrace);
      rethrow;
    }
  }

  /// 匯出為 CSV 格式（僅學習進度）
  Future<String> exportToCsv() async {
    try {
      AppLogger.info('開始匯出 CSV 格式');

      // 獲取 FSRS 卡片資料
      final cardsBox = await Hive.openBox<FSRSCardModel>('fsrs_cards');
      final cards = cardsBox.values.toList();

      final csvBuffer = StringBuffer();
      
      // Header
      csvBuffer.writeln('單字,義項ID,狀態,重複次數,失誤次數,穩定性,難度,下次複習日期,上次複習日期,預定天數');
      
      // Data rows
      for (final card in cards) {
        final stateNames = ['新卡片', '學習中', '複習中', '重新學習'];
        final stateName = card.state >= 0 && card.state < stateNames.length 
            ? stateNames[card.state] 
            : '未知';
        
        csvBuffer.writeln(
          '${card.lemma},'
          '${card.senseId},'
          '$stateName,'
          '${card.reps},'
          '${card.lapses},'
          '${card.stability.toStringAsFixed(2)},'
          '${card.difficulty.toStringAsFixed(2)},'
          '${_formatDate(card.due)},'
          '${card.lastReview != null ? _formatDate(card.lastReview!) : ""},'
          '${card.scheduledDays}'
        );
      }

      AppLogger.info('CSV 匯出完成：${cards.length} 張卡片');
      return csvBuffer.toString();
      
    } catch (e, stackTrace) {
      AppLogger.error('匯出 CSV 失敗', e, stackTrace);
      rethrow;
    }
  }

  /// 儲存並分享匯出檔案
  Future<void> exportAndShare({required ExportFormat format}) async {
    try {
      AppLogger.info('開始匯出資料，格式：${format.name}');
      
      String content;
      String filename;
      String mimeType;

      switch(format) {
        case ExportFormat.json:
          content = await exportToJson();
          filename = 'wayfinder_export_${_getTimestamp()}.json';
          mimeType = 'application/json';
          break;
        case ExportFormat.csv:
          content = await exportToCsv();
          filename = 'wayfinder_export_${_getTimestamp()}.csv';
          mimeType = 'text/csv';
          break;
      }

      // 儲存到臨時目錄
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/$filename';
      final file = File(filePath);
      await file.writeAsString(content, encoding: utf8);

      AppLogger.info('檔案已儲存至：$filePath');

      // 分享檔案
      final result = await Share.shareXFiles(
        [XFile(filePath, mimeType: mimeType)],
        subject: 'WayFinder 學習記錄',
        text: '我的 WayFinder 學習記錄匯出檔案',
      );

      AppLogger.info('分享結果：${result.status}');
      
      // 清理臨時檔案（延遲刪除，確保分享完成）
      Future.delayed(const Duration(seconds: 5), () {
        try {
          if (file.existsSync()) {
            file.deleteSync();
            AppLogger.debug('臨時檔案已刪除');
          }
        } catch (e) {
          AppLogger.warning('刪除臨時檔案失敗：$e');
        }
      });
      
    } catch (e, stackTrace) {
      AppLogger.error('匯出失敗', e, stackTrace);
      rethrow;
    }
  }

  /// 格式化時間長度
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '$hours 小時 $minutes 分鐘';
    } else if (minutes > 0) {
      return '$minutes 分鐘 $seconds 秒';
    } else {
      return '$seconds 秒';
    }
  }

  /// 格式化日期
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// 獲取時間戳字串
  String _getTimestamp() {
    final now = DateTime.now();
    return '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_'
           '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
  }
}

enum ExportFormat {
  json,
  csv,
}
