import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../domain/repositories/review_scheduler_repository.dart';
import '../../core/utils/logger.dart';

/// 匯出學習資料服務
/// 
/// 提供多種格式的資料匯出功能：
/// - JSON: 完整資料結構
/// - CSV: 簡化的表格格式
class ExportService {
  final ReviewSchedulerRepository _reviewSchedulerRepository;

  ExportService({
    required ReviewSchedulerRepository reviewSchedulerRepository,
  }) : _reviewSchedulerRepository = reviewSchedulerRepository;

  /// 匯出所有學習記錄為 JSON
  Future<String> exportToJson() async {

    // 獲取所有學習進度
    final progressResult = await _reviewSchedulerRepository.getAllProgress();
    final progressList = progressResult.fold(
      (failure) => <dynamic>[],
      (data) => data,
    );

    // 獲取統計資料
    final learnedCountResult = await _reviewSchedulerRepository.getLearnedWordsCount();
    final learnedCount = learnedCountResult.fold((failure) => 0, (count) => count);

    final masteredCountResult = await _reviewSchedulerRepository.getMasteredWordsCount();
    final masteredCount = masteredCountResult.fold((failure) => 0, (count) => count);

    final streakResult = await _reviewSchedulerRepository.getLearningStreak();
    final streak = streakResult.fold((failure) => 0, (count) => count);

    // 計算總複習次數和正確次數
    int totalReviews = 0;
    int correctReviews = 0;
    Duration totalTimeSpent = Duration.zero;

    for (final progress in progressList) {
      totalReviews += progress.history.length as int;
      correctReviews += (progress.history.where((h) => h.correct).length as int);
      
      for (final history in progress.history) {
        totalTimeSpent += history.timeSpent;
      }
    }

    final exportData = {
      'exportDate': DateTime.now().toIso8601String(),
      'exportVersion': '1.0',
      'appName': 'WayFinder',
      'statistics': {
        'totalWords': progressList.length,
        'learnedWords': learnedCount,
        'masteredWords': masteredCount,
        'totalReviews': totalReviews,
        'correctReviews': correctReviews,
        'accuracy': totalReviews > 0 ? (correctReviews / totalReviews * 100).toStringAsFixed(2) : '0.00',
        'totalTimeSpent': totalTimeSpent.inSeconds,
        'totalTimeSpentFormatted': _formatDuration(totalTimeSpent),
        'learningStreak': streak,
        'averageTimePerWord': progressList.isNotEmpty 
            ? (totalTimeSpent.inSeconds / progressList.length).toStringAsFixed(2)
            : '0.00',
      },
      'progress': progressList.map((p) => {
        'word': p.lemma,
        'repetitions': p.repetitions,
        'interval': p.interval,
        'easeFactor': p.easeFactor,
        'nextReviewDate': p.nextReviewDate.toIso8601String(),
        'lastReviewDate': p.lastReviewDate.toIso8601String(),
        'proficiencyLevel': p.proficiencyLevel.value,
        'proficiencyLevelName': p.proficiencyLevel.displayName,
        'isDue': p.isDue,
        'reviewHistory': p.history.map((h) => {
          'date': h.reviewDate.toIso8601String(),
          'quality': h.quality,
          'timeSpent': h.timeSpent.inSeconds,
          'questionType': h.questionType,
          'correct': h.correct,
        }).toList(),
      }).toList(),
    };

    return const JsonEncoder.withIndent('  ').convert(exportData);
  }

  /// 匯出為 CSV 格式
  Future<String> exportToCsv() async {

    // 獲取所有學習進度
    final progressResult = await _reviewSchedulerRepository.getAllProgress();
    final progressList = progressResult.fold(
      (failure) => <dynamic>[],
      (data) => data,
    );

    final csvBuffer = StringBuffer();
    
    // Header
    csvBuffer.writeln('單字,重複次數,間隔天數,難易度因子,下次複習日期,上次複習日期,熟練度,總複習次數,正確次數,正確率');
    
    // Data rows
    for (final progress in progressList) {
      final totalReviews = progress.history.length;
      final correctReviews = progress.history.where((h) => h.correct).length;
      final accuracy = totalReviews > 0 ? (correctReviews / totalReviews * 100).toStringAsFixed(1) : '0.0';
      
      csvBuffer.writeln(
        '${progress.lemma},'
        '${progress.repetitions},'
        '${progress.interval},'
        '${progress.easeFactor.toStringAsFixed(2)},'
        '${_formatDate(progress.nextReviewDate)},'
        '${_formatDate(progress.lastReviewDate)},'
        '${progress.proficiencyLevel.displayName},'
        '$totalReviews,'
        '$correctReviews,'
        '$accuracy%'
      );
    }

    return csvBuffer.toString();
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
