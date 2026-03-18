import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/connectivity_providers.dart';
import '../../core/services/offline_capability_service.dart';
import '../theme/app_theme.dart';

/// Widget that wraps a feature and disables it when offline if required
class OfflineAwareWidget extends ConsumerWidget {
  final OfflineFeature feature;
  final Widget child;
  final Widget? offlineWidget;
  final VoidCallback? onTapWhenOffline;

  const OfflineAwareWidget({
    super.key,
    required this.feature,
    required this.child,
    this.offlineWidget,
    this.onTapWhenOffline,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAvailable = ref.watch(featureAvailabilityProvider(feature));

    if (isAvailable) {
      return child;
    }

    // Feature is not available offline
    if (offlineWidget != null) {
      return offlineWidget!;
    }

    // Default disabled state
    return Opacity(
      opacity: 0.5,
      child: IgnorePointer(
        child: Stack(
          children: [
            child,
            if (onTapWhenOffline != null)
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onTapWhenOffline,
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Button that shows offline message when tapped while offline
class OfflineAwareButton extends ConsumerWidget {
  final OfflineFeature feature;
  final VoidCallback onPressed;
  final Widget child;
  final ButtonStyle? style;

  const OfflineAwareButton({
    super.key,
    required this.feature,
    required this.onPressed,
    required this.child,
    this.style,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAvailable = ref.watch(featureAvailabilityProvider(feature));

    return ElevatedButton(
      onPressed: isAvailable
          ? onPressed
          : () => _showOfflineMessage(context, feature),
      style: style,
      child: child,
    );
  }

  void _showOfflineMessage(BuildContext context, OfflineFeature feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              color: AppTheme.pureWhite,
              size: 20,
            ),
            const SizedBox(width: AppTheme.space12),
            Expanded(
              child: Text(
                '${feature.name}需要網路連線',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.pureWhite,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.gray800,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
      ),
    );
  }
}

/// Icon button that shows offline message when tapped while offline
class OfflineAwareIconButton extends ConsumerWidget {
  final OfflineFeature feature;
  final VoidCallback onPressed;
  final Icon icon;
  final String? tooltip;

  const OfflineAwareIconButton({
    super.key,
    required this.feature,
    required this.onPressed,
    required this.icon,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAvailable = ref.watch(featureAvailabilityProvider(feature));

    return IconButton(
      onPressed: isAvailable
          ? onPressed
          : () => _showOfflineMessage(context, feature),
      icon: Opacity(
        opacity: isAvailable ? 1.0 : 0.5,
        child: icon,
      ),
      tooltip: tooltip,
    );
  }

  void _showOfflineMessage(BuildContext context, OfflineFeature feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              color: AppTheme.pureWhite,
              size: 20,
            ),
            const SizedBox(width: AppTheme.space12),
            Expanded(
              child: Text(
                '${feature.name}需要網路連線',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.pureWhite,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.gray800,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
      ),
    );
  }
}

/// List tile that shows offline indicator when feature is unavailable
class OfflineAwareListTile extends ConsumerWidget {
  final OfflineFeature feature;
  final Widget title;
  final Widget? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;

  const OfflineAwareListTile({
    super.key,
    required this.feature,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAvailable = ref.watch(featureAvailabilityProvider(feature));

    return ListTile(
      title: title,
      subtitle: subtitle,
      leading: leading,
      trailing: isAvailable
          ? trailing
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (trailing != null) ...[
                  trailing!,
                  const SizedBox(width: AppTheme.space8),
                ],
                const Icon(
                  Icons.cloud_off_outlined,
                  size: 16,
                  color: AppTheme.gray400,
                ),
              ],
            ),
      onTap: isAvailable
          ? onTap
          : () => _showOfflineMessage(context, feature),
      enabled: isAvailable,
    );
  }

  void _showOfflineMessage(BuildContext context, OfflineFeature feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              color: AppTheme.pureWhite,
              size: 20,
            ),
            const SizedBox(width: AppTheme.space12),
            Expanded(
              child: Text(
                '${feature.name}需要網路連線',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.pureWhite,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.gray800,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
      ),
    );
  }
}
