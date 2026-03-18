import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// WayFinder Design System
/// 高冷、文青、簡約的黑白灰設計系統
/// iOS 風格，擺脫 Material Design
class AppTheme {
  // ==================== 色彩系統 ====================
  
  // 主色調 - 純粹的黑白灰
  static const Color pureBlack = Color(0xFF000000);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color offWhite = Color(0xFFFAFAFA);
  
  // 灰階系統 - 優化對比度（WCAG AA 標準）
  static const Color gray950 = Color(0xFF0F0F0F);  // 深邃黑（提升亮度）
  static const Color gray900 = Color(0xFF1F1F1F);  // 夜幕（提升亮度）
  static const Color gray850 = Color(0xFF2A2A2A);  // 暗影（提升亮度）
  static const Color gray800 = Color(0xFF353535);  // 石墨（提升亮度）
  static const Color gray700 = Color(0xFF4A4A4A);  // 深灰（提升對比）
  static const Color gray600 = Color(0xFF666666);  // 中灰（提升對比）
  static const Color gray500 = Color(0xFF858585);  // 霧灰（提升對比）
  static const Color gray400 = Color(0xFFA3A3A3);  // 淺灰（提升對比）
  static const Color gray300 = Color(0xFFC2C2C2);  // 銀灰（提升對比）
  static const Color gray200 = Color(0xFFDDDDDD);  // 淡灰（提升對比）
  static const Color gray100 = Color(0xFFEDEDED);  // 煙灰（提升對比）
  static const Color gray50 = Color(0xFFF5F5F5);   // 霧白（提升對比）
  
  // 功能色 - 極簡設計
  static const Color accentGray = Color(0xFF4A4A4A);  // 強調灰
  static const Color dividerGray = Color(0xFFEEEEEE);  // 分隔線
  static const Color errorRed = Color(0xFF2C2C2C);     // 錯誤色（低調）
  static const Color successGray = Color(0xFF3A3A3A);  // 成功色（低調）
  
  // ==================== 間距系統 ====================
  
  static const double space2 = 2.0;
  static const double space4 = 4.0;
  static const double space6 = 6.0;
  static const double space8 = 8.0;
  static const double space10 = 10.0;
  static const double space12 = 12.0;
  static const double space14 = 14.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space28 = 28.0;
  static const double space32 = 32.0;
  static const double space40 = 40.0;
  static const double space48 = 48.0;
  static const double space56 = 56.0;
  static const double space64 = 64.0;
  
  // ==================== 圓角系統 ====================
  
  static const double radiusTiny = 4.0;      // 極小圓角
  static const double radiusSmall = 8.0;     // 小圓角
  static const double radiusMedium = 12.0;   // 中圓角
  static const double radiusLarge = 16.0;    // 大圓角
  static const double radiusXLarge = 20.0;   // 超大圓角
  static const double radiusRound = 999.0;   // 完全圓形
  
  // ==================== 陰影系統 ====================
  
  // 微妙陰影 - 若隱若現
  static List<BoxShadow> get subtleShadow => [
        const BoxShadow(
          color: Color(0x0A000000),
          blurRadius: 4,
          offset: Offset(0, 1),
          spreadRadius: 0,
        ),
      ];
  
  // 卡片陰影 - 輕盈浮起
  static List<BoxShadow> get cardShadow => [
        const BoxShadow(
          color: Color(0x0F000000),
          blurRadius: 12,
          offset: Offset(0, 2),
          spreadRadius: -2,
        ),
        const BoxShadow(
          color: Color(0x0A000000),
          blurRadius: 6,
          offset: Offset(0, 4),
          spreadRadius: -2,
        ),
      ];
  
  // 懸浮陰影 - 明顯層次
  static List<BoxShadow> get elevatedShadow => [
        const BoxShadow(
          color: Color(0x14000000),
          blurRadius: 20,
          offset: Offset(0, 4),
          spreadRadius: -4,
        ),
        const BoxShadow(
          color: Color(0x0F000000),
          blurRadius: 12,
          offset: Offset(0, 8),
          spreadRadius: -4,
        ),
      ];
  
  // 深度陰影 - 強烈對比
  static List<BoxShadow> get deepShadow => [
        const BoxShadow(
          color: Color(0x1F000000),
          blurRadius: 32,
          offset: Offset(0, 8),
          spreadRadius: -8,
        ),
        const BoxShadow(
          color: Color(0x14000000),
          blurRadius: 16,
          offset: Offset(0, 12),
          spreadRadius: -8,
        ),
      ];
  
  // 內陰影效果（用於凹陷感）
  static List<BoxShadow> get innerShadow => [
        const BoxShadow(
          color: Color(0x14000000),
          blurRadius: 8,
          offset: Offset(0, 2),
          spreadRadius: -4,
        ),
      ];

  
  // ==================== 字體系統 ====================
  
  // 字重
  static const FontWeight weightThin = FontWeight.w100;
  static const FontWeight weightLight = FontWeight.w300;
  static const FontWeight weightRegular = FontWeight.w400;
  static const FontWeight weightMedium = FontWeight.w500;
  static const FontWeight weightSemiBold = FontWeight.w600;
  static const FontWeight weightBold = FontWeight.w700;
  
  // 字號（優化可讀性 +1~2pt）
  static const double fontSize10 = 11.0;  // +1
  static const double fontSize11 = 12.0;  // +1
  static const double fontSize12 = 13.0;  // +1
  static const double fontSize13 = 14.0;  // +1
  static const double fontSize14 = 15.0;  // +1
  static const double fontSize15 = 16.0;  // +1
  static const double fontSize16 = 17.0;  // +1
  static const double fontSize17 = 18.0;  // +1 (iOS 標準改為 18)
  static const double fontSize18 = 19.0;  // +1
  static const double fontSize20 = 22.0;  // +2
  static const double fontSize22 = 24.0;  // +2
  static const double fontSize24 = 26.0;  // +2
  static const double fontSize28 = 30.0;  // +2
  static const double fontSize32 = 34.0;  // +2
  static const double fontSize36 = 38.0;  // +2
  static const double fontSize40 = 42.0;  // +2
  
  // 行高
  static const double lineHeightTight = 1.2;
  static const double lineHeightNormal = 1.5;
  static const double lineHeightRelaxed = 1.8;
  
  // ==================== iOS 風格主題 ====================
  
  // 字體家族
  static const String fontFamilyChinese = 'NotoSerifTC';
  static const String fontFamilyEnglish = 'CormorantGaramond';
  
  // Light Theme - 純淨白
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: false,  // 關閉 Material 3
      brightness: Brightness.light,
      
      // 基礎配色
      primaryColor: pureBlack,
      scaffoldBackgroundColor: offWhite,
      canvasColor: pureWhite,
      cardColor: pureWhite,
      dividerColor: dividerGray,
      
      // 去除水波紋效果，但保留極淡的點擊高亮
      splashFactory: NoSplash.splashFactory,
      highlightColor: const Color(0x0A000000), // 極淡黑色
      splashColor: Colors.transparent,
      hoverColor: Colors.transparent,

      // 頁面轉場動畫 - iOS 滑動風格
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      
      // 字體家族
      fontFamily: fontFamilyChinese,
      fontFamilyFallback: const [fontFamilyEnglish],
      
      // ColorScheme（最小化使用）
      colorScheme: const ColorScheme.light(
        primary: pureBlack,
        secondary: gray700,
        surface: pureWhite,
        error: errorRed,
        onPrimary: pureWhite,
        onSecondary: pureWhite,
        onSurface: pureBlack,
        onError: pureWhite,
      ),
      
      // AppBar - iOS 風格
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent, // 透明，由外部容器提供模糊
        foregroundColor: pureBlack,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.dark, // 狀態列深色圖標
        titleTextStyle: TextStyle(
          fontSize: fontSize17,
          fontWeight: weightSemiBold,
          color: pureBlack,
          letterSpacing: -0.4,  // iOS 字距
        ),
        iconTheme: IconThemeData(
          color: pureBlack,
          size: 22,
        ),
      ),
      
      // Card - 極簡卡片
      cardTheme: CardThemeData(
        color: pureWhite,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
      ),
      
      // 按鈕主題 - iOS 風格
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: pureBlack,
          foregroundColor: pureWhite,
          elevation: 0,
          shadowColor: Colors.transparent,
          splashFactory: NoSplash.splashFactory,
          padding: const EdgeInsets.symmetric(
            horizontal: space24,
            vertical: space14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          textStyle: const TextStyle(
            fontSize: fontSize16,
            fontWeight: weightSemiBold,
            letterSpacing: -0.3,
          ),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: pureBlack,
          splashFactory: NoSplash.splashFactory,
          padding: const EdgeInsets.symmetric(
            horizontal: space16,
            vertical: space10,
          ),
          textStyle: const TextStyle(
            fontSize: fontSize16,
            fontWeight: weightMedium,
            letterSpacing: -0.3,
          ),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: pureBlack,
          side: const BorderSide(color: gray300, width: 1),
          splashFactory: NoSplash.splashFactory,
          padding: const EdgeInsets.symmetric(
            horizontal: space24,
            vertical: space14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          textStyle: const TextStyle(
            fontSize: fontSize16,
            fontWeight: weightMedium,
            letterSpacing: -0.3,
          ),
        ),
      ),
      
      // 輸入框 - 極簡風格
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: gray50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: pureBlack, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: space16,
          vertical: space14,
        ),
        hintStyle: const TextStyle(
          color: gray400,
          fontSize: fontSize16,
          fontWeight: weightRegular,
        ),
      ),
      
      // 文字主題 - iOS San Francisco 風格
      textTheme: const TextTheme(
        // 超大標題
        displayLarge: TextStyle(
          fontSize: fontSize40,
          fontWeight: weightBold,
          color: pureBlack,
          letterSpacing: -1.0,
          height: lineHeightTight,
        ),
        displayMedium: TextStyle(
          fontSize: fontSize36,
          fontWeight: weightBold,
          color: pureBlack,
          letterSpacing: -0.8,
          height: lineHeightTight,
        ),
        displaySmall: TextStyle(
          fontSize: fontSize32,
          fontWeight: weightBold,
          color: pureBlack,
          letterSpacing: -0.6,
          height: lineHeightTight,
        ),
        
        // 標題
        headlineLarge: TextStyle(
          fontSize: fontSize28,
          fontWeight: weightBold,
          color: pureBlack,
          letterSpacing: -0.5,
          height: lineHeightTight,
        ),
        headlineMedium: TextStyle(
          fontSize: fontSize24,
          fontWeight: weightSemiBold,
          color: pureBlack,
          letterSpacing: -0.4,
          height: lineHeightNormal,
        ),
        headlineSmall: TextStyle(
          fontSize: fontSize20,
          fontWeight: weightSemiBold,
          color: pureBlack,
          letterSpacing: -0.3,
          height: lineHeightNormal,
        ),
        
        // 標題文字
        titleLarge: TextStyle(
          fontSize: fontSize18,
          fontWeight: weightSemiBold,
          color: pureBlack,
          letterSpacing: -0.3,
        ),
        titleMedium: TextStyle(
          fontSize: fontSize16,
          fontWeight: weightSemiBold,
          color: pureBlack,
          letterSpacing: -0.2,
        ),
        titleSmall: TextStyle(
          fontSize: fontSize14,
          fontWeight: weightSemiBold,
          color: pureBlack,
          letterSpacing: -0.1,
        ),
        
        // 正文
        bodyLarge: TextStyle(
          fontSize: fontSize17,  // iOS 標準
          fontWeight: weightRegular,
          color: pureBlack,
          letterSpacing: -0.4,
          height: lineHeightNormal,
        ),
        bodyMedium: TextStyle(
          fontSize: fontSize15,
          fontWeight: weightRegular,
          color: gray700,
          letterSpacing: -0.2,
          height: lineHeightNormal,
        ),
        bodySmall: TextStyle(
          fontSize: fontSize13,
          fontWeight: weightRegular,
          color: gray600,
          letterSpacing: -0.1,
          height: lineHeightNormal,
        ),
        
        // 標籤
        labelLarge: TextStyle(
          fontSize: fontSize15,
          fontWeight: weightMedium,
          color: pureBlack,
          letterSpacing: -0.2,
        ),
        labelMedium: TextStyle(
          fontSize: fontSize13,
          fontWeight: weightMedium,
          color: gray700,
          letterSpacing: -0.1,
        ),
        labelSmall: TextStyle(
          fontSize: fontSize11,
          fontWeight: weightMedium,
          color: gray600,
          letterSpacing: 0,
        ),
      ),
      
      // 圖標主題
      iconTheme: const IconThemeData(
        color: pureBlack,
        size: 24,
      ),
      
      // 分隔線
      dividerTheme: const DividerThemeData(
        color: dividerGray,
        thickness: 0.5,
        space: 1,
      ),
    );
  }


  // Dark Theme - 深邃黑
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: false,  // 關閉 Material 3
      brightness: Brightness.dark,
      
      // 基礎配色
      primaryColor: pureWhite,
      scaffoldBackgroundColor: pureBlack,
      canvasColor: gray950,
      cardColor: gray900,
      dividerColor: gray800,
      
      // 去除水波紋效果，但保留極淡的點擊高亮
      splashFactory: NoSplash.splashFactory,
      highlightColor: const Color(0x0AFFFFFF), // 極淡白色
      splashColor: Colors.transparent,
      hoverColor: Colors.transparent,

      // 頁面轉場動畫 - iOS 滑動風格
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      
      // 字體家族
      fontFamily: fontFamilyChinese,
      fontFamilyFallback: const [fontFamilyEnglish],
      
      // ColorScheme
      colorScheme: const ColorScheme.dark(
        primary: pureWhite,
        secondary: gray300,
        surface: gray900,
        error: gray700,
        onPrimary: pureBlack,
        onSecondary: pureBlack,
        onSurface: pureWhite,
        onError: pureWhite,
      ),
      
      // AppBar - iOS 風格
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: pureWhite,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: TextStyle(
          fontSize: fontSize17,
          fontWeight: weightSemiBold,
          color: pureWhite,
          letterSpacing: -0.4,
        ),
        iconTheme: IconThemeData(
          color: pureWhite,
          size: 22,
        ),
      ),
      
      // Card
      cardTheme: CardThemeData(
        color: gray900,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
      ),
      
      // 按鈕主題
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: pureWhite,
          foregroundColor: pureBlack,
          elevation: 0,
          shadowColor: Colors.transparent,
          splashFactory: NoSplash.splashFactory,
          padding: const EdgeInsets.symmetric(
            horizontal: space24,
            vertical: space14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          textStyle: const TextStyle(
            fontSize: fontSize16,
            fontWeight: weightSemiBold,
            letterSpacing: -0.3,
          ),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: pureWhite,
          splashFactory: NoSplash.splashFactory,
          padding: const EdgeInsets.symmetric(
            horizontal: space16,
            vertical: space10,
          ),
          textStyle: const TextStyle(
            fontSize: fontSize16,
            fontWeight: weightMedium,
            letterSpacing: -0.3,
          ),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: pureWhite,
          side: const BorderSide(color: gray700, width: 1),
          splashFactory: NoSplash.splashFactory,
          padding: const EdgeInsets.symmetric(
            horizontal: space24,
            vertical: space14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          textStyle: const TextStyle(
            fontSize: fontSize16,
            fontWeight: weightMedium,
            letterSpacing: -0.3,
          ),
        ),
      ),
      
      // 輸入框
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: gray850,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: pureWhite, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: space16,
          vertical: space14,
        ),
        hintStyle: const TextStyle(
          color: gray500,
          fontSize: fontSize16,
          fontWeight: weightRegular,
        ),
      ),
      
      // 文字主題
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: fontSize40,
          fontWeight: weightBold,
          color: pureWhite,
          letterSpacing: -1.0,
          height: lineHeightTight,
        ),
        displayMedium: TextStyle(
          fontSize: fontSize36,
          fontWeight: weightBold,
          color: pureWhite,
          letterSpacing: -0.8,
          height: lineHeightTight,
        ),
        displaySmall: TextStyle(
          fontSize: fontSize32,
          fontWeight: weightBold,
          color: pureWhite,
          letterSpacing: -0.6,
          height: lineHeightTight,
        ),
        headlineLarge: TextStyle(
          fontSize: fontSize28,
          fontWeight: weightBold,
          color: pureWhite,
          letterSpacing: -0.5,
          height: lineHeightTight,
        ),
        headlineMedium: TextStyle(
          fontSize: fontSize24,
          fontWeight: weightSemiBold,
          color: pureWhite,
          letterSpacing: -0.4,
          height: lineHeightNormal,
        ),
        headlineSmall: TextStyle(
          fontSize: fontSize20,
          fontWeight: weightSemiBold,
          color: pureWhite,
          letterSpacing: -0.3,
          height: lineHeightNormal,
        ),
        titleLarge: TextStyle(
          fontSize: fontSize18,
          fontWeight: weightSemiBold,
          color: pureWhite,
          letterSpacing: -0.3,
        ),
        titleMedium: TextStyle(
          fontSize: fontSize16,
          fontWeight: weightSemiBold,
          color: pureWhite,
          letterSpacing: -0.2,
        ),
        titleSmall: TextStyle(
          fontSize: fontSize14,
          fontWeight: weightSemiBold,
          color: pureWhite,
          letterSpacing: -0.1,
        ),
        bodyLarge: TextStyle(
          fontSize: fontSize17,
          fontWeight: weightRegular,
          color: pureWhite,
          letterSpacing: -0.4,
          height: lineHeightNormal,
        ),
        bodyMedium: TextStyle(
          fontSize: fontSize15,
          fontWeight: weightRegular,
          color: gray300,
          letterSpacing: -0.2,
          height: lineHeightNormal,
        ),
        bodySmall: TextStyle(
          fontSize: fontSize13,
          fontWeight: weightRegular,
          color: gray400,
          letterSpacing: -0.1,
          height: lineHeightNormal,
        ),
        labelLarge: TextStyle(
          fontSize: fontSize15,
          fontWeight: weightMedium,
          color: pureWhite,
          letterSpacing: -0.2,
        ),
        labelMedium: TextStyle(
          fontSize: fontSize13,
          fontWeight: weightMedium,
          color: gray300,
          letterSpacing: -0.1,
        ),
        labelSmall: TextStyle(
          fontSize: fontSize11,
          fontWeight: weightMedium,
          color: gray400,
          letterSpacing: 0,
        ),
      ),
      
      iconTheme: const IconThemeData(
        color: pureWhite,
        size: 24,
      ),
      
      dividerTheme: const DividerThemeData(
        color: gray800,
        thickness: 0.5,
        space: 1,
      ),
    );
  }
}
