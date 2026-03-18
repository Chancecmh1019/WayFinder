import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/connectivity_providers.dart';
import '../theme/app_theme.dart';

/// Widget that displays an offline mode indicator banner
class OfflineIndicator extends ConsumerWidget {
  const OfflineIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOffline = ref.watch(isOfflineProvider);
    final displayName = ref.watch(connectivityDisplayNameProvider);

    if (!isOffline) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space16,
        vertical: AppTheme.space8,
      ),
      decoration: BoxDecoration(
        color: AppTheme.gray800,
        boxShadow: AppTheme.subtleShadow,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            size: 16,
            color: AppTheme.pureWhite,
          ),
          const SizedBox(width: AppTheme.space8),
          Text(
            '$displayName模式',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppTheme.pureWhite,
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact offline indicator for use in app bars
class CompactOfflineIndicator extends ConsumerWidget {
  const CompactOfflineIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOffline = ref.watch(isOfflineProvider);

    if (!isOffline) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space8,
        vertical: AppTheme.space4,
      ),
      decoration: BoxDecoration(
        color: AppTheme.gray700,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            size: 12,
            color: AppTheme.pureWhite,
          ),
          const SizedBox(width: AppTheme.space4),
          Text(
            '離線',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppTheme.pureWhite,
            ),
          ),
        ],
      ),
    );
  }
}

/// Snackbar notification for connectivity changes
class ConnectivitySnackbar {
  static void show(BuildContext context, bool isOffline) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isOffline ? Icons.cloud_off_outlined : Icons.cloud_done_outlined,
              color: AppTheme.pureWhite,
              size: 20,
            ),
            const SizedBox(width: AppTheme.space12),
            Expanded(
              child: Text(
                isOffline
                    ? '已切換至離線模式'
                    : '網路連線已恢復',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.pureWhite,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isOffline ? AppTheme.gray800 : AppTheme.pureBlack,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
      ),
    );
  }
}
