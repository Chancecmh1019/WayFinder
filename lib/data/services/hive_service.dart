import 'package:hive_flutter/hive_flutter.dart';
import '../models/vocab_models_enhanced.dart';
import '../models/fsrs_card_model.dart';
import '../models/fsrs_review_log_model.dart';
import '../models/fsrs_daily_stats_model.dart';
import '../models/learning_progress_model.dart';
import '../models/word_folder_model.dart';
import '../models/user_model.dart';
import '../models/user_settings_model.dart';

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
