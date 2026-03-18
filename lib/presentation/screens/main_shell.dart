import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import 'home/home_screen.dart';
import 'browse/browse_screen.dart';
import 'study/study_hub_screen.dart';
import 'grammar/grammar_screen.dart';
import 'stats/stats_screen.dart';

final _currentTabProvider = StateProvider<int>((_) => 0);

class MainShell extends ConsumerWidget {
  const MainShell({super.key});

  static const _pages = [
    HomeScreen(),
    BrowseScreen(),
    StudyHubScreen(),
    GrammarScreen(),
    StatsScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark     = Theme.of(context).brightness == Brightness.dark;
    final currentTab = ref.watch(_currentTabProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: isDark ? AppTheme.pureBlack : AppTheme.offWhite,
        body: IndexedStack(index: currentTab, children: _pages),
        bottomNavigationBar: _NavBar(
          currentIndex: currentTab,
          isDark: isDark,
          onTap: (i) {
            HapticFeedback.selectionClick();
            ref.read(_currentTabProvider.notifier).state = i;
          },
        ),
      ),
    );
  }
}

class _NavBar extends StatelessWidget {
  final int currentIndex;
  final bool isDark;
  final ValueChanged<int> onTap;
  const _NavBar({required this.currentIndex, required this.isDark, required this.onTap});

  static const _items = [
    _NavItem('首頁',  Icons.home_outlined,        Icons.home_rounded),
    _NavItem('字彙庫', Icons.library_books_outlined, Icons.library_books_rounded),
    _NavItem('學習',  Icons.school_outlined,       Icons.school_rounded),
    _NavItem('文法',  Icons.menu_book_outlined,    Icons.menu_book_rounded),
    _NavItem('統計',  Icons.bar_chart_outlined,    Icons.bar_chart_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final bg       = isDark ? AppTheme.gray950    : AppTheme.pureWhite;
    final border   = isDark ? AppTheme.gray800    : const Color(0xFFEAEAEA);
    final active   = isDark ? AppTheme.pureWhite  : AppTheme.pureBlack;
    final inactive = isDark ? AppTheme.gray600    : AppTheme.gray400;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        border: Border(top: BorderSide(color: border, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: List.generate(_items.length, (i) {
              final sel = i == currentIndex;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(sel ? _items[i].activeIcon : _items[i].icon,
                          size: 22, color: sel ? active : inactive),
                      const SizedBox(height: 3),
                      Text(_items[i].label,
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamilyChinese,
                            fontSize: 10,
                            fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                            color: sel ? active : inactive,
                            letterSpacing: 0.3,
                          )),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon, activeIcon;
  const _NavItem(this.label, this.icon, this.activeIcon);
}
