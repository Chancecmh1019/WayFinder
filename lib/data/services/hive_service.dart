import 'package:hive_flutter/hive_flutter.dart';
import '../models/vocab_models_enhanced.dart';
import '../models/fsrs_card_model.dart';
import '../models/fsrs_review_log_model.dart';
import '../models/fsrs_daily_stats_model.dart';
import '../models/learning_progress_model.dart';
import '../models/word_folder_model.dart';
import '../models/user_model.dart';
import '../models/user_settings_model.dart';
import 'vocabulary_initialization_service.dart';
import 'package:logger/logger.dart';

class HiveService {
  static const String vocabularyBoxName = 'vocabulary';
  static const String fsrsCardsBoxName = 'fsrs_cards';
  static const String fsrsReviewLogsBoxName = 'fsrs_review_logs';
  static const String fsrsDailyStatsBoxName = 'fsrs_daily_stats';
  static const String progressBoxName = 'progress';
  static const String settingsBoxName = 'settings';
  static const String sessionBoxName = 'session';
  static const String userBoxName = 'user';

  static bool _initialized = false;
  static final Logger _logger = Logger();

  static Future<void> initialize() async {
    if (_initialized) return;

    await Hive.initFlutter();

    // User adapters (typeId: 10-11)
    Hive.registerAdapter(UserModelAdapter());           // 10
    Hive.registerAdapter(UserSettingsModelAdapter());   // 11

    // FSRS adapters
    Hive.registerAdapter(FSRSCardModelAdapter());       // typeId: 40
    Hive.registerAdapter(FSRSReviewLogModelAdapter());  // typeId: 41
    Hive.registerAdapter(FSRSDailyStatsModelAdapter()); // typeId: 42

    // Vocab enhanced adapters (typeId: 50-59)
    Hive.registerAdapter(SourceInfoModelAdapter());         // 50
    Hive.registerAdapter(ExamExampleModelAdapter());        // 51
    Hive.registerAdapter(VocabSenseModelAdapter());         // 52
    Hive.registerAdapter(FrequencyDataModelAdapter());      // 53
    Hive.registerAdapter(ConfusionNoteModelAdapter());      // 54
    Hive.registerAdapter(RootInfoModelAdapter());           // 55
    Hive.registerAdapter(VocabEntryModelAdapter());         // 56
    Hive.registerAdapter(VocabIndexItemModelAdapter());     // 57
    Hive.registerAdapter(PatternSubtypeModelAdapter());     // 58
    Hive.registerAdapter(PatternEntryModelAdapter());       // 59
    
    // Word folder adapter (typeId: 60)
    Hive.registerAdapter(WordFolderModelAdapter());         // 60
    
    // Additional vocab adapters (typeId: 61-62)
    Hive.registerAdapter(PhraseEntryModelAdapter());        // 61
    Hive.registerAdapter(WordEntryModelAdapter());          // 62

    // Progress adapter
    Hive.registerAdapter(LearningProgressModelAdapter()); // typeId: 1

    _initialized = true;
  }
  
  /// 初始化單字卡片（在 app 啟動後執行）
  static Future<void> initializeVocabularyCards(String userId) async {
    try {
      _logger.i('[HiveService] 檢查是否需要初始化單字卡片...');
      
      final vocabularyBox = await openVocabularyBox();
      final cardsBox = await openFsrsCardsBox();
      
      final initService = VocabularyInitializationService();
      
      // 檢查是否需要初始化
      if (initService.needsInitialization(userId: userId, cardsBox: cardsBox)) {
        _logger.i('[HiveService] 開始初始化單字卡片...');
        final createdCount = await initService.initializeVocabularyCards(
          userId: userId,
          vocabularyBox: vocabularyBox,
          cardsBox: cardsBox,
        );
        _logger.i('[HiveService] 單字卡片初始化完成，創建了 $createdCount 個卡片');
      } else {
        _logger.i('[HiveService] 單字卡片已初始化，跳過');
      }
    } catch (e) {
      _logger.e('[HiveService] 初始化單字卡片時發生錯誤: $e');
    }
  }

  static Future<LazyBox<VocabEntryModel>> openVocabularyBox() async {
    return Hive.openLazyBox<VocabEntryModel>(vocabularyBoxName);
  }

  static Future<Box<FSRSCardModel>> openFsrsCardsBox() async {
    return Hive.openBox<FSRSCardModel>(fsrsCardsBoxName);
  }

  static Future<Box<FSRSReviewLogModel>> openFsrsReviewLogsBox() async {
    return Hive.openBox<FSRSReviewLogModel>(fsrsReviewLogsBoxName);
  }

  static Future<Box<FSRSDailyStatsModel>> openFsrsDailyStatsBox() async {
    return Hive.openBox<FSRSDailyStatsModel>(fsrsDailyStatsBoxName);
  }

  static Future<Box<LearningProgressModel>> openProgressBox() async {
    return Hive.openBox<LearningProgressModel>(progressBoxName);
  }

  static Future<Box<dynamic>> openSettingsBox() async {
    return Hive.openBox<dynamic>(settingsBoxName);
  }

  static Future<Box<dynamic>> openSessionBox() async {
    return Hive.openBox<dynamic>(sessionBoxName);
  }

  static Future<Box<dynamic>> openUserBox() async {
    return Hive.openBox<dynamic>(userBoxName);
  }
}
