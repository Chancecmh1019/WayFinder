import 'dart:io';
import 'dart:convert';
import 'package:archive/archive.dart';

void main() async {
  print('=== 測試新字典檔案載入 ===\n');
  
  // 讀取壓縮檔案
  final file = File('assets/GSAT-English.json.gz');
  if (!await file.exists()) {
    print('❌ 檔案不存在: ${file.path}');
    return;
  }
  
  print('✓ 找到檔案: ${file.path}');
  final bytes = await file.readAsBytes();
  print('✓ 檔案大小: ${(bytes.length / 1024 / 1024).toStringAsFixed(2)} MB\n');
  
  // 解壓縮
  print('正在解壓縮...');
  final decompressed = GZipDecoder().decodeBytes(bytes);
  print('✓ 解壓縮後大小: ${(decompressed.length / 1024 / 1024).toStringAsFixed(2)} MB\n');
  
  // 解析 JSON
  print('正在解析 JSON...');
  final jsonString = utf8.decode(decompressed);
  final jsonData = json.decode(jsonString) as Map<String, dynamic>;
  
  // 顯示基本資訊
  print('\n=== 資料庫資訊 ===');
  print('版本: ${jsonData['version']}');
  print('生成時間: ${jsonData['generated_at']}');
  
  if (jsonData.containsKey('metadata')) {
    final metadata = jsonData['metadata'] as Map<String, dynamic>;
    print('\n=== Metadata ===');
    print('總條目數: ${metadata['total_entries']}');
    
    if (metadata.containsKey('count_by_type')) {
      final countByType = metadata['count_by_type'] as Map<String, dynamic>;
      print('\n類型統計:');
      print('  - 單字 (words): ${countByType['word']}');
      print('  - 片語 (phrases): ${countByType['phrase']}');
      print('  - 文法 (patterns): ${countByType['pattern']}');
    }
    
    if (metadata.containsKey('exam_year_range')) {
      final yearRange = metadata['exam_year_range'] as Map<String, dynamic>;
      print('\n考試年份範圍: ${yearRange['min']} - ${yearRange['max']}');
    }
  }
  
  // 檢查資料結構
  print('\n=== 資料結構檢查 ===');
  
  if (jsonData.containsKey('words')) {
    final words = jsonData['words'] as List<dynamic>;
    print('✓ words 陣列: ${words.length} 個單字');
    
    if (words.isNotEmpty) {
      final firstWord = words[0] as Map<String, dynamic>;
      print('\n第一個單字範例:');
      print('  lemma: ${firstWord['lemma']}');
      print('  pos: ${firstWord['pos']}');
      print('  level: ${firstWord['level']}');
      print('  in_official_list: ${firstWord['in_official_list']}');
      
      if (firstWord.containsKey('frequency')) {
        final freq = firstWord['frequency'] as Map<String, dynamic>;
        print('  frequency.total_appearances: ${freq['total_appearances']}');
        print('  frequency.importance_score: ${freq['importance_score']}');
      }
      
      if (firstWord.containsKey('senses')) {
        final senses = firstWord['senses'] as List<dynamic>;
        print('  senses: ${senses.length} 個義項');
        if (senses.isNotEmpty) {
          final firstSense = senses[0] as Map<String, dynamic>;
          print('    - zh_def: ${firstSense['zh_def']}');
          print('    - en_def: ${firstSense['en_def']}');
        }
      }
      
      if (firstWord.containsKey('root_info')) {
        print('  ✓ 有 root_info');
      }
    }
  }
  
  if (jsonData.containsKey('phrases')) {
    final phrases = jsonData['phrases'] as List<dynamic>;
    print('\n✓ phrases 陣列: ${phrases.length} 個片語');
    
    if (phrases.isNotEmpty) {
      final firstPhrase = phrases[0] as Map<String, dynamic>;
      print('\n第一個片語範例:');
      print('  lemma: ${firstPhrase['lemma']}');
      if (firstPhrase.containsKey('senses')) {
        final senses = firstPhrase['senses'] as List<dynamic>;
        print('  senses: ${senses.length} 個義項');
      }
    }
  }
  
  if (jsonData.containsKey('patterns')) {
    final patterns = jsonData['patterns'] as List<dynamic>;
    print('\n✓ patterns 陣列: ${patterns.length} 個文法句型');
    
    if (patterns.isNotEmpty) {
      final firstPattern = patterns[0] as Map<String, dynamic>;
      print('\n第一個文法句型範例:');
      print('  lemma: ${firstPattern['lemma']}');
      print('  pattern_category: ${firstPattern['pattern_category']}');
      if (firstPattern.containsKey('subtypes')) {
        final subtypes = firstPattern['subtypes'] as List<dynamic>;
        print('  subtypes: ${subtypes.length} 個子類型');
      }
    }
  }
  
  print('\n=== 測試完成 ===');
}
