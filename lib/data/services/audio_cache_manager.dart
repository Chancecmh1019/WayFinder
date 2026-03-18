import 'dart:io';
import 'dart:async';
import 'package:hive/hive.dart';
import '../../core/utils/logger.dart';

/// Audio cache metadata
class AudioCacheEntry {
  final String lemma;
  final String pronunciationType;
  final String filePath;
  final DateTime cachedAt;
  final int accessCount;
  final DateTime lastAccessedAt;
  final int fileSizeBytes;

  AudioCacheEntry({
    required this.lemma,
    required this.pronunciationType,
    required this.filePath,
    required this.cachedAt,
    this.accessCount = 0,
    required this.lastAccessedAt,
    this.fileSizeBytes = 0,
  });

  Map<String, dynamic> toJson() => {
        'word': lemma,
        'pronunciationType': pronunciationType,
        'filePath': filePath,
        'cachedAt': cachedAt.toIso8601String(),
        'accessCount': accessCount,
        'lastAccessedAt': lastAccessedAt.toIso8601String(),
        'fileSizeBytes': fileSizeBytes,
      };

  factory AudioCacheEntry.fromJson(Map<String, dynamic> json) {
    return AudioCacheEntry(
      lemma: json['word'] as String,
      pronunciationType: json['pronunciationType'] as String,
      filePath: json['filePath'] as String,
      cachedAt: DateTime.parse(json['cachedAt'] as String),
      accessCount: json['accessCount'] as int? ?? 0,
      lastAccessedAt: DateTime.parse(json['lastAccessedAt'] as String),
      fileSizeBytes: json['fileSizeBytes'] as int? ?? 0,
    );
  }

  AudioCacheEntry copyWith({
    int? accessCount,
    DateTime? lastAccessedAt,
    int? fileSizeBytes,
  }) {
    return AudioCacheEntry(
      lemma: lemma,
      pronunciationType: pronunciationType,
      filePath: filePath,
      cachedAt: cachedAt,
      accessCount: accessCount ?? this.accessCount,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
    );
  }

  /// Check if this entry is expired (older than 30 days)
  bool isExpired({Duration maxAge = const Duration(days: 30)}) {
    final now = DateTime.now();
    return now.difference(cachedAt) > maxAge;
  }
}

/// Cache statistics
class AudioCacheStats {
  final int entryCount;
  final int totalSizeBytes;
  final int expiredCount;
  final DateTime? oldestEntryDate;
  final DateTime? newestEntryDate;

  AudioCacheStats({
    required this.entryCount,
    required this.totalSizeBytes,
    required this.expiredCount,
    this.oldestEntryDate,
    this.newestEntryDate,
  });

  /// Get total size in MB
  double get totalSizeMB => totalSizeBytes / (1024 * 1024);

  /// Get percentage of max cache size used
  double getUsagePercentage(int maxSizeBytes) {
    return (totalSizeBytes / maxSizeBytes) * 100;
  }

  @override
  String toString() {
    return 'AudioCacheStats(entries: $entryCount, size: ${totalSizeMB.toStringAsFixed(2)}MB, expired: $expiredCount)';
  }
}

/// Audio cache manager with persistent metadata
/// 
/// Manages audio file caching with:
/// - LRU eviction policy when cache exceeds 100MB
/// - Automatic cleanup of expired entries (30 days)
/// - Thread-safe operations
/// - Cache size monitoring
class AudioCacheManager {
  static const String _boxName = 'audio_cache_metadata';
  static const int maxCacheSizeBytes = 100 * 1024 * 1024; // 100MB
  static const Duration maxCacheAge = Duration(days: 30);
  
  Box<Map>? _cacheBox;
  final _lock = Completer<void>()..complete(); // For thread-safety
  int _cachedTotalSize = 0; // Cached total size to avoid recalculation

  /// Initialize the cache manager
  Future<void> initialize() async {
    try {
      _cacheBox = await Hive.openBox<Map>(_boxName);
      AppLogger.info('Audio cache manager initialized');
      
      // Calculate initial cache size
      await _recalculateTotalSize();
      
      // Clean up invalid and expired entries on startup
      await _cleanupInvalidEntries();
      await cleanupExpiredEntries();
      
      AppLogger.info('Audio cache ready: ${(_cachedTotalSize / (1024 * 1024)).toStringAsFixed(2)}MB');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to initialize audio cache manager', e, stackTrace);
      rethrow;
    }
  }

  /// Recalculate total cache size
  Future<void> _recalculateTotalSize() async {
    int totalSize = 0;
    final entries = getAllEntries();

    for (final entry in entries) {
      if (entry.fileSizeBytes > 0) {
        totalSize += entry.fileSizeBytes;
      } else {
        // If file size not stored, calculate it
        try {
          final file = File(entry.filePath);
          if (await file.exists()) {
            final size = await file.length();
            totalSize += size;
            // Update entry with file size
            final updatedEntry = entry.copyWith(fileSizeBytes: size);
            final cacheKey = '${entry.lemma}_${entry.pronunciationType}';
            await _cacheBox!.put(cacheKey, updatedEntry.toJson());
          }
        } catch (e) {
          AppLogger.warning('Failed to get file size: ${entry.filePath}');
        }
      }
    }

    _cachedTotalSize = totalSize;
  }

  /// Get cache entry for a word
  AudioCacheEntry? getEntry(String cacheKey) {
    if (_cacheBox == null) return null;

    final data = _cacheBox!.get(cacheKey);
    if (data == null) return null;

    try {
      return AudioCacheEntry.fromJson(Map<String, dynamic>.from(data));
    } catch (e) {
      AppLogger.warning('Failed to parse cache entry: $cacheKey - $e');
      return null;
    }
  }

  /// Add or update cache entry (thread-safe)
  Future<void> putEntry(String cacheKey, AudioCacheEntry entry) async {
    if (_cacheBox == null) return;

    // Wait for any ongoing operations
    await _lock.future;

    try {
      // Get file size if not provided
      int fileSize = entry.fileSizeBytes;
      if (fileSize == 0) {
        try {
          final file = File(entry.filePath);
          if (await file.exists()) {
            fileSize = await file.length();
          }
        } catch (e) {
          AppLogger.warning('Failed to get file size: ${entry.filePath}');
        }
      }

      // Update entry with file size
      final updatedEntry = entry.copyWith(fileSizeBytes: fileSize);

      // Check if we need to evict entries to make space
      final existingEntry = getEntry(cacheKey);
      final sizeIncrease = fileSize - (existingEntry?.fileSizeBytes ?? 0);
      
      if (_cachedTotalSize + sizeIncrease > maxCacheSizeBytes) {
        await _evictToMakeSpace(sizeIncrease);
      }

      await _cacheBox!.put(cacheKey, updatedEntry.toJson());
      
      // Update cached total size
      _cachedTotalSize += sizeIncrease;
      
      AppLogger.debug('Cache entry saved: $cacheKey (${(fileSize / 1024).toStringAsFixed(1)}KB)');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to save cache entry', e, stackTrace);
    }
  }

  /// Update access time for cache entry
  Future<void> updateAccess(String cacheKey) async {
    final entry = getEntry(cacheKey);
    if (entry == null) return;

    final updatedEntry = entry.copyWith(
      accessCount: entry.accessCount + 1,
      lastAccessedAt: DateTime.now(),
    );

    await _cacheBox!.put(cacheKey, updatedEntry.toJson());
  }

  /// Remove cache entry
  Future<void> removeEntry(String cacheKey) async {
    if (_cacheBox == null) return;

    try {
      final entry = getEntry(cacheKey);
      if (entry != null) {
        // Delete the audio file
        final file = File(entry.filePath);
        if (await file.exists()) {
          await file.delete();
        }
        
        // Update cached total size
        _cachedTotalSize -= entry.fileSizeBytes;
      }

      await _cacheBox!.delete(cacheKey);
      AppLogger.debug('Cache entry removed: $cacheKey');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to remove cache entry', e, stackTrace);
    }
  }

  /// Get all cache entries
  List<AudioCacheEntry> getAllEntries() {
    if (_cacheBox == null) return [];

    final entries = <AudioCacheEntry>[];
    for (final key in _cacheBox!.keys) {
      final entry = getEntry(key as String);
      if (entry != null) {
        entries.add(entry);
      }
    }

    return entries;
  }

  /// Get cache size (number of entries)
  int getCacheSize() {
    return _cacheBox?.length ?? 0;
  }

  /// Get total cache size in bytes (cached value for performance)
  int getCacheSizeBytes() {
    return _cachedTotalSize;
  }

  /// Get cache statistics
  Future<AudioCacheStats> getStats() async {
    final entries = getAllEntries();
    
    if (entries.isEmpty) {
      return AudioCacheStats(
        entryCount: 0,
        totalSizeBytes: 0,
        expiredCount: 0,
      );
    }

    int expiredCount = 0;
    DateTime? oldestDate;
    DateTime? newestDate;

    for (final entry in entries) {
      if (entry.isExpired(maxAge: maxCacheAge)) {
        expiredCount++;
      }

      if (oldestDate == null || entry.cachedAt.isBefore(oldestDate)) {
        oldestDate = entry.cachedAt;
      }

      if (newestDate == null || entry.cachedAt.isAfter(newestDate)) {
        newestDate = entry.cachedAt;
      }
    }

    return AudioCacheStats(
      entryCount: entries.length,
      totalSizeBytes: _cachedTotalSize,
      expiredCount: expiredCount,
      oldestEntryDate: oldestDate,
      newestEntryDate: newestDate,
    );
  }

  /// Clear all cache entries
  Future<void> clearAll() async {
    if (_cacheBox == null) return;

    try {
      AppLogger.info('Clearing all audio cache entries');

      // Delete all audio files
      final entries = getAllEntries();
      for (final entry in entries) {
        try {
          final file = File(entry.filePath);
          if (await file.exists()) {
            await file.delete();
          }
        } catch (e) {
          AppLogger.warning('Failed to delete file: ${entry.filePath}');
        }
      }

      // Clear metadata
      await _cacheBox!.clear();
      _cachedTotalSize = 0;
      
      AppLogger.info('Audio cache cleared');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to clear cache', e, stackTrace);
    }
  }

  /// Clean up expired entries (older than 30 days)
  Future<int> cleanupExpiredEntries() async {
    if (_cacheBox == null) return 0;

    AppLogger.info('Cleaning up expired cache entries');
    int removedCount = 0;

    final entries = getAllEntries();
    for (final entry in entries) {
      if (entry.isExpired(maxAge: maxCacheAge)) {
        final cacheKey = '${entry.lemma}_${entry.pronunciationType}';
        await removeEntry(cacheKey);
        removedCount++;
      }
    }

    if (removedCount > 0) {
      AppLogger.info('Removed $removedCount expired cache entries');
    }

    return removedCount;
  }

  /// Evict entries to make space for new entry
  Future<void> _evictToMakeSpace(int requiredSpace) async {
    final entries = getAllEntries();
    if (entries.isEmpty) return;

    // Sort by last accessed time (oldest first) - LRU strategy
    entries.sort((a, b) => a.lastAccessedAt.compareTo(b.lastAccessedAt));

    int freedSpace = 0;
    int evictedCount = 0;

    for (final entry in entries) {
      if (_cachedTotalSize - freedSpace + requiredSpace <= maxCacheSizeBytes) {
        break;
      }

      final cacheKey = '${entry.lemma}_${entry.pronunciationType}';
      freedSpace += entry.fileSizeBytes;
      await removeEntry(cacheKey);
      evictedCount++;
    }

    if (evictedCount > 0) {
      AppLogger.info('Evicted $evictedCount entries to free ${(freedSpace / (1024 * 1024)).toStringAsFixed(2)}MB');
    }
  }

  /// Clean up invalid cache entries (files that don't exist)
  Future<void> _cleanupInvalidEntries() async {
    if (_cacheBox == null) return;

    AppLogger.info('Cleaning up invalid cache entries');
    int removedCount = 0;

    final entries = getAllEntries();
    for (final entry in entries) {
      final file = File(entry.filePath);
      if (!await file.exists()) {
        final cacheKey = '${entry.lemma}_${entry.pronunciationType}';
        await _cacheBox!.delete(cacheKey);
        removedCount++;
      }
    }

    if (removedCount > 0) {
      AppLogger.info('Removed $removedCount invalid cache entries');
    }
  }

  /// Close the cache manager
  Future<void> close() async {
    await _cacheBox?.close();
  }
}
