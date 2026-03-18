import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/repository_providers.dart';

/// Statistics data model
class StatisticsData {
  final int learningStreak;
  final int totalWordsLearned;
  final int wordsInReview;
  final int totalReviews;
  final Map<int, int> proficiencyDistribution; // proficiency level -> count
  final Map<DateTime, int> dailyActivity; // date -> review count
  final double averageAccuracy;
  final Duration totalLearningTime;

  const StatisticsData({
    required this.learningStreak,
    required this.totalWordsLearned,
    required this.wordsInReview,
    required this.totalReviews,
    required this.proficiencyDistribution,
    required this.dailyActivity,
    required this.averageAccuracy,
    required this.totalLearningTime,
  });

  factory StatisticsData.empty() {
    return StatisticsData(
      learningStreak: 0,
      totalWordsLearned: 0,
      wordsInReview: 0,
      totalReviews: 0,
      proficiencyDistribution: {},
      dailyActivity: {},
      averageAccuracy: 0.0,
      totalLearningTime: Duration.zero,
    );
  }
}

/// Provider for statistics data
final statisticsProvider = FutureProvider<StatisticsData>((ref) async {
  try {
    final repository = ref.watch(reviewSchedulerRepositoryProvider);
    
    // Get all progress data
    final progressResult = await repository.getAllProgress();
    
    return progressResult.fold(
      (failure) => StatisticsData.empty(),
      (progressList) {
        // Calculate statistics
        final totalWordsLearned = progressList.length;
        final wordsInReview = progressList.where((p) => p.repetitions > 0).length;
        
        // Calculate proficiency distribution
        final proficiencyDistribution = <int, int>{};
        for (var progress in progressList) {
          final level = progress.proficiencyLevel.value;
          proficiencyDistribution[level] = (proficiencyDistribution[level] ?? 0) + 1;
        }
        
        // Calculate total reviews
        int totalReviews = 0;
        int totalCorrect = 0;
        final dailyActivity = <DateTime, int>{};
        
        for (var progress in progressList) {
          for (var review in progress.history) {
            totalReviews++;
            if (review.correct) totalCorrect++;
            
            // Add to daily activity
            final date = DateTime(
              review.reviewDate.year,
              review.reviewDate.month,
              review.reviewDate.day,
            );
            dailyActivity[date] = (dailyActivity[date] ?? 0) + 1;
          }
        }
        
        // Calculate learning streak
        int streak = 0;
        final today = DateTime.now();
        final todayDate = DateTime(today.year, today.month, today.day);
        
        for (int i = 0; i < 365; i++) {
          final checkDate = todayDate.subtract(Duration(days: i));
          if (dailyActivity.containsKey(checkDate)) {
            streak++;
          } else {
            break;
          }
        }
        
        // Calculate average accuracy
        final averageAccuracy = totalReviews > 0 
            ? (totalCorrect / totalReviews) * 100 
            : 0.0;
        
        // Calculate total learning time (sum of all review times)
        Duration totalTime = Duration.zero;
        for (var progress in progressList) {
          for (var review in progress.history) {
            totalTime += review.timeSpent;
          }
        }
        
        return StatisticsData(
          learningStreak: streak,
          totalWordsLearned: totalWordsLearned,
          wordsInReview: wordsInReview,
          totalReviews: totalReviews,
          proficiencyDistribution: proficiencyDistribution,
          dailyActivity: dailyActivity,
          averageAccuracy: averageAccuracy,
          totalLearningTime: totalTime,
        );
      },
    );
  } catch (e) {
    return StatisticsData.empty();
  }
});

/// Provider for learning streak
final learningStreakProvider = Provider<int>((ref) {
  final stats = ref.watch(statisticsProvider);
  return stats.when(
    data: (data) => data.learningStreak,
    loading: () => 0,
    error: (_, _) => 0,
  );
});

/// Provider for total words learned
final totalWordsLearnedProvider = Provider<int>((ref) {
  final stats = ref.watch(statisticsProvider);
  return stats.when(
    data: (data) => data.totalWordsLearned,
    loading: () => 0,
    error: (_, _) => 0,
  );
});

/// Provider for words in review
final wordsInReviewProvider = Provider<int>((ref) {
  final stats = ref.watch(statisticsProvider);
  return stats.when(
    data: (data) => data.wordsInReview,
    loading: () => 0,
    error: (_, _) => 0,
  );
});
