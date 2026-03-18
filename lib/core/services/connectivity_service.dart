import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../utils/logger.dart';

/// Service for monitoring network connectivity status
class ConnectivityService {
  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  final _controller = StreamController<ConnectivityStatus>.broadcast();

  ConnectivityService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  /// Stream of connectivity status changes
  Stream<ConnectivityStatus> get statusStream => _controller.stream;

  /// Check current connectivity status
  Future<ConnectivityStatus> checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      final status = _mapResultsToStatus(results);
      AppLogger.debug('Current connectivity status: $status');
      return status;
    } catch (e, stackTrace) {
      AppLogger.error('Error checking connectivity', e, stackTrace);
      return ConnectivityStatus.offline;
    }
  }

  /// Start monitoring connectivity changes
  void startMonitoring() {
    AppLogger.info('Starting connectivity monitoring');
    _subscription?.cancel();
    
    _subscription = _connectivity.onConnectivityChanged.listen(
      (results) {
        final status = _mapResultsToStatus(results);
        AppLogger.info('Connectivity changed: $status');
        _controller.add(status);
      },
      onError: (error, stackTrace) {
        AppLogger.error('Error in connectivity stream', error, stackTrace);
        _controller.add(ConnectivityStatus.offline);
      },
    );
  }

  /// Stop monitoring connectivity changes
  void stopMonitoring() {
    AppLogger.info('Stopping connectivity monitoring');
    _subscription?.cancel();
    _subscription = null;
  }

  /// Map connectivity results to status
  ConnectivityStatus _mapResultsToStatus(List<ConnectivityResult> results) {
    if (results.isEmpty || results.contains(ConnectivityResult.none)) {
      return ConnectivityStatus.offline;
    }
    
    if (results.contains(ConnectivityResult.wifi)) {
      return ConnectivityStatus.wifi;
    }
    
    if (results.contains(ConnectivityResult.mobile)) {
      return ConnectivityStatus.mobile;
    }
    
    if (results.contains(ConnectivityResult.ethernet)) {
      return ConnectivityStatus.ethernet;
    }
    
    return ConnectivityStatus.online;
  }

  /// Dispose resources
  void dispose() {
    stopMonitoring();
    _controller.close();
  }
}

/// Connectivity status enum
enum ConnectivityStatus {
  online,
  offline,
  wifi,
  mobile,
  ethernet;

  bool get isOnline => this != ConnectivityStatus.offline;
  bool get isOffline => this == ConnectivityStatus.offline;
  
  String get displayName {
    switch (this) {
      case ConnectivityStatus.online:
        return '線上';
      case ConnectivityStatus.offline:
        return '離線';
      case ConnectivityStatus.wifi:
        return 'Wi-Fi';
      case ConnectivityStatus.mobile:
        return '行動網路';
      case ConnectivityStatus.ethernet:
        return '乙太網路';
    }
  }
}
