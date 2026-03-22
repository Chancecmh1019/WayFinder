import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:hive/hive.dart';
import '../../core/utils/logger.dart';
import '../../domain/entities/user_settings.dart';
import '../models/fsrs_card_model.dart';
import '../models/fsrs_review_log_model.dart';
import '../models/fsrs_daily_stats_model.dart';
import '../models/user_model.dart';
import '../models/user_settings_model.dart';
import '../models/word_folder_model.dart';
import '../datasources/local/user_local_datasource.dart';
import '../repositories/word_folder_repository.dart';

/// 匯入學習資料服務
class ImportService {
  final UserLocalDataSource _userLocalDataSource;
  final WordFolderRepository _wordFolderRepository;

  ImportService({
    required UserLocalDataSource userLocalDataSource,
    required WordFolderRepository wordFolderRepository,
  }) : _userLocalDataSource = userLocalDataSource,
       _wordFolderRepository = wordFolderRepository;

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
      if (!data.containsKey('exportVersion') || !data.containsKey('appName')) {
        throw Exception('無效的匯入檔案格式');
      }

      final exportVersion = data['exportVersion'] as String;
      AppLogger.info('匯入檔案版本：$exportVersion');

      int importedCards = 0;
      int importedLogs = 0;
      int importedStats = 0;
      int importedFolders = 0;
      bool settingsImported = false;
      int skipped = 0;
      int failed = 0;

      // 1. 匯入使用者設定
      if (data.containsKey('userSettings') && data['userSettings'] != null) {
        try {
          final settingsData = data['userSettings'] as Map<String, dynamic>;
          
          // 解析學習風格
          LearningStyle learningStyle = LearningStyle.balanced;
          if (settingsData.containsKey('learningStyle')) {
            final styleStr = settingsData['learningStyle'] as String;
            learningStyle = LearningStyle.values.firstWhere(
              (e) => e.toString().split('.').last == styleStr,
              orElse: () => LearningStyle.balanced,
            );
          }

          // 解析發音類型
          PronunciationType pronunciation = PronunciationType.us;
          if (settingsData.containsKey('preferredPronunciation')) {
            final pronStr = settingsData['preferredPronunciation'] as String;
            pronunciation = PronunciationType.values.firstWhere(
              (e) => e.toString().split('.').last == pronStr,
              orElse: () => PronunciationType.us,
            );
          }

          // 解析 TTS 引擎
          TtsEngineType ttsEngine = TtsEngineType.flutterTts;
          if (settingsData.containsKey('ttsEngine')) {
            final engineStr = settingsData['ttsEngine'] as String;
            ttsEngine = TtsEngineType.values.firstWhere(
              (e) => e.toString().split('.').last == engineStr,
              orElse: () => TtsEngineType.flutterTts,
            );
          }

          final settings = UserSettings(
            targetLevel: settingsData['targetLevel'] as int? ?? 4,
            focusAreas: (settingsData['focusAreas'] as List<dynamic>?)?.cast<String>() ?? [],
            learningStyle: learningStyle,
            includePhrasesInStudy: settingsData['includePhrasesInStudy'] as bool? ?? true,
            dailyGoal: settingsData['dailyGoal'] as int? ?? 30,
            preferredPronunciation: pronunciation,
            autoPlayAudio: settingsData['autoPlayAudio'] as bool? ?? false,
            ttsEngine: ttsEngine,
            speechRate: (settingsData['speechRate'] as num?)?.toDouble() ?? 0.45,
            hasCompletedOnboarding: settingsData['hasCompletedOnboarding'] as bool? ?? false,
          );

          // 儲存設定
          var userModel = await _userLocalDataSource.getUser();
          if (userModel == null) {
            userModel = UserModel(
              id: 'local_user',
              email: 'local@wayfinder.app',
              displayName: '本地用戶',
              createdAt: DateTime.now(),
              settings: UserSettingsModel.fromEntity(settings),
            );
          } else {
            userModel = userModel.copyWith(
              settings: UserSettingsModel.fromEntity(settings),
            );
          }
          await _userLocalDataSource.saveUser(userModel);
          settingsImported = true;
          AppLogger.info('使用者設定匯入成功');
        } catch (e) {
          AppLogger.warning('匯入使用者設定失敗：$e');
          failed++;
        }
      }

      // 2. 匯入 FSRS 資料
      if (data.containsKey('fsrsData')) {
        final fsrsData = data['fsrsData'] as Map<String, dynamic>;

        // 2.1 匯入卡片
        if (fsrsData.containsKey('cards')) {
          try {
            final cardsBox = await Hive.openBox<FSRSCardModel>('fsrs_cards');
            final cardsList = fsrsData['cards'] as List<dynamic>;
            
            for (final cardData in cardsList) {
              try {
                final card = FSRSCardModel.fromJson(cardData as Map<String, dynamic>);
                final key = '${card.userId}_${card.lemma}_${card.senseId}';
                
                // 檢查是否已存在
                if (cardsBox.containsKey(key)) {
                  skipped++;
                } else {
                  await cardsBox.put(key, card);
                  importedCards++;
                }
              } catch (e) {
                AppLogger.warning('匯入卡片失敗：$e');
                failed++;
              }
            }
            AppLogger.info('卡片匯入完成：$importedCards 張');
          } catch (e) {
            AppLogger.error('匯入卡片資料失敗', e);
          }
        }

        // 2.2 匯入複習記錄
        if (fsrsData.containsKey('reviewLogs')) {
          try {
            final reviewLogsBox = await Hive.openBox<FSRSReviewLogModel>('fsrs_review_logs');
            final logsList = fsrsData['reviewLogs'] as List<dynamic>;
            
            for (final logData in logsList) {
              try {
                final log = FSRSReviewLogModel.fromJson(logData as Map<String, dynamic>);
                await reviewLogsBox.add(log);
                importedLogs++;
              } catch (e) {
                AppLogger.warning('匯入複習記錄失敗：$e');
                failed++;
              }
            }
            AppLogger.info('複習記錄匯入完成：$importedLogs 筆');
          } catch (e) {
            AppLogger.error('匯入複習記錄失敗', e);
          }
        }

        // 2.3 匯入每日統計
        if (fsrsData.containsKey('dailyStats')) {
          try {
            final dailyStatsBox = await Hive.openBox<FSRSDailyStatsModel>('fsrs_daily_stats');
            final statsList = fsrsData['dailyStats'] as List<dynamic>;
            
            for (final statsData in statsList) {
              try {
                final stats = FSRSDailyStatsModel.fromJson(statsData as Map<String, dynamic>);
                final key = '${stats.userId}_${stats.date.toIso8601String().split('T')[0]}';
                
                // 檢查是否已存在
                if (dailyStatsBox.containsKey(key)) {
                  skipped++;
                } else {
                  await dailyStatsBox.put(key, stats);
                  importedStats++;
                }
              } catch (e) {
                AppLogger.warning('匯入每日統計失敗：$e');
                failed++;
              }
            }
            AppLogger.info('每日統計匯入完成：$importedStats 筆');
          } catch (e) {
            AppLogger.error('匯入每日統計失敗', e);
          }
        }
      }

      // 3. 匯入單字資料夾
      if (data.containsKey('wordFolders')) {
        try {
          final foldersList = data['wordFolders'] as List<dynamic>;
          
          for (final folderData in foldersList) {
            try {
              final folder = WordFolderModel.fromJson(folderData as Map<String, dynamic>);

              // 檢查是否已存在
              final existingFolder = await _wordFolderRepository.getFolder(folder.id);
              if (existingFolder != null) {
                skipped++;
              } else {
                await _wordFolderRepository.createFolder(folder);
                importedFolders++;
              }
            } catch (e) {
              AppLogger.warning('匯入資料夾失敗：$e');
              failed++;
            }
          }
          AppLogger.info('資料夾匯入完成：$importedFolders 個');
        } catch (e) {
          AppLogger.error('匯入資料夾失敗', e);
        }
      }

      final message = '匯入完成！\n'
          '卡片：$importedCards，複習記錄：$importedLogs，統計：$importedStats\n'
          '資料夾：$importedFolders，設定：${settingsImported ? "已匯入" : "未匯入"}\n'
          '跳過：$skipped，失敗：$failed';
      AppLogger.info(message);

      return ImportResult(
        imported: importedCards + importedLogs + importedStats + importedFolders + (settingsImported ? 1 : 0),
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
