import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// iOS 風格底部導航欄
/// 
/// 設計要點：
/// - 高度 56px + SafeArea
/// - 背景半透明白色/黑色 + 高斯模糊 (Glassmorphism)
/// - 圖標大小 24px
/// - 選中狀態 pureBlack/pureWhite，未選中 gray400/gray500
/// - 無陰影、極簡分隔線
/// - 圓角圖標設計
class AppBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // 使用 ClipRect 裁切模糊效果，防止溢出
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
        child: Container(
          decoration: BoxDecoration(
            color: isDark 
                ? const Color(0xCC000000)  // 半透明黑 (~80%)
                : const Color(0xCCFFFFFF), // 半透明白 (~80%)
            border: Border(
              top: BorderSide(
                color: isDark ? AppTheme.gray800 : AppTheme.dividerGray,
                width: 0.5,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 56, // iOS 標準高度通常較矮，Flutter Material 預設是 56，也可以設為 49 但 56 較舒適
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(
                    context: context,
                    icon: Icons.home_rounded,
                    activeIcon: Icons.home_filled,
                    label: '首頁',
                    index: 0,
                    isDark: isDark,
                  ),
                  _buildNavItem(
                    context: context,
                    icon: Icons.explore_outlined,
                    activeIcon: Icons.explore,
                    label: '探索',
                    index: 1,
                    isDark: isDark,
                  ),
                  _buildNavItem(
                    context: context,
                    icon: Icons.bar_chart_rounded,
                    activeIcon: Icons.bar_chart,
                    label: '統計',
                    index: 2,
                    isDark: isDark,
                  ),
                  _buildNavItem(
                    context: context,
                    icon: Icons.settings_outlined,
                    activeIcon: Icons.settings_rounded,
                    label: '設定',
                    index: 3,
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
    required bool isDark,
  }) {
    final isSelected = currentIndex == index;
    final color = isSelected 
        ? (isDark ? AppTheme.pureWhite : AppTheme.pureBlack)
        : (isDark ? AppTheme.gray500 : AppTheme.gray400);

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onTap(index),
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent, // Disable default highlights
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: AppTheme.space8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isSelected ? activeIcon : icon,
                  size: 24,
                  color: color,
                ),
                const SizedBox(height: AppTheme.space2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: AppTheme.fontSize11,
                    fontWeight: isSelected
                        ? AppTheme.weightMedium
                        : AppTheme.weightRegular,
                    color: color,
                    letterSpacing: -0.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
