import 'dart:io';
import 'dart:convert';
import 'package:archive/archive.dart';

void main() async {
  print('=== 詞彙資料庫統計 ===\n');
  
  final file = File('assets/GSAT-English.json.gz');
  final bytes = await file.readAsBytes();
  final decompressed = GZipDecoder().decodeBytes(bytes);
  final jsonString = utf8.decode(decompressed);
  final jsonData = json.decode(jsonString) as Map<String, dynamic>;
  
  // 統計單字
  if (jsonData.containsKey('words')) {
    final words = jsonData['words'] as List<dynamic>;
    print('📚 單字統計 (共 ${words.length} 個)');
    print('─' * 50);
    
    // 按級別統計
    final levelCounts = <int, int>{};
    var officialCount = 0;
    var withRootInfo = 0;
    var withConfusionNotes = 0;
    var withSynonyms = 0;
    var withAntonyms = 0;
    
    for (final word in words) {
      final wordMap = word as Map<String, dynamic>;
      
      final level = wordMap['level'] as int?;
      if (level != null) {
        levelCounts[level] = (levelCounts[level] ?? 0) + 1;
      }
      
      if (wordMap['in_official_list'] == true) {
        officialCount++;
      }
      
      if (wordMap.containsKey('root_info') && wordMap['root_info'] != null) {
        withRootInfo++;
      }
      
      if (wordMap.containsKey('confusion_notes')) {
        final notes = wordMap['confusion_notes'] as List<dynamic>;
        if (notes.isNotEmpty) {
          withConfusionNotes++;
        }
      }
      
      if (wordMap.containsKey('synonyms')) {
        final synonyms = wordMap['synonyms'] as List<dynamic>;
        if (synonyms.isNotEmpty) {
          withSynonyms++;
        }
      }
      
      if (wordMap.containsKey('antonyms')) {
        final antonyms = wordMap['antonyms'] as List<dynamic>;
        if (antonyms.isNotEmpty) {
          withAntonyms++;
        }
      }
    }
    
    print('\n按級別分布:');
    final sortedLevels = levelCounts.keys.toList()..sort();
    for (final level in sortedLevels) {
      final count = levelCounts[level]!;
      final percentage = (count / words.length * 100).toStringAsFixed(1);
      print('  Level $level: $count 個 ($percentage%)');
    }
    
    print('\n特殊標記:');
    print('  官方字彙表: $officialCount 個');
    print('  有字根資訊: $withRootInfo 個');
    print('  有易混淆詞: $withConfusionNotes 個');
    print('  有同義詞: $withSynonyms 個');
    print('  有反義詞: $withAntonyms 個');
    
    // 統計詞性
    final posCounts = <String, int>{};
    for (final word in words) {
      final wordMap = word as Map<String, dynamic>;
      final posList = wordMap['pos'] as List<dynamic>?;
      if (posList != null) {
        for (final pos in posList) {
          posCounts[pos as String] = (posCounts[pos] ?? 0) + 1;
        }
      }
    }
    
    print('\n詞性分布:');
    final sortedPos = posCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    for (final entry in sortedPos.take(10)) {
      print('  ${entry.key}: ${entry.value} 個');
    }
  }
  
  // 統計片語
  if (jsonData.containsKey('phrases')) {
    final phrases = jsonData['phrases'] as List<dynamic>;
    print('\n\n💬 片語統計 (共 ${phrases.length} 個)');
    print('─' * 50);
    
    var withFrequency = 0;
    var totalExamples = 0;
    
    for (final phrase in phrases) {
      final phraseMap = phrase as Map<String, dynamic>;
      
      if (phraseMap.containsKey('frequency') && phraseMap['frequency'] != null) {
        withFrequency++;
      }
      
      if (phraseMap.containsKey('senses')) {
        final senses = phraseMap['senses'] as List<dynamic>;
        for (final sense in senses) {
          final senseMap = sense as Map<String, dynamic>;
          if (senseMap.containsKey('examples')) {
            final examples = senseMap['examples'] as List<dynamic>;
            totalExamples += examples.length;
          }
        }
      }
    }
    
    print('  有頻率資料: $withFrequency 個');
    print('  總例句數: $totalExamples 個');
    print('  平均例句數: ${(totalExamples / phrases.length).toStringAsFixed(1)} 個/片語');
  }
  
  // 統計文法句型
  if (jsonData.containsKey('patterns')) {
    final patterns = jsonData['patterns'] as List<dynamic>;
    print('\n\n📖 文法句型統計 (共 ${patterns.length} 個)');
    print('─' * 50);
    
    var totalSubtypes = 0;
    var totalExamples = 0;
    
    print('\n句型列表:');
    for (final pattern in patterns) {
      final patternMap = pattern as Map<String, dynamic>;
      final lemma = patternMap['lemma'] as String;
      final category = patternMap['pattern_category'] as String;
      
      if (patternMap.containsKey('subtypes')) {
        final subtypes = patternMap['subtypes'] as List<dynamic>;
        totalSubtypes += subtypes.length;
        
        for (final subtype in subtypes) {
          final subtypeMap = subtype as Map<String, dynamic>;
          if (subtypeMap.containsKey('examples')) {
            final examples = subtypeMap['examples'] as List<dynamic>;
            totalExamples += examples.length;
          }
        }
        
        print('  $lemma ($category): ${subtypes.length} 個子類型');
      }
    }
    
    print('\n  總子類型數: $totalSubtypes 個');
    print('  總例句數: $totalExamples 個');
  }
  
  print('\n' + '=' * 50);
  print('統計完成！');
}
