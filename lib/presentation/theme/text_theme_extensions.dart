import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Extension methods for easy access to text styles
extension TextThemeExtensions on BuildContext {
  TextTheme get textTheme => Theme.of(this).textTheme;
  
  // Display styles
  TextStyle get displayLarge => textTheme.displayLarge!;
  TextStyle get displayMedium => textTheme.displayMedium!;
  TextStyle get displaySmall => textTheme.displaySmall!;
  
  // Headline styles
  TextStyle get headlineLarge => textTheme.headlineLarge!;
  TextStyle get headlineMedium => textTheme.headlineMedium!;
  TextStyle get headlineSmall => textTheme.headlineSmall!;
  
  // Title styles
  TextStyle get titleLarge => textTheme.titleLarge!;
  TextStyle get titleMedium => textTheme.titleMedium!;
  TextStyle get titleSmall => textTheme.titleSmall!;
  
  // Body styles
  TextStyle get bodyLarge => textTheme.bodyLarge!;
  TextStyle get bodyMedium => textTheme.bodyMedium!;
  TextStyle get bodySmall => textTheme.bodySmall!;
  
  // Label styles
  TextStyle get labelLarge => textTheme.labelLarge!;
  TextStyle get labelMedium => textTheme.labelMedium!;
  TextStyle get labelSmall => textTheme.labelSmall!;
}

/// Static text style accessors for use outside of BuildContext
class AppTextStyles {
  // Display styles
  static const TextStyle displayLarge = TextStyle(
    fontSize: AppTheme.fontSize40,
    fontWeight: AppTheme.weightBold,
    color: AppTheme.pureBlack,
    letterSpacing: -1.0,
    height: AppTheme.lineHeightTight,
  );
  
  static const TextStyle displayMedium = TextStyle(
    fontSize: AppTheme.fontSize36,
    fontWeight: AppTheme.weightBold,
    color: AppTheme.pureBlack,
    letterSpacing: -0.8,
    height: AppTheme.lineHeightTight,
  );
  
  static const TextStyle displaySmall = TextStyle(
    fontSize: AppTheme.fontSize32,
    fontWeight: AppTheme.weightBold,
    color: AppTheme.pureBlack,
    letterSpacing: -0.6,
    height: AppTheme.lineHeightTight,
  );
  
  // Headline styles
  static const TextStyle headlineLarge = TextStyle(
    fontSize: AppTheme.fontSize28,
    fontWeight: AppTheme.weightBold,
    color: AppTheme.pureBlack,
    letterSpacing: -0.5,
    height: AppTheme.lineHeightTight,
  );
  
  static const TextStyle headlineMedium = TextStyle(
    fontSize: AppTheme.fontSize24,
    fontWeight: AppTheme.weightSemiBold,
    color: AppTheme.pureBlack,
    letterSpacing: -0.4,
    height: AppTheme.lineHeightNormal,
  );
  
  static const TextStyle headlineSmall = TextStyle(
    fontSize: AppTheme.fontSize20,
    fontWeight: AppTheme.weightSemiBold,
    color: AppTheme.pureBlack,
    letterSpacing: -0.3,
    height: AppTheme.lineHeightNormal,
  );
  
  // Title styles
  static const TextStyle titleLarge = TextStyle(
    fontSize: AppTheme.fontSize18,
    fontWeight: AppTheme.weightSemiBold,
    color: AppTheme.pureBlack,
    letterSpacing: -0.3,
  );
  
  static const TextStyle titleMedium = TextStyle(
    fontSize: AppTheme.fontSize16,
    fontWeight: AppTheme.weightSemiBold,
    color: AppTheme.pureBlack,
    letterSpacing: -0.2,
  );
  
  static const TextStyle titleSmall = TextStyle(
    fontSize: AppTheme.fontSize14,
    fontWeight: AppTheme.weightSemiBold,
    color: AppTheme.pureBlack,
    letterSpacing: -0.1,
  );
  
  // Body styles
  static const TextStyle bodyLarge = TextStyle(
    fontSize: AppTheme.fontSize17,
    fontWeight: AppTheme.weightRegular,
    color: AppTheme.pureBlack,
    letterSpacing: -0.4,
    height: AppTheme.lineHeightNormal,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontSize: AppTheme.fontSize15,
    fontWeight: AppTheme.weightRegular,
    color: AppTheme.gray700,
    letterSpacing: -0.2,
    height: AppTheme.lineHeightNormal,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontSize: AppTheme.fontSize13,
    fontWeight: AppTheme.weightRegular,
    color: AppTheme.gray600,
    letterSpacing: -0.1,
    height: AppTheme.lineHeightNormal,
  );
  
  // Label styles
  static const TextStyle labelLarge = TextStyle(
    fontSize: AppTheme.fontSize15,
    fontWeight: AppTheme.weightMedium,
    color: AppTheme.pureBlack,
    letterSpacing: -0.2,
  );
  
  static const TextStyle labelMedium = TextStyle(
    fontSize: AppTheme.fontSize13,
    fontWeight: AppTheme.weightMedium,
    color: AppTheme.gray700,
    letterSpacing: -0.1,
  );
  
  static const TextStyle labelSmall = TextStyle(
    fontSize: AppTheme.fontSize11,
    fontWeight: AppTheme.weightMedium,
    color: AppTheme.gray600,
    letterSpacing: 0,
  );
}
