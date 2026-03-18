import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/connectivity_service.dart';
import '../services/offline_capability_service.dart';

/// Provider for ConnectivityService instance
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final service = ConnectivityService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Provider for OfflineCapabilityService instance
final offlineCapabilityServiceProvider = Provider<OfflineCapabilityService>((ref) {
  final connectivityService = ref.watch(connectivityServiceProvider);
  return OfflineCapabilityService(connectivityService: connectivityService);
});

/// Provider for current connectivity status
final connectivityStatusProvider = StreamProvider<ConnectivityStatus>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  service.startMonitoring();
  return service.statusStream;
});

/// Provider for checking if device is online
final isOnlineProvider = Provider<bool>((ref) {
  final statusAsync = ref.watch(connectivityStatusProvider);
  return statusAsync.when(
    data: (status) => status.isOnline,
    loading: () => true, // Assume online while loading
    error: (_, _) => false, // Assume offline on error
  );
});

/// Provider for checking if device is offline
final isOfflineProvider = Provider<bool>((ref) {
  return !ref.watch(isOnlineProvider);
});

/// Provider for connectivity status display name
final connectivityDisplayNameProvider = Provider<String>((ref) {
  final statusAsync = ref.watch(connectivityStatusProvider);
  return statusAsync.when(
    data: (status) => status.displayName,
    loading: () => '檢查中...',
    error: (_, _) => '未知',
  );
});


/// Provider for checking if a specific feature is available
final featureAvailabilityProvider = Provider.family<bool, OfflineFeature>((ref, feature) {
  final isOnline = ref.watch(isOnlineProvider);
  
  // If feature is available offline, always return true
  if (feature.isAvailableOffline) {
    return true;
  }
  
  // If feature requires network, check connectivity
  return isOnline;
});

/// Provider for getting list of unavailable features
final unavailableFeaturesProvider = Provider<List<OfflineFeature>>((ref) {
  final isOnline = ref.watch(isOnlineProvider);
  
  if (isOnline) {
    return [];
  }
  
  // Return all features that require network
  return OfflineFeature.values
      .where((feature) => !feature.isAvailableOffline)
      .toList();
});

/// Provider for offline validation result
final offlineValidationProvider = FutureProvider<OfflineValidationResult>((ref) async {
  final service = ref.watch(offlineCapabilityServiceProvider);
  return await service.validateOfflineCapabilities();
});
