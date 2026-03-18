import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';

/// Account management screen (本地版本)
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.pureBlack : AppTheme.offWhite,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              backgroundColor: isDark ? AppTheme.pureBlack : AppTheme.offWhite,
              elevation: 0,
              pinned: true,
              title: Text(
                '帳號',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),

            // Content
            SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: AppTheme.space24),

                // User info card
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: AppTheme.space16),
                  padding: const EdgeInsets.all(AppTheme.space24),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.gray900 : AppTheme.pureWhite,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: Column(
                    children: [
                      // Avatar
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.gray800 : AppTheme.gray100,
                          borderRadius: BorderRadius.circular(AppTheme.radiusRound),
                        ),
                        child: Icon(
                          Icons.person,
                          size: 32,
                          color: isDark ? AppTheme.gray600 : AppTheme.gray400,
                        ),
                      ),
                      const SizedBox(height: AppTheme.space16),

                      // Name
                      Text(
                        '本地用戶',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: AppTheme.space4),

                      // Info
                      Text(
                        '本地儲存模式',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isDark ? AppTheme.gray400 : AppTheme.gray600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppTheme.space32),

                // Info section
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: AppTheme.space16),
                  padding: const EdgeInsets.all(AppTheme.space20),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.gray900 : AppTheme.pureWhite,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 20,
                            color: isDark ? AppTheme.gray400 : AppTheme.gray600,
                          ),
                          const SizedBox(width: AppTheme.space8),
                          Text(
                            '關於本地儲存',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.space12),
                      Text(
                        '您的所有學習數據都儲存在本地裝置上。\n\n'
                        '• 無需登入即可使用所有功能\n'
                        '• 數據僅存在於此裝置\n'
                        '• 刪除應用程式會清除所有數據\n'
                        '• 無法在多個裝置間同步',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isDark ? AppTheme.gray400 : AppTheme.gray600,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppTheme.space32),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
