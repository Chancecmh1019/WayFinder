import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';

void main() async {
  print('檢查 GSAT-English.json.gz 中的新欄位...\n');
  
  // 讀取並解壓縮
  final file = File('assets/GSAT-English.json.gz');
  if (!file.existsSync()) {
    print('錯誤：找不到 assets/GSAT-English.json.gz');
    return;
  }
  
  final bytes = await file.readAsBytes();
  final archive = GZipDecoder().decodeBytes(bytes);
  final jsonString = utf8.decode(archive);
  final data = json.decode(jsonString) as Map<String, dynamic>;
  
  print('版本：${data['version']}');
  print('生成時間：${data['generated_at']}\n');
  
  final words = data['words'] as List<dynamic>;
  print('總單字數：${words.length}\n');
  
  // 統計新欄位
  int withCollocations = 0;
  int withUsageNotes = 0;
  int withGrammarNotes = 0;
  int withCommonMistakes = 0;
  
  List<String> exampleWords = [];
  
  for (final word in words) {
    final wordMap = word as Map<String, dynamic>;
    final lemma = wordMap['lemma'] as String;
    
    final collocations = wordMap['collocations'] as List<dynamic>?;
    final usageNotes = wordMap['usage_notes'] as String?;
    final grammarNotes = wordMap['grammar_notes'] as String?;
    final commonMistakes = wordMap['common_mistakes'] as String?;
    
    if (collocations != null && collocations.isNotEmpty) {
      withCollocations++;
      if (exampleWords.length < 5) {
        exampleWords.add(lemma);
        print('範例單字：$lemma');
        print('  collocations: ${collocations.length} 組');
        if (collocations.isNotEmpty) {
          final first = collocations[0] as Map<String, dynamic>;
          final english = first['collocation'] ?? first['english'] ?? 'null';
          final chinese = first['zh'] ?? first['chinese'] ?? 'null';
          print('    - $english ($chinese)');
        }
        if (usageNotes != null) {
          print('  usage_notes: ${usageNotes.substring(0, usageNotes.length > 50 ? 50 : usageNotes.length)}...');
        }
        if (grammarNotes != null) {
          print('  grammar_notes: ${grammarNotes.substring(0, grammarNotes.length > 50 ? 50 : grammarNotes.length)}...');
        }
        if (commonMistakes != null) {
          print('  common_mistakes: ${commonMistakes.substring(0, commonMistakes.length > 50 ? 50 : commonMistakes.length)}...');
        }
        print('');
      }
    }
    
    if (usageNotes != null) withUsageNotes++;
    if (grammarNotes != null) withGrammarNotes++;
    if (commonMistakes != null) withCommonMistakes++;
  }
  
  print('\n統計結果：');
  print('  有 collocations 的單字：$withCollocations');
  print('  有 usage_notes 的單字：$withUsageNotes');
  print('  有 grammar_notes 的單字：$withGrammarNotes');
  print('  有 common_mistakes 的單字：$withCommonMistakes');
  
  if (withCollocations == 0) {
    print('\n⚠️  警告：資料庫中沒有任何單字包含新欄位！');
    print('請確認 GSAT-English.json.gz 是否為 v6.1.0 版本。');
  }
}
