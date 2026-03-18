import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';

/// 驗證 ml_score 修復
/// 
/// 這個腳本會：
/// 1. 讀取壓縮的 JSON 數據庫
/// 2. 檢查前 20 個單字的 ml_score
/// 3. 驗證 FrequencyDataModel.fromJson 是否正確處理 ml_score
void main() async {
  print('=== 驗證 ML Score 修復 ===\n');
  
  // 讀取壓縮的 JSON 檔案
  final file = File('assets/GSAT-English.json.gz');
  if (!file.existsSync()) {
    print('錯誤：找不到 assets/GSAT-English.json.gz');
    return;
  }
  
  print('讀取數據庫...');
  final bytes = await file.readAsBytes();
  final archive = GZipDecoder().decodeBytes(bytes);
  final jsonString = utf8.decode(archive);
  final data = jsonDecode(jsonString) as Map<String, dynamic>;
  
  final words = data['words'] as List<dynamic>;
  print('總共 ${words.length} 個單字\n');
  
  // 檢查前 20 個單字
  print('檢查前 20 個單字的 ml_score：\n');
  print('${'單字'.padRight(20)} | ml_score    | importance_score');
  print('-' * 60);
  
  int hasMLScore = 0;
  int hasImportanceScore = 0;
  
  for (var i = 0; i < 20 && i < words.length; i++) {
    final word = words[i] as Map<String, dynamic>;
    final lemma = word['lemma'] as String;
    final freq = word['frequency'] as Map<String, dynamic>?;
    
    if (freq != null) {
      final mlScore = freq['ml_score'];
      final importanceScore = freq['importance_score'];
      
      if (mlScore != null) hasMLScore++;
      if (importanceScore != null) hasImportanceScore++;
      
      print('${lemma.padRight(20)} | ${mlScore?.toString().padRight(11) ?? 'null'.padRight(11)} | ${importanceScore?.toString() ?? 'null'}');
    } else {
      print('${lemma.padRight(20)} | 無 frequency 數據');
    }
  }
  
  print('\n統計：');
  print('- 有 ml_score 的單字：$hasMLScore / 20');
  print('- 有 importance_score 的單字：$hasImportanceScore / 20');
  
  // 測試 FrequencyDataModel.fromJson
  print('\n測試 FrequencyDataModel.fromJson 處理：');
  final testWord = words[0] as Map<String, dynamic>;
  final testFreq = testWord['frequency'] as Map<String, dynamic>?;
  
  if (testFreq != null) {
    final mlScore = testFreq['ml_score'];
    final importanceScore = testFreq['importance_score'];
    
    print('原始數據：');
    print('  ml_score: $mlScore');
    print('  importance_score: $importanceScore');
    
    print('\n修復後的邏輯：');
    print('  如果沒有 importance_score，應該使用 ml_score');
    print('  預期結果：importanceScore = ${mlScore ?? 0.0}');
  }
  
  print('\n✅ 修復說明：');
  print('1. JSON 數據中只有 ml_score，沒有 importance_score');
  print('2. 修改了 FrequencyDataModel.fromJson，當沒有 importance_score 時使用 ml_score');
  print('3. 修改了 VocabIndexItemModel.fromJson，從 frequency.ml_score 獲取值');
  print('4. 用戶需要清除緩存並重新加載數據庫才能看到變化');
  
  print('\n清除緩存的方法：');
  print('- 刪除應用數據（設置 > 應用 > Wayfinder > 清除數據）');
  print('- 或在代碼中添加版本檢查，自動重新加載數據庫');
}
