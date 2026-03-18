import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '../../domain/usecases/unified_learning_usecase.dart';
import '../../domain/services/fsrs_algorithm.dart';
import '../../core/utils/logger.dart';

/// 匯入學習資料服務
class ImportService {
  final UnifiedLearningUseCase _learningUseCase;

  ImportService({
    required UnifiedLearningUseCase learningUseCase,
  }) : _learningUseCase = learningUseCase;

  /// 選擇並匯入 JSON 檔案
  Future<ImportResult> pickAndImportJson() async {
    try {
      // 選擇檔案
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return ImportResult(
          imported: 0,
          skipped: 0,
          failed: 0,
          message: '未選擇檔案',
        );
      }

      final file = File(result.files.single.path!);
      final content = await file.readAsString();

      return await importFromJson(content);
    } catch (e, stackTrace) {
      AppLogger.error('選擇檔案失敗', e, stackTrace);
      return ImportResult(
        imported: 0,
        skipped: 0,
        failed: 0,
        message: '選擇檔案失敗：$e',
      );
    }
  }

  /// 從 JSON 字符串匯入
  Future<ImportResult> importFromJson(String jsonContent) async {
    try {
      AppLogger.info('開始匯入資料');

      final data = jsonDecode(jsonContent) as Map<String, dynamic>;

      // 驗證格式
      if (!data.containsKey('exportVersion') || !data.containsKey('progress')) {
        throw Exception('無效的匯入檔案格式');
      }

      final exportVersion = data['exportVersion'] as String;
      AppLogger.info('匯入檔案版本：$exportVersion');

      final progressList = data['progress'] as List<dynamic>;
      int imported = 0;
      int skipped = 0;
      int failed = 0;

      for (final item in progressList) {
        try {
          final word = item['word'] as String;
          // Unused variables - kept for future SM2 to FSRS conversion
          // ignore: unused_local_variable
          final repetitions = item['repetitions'] as int;
          // ignore: unused_local_variable
          final easeFactor = (item['easeFactor'] as num).toDouble();
          // ignore: unused_local_variable
          final nextReviewDate = DateTime.parse(item['nextReviewDate'] as String);
          // ignore: unused_local_variable
          final lastReviewDate = DateTime.parse(item['lastReviewDate'] as String);
          final proficiencyLevel = item['proficiencyLevel'] as int;

          // 轉換為 FSRS 格式
          // 注意：這裡需要根據舊的 SM2 數據推算 FSRS 參數
          final card = await _learningUseCase.getOrCreateCard(
            userId: 'default_user',
            lemma: word,
            senseId: 'default', // 如果沒有 senseId，使用默認值
            isUnlocked: true,
          );

          // 如果卡片已經存在且有學習記錄，跳過
          if (!card.isNew) {
            skipped++;
            continue;
          }

          // 將 SM2 數據轉換為 FSRS 數據
          // 這是一個簡化的轉換，實際可能需要更複雜的邏輯
          // ignore: unused_local_variable
          final fsrsCard = card.toFSRSCard();
          
          // 根據熟練度等級決定評分
          FSRSRating rating;
          if (proficiencyLevel >= 4) {
            rating = FSRSRating.easy;
          } else if (proficiencyLevel >= 3) {
            rating = FSRSRating.good;
          } else if (proficiencyLevel >= 2) {
            rating = FSRSRating.hard;
          } else {
            rating = FSRSRating.again;
          }

          // 提交複習（這會創建學習記錄）
          await _learningUseCase.submitReview(
            card: card,
            rating: rating,
          );

          imported++;
          
          if (imported % 10 == 0) {
            AppLogger.info('已匯入 $imported 個單字');
          }
        } catch (e) {
          AppLogger.warning('匯入單字失敗：$e');
          failed++;
        }
      }

      final message = '匯入完成！成功：$imported，跳過：$skipped，失敗：$failed';
      AppLogger.info(message);

      return ImportResult(
        imported: imported,
        skipped: skipped,
        failed: failed,
        message: message,
      );
    } catch (e, stackTrace) {
      AppLogger.error('匯入失敗', e, stackTrace);
      return ImportResult(
        imported: 0,
        skipped: 0,
        failed: 0,
        message: '匯入失敗：$e',
      );
    }
  }
}

/// 匯入結果
class ImportResult {
  final int imported;
  final int skipped;
  final int failed;
  final String message;

  const ImportResult({
    required this.imported,
    required this.skipped,
    required this.failed,
    required this.message,
  });

  int get total => imported + skipped + failed;
  bool get hasErrors => failed > 0;
  bool get isSuccess => imported > 0 && failed == 0;
}
