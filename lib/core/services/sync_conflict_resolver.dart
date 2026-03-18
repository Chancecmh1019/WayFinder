import '../utils/logger.dart';
import '../../data/models/learning_progress_model.dart';
import '../../data/models/review_history_model.dart';

/// Service for resolving sync conflicts between local and remote data
class SyncConflictResolver {
  /// Resolve conflict between local and remote learning progress
  LearningProgressModel resolveProgressConflict({
    required LearningProgressModel local,
    required LearningProgressModel remote,
    ConflictResolutionStrategy strategy = ConflictResolutionStrategy.latestTimestamp,
  }) {
    AppLogger.info('Resolving progress conflict for word: ${local.word}');
    AppLogger.debug('Local updated: ${local.updatedAt}, Remote updated: ${remote.updatedAt}');

    switch (strategy) {
      case ConflictResolutionStrategy.latestTimestamp:
        return _resolveByLatestTimestamp(local, remote);
      
      case ConflictResolutionStrategy.mostProgress:
        return _resolveByMostProgress(local, remote);
      
      case ConflictResolutionStrategy.localWins:
        AppLogger.info('Conflict resolved: local wins');
        return local;
      
      case ConflictResolutionStrategy.remoteWins:
        AppLogger.info('Conflict resolved: remote wins');
        return remote;
      
      case ConflictResolutionStrategy.merge:
        return _mergeProgress(local, remote);
    }
  }

  /// Resolve by latest timestamp (default strategy)
  LearningProgressModel _resolveByLatestTimestamp(
    LearningProgressModel local,
    LearningProgressModel remote,
  ) {
    final result = local.updatedAt.isAfter(remote.updatedAt) ? local : remote;
    AppLogger.info('Conflict resolved: latest timestamp (${result.updatedAt})');
    return result;
  }

  /// Resolve by most progress (higher proficiency level)
  LearningProgressModel _resolveByMostProgress(
    LearningProgressModel local,
    LearningProgressModel remote,
  ) {
    // Compare proficiency levels
    if (local.proficiencyLevel != remote.proficiencyLevel) {
      final result = local.proficiencyLevel > remote.proficiencyLevel ? local : remote;
      AppLogger.info('Conflict resolved: most progress (proficiency ${result.proficiencyLevel})');
      return result;
    }

    // If same proficiency, compare repetitions
    if (local.repetitions != remote.repetitions) {
      final result = local.repetitions > remote.repetitions ? local : remote;
      AppLogger.info('Conflict resolved: most progress (repetitions ${result.repetitions})');
      return result;
    }

    // If same repetitions, use latest timestamp
    return _resolveByLatestTimestamp(local, remote);
  }

  /// Merge progress data (take best of both)
  LearningProgressModel _mergeProgress(
    LearningProgressModel local,
    LearningProgressModel remote,
  ) {
    AppLogger.info('Conflict resolved: merge');

    // Take the higher proficiency level
    final proficiencyLevel = local.proficiencyLevel > remote.proficiencyLevel
        ? local.proficiencyLevel
        : remote.proficiencyLevel;

    // Take the higher repetitions
    final repetitions = local.repetitions > remote.repetitions
        ? local.repetitions
        : remote.repetitions;

    // Take the longer interval
    final interval = local.interval > remote.interval
        ? local.interval
        : remote.interval;

    // Take the higher ease factor
    final easeFactor = local.easeFactor > remote.easeFactor
        ? local.easeFactor
        : remote.easeFactor;

    // Take the earlier next review date (more conservative)
    final nextReviewDate = local.nextReviewDate.isBefore(remote.nextReviewDate)
        ? local.nextReviewDate
        : remote.nextReviewDate;

    // Take the later last review date
    final lastReviewDate = local.lastReviewDate.isAfter(remote.lastReviewDate)
        ? local.lastReviewDate
        : remote.lastReviewDate;

    // Merge review history (combine both)
    final mergedHistory = <ReviewHistoryModel>[
      ...local.history,
      ...remote.history,
    ];
    
    // Sort by review date and remove duplicates
    mergedHistory.sort((a, b) => a.reviewDate.compareTo(b.reviewDate));
    final uniqueHistory = _removeDuplicateReviews(mergedHistory);

    // Use latest timestamp
    final updatedAt = local.updatedAt.isAfter(remote.updatedAt)
        ? local.updatedAt
        : remote.updatedAt;

    return LearningProgressModel(
      userId: local.userId,
      word: local.word,
      repetitions: repetitions,
      interval: interval,
      easeFactor: easeFactor,
      nextReviewDate: nextReviewDate,
      lastReviewDate: lastReviewDate,
      proficiencyLevel: proficiencyLevel,
      history: uniqueHistory,
      updatedAt: updatedAt,
    );
  }

  /// Remove duplicate review entries
  List<ReviewHistoryModel> _removeDuplicateReviews(
    List<ReviewHistoryModel> history,
  ) {
    final seen = <String>{};
    final unique = <ReviewHistoryModel>[];

    for (final review in history) {
      final key = '${review.reviewDate.millisecondsSinceEpoch}_${review.quality}';
      if (!seen.contains(key)) {
        seen.add(key);
        unique.add(review);
      }
    }

    return unique;
  }

  /// Detect if there's a conflict between local and remote data
  bool hasConflict({
    required LearningProgressModel local,
    required LearningProgressModel remote,
  }) {
    // No conflict if timestamps are the same
    if (local.updatedAt == remote.updatedAt) {
      return false;
    }

    // Check if data is different
    return local.repetitions != remote.repetitions ||
        local.interval != remote.interval ||
        local.easeFactor != remote.easeFactor ||
        local.proficiencyLevel != remote.proficiencyLevel ||
        local.nextReviewDate != remote.nextReviewDate;
  }

  /// Get conflict details for logging/debugging
  Map<String, dynamic> getConflictDetails({
    required LearningProgressModel local,
    required LearningProgressModel remote,
  }) {
    return {
      'word': local.word,
      'local': {
        'updatedAt': local.updatedAt.toIso8601String(),
        'proficiencyLevel': local.proficiencyLevel,
        'repetitions': local.repetitions,
        'interval': local.interval,
        'easeFactor': local.easeFactor,
      },
      'remote': {
        'updatedAt': remote.updatedAt.toIso8601String(),
        'proficiencyLevel': remote.proficiencyLevel,
        'repetitions': remote.repetitions,
        'interval': remote.interval,
        'easeFactor': remote.easeFactor,
      },
      'differences': {
        'proficiencyLevel': local.proficiencyLevel != remote.proficiencyLevel,
        'repetitions': local.repetitions != remote.repetitions,
        'interval': local.interval != remote.interval,
        'easeFactor': local.easeFactor != remote.easeFactor,
      },
    };
  }
}

/// Strategy for resolving sync conflicts
enum ConflictResolutionStrategy {
  /// Use the data with the latest timestamp (default)
  latestTimestamp,
  
  /// Use the data with the most progress (higher proficiency)
  mostProgress,
  
  /// Always use local data
  localWins,
  
  /// Always use remote data
  remoteWins,
  
  /// Merge both datasets (take best of both)
  merge;

  String get displayName {
    switch (this) {
      case ConflictResolutionStrategy.latestTimestamp:
        return '最新時間戳';
      case ConflictResolutionStrategy.mostProgress:
        return '最多進度';
      case ConflictResolutionStrategy.localWins:
        return '本地優先';
      case ConflictResolutionStrategy.remoteWins:
        return '雲端優先';
      case ConflictResolutionStrategy.merge:
        return '合併資料';
    }
  }
}
