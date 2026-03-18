import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;
import 'package:logger/logger.dart';

/// HTML 內容翻譯服務
/// 
/// 智能翻譯 HTML 內容，保留標籤結構
/// 只翻譯文本節點，不破壞 HTML 格式
class HtmlTranslationService {
  final Logger _logger = Logger();
  final Map<String, String> _cache = {};
  
  /// 翻譯 HTML 內容
  /// 
  /// [html] - 原始 HTML 內容
  /// [targetLang] - 目標語言（zh-TW 為繁體中文）
  /// [preserveTags] - 要保留的標籤列表
  Future<String> translateHtml(
    String html, {
    String targetLang = 'zh-TW',
    bool useCache = true,
  }) async {
    try {
      // 檢查緩存
      if (useCache && _cache.containsKey(html)) {
        return _cache[html]!;
      }
      
      // 解析 HTML
      final document = html_parser.parse(html);
      
      // 提取所有文本節點
      final textsToTranslate = <String>[];
      final textNodes = <dom.Node>[];
      
      _extractTextNodes(document.body, textsToTranslate, textNodes);
      
      if (textsToTranslate.isEmpty) {
        return html;
      }
      
      // 批量翻譯文本
      final translatedTexts = await _batchTranslate(
        textsToTranslate,
        targetLang: targetLang,
      );
      
      // 替換文本節點
      for (int i = 0; i < textNodes.length && i < translatedTexts.length; i++) {
        textNodes[i].text = translatedTexts[i];
      }
      
      // 生成翻譯後的 HTML
      final translatedHtml = document.body?.outerHtml ?? html;
      
      // 緩存結果
      if (useCache) {
        _cache[html] = translatedHtml;
      }
      
      return translatedHtml;
      
    } catch (e, stackTrace) {
      _logger.e('[HtmlTranslationService] 翻譯失敗: $e', stackTrace: stackTrace);
      return html; // 失敗時返回原文
    }
  }
  
  /// 提取文本節點
  void _extractTextNodes(
    dom.Node? node,
    List<String> texts,
    List<dom.Node> nodes,
  ) {
    if (node == null) return;
    
    if (node.nodeType == dom.Node.TEXT_NODE) {
      final text = node.text?.trim() ?? '';
      if (text.isNotEmpty && text.length > 1) {
        // 跳過純標點符號和特殊字符
        if (!_isPunctuation(text)) {
          texts.add(text);
          nodes.add(node);
        }
      }
    } else {
      for (final child in node.nodes) {
        _extractTextNodes(child, texts, nodes);
      }
    }
  }
  
  /// 檢查是否為純標點符號
  bool _isPunctuation(String text) {
    final punctuation = RegExp(r'^[\s\p{P}\p{S}]+$', unicode: true);
    return punctuation.hasMatch(text);
  }
  
  /// 批量翻譯文本
  Future<List<String>> _batchTranslate(
    List<String> texts, {
    required String targetLang,
  }) async {
    // 這裡可以使用不同的翻譯服務
    // 1. Google Translate API
    // 2. 本地翻譯模型
    // 3. 其他翻譯服務
    
    // 暫時返回原文（需要實現實際的翻譯邏輯）
    return texts;
  }
  
  /// 清除緩存
  void clearCache() {
    _cache.clear();
  }
  
  /// 獲取緩存大小
  int get cacheSize => _cache.length;
}
