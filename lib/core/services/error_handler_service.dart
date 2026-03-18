import 'dart:async';
import 'package:flutter/foundation.dart';
import '../errors/failures.dart';
import '../errors/exceptions.dart';
import '../utils/logger.dart';

/// Stub for FirebaseCrashlytics (not used in local-only version)
class _FirebaseCrashlyticsStub {
  Future<void> setCrashlyticsCollectionEnabled(bool enabled) async {}
  void recordFlutterFatalError(FlutterErrorDetails details) {}
  void recordError(dynamic error, StackTrace? stack, {bool fatal = false, String? reason, List<String>? information}) {}
  Future<void> setCustomKey(String key, dynamic value) async {}
  Future<void> setUserIdentifier(String userId) async {}
  Future<void> log(String message) async {}
}

/// Global error handler service
class ErrorHandlerService {
  static ErrorHandlerService? _instance;
  final _FirebaseCrashlyticsStub? _crashlytics;
  
  ErrorHandlerService._({_FirebaseCrashlyticsStub? crashlytics})
      : _crashlytics = crashlytics;

  /// Get singleton instance
  static ErrorHandlerService get instance {
    _instance ??= ErrorHandlerService._();
    return _instance!;
  }

  /// Initialize error handler with Firebase Crashlytics
  static Future<void> initialize({
    bool enableCrashlytics = false, // Disabled by default for local-only version
  }) async {
    try {
      _FirebaseCrashlyticsStub? crashlytics;
      
      if (enableCrashlytics) {
        crashlytics = _FirebaseCrashlyticsStub();
        
        // Enable crash collection
        crashlytics.setCrashlyticsCollectionEnabled(true);
        
        // Pass all uncaught errors to Crashlytics
        FlutterError.onError = (FlutterErrorDetails details) {
          crashlytics!.recordFlutterFatalError(details);
          AppLogger.fatal(
            'Flutter fatal error',
            details.exception,
            details.stack,
          );
        };
        
        // Pass all uncaught asynchronous errors to Crashlytics
        PlatformDispatcher.instance.onError = (error, stack) {
          crashlytics!.recordError(error, stack, fatal: true);
          AppLogger.fatal('Uncaught async error', error, stack);
          return true;
        };
        
        AppLogger.info('Error handler initialized (local mode)');
      }
      
      _instance = ErrorHandlerService._(crashlytics: crashlytics);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to initialize ErrorHandlerService', e, stackTrace);
    }
  }

  /// Record a non-fatal error
  Future<void> recordError(
    dynamic error,
    StackTrace? stackTrace, {
    String? reason,
    Map<String, dynamic>? context,
  }) async {
    try {
      // Log to console
      AppLogger.error(reason ?? 'Error occurred', error, stackTrace);
      
      // Record to Crashlytics
      if (_crashlytics != null) {
        _crashlytics.recordError(
          error,
          stackTrace,
          reason: reason,
          information: context?.entries.map((e) => '${e.key}: ${e.value}').toList() ?? [],
          fatal: false,
        );
      }
    } catch (e) {
      AppLogger.error('Failed to record error', e);
    }
  }

  /// Record a fatal error
  Future<void> recordFatalError(
    dynamic error,
    StackTrace? stackTrace, {
    String? reason,
  }) async {
    try {
      // Log to console
      AppLogger.fatal(reason ?? 'Fatal error occurred', error, stackTrace);
      
      // Record to Crashlytics
      if (_crashlytics != null) {
        _crashlytics.recordError(
          error,
          stackTrace,
          reason: reason,
          fatal: true,
        );
      }
    } catch (e) {
      AppLogger.error('Failed to record fatal error', e);
    }
  }

  /// Set custom key-value pairs for crash reports
  Future<void> setCustomKey(String key, dynamic value) async {
    try {
      if (_crashlytics != null) {
        await _crashlytics.setCustomKey(key, value);
      }
    } catch (e) {
      AppLogger.error('Failed to set custom key', e);
    }
  }

  /// Set user identifier for crash reports
  Future<void> setUserIdentifier(String userId) async {
    try {
      if (_crashlytics != null) {
        await _crashlytics.setUserIdentifier(userId);
      }
      AppLogger.info('User identifier set: $userId');
    } catch (e) {
      AppLogger.error('Failed to set user identifier', e);
    }
  }

  /// Log a message to crash reports
  Future<void> log(String message) async {
    try {
      if (_crashlytics != null) {
        await _crashlytics.log(message);
      }
      AppLogger.debug(message);
    } catch (e) {
      AppLogger.error('Failed to log message', e);
    }
  }

  /// Handle a failure and return user-friendly message
  String handleFailure(Failure failure) {
    AppLogger.error('Handling failure', failure, failure.stackTrace);
    
    // Record to Crashlytics
    recordError(
      failure,
      failure.stackTrace,
      reason: 'Failure: ${failure.runtimeType}',
    );
    
    // Return user-friendly message
    return _getFailureMessage(failure);
  }

  /// Handle an exception and return user-friendly message
  String handleException(Exception exception, [StackTrace? stackTrace]) {
    AppLogger.error('Handling exception', exception, stackTrace);
    
    // Record to Crashlytics
    recordError(
      exception,
      stackTrace,
      reason: 'Exception: ${exception.runtimeType}',
    );
    
    // Return user-friendly message
    return _getExceptionMessage(exception);
  }

  /// Get user-friendly message for failure
  String _getFailureMessage(Failure failure) {
    if (failure is NetworkFailure) {
      return '網路連線失敗，請檢查您的網路設定';
    } else if (failure is ServerFailure) {
      return '伺服器錯誤，請稍後再試';
    } else if (failure is CacheFailure) {
      return '快取錯誤，請清除應用程式資料';
    } else if (failure is DatabaseFailure) {
      return '資料庫錯誤，請重新啟動應用程式';
    } else if (failure is AuthFailure) {
      return '認證失敗，請重新登入';
    } else if (failure is ValidationFailure) {
      return '輸入資料無效，請檢查後重試';
    } else if (failure is NotFoundFailure) {
      return '找不到請求的資料';
    } else if (failure is SyncFailure) {
      return '同步失敗，將在下次連線時重試';
    }
    
    return failure.message.isNotEmpty 
        ? failure.message 
        : '發生錯誤，請稍後再試';
  }

  /// Get user-friendly message for exception
  String _getExceptionMessage(Exception exception) {
    if (exception is NetworkException) {
      return '網路連線失敗，請檢查您的網路設定';
    } else if (exception is ServerException) {
      return '伺服器錯誤，請稍後再試';
    } else if (exception is CacheException) {
      return '快取錯誤，請清除應用程式資料';
    } else if (exception is DatabaseException) {
      return '資料庫錯誤，請重新啟動應用程式';
    } else if (exception is AuthException) {
      return '認證失敗，請重新登入';
    } else if (exception is ValidationException) {
      return '輸入資料無效，請檢查後重試';
    } else if (exception is NotFoundException) {
      return '找不到請求的資料';
    }
    
    return '發生錯誤，請稍後再試';
  }

  /// Show error dialog helper
  static void showErrorDialog({
    required String title,
    required String message,
    VoidCallback? onRetry,
  }) {
    // This would be implemented in the UI layer
    AppLogger.error('Error dialog: $title - $message');
  }

  /// Show error snackbar helper
  static void showErrorSnackbar({
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    // This would be implemented in the UI layer
    AppLogger.error('Error snackbar: $message');
  }
}

/// Extension for handling errors in async operations
extension ErrorHandlerExtension on Future {
  /// Handle errors with automatic logging and user-friendly messages
  Future<T> handleErrors<T>({
    String? context,
    T Function(Object error)? onError,
  }) async {
    try {
      return await this as T;
    } catch (error, stackTrace) {
      ErrorHandlerService.instance.recordError(
        error,
        stackTrace,
        reason: context,
      );
      
      if (onError != null) {
        return onError(error);
      }
      
      rethrow;
    }
  }
}
