import 'package:flutter/foundation.dart';

class AppLogger {
  static void info(String message) {
    if (kDebugMode) debugPrint('[INFO] $message');
  }

  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('[ERROR] $message${error != null ? ': $error' : ''}');
      if (stackTrace != null) {
        debugPrint('[ERROR] Stack trace: $stackTrace');
      }
    }
  }

  static void debug(String message) {
    if (kDebugMode) debugPrint('[DEBUG] $message');
  }

  static void warning(String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('[WARN] $message${error != null ? ': $error' : ''}');
      if (stackTrace != null) {
        debugPrint('[WARN] Stack trace: $stackTrace');
      }
    }
  }

  static void fatal(String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('[FATAL] $message${error != null ? ': $error' : ''}');
      if (stackTrace != null) {
        debugPrint('[FATAL] Stack trace: $stackTrace');
      }
    }
  }
}
