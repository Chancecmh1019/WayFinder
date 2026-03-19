import 'package:hive_flutter/hive_flutter.dart';
import 'package:logger/logger.dart';
import '../models/vocab_models_enhanced.dart';
import '../models/fsrs_card_model.dart';

/// 單字初始化服務
/// 
/// 負責在應用程式啟動時為所有單字的第一個 sense 創建 FSRS 卡片
/// 這確保用戶有足夠的單字可以學習
class VocabularyInitializationService {
  final Logger _logger = Logger();
  
  /// 初始化所有單字的卡片
  /// 
  /// 為每個單字的第一個 sense 創建一個已解鎖的卡片
  /// 只會創建尚未存在的卡片
  Future<int> initializeVocabularyCards({
    required String userId,
    required LazyBox<VocabEntryModel> vocabularyBox,
    required Box<FSRSCardModel> cardsBox,
  }) async {
    _logger.i('[VocabularyInitialization] 開始初始化單字卡片...');
    
    int createdCount = 0;
    int skippedCount = 0;
    int errorCount = 0;
    
    try {
      // 獲取所有單字的 key
      final allKeys = vocabularyBox.keys.toList();
      _logger.i('[VocabularyInitialization] 找到 ${allKeys.length} 個單字');
      
      for (final key in allKeys) {
        try {
          final entry = await vocabularyBox.get(key);
          
          if (entry == null || entry.senses.isEmpty) {
            skippedCount++;
            continue;
          }
          
          // 只為第一個 sense 創建卡片
          final firstSense = entry.senses.first;
          final cardKey = _getCardKey(userId, entry.lemma, firstSense.senseId);
          
          // 檢查卡片是否已存在
          if (cardsBox.containsKey(cardKey)) {
            skippedCount++;
            continue;
          }
          
          // 創建新卡片（已解鎖）
          final card = FSRSCardModel.newCard(
            userId: userId,
            lemma: entry.lemma,
            senseId: firstSense.senseId,
            isUnlocked: true,
          );
          
          await cardsBox.put(cardKey, card);
          createdCount++;
          
          // 每 100 個卡片記錄一次進度
          if (createdCount % 100 == 0) {
            _logger.i('[VocabularyInitialization] 已創建 $createdCount 個卡片...');
          }
        } catch (e) {
          errorCount++;
          _logger.e('[VocabularyInitialization] 處理單字時發生錯誤: $e');
        }
      }
      
      _logger.i('[VocabularyInitialization] 初始化完成！');
      _logger.i('[VocabularyInitialization] 創建: $createdCount, 跳過: $skippedCount, 錯誤: $errorCount');
      
      return createdCount;
    } catch (e) {
      _logger.e('[VocabularyInitialization] 初始化失敗: $e');
      rethrow;
    }
  }
  
  /// 檢查是否需要初始化
  /// 
  /// 如果用戶的卡片數量少於 100，則認為需要初始化
  bool needsInitialization({
    required String userId,
    required Box<FSRSCardModel> cardsBox,
  }) {
    final userCards = cardsBox.values
        .where((card) => card.userId == userId)
        .length;
    
    return userCards < 100;
  }
  
  /// 生成卡片鍵
  String _getCardKey(String userId, String lemma, String senseId) {
    return '$userId:$lemma:$senseId';
  }
}
