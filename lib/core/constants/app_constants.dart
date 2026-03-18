/// Application-wide constants
class AppConstants {
  // App Info
  static const String appName = 'WayFinder';
  static const String appVersion = '1.0.0';
  
  // Database
  static const String vocabularyBoxName = 'vocabulary';
  static const String progressBoxName = 'progress';
  static const String settingsBoxName = 'settings';
  static const String cacheBoxName = 'cache';
  static const String sessionBoxName = 'session';
  
  // Learning
  static const int minDailyGoal = 5;
  static const int maxDailyGoal = 100;
  static const int defaultDailyGoal = 30; // 修正預設值為 30
  static const int totalVocabularyCount = 7837;
  
  // SM-2 Algorithm
  static const double initialEaseFactor = 2.5;
  static const double minEaseFactor = 1.3;
  static const int initialInterval = 1;
  static const int secondInterval = 6;
  
  // Cache
  static const int maxDictionaryCacheSize = 1000;
  static const int maxAudioCacheSize = 500;
  static const Duration datamuseCacheDuration = Duration(days: 7);
  static const Duration wiktionaryCacheDuration = Duration(days: 30);
  
  // Performance
  static const Duration queryTimeout = Duration(milliseconds: 100);
  static const Duration apiTimeout = Duration(seconds: 10);
  static const int maxRetries = 3;
  
  // Interleaving
  static const int maxConsecutiveSameCategory = 3;
  
  // Notifications
  static const int dueReviewReminderThreshold = 20;
}
