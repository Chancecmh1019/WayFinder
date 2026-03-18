import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';

void main() async {
  print('詳細檢查 collocations 資料結構...\n');
  
  final file = File('assets/GSAT-English.json.gz');
  final bytes = await file.readAsBytes();
  final archive = GZipDecoder().decodeBytes(bytes);
  final jsonString = utf8.decode(archive);
  final data = json.decode(jsonString) as Map<String, dynamic>;
  
  final words = data['words'] as List<dynamic>;
  
  // 找第一個有 collocations 的單字
  for (final word in words) {
    final wordMap = word as Map<String, dynamic>;
    final collocations = wordMap['collocations'];
    
    if (collocations != null && collocations is List && collocations.isNotEmpty) {
      final lemma = wordMap['lemma'];
      print('單字：$lemma');
      print('collocations 類型：${collocations.runtimeType}');
      print('collocations 長度：${collocations.length}');
      print('\n第一個 collocation:');
      final first = collocations[0];
      print('  類型：${first.runtimeType}');
      print('  內容：$first');
      
      if (first is Map) {
        print('  Keys: ${first.keys.toList()}');
        for (final key in first.keys) {
          print('    $key: ${first[key]} (${first[key].runtimeType})');
        }
      } else if (first is String) {
        print('  這是一個字串！');
      }
      
      print('\n所有 collocations:');
      for (int i = 0; i < collocations.length; i++) {
        print('  [$i] ${collocations[i]}');
      }
      
      break;
    }
  }
}
