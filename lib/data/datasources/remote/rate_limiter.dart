import 'dart:collection';

/// Rate limiter to prevent exceeding API rate limits
class RateLimiter {
  final int maxRequests;
  final Duration window;
  final Queue<DateTime> _requests = Queue();

  RateLimiter({
    required this.maxRequests,
    required this.window,
  });

  /// Acquire permission to make a request
  /// Waits if rate limit would be exceeded
  Future<void> acquire() async {
    _cleanOldRequests();

    if (_requests.length >= maxRequests) {
      final oldestRequest = _requests.first;
      final waitTime = window - DateTime.now().difference(oldestRequest);

      if (waitTime.inMilliseconds > 0) {
        await Future.delayed(waitTime);
        _cleanOldRequests();
      }
    }

    _requests.add(DateTime.now());
  }

  /// Remove requests outside the time window
  void _cleanOldRequests() {
    final now = DateTime.now();
    while (_requests.isNotEmpty) {
      final requestTime = _requests.first;
      if (now.difference(requestTime) > window) {
        _requests.removeFirst();
      } else {
        break;
      }
    }
  }

  /// Get current request count in window
  int get currentCount {
    _cleanOldRequests();
    return _requests.length;
  }

  /// Check if can make request without waiting
  bool get canMakeRequest {
    _cleanOldRequests();
    return _requests.length < maxRequests;
  }

  /// Reset the rate limiter
  void reset() {
    _requests.clear();
  }
}
