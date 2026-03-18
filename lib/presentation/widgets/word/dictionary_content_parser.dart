import 'package:flutter/material.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;
import '../../theme/app_theme.dart';

/// 解析並顯示字典 HTML 內容
/// 
/// 完整支援兩個字典的所有標籤和 class：
/// - 朗文進階英漢雙解詞典（第五版）：53 種標籤，160 種 class
/// - 牛津高階英漢雙解詞典（第10版）：28 種標籤，184 種 class
/// - 總計：67 種標籤，335 種 class
class DictionaryContentParser {
  /// 解析 HTML 並轉換為 Flutter Widget
  static List<Widget> parseHtml(String htmlContent, bool isDark) {
    try {
      // 移除 script、link 和 audio 標籤
      htmlContent = htmlContent
          .replaceAll(RegExp(r'<script[^>]*>.*?</script>', dotAll: true), '')
          .replaceAll(RegExp(r'<link[^>]*>', dotAll: true), '')
          .replaceAll(RegExp(r'<audio-wr[^>]*>.*?</audio-wr>', dotAll: true), '')
          .replaceAll(RegExp(r'<xaudio[^>]*>.*?</xaudio>', dotAll: true), '');
      
      final document = html_parser.parse(htmlContent);
      final body = document.body;
      
      if (body == null) {
        return [_buildErrorText('無法解析內容', isDark)];
      }

      final widgets = <Widget>[];
      
      for (final node in body.nodes) {
        final widget = _parseNode(node, isDark);
        if (widget != null) {
          widgets.add(widget);
        }
      }

      return widgets.isEmpty 
          ? [_buildErrorText('無內容', isDark)]
          : widgets;
    } catch (e) {
      return [_buildErrorText('解析錯誤: $e', isDark)];
    }
  }

  static Widget? _parseNode(dom.Node node, bool isDark, {int depth = 0}) {
    if (node is dom.Element) {
      return _parseElement(node, isDark, depth: depth);
    } else if (node is dom.Text) {
      final text = node.text.trim();
      if (text.isEmpty) return null;
      return _buildText(text, isDark);
    }
    return null;
  }

  static Widget? _parseElement(dom.Element element, bool isDark, {int depth = 0}) {
    final tag = element.localName?.toLowerCase();
    
    // 跳過不需要的元素
    if (tag == 'script' || tag == 'link' || tag == 'audio-wr' || tag == 'xaudio' || tag == 'on-audio') {
      return null;
    }
    
    // 根據 class 優先處理
    final className = element.className;
    if (className.isNotEmpty) {
      final widget = _parseByClass(element, isDark, depth: depth);
      if (widget != null) return widget;
    }
    
    // 根據標籤處理
    switch (tag) {
      // 標題
      case 'h1':
      case 'h2':
      case 'h3':
      case 'h4':
        final level = tag != null ? int.parse(tag[1]) : 1;
        return _buildHeading(element, isDark, level: level);
      
      // 段落
      case 'p':
        return _buildParagraph(element, isDark);
      
      // 容器
      case 'div':
        return _buildDiv(element, isDark, depth: depth);
      
      // Span
      case 'span':
        return _buildSpan(element, isDark, depth: depth);
      
      // 文本樣式
      case 'strong':
      case 'b':
        return _buildBoldText(element.text, isDark);
      
      case 'em':
      case 'i':
        return _buildItalicText(element.text, isDark);
      
      case 'sup':
      case 'sub':
        return _buildText(element.text, isDark);
      
      // 列表
      case 'ul':
      case 'ol':
      case 'dl':
        return _buildList(element, isDark, ordered: tag == 'ol');
      
      case 'li':
        return _buildListItem(element, isDark);
      
      // 表格
      case 'table':
      case 'tbody':
      case 'thead':
        return _buildTable(element, isDark);
      
      case 'tr':
      case 'td':
      case 'th':
        return _buildContainer(element, isDark, depth: depth);
      
      // 換行
      case 'br':
      case 'hr':
        return const SizedBox(height: AppTheme.space8);
      
      // 連結
      case 'a':
        return _buildLink(element, isDark);
      
      // 圖片
      case 'img':
        return const SizedBox.shrink(); // 暫時跳過圖片
      
      // 字典特殊標籤 - 中文內容
      case 'chn':
      case 'expcn':
      case 'explcn':
        return _buildChineseText(element.text, isDark);
      
      // 字典特殊標籤 - 英文內容
      case 'expen':
      case 'explen':
        return _buildEnglishText(element.text, isDark);
      
      // 字典特殊標籤 - 定義
      case 'deft':
        return _buildDefinition(element, isDark);
      
      // 字典特殊標籤 - 例句
      case 'xt':
        return _buildExample(element, isDark);
      
      // 其他所有特殊標籤 - 嘗試解析內容
      case 'o10':
      case 'ot':
      case 'other':
      case 'at':
      case 'ai':
      case 'ad':
      case 'adt':
      case 'undt':
      case 'subjt':
      case 'shcutt':
      case 'unboxt':
      case 'dis-gt':
      case 'mh':
      case 'unt':
      case 'unxt':
      case 'uset':
      case 'h4t':
      case 'closedt':
      case 'aside':
      case 'tw':
      case 'eph-blk':
      case 'hk':
      case 'label-g-blk':
      case 'label-g':
      case 'geo-blk':
      case 'geo':
      case 'brelabel':
      case 'reg-blk':
      case 'reg':
        return _buildContainer(element, isDark, depth: depth);
      
      default:
        return _buildContainer(element, isDark, depth: depth);
    }
  }

  /// 根據 CSS class 解析元素
  static Widget? _parseByClass(dom.Element element, bool isDark, {int depth = 0}) {
    final className = element.className;
    final text = element.text.trim();
    
    // 中文內容相關 class
    if (className.contains('defcn') || 
        className.contains('chinese') || 
        className.contains('zh') ||
        className.contains('chn') ||
        className.contains('expcn') ||
        className.contains('explcn') ||
        className.contains('gramcn') ||
        className.contains('collocn')) {
      if (text.isNotEmpty) {
        return _buildChineseText(text, isDark);
      }
    }
    
    // 定義相關 class
    if (className.contains('def') && !className.contains('defcn')) {
      return _buildDefinition(element, isDark);
    }
    
    // 例句相關 class
    if (className.contains('example') || 
        className.contains('exa') ||
        className.contains('colloinexa') ||
        className.contains('gramexa') ||
        className.contains('badexa') ||
        className.contains('colloexa')) {
      return _buildExample(element, isDark);
    }
    
    // 詞性 class
    if (className.contains('pos')) {
      if (text.isNotEmpty) {
        return _buildPartOfSpeech(text, isDark);
      }
    }
    
    // 音標 class
    if (className.contains('phon') || 
        className.contains('pron') ||
        className.contains('phonetics')) {
      if (text.isNotEmpty) {
        return _buildPhonetic(text, isDark);
      }
    }
    
    // 標籤 class
    if (className.contains('label') || 
        className.contains('registerlab') ||
        className.contains('geo') ||
        className.contains('topic')) {
      if (text.isNotEmpty) {
        return _buildLabel(text, isDark);
      }
    }
    
    // 單字 class
    if (className.contains('headword') || 
        className.contains('hwd') ||
        className.contains('entry')) {
      if (text.isNotEmpty && element.localName == 'h1') {
        return _buildHeadword(text, isDark);
      }
    }
    
    // 區塊 class
    if (className.contains('sense') || 
        className.contains('section') ||
        className.contains('entry')) {
      return _buildSection(element, isDark, depth: depth);
    }
    
    return null;
  }

  static Widget _buildDiv(dom.Element element, bool isDark, {int depth = 0}) {
    final className = element.className;
    
    // 特殊處理某些 class
    if (className.contains('entry') || 
        className.contains('sense') ||
        className.contains('section')) {
      return _buildSection(element, isDark, depth: depth);
    }
    
    if (className.contains('example') || 
        className.contains('examples')) {
      return _buildExampleSection(element, isDark);
    }
    
    if (className.contains('phonetics') || 
        className.contains('pron')) {
      return _buildPhonetics(element, isDark);
    }
    
    // 跳過某些容器
    if (className.contains('contentslot') ||
        className.contains('ad_') ||
        className.contains('popup') ||
        className.contains('menu')) {
      return const SizedBox.shrink();
    }
    
    return _buildContainer(element, isDark, depth: depth);
  }

  static Widget _buildSpan(dom.Element element, bool isDark, {int depth = 0}) {
    final text = element.text.trim();
    
    if (text.isEmpty) {
      return _buildContainer(element, isDark, depth: depth);
    }
    
    // 使用 class 解析
    final widget = _parseByClass(element, isDark, depth: depth);
    if (widget != null) return widget;
    
    // 預設處理
    return _buildContainer(element, isDark, depth: depth);
  }

  static Widget _buildSection(dom.Element element, bool isDark, {int depth = 0}) {
    final children = <Widget>[];
    
    for (final node in element.nodes) {
      final widget = _parseNode(node, isDark, depth: depth + 1);
      if (widget != null) {
        children.add(widget);
      }
    }

    if (children.isEmpty) return const SizedBox.shrink();

    // 如果深度太深，不添加背景
    if (depth > 2) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.space12),
      padding: const EdgeInsets.all(AppTheme.space12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.gray850 : AppTheme.gray50,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  static Widget _buildHeading(dom.Element element, bool isDark, {required int level}) {
    final text = element.text.trim();
    if (text.isEmpty) return const SizedBox.shrink();
    
    final fontSize = level == 1 ? 18.0 : (level == 2 ? 16.0 : 15.0);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.space12, top: AppTheme.space8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          height: 1.4,
          color: isDark ? AppTheme.pureWhite : AppTheme.pureBlack,
        ),
      ),
    );
  }

  static Widget _buildHeadword(String text, bool isDark) {
    if (text.trim().isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.space8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          height: 1.3,
          color: isDark ? AppTheme.pureWhite : AppTheme.pureBlack,
        ),
      ),
    );
  }

  static Widget _buildDefinition(dom.Element element, bool isDark) {
    final text = element.text.trim();
    if (text.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.space12, left: AppTheme.space8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '•',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDark ? AppTheme.gray400 : AppTheme.gray600,
            ),
          ),
          const SizedBox(width: AppTheme.space8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                height: 1.6,
                color: isDark ? AppTheme.gray300 : AppTheme.gray700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildExample(dom.Element element, bool isDark) {
    final text = element.text.trim();
    if (text.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.space8, left: AppTheme.space16),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          fontStyle: FontStyle.italic,
          height: 1.6,
          color: isDark ? AppTheme.gray400 : AppTheme.gray600,
        ),
      ),
    );
  }

  static Widget _buildExampleSection(dom.Element element, bool isDark) {
    final children = <Widget>[];
    
    for (final node in element.nodes) {
      final widget = _parseNode(node, isDark);
      if (widget != null) {
        children.add(widget);
      }
    }

    if (children.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.space12),
      padding: const EdgeInsets.all(AppTheme.space12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.gray850 : AppTheme.gray50,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  static Widget _buildChineseText(String text, bool isDark) {
    if (text.trim().isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.space8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          height: 1.6,
          color: isDark ? AppTheme.pureWhite : AppTheme.pureBlack,
        ),
      ),
    );
  }

  static Widget _buildEnglishText(String text, bool isDark) {
    if (text.trim().isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.space8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 1.6,
          color: isDark ? AppTheme.gray300 : AppTheme.gray700,
        ),
      ),
    );
  }

  static Widget _buildPartOfSpeech(String text, bool isDark) {
    if (text.trim().isEmpty) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.space8, right: AppTheme.space8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.gray800 : AppTheme.gray100,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: isDark ? AppTheme.gray400 : AppTheme.gray600,
        ),
      ),
    );
  }

  static Widget _buildPhonetic(String text, bool isDark) {
    if (text.trim().isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.space8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: isDark ? AppTheme.gray400 : AppTheme.gray600,
        ),
      ),
    );
  }

  static Widget _buildPhonetics(dom.Element element, bool isDark) {
    final text = element.text.trim();
    if (text.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.space12),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: isDark ? AppTheme.gray400 : AppTheme.gray600,
        ),
      ),
    );
  }

  static Widget _buildLabel(String text, bool isDark) {
    if (text.trim().isEmpty) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.space8, right: AppTheme.space8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.gray850 : AppTheme.gray100,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: isDark ? AppTheme.gray400 : AppTheme.gray600,
        ),
      ),
    );
  }

  static Widget _buildParagraph(dom.Element element, bool isDark) {
    final children = <InlineSpan>[];
    
    for (final node in element.nodes) {
      if (node is dom.Text) {
        final text = node.text.trim();
        if (text.isNotEmpty) {
          children.add(TextSpan(text: text));
        }
      } else if (node is dom.Element) {
        children.add(_parseInlineElement(node, isDark));
      }
    }

    if (children.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.space12),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            height: 1.6,
            color: isDark ? AppTheme.gray300 : AppTheme.gray700,
          ),
          children: children,
        ),
      ),
    );
  }

  static InlineSpan _parseInlineElement(dom.Element element, bool isDark) {
    final tag = element.localName?.toLowerCase();
    final text = element.text;
    final className = element.className;

    // 中文內容
    if (className.contains('defcn') || 
        className.contains('chinese') || 
        className.contains('zh') ||
        className.contains('expcn')) {
      return TextSpan(
        text: text,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: isDark ? AppTheme.pureWhite : AppTheme.pureBlack,
        ),
      );
    }

    switch (tag) {
      case 'strong':
      case 'b':
        return TextSpan(
          text: text,
          style: const TextStyle(fontWeight: FontWeight.w600),
        );
      
      case 'em':
      case 'i':
        return TextSpan(
          text: text,
          style: const TextStyle(fontStyle: FontStyle.italic),
        );
      
      case 'chn':
      case 'expcn':
        return TextSpan(
          text: text,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: isDark ? AppTheme.pureWhite : AppTheme.pureBlack,
          ),
        );
      
      default:
        return TextSpan(text: text);
    }
  }

  static Widget _buildContainer(dom.Element element, bool isDark, {int depth = 0}) {
    final children = <Widget>[];
    
    for (final node in element.nodes) {
      final widget = _parseNode(node, isDark, depth: depth + 1);
      if (widget != null) {
        children.add(widget);
      }
    }

    if (children.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  static Widget _buildText(String text, bool isDark) {
    if (text.trim().isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.space8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          height: 1.6,
          color: isDark ? AppTheme.gray300 : AppTheme.gray700,
        ),
      ),
    );
  }

  static Widget _buildBoldText(String text, bool isDark) {
    if (text.trim().isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.space8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          height: 1.6,
          color: isDark ? AppTheme.pureWhite : AppTheme.pureBlack,
        ),
      ),
    );
  }

  static Widget _buildItalicText(String text, bool isDark) {
    if (text.trim().isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.space8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          fontStyle: FontStyle.italic,
          height: 1.6,
          color: isDark ? AppTheme.gray300 : AppTheme.gray700,
        ),
      ),
    );
  }

  static Widget _buildList(dom.Element element, bool isDark, {required bool ordered}) {
    final items = <Widget>[];
    int index = 1;
    
    for (final child in element.children) {
      if (child.localName == 'li') {
        items.add(_buildListItemWithMarker(
          child,
          isDark,
          marker: ordered ? '$index.' : '•',
        ));
        index++;
      }
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.space12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items,
      ),
    );
  }

  static Widget _buildListItem(dom.Element element, bool isDark) {
    return _buildListItemWithMarker(element, isDark, marker: '•');
  }

  static Widget _buildListItemWithMarker(dom.Element element, bool isDark, {required String marker}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.space8, left: AppTheme.space16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 20,
            child: Text(
              marker,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: isDark ? AppTheme.gray400 : AppTheme.gray600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              element.text,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                height: 1.6,
                color: isDark ? AppTheme.gray300 : AppTheme.gray700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildTable(dom.Element element, bool isDark) {
    final rows = <TableRow>[];
    
    for (final row in element.querySelectorAll('tr')) {
      final cells = <Widget>[];
      
      for (final cell in row.querySelectorAll('td, th')) {
        cells.add(
          Padding(
            padding: const EdgeInsets.all(AppTheme.space8),
            child: Text(
              cell.text,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: isDark ? AppTheme.gray300 : AppTheme.gray700,
              ),
            ),
          ),
        );
      }
      
      if (cells.isNotEmpty) {
        rows.add(TableRow(children: cells));
      }
    }

    if (rows.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.space12),
      child: Table(
        border: TableBorder.all(
          color: isDark ? AppTheme.gray800 : AppTheme.dividerGray,
          width: 1,
        ),
        children: rows,
      ),
    );
  }

  static Widget _buildLink(dom.Element element, bool isDark) {
    final text = element.text;
    if (text.trim().isEmpty) return const SizedBox.shrink();
    
    // 跳過音頻連結
    if (element.className.contains('audio') || 
        element.className.contains('sound')) {
      return const SizedBox.shrink();
    }
    
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.space8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          height: 1.6,
          color: isDark ? AppTheme.gray400 : AppTheme.gray600,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }

  static Widget _buildErrorText(String message, bool isDark) {
    return Text(
      message,
      style: TextStyle(
        fontSize: 14,
        color: isDark ? AppTheme.gray400 : AppTheme.gray600,
      ),
    );
  }
}
