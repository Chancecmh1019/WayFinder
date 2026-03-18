import 'dart:convert';
import 'package:hive/hive.dart';
import '../../../core/errors/exceptions.dart';

/// Cached API response
class CachedResponse {
  final String key;
  final dynamic data;
  final DateTime cachedAt;
  final Duration ttl;

  CachedResponse({
    required this.key,
    required this.data,
    required this.cachedAt,
    required this.ttl,
  });

  bool get isExpired =>
      DateTime.now().difference(cachedAt) > ttl;

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'data': data,
      'cachedAt': cachedAt.toIso8601String(),
      'ttl': ttl.inSeconds,
    };
  }

  factory CachedResponse.fromJson(Map<String, dynamic> json) {
    return CachedResponse(
      key: json['key'] as String,
      data: json['data'],
      cachedAt: DateTime.parse(json['cachedAt'] as String),
      ttl: Duration(seconds: json['ttl'] as int),
    );
  }
}

/// Manager for API response caching
class APICacheManager {
  static const String _boxName = 'api_cache';
  Box<String>? _box;

  /// Initialize the cache
  Future<void> initialize() async {
    if (_box != null) return;

    try {
      _box = await Hive.openBox<String>(_boxName);
    } catch (e) {
      throw CacheException('Failed to initialize API cache: $e');
    }
  }

  /// Get cached response
  Future<T?> get<T>(String key) async {
    await _ensureInitialized();

    try {
      final jsonString = _box!.get(key);
      if (jsonString == null) return null;

      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final cached = CachedResponse.fromJson(json);

      // Check if expired
      if (cached.isExpired) {
        await delete(key);
        return null;
      }

      return cached.data as T;
    } catch (e) {
      // If error parsing, delete the corrupted cache
      await delete(key);
      return null;
    }
  }

  /// Put response in cache
  Future<void> put(
    String key,
    dynamic data, {
    required Duration ttl,
  }) async {
    await _ensureInitialized();

    try {
      final cached = CachedResponse(
        key: key,
        data: data,
        cachedAt: DateTime.now(),
        ttl: ttl,
      );

      final jsonString = jsonEncode(cached.toJson());
      await _box!.put(key, jsonString);
    } catch (e) {
      throw CacheException('Failed to cache response: $e');
    }
  }

  /// Delete cached response
  Future<void> delete(String key) async {
    await _ensureInitialized();
    await _box!.delete(key);
  }

  /// Clear all cache
  Future<void> clearAll() async {
    await _ensureInitialized();
    await _box!.clear();
  }

  /// Clear expired cache entries
  Future<void> clearExpired() async {
    await _ensureInitialized();

    final keysToDelete = <String>[];

    for (final key in _box!.keys) {
      try {
        final jsonString = _box!.get(key);
        if (jsonString == null) continue;

        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        final cached = CachedResponse.fromJson(json);

        if (cached.isExpired) {
          keysToDelete.add(key);
        }
      } catch (e) {
        // If error parsing, mark for deletion
        keysToDelete.add(key);
      }
    }

    for (final key in keysToDelete) {
      await _box!.delete(key);
    }
  }

  /// Get cache size (number of entries)
  int get size => _box?.length ?? 0;

  /// Check if key exists and is not expired
  Future<bool> has(String key) async {
    final data = await get(key);
    return data != null;
  }

  /// Generate cache key from endpoint and parameters
  static String generateKey(String endpoint, Map<String, dynamic>? params) {
    if (params == null || params.isEmpty) {
      return endpoint;
    }

    final sortedParams = Map.fromEntries(
      params.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );

    final paramsString = sortedParams.entries
        .map((e) => '${e.key}=${e.value}')
        .join('&');

    return '$endpoint?$paramsString';
  }

  Future<void> _ensureInitialized() async {
    if (_box == null) {
      await initialize();
    }
  }
}

/// Cache configuration for different APIs
class CacheConfig {
  static const Duration datamuseTTL = Duration(days: 7);
  static const Duration wiktionaryTTL = Duration(days: 30);
  static const Duration tatoebaTTL = Duration(days: 30);

  /// Get TTL for specific API
  static Duration getTTL(String apiName) {
    switch (apiName.toLowerCase()) {
      case 'datamuse':
        return datamuseTTL;
      case 'wiktionary':
        return wiktionaryTTL;
      case 'tatoeba':
        return tatoebaTTL;
      default:
        return const Duration(days: 7); // Default TTL
    }
  }
}
