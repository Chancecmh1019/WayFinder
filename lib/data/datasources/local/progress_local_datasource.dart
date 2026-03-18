import 'dart:async';
import 'package:hive/hive.dart';
import '../../models/learning_progress_model.dart';
import '../../services/hive_service.dart';

/// Local data source for learning progress using Hive
class ProgressLocalDataSource {
  Box<LearningProgressModel>? _progressBox;
  final StreamController<int> _dueReviewCountController =
      StreamController<int>.broadcast();

  /// Initialize the data source
  Future<void> initialize() async {
    _progressBox = await HiveService.openProgressBox();
    _updateDueReviewCount();
  }

  /// Get all learning progress for a user
  Future<List<LearningProgressModel>> getAllProgress(String userId) async {
    await _ensureInitialized();
    return _progressBox!.values
        .where((progress) => progress.userId == userId)
        .toList();
  }

  /// Get learning progress for a specific word
  Future<LearningProgressModel?> getProgress(String userId, String word) async {
    await _ensureInitialized();
    final key = _makeKey(userId, word);
    return _progressBox!.get(key);
  }

  /// Get all words due for review
  Future<List<LearningProgressModel>> getDueReviews(String userId) async {
    await _ensureInitialized();
    final now = DateTime.now();
    final dueReviews = _progressBox!.values
        .where((progress) =>
            progress.userId == userId && progress.nextReviewDate.isBefore(now))
        .toList();

    // Sort by due date (oldest first)
    dueReviews.sort((a, b) => a.nextReviewDate.compareTo(b.nextReviewDate));
    return dueReviews;
  }

  /// Save or update learning progress
  Future<void> saveProgress(LearningProgressModel progress) async {
    await _ensureInitialized();
    final key = _makeKey(progress.userId, progress.word);
    await _progressBox!.put(key, progress);
    _updateDueReviewCount();
  }

  /// Delete learning progress for a word
  Future<void> deleteProgress(String userId, String word) async {
    await _ensureInitialized();
    final key = _makeKey(userId, word);
    await _progressBox!.delete(key);
    _updateDueReviewCount();
  }

  /// Get count of words learned (with at least one review)
  Future<int> getLearnedWordsCount(String userId) async {
    await _ensureInitialized();
    return _progressBox!.values
        .where((progress) =>
            progress.userId == userId && progress.history.isNotEmpty)
        .length;
  }

  /// Get count of words mastered (proficiency level >= 4)
  Future<int> getMasteredWordsCount(String userId) async {
    await _ensureInitialized();
    return _progressBox!.values
        .where((progress) =>
            progress.userId == userId && progress.proficiencyLevel >= 4)
        .length;
  }

  /// Get learning streak (consecutive days with at least one review)
  Future<int> getLearningStreak(String userId) async {
    await _ensureInitialized();

    // Get all progress for user
    final allProgress = _progressBox!.values
        .where((progress) => progress.userId == userId)
        .toList();

    if (allProgress.isEmpty) return 0;

    // Collect all review dates
    final Set<DateTime> reviewDates = {};
    for (final progress in allProgress) {
      for (final review in progress.history) {
        final date = DateTime(
          review.reviewDate.year,
          review.reviewDate.month,
          review.reviewDate.day,
        );
        reviewDates.add(date);
      }
    }

    if (reviewDates.isEmpty) return 0;

    // Sort dates in descending order
    final sortedDates = reviewDates.toList()..sort((a, b) => b.compareTo(a));

    // Calculate streak from today backwards
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    int streak = 0;
    DateTime checkDate = todayDate;

    for (final date in sortedDates) {
      if (date.isAtSameMomentAs(checkDate)) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else if (date.isBefore(checkDate)) {
        // Gap in streak
        break;
      }
    }

    return streak;
  }

  /// Stream of due review count
  Stream<int> get dueReviewCountStream => _dueReviewCountController.stream;

  /// Update due review count and emit to stream
  void _updateDueReviewCount() {
    if (_progressBox == null) return;

    final now = DateTime.now();
    final count = _progressBox!.values
        .where((progress) => progress.nextReviewDate.isBefore(now))
        .length;

    _dueReviewCountController.add(count);
  }

  /// Create a unique key for progress storage
  String _makeKey(String userId, String word) {
    return '${userId}_$word';
  }

  /// Ensure the data source is initialized
  Future<void> _ensureInitialized() async {
    if (_progressBox == null) {
      await initialize();
    }
  }

  /// Close the data source
  Future<void> close() async {
    await _progressBox?.close();
    await _dueReviewCountController.close();
  }
}
