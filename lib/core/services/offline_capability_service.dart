import '../utils/logger.dart';
import 'connectivity_service.dart';

/// Service for managing offline capabilities and feature availability
class OfflineCapabilityService {
  final ConnectivityService _connectivityService;

  OfflineCapabilityService({
    required ConnectivityService connectivityService,
  }) : _connectivityService = connectivityService;

  /// Check if a specific feature is available offline
  bool isFeatureAvailableOffline(OfflineFeature feature) {
    return feature.isAvailableOffline;
  }

  /// Check if a specific feature requires network
  bool doesFeatureRequireNetwork(OfflineFeature feature) {
    return !feature.isAvailableOffline;
  }

  /// Get current connectivity status
  Future<ConnectivityStatus> getConnectivityStatus() async {
    return await _connectivityService.checkConnectivity();
  }

  /// Check if a feature can be used with current connectivity
  Future<bool> canUseFeature(OfflineFeature feature) async {
    final status = await getConnectivityStatus();
    
    // If feature is available offline, always return true
    if (feature.isAvailableOffline) {
      return true;
    }
    
    // If feature requires network, check connectivity
    return status.isOnline;
  }

  /// Get list of features that are currently unavailable
  Future<List<OfflineFeature>> getUnavailableFeatures() async {
    final status = await getConnectivityStatus();
    
    if (status.isOnline) {
      return [];
    }
    
    // Return all features that require network
    return OfflineFeature.values
        .where((feature) => !feature.isAvailableOffline)
        .toList();
  }

  /// Validate that core offline features are working
  Future<OfflineValidationResult> validateOfflineCapabilities() async {
    AppLogger.info('Validating offline capabilities');
    
    final results = <String, bool>{};
    final errors = <String>[];

    try {
      // Validate core learning functionality
      results['learning_session'] = await _validateLearningSession();
      
      // Validate vocabulary query
      results['vocabulary_query'] = await _validateVocabularyQuery();
      
      // Validate statistics viewing
      results['statistics_view'] = await _validateStatisticsView();
      
      // Validate local data access
      results['local_data_access'] = await _validateLocalDataAccess();
      
    } catch (e, stackTrace) {
      AppLogger.error('Error validating offline capabilities', e, stackTrace);
      errors.add('Validation error: $e');
    }

    final allPassed = results.values.every((result) => result);
    
    AppLogger.info('Offline validation complete: ${allPassed ? "PASSED" : "FAILED"}');
    
    return OfflineValidationResult(
      isValid: allPassed,
      results: results,
      errors: errors,
    );
  }

  /// Validate learning session functionality
  Future<bool> _validateLearningSession() async {
    try {
      // Check if learning session can be started offline
      // This would typically check if local data is available
      AppLogger.debug('Validating learning session offline capability');
      return true; // Placeholder - actual validation would check data availability
    } catch (e) {
      AppLogger.error('Learning session validation failed', e);
      return false;
    }
  }

  /// Validate vocabulary query functionality
  Future<bool> _validateVocabularyQuery() async {
    try {
      // Check if vocabulary can be queried from local database
      AppLogger.debug('Validating vocabulary query offline capability');
      return true; // Placeholder - actual validation would query local DB
    } catch (e) {
      AppLogger.error('Vocabulary query validation failed', e);
      return false;
    }
  }

  /// Validate statistics viewing functionality
  Future<bool> _validateStatisticsView() async {
    try {
      // Check if statistics can be calculated from local data
      AppLogger.debug('Validating statistics view offline capability');
      return true; // Placeholder - actual validation would check local stats
    } catch (e) {
      AppLogger.error('Statistics view validation failed', e);
      return false;
    }
  }

  /// Validate local data access
  Future<bool> _validateLocalDataAccess() async {
    try {
      // Check if local database is accessible
      AppLogger.debug('Validating local data access');
      return true; // Placeholder - actual validation would check Hive
    } catch (e) {
      AppLogger.error('Local data access validation failed', e);
      return false;
    }
  }
}

/// Enum defining all features and their offline availability
enum OfflineFeature {
  // Core learning features (available offline)
  learningSession(
    name: '學習會話',
    description: '開始學習會話並複習單字',
    isAvailableOffline: true,
  ),
  vocabularyBrowse(
    name: '單字瀏覽',
    description: '瀏覽和搜尋單字',
    isAvailableOffline: true,
  ),
  vocabularyDetail(
    name: '單字詳情',
    description: '查看單字詳細資訊',
    isAvailableOffline: true,
  ),
  statistics(
    name: '統計資料',
    description: '查看學習統計',
    isAvailableOffline: true,
  ),
  mdxDictionary(
    name: 'MDX 字典',
    description: '查詢離線字典',
    isAvailableOffline: true,
  ),
  localAudio(
    name: '本地音訊',
    description: '播放本地音訊檔案',
    isAvailableOffline: true,
  ),
  
  // Features requiring network (not available offline)
  cloudSync(
    name: '雲端同步',
    description: '同步學習進度到雲端',
    isAvailableOffline: false,
  ),
  translation(
    name: '例句翻譯',
    description: '翻譯例句為中文',
    isAvailableOffline: false,
  ),
  datamuseApi(
    name: 'Datamuse API',
    description: '尋找相似單字',
    isAvailableOffline: false,
  ),
  wiktionaryApi(
    name: 'Wiktionary API',
    description: '獲取字源資訊',
    isAvailableOffline: false,
  ),
  authentication(
    name: '使用者認證',
    description: 'Google 登入',
    isAvailableOffline: false,
  );

  const OfflineFeature({
    required this.name,
    required this.description,
    required this.isAvailableOffline,
  });

  final String name;
  final String description;
  final bool isAvailableOffline;
}

/// Result of offline capability validation
class OfflineValidationResult {
  final bool isValid;
  final Map<String, bool> results;
  final List<String> errors;

  const OfflineValidationResult({
    required this.isValid,
    required this.results,
    required this.errors,
  });

  @override
  String toString() {
    return 'OfflineValidationResult(isValid: $isValid, results: $results, errors: $errors)';
  }
}
