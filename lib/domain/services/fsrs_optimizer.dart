import 'dart:math';
import 'fsrs_algorithm.dart';
import '../../data/models/fsrs_review_log_model.dart';

/// FSRS Optimizer
/// 
/// 根據用戶的複習歷史記錄，使用機器學習優化 FSRS 參數。
/// 這可以為每個用戶生成個性化的學習曲線。
/// 
/// 注意：這是一個簡化版本的優化器。
/// 完整版本需要使用梯度下降或其他優化算法。
class FSRSOptimizer {
  /// 最小需要的複習記錄數量
  static const int minReviewsForOptimization = 100;

  /// 優化權重參數
  /// 
  /// [reviewLogs]: 用戶的複習歷史記錄
  /// [currentParams]: 當前使用的參數
  /// 
  /// 返回優化後的參數
  FSRSParameters optimize({
    required List<FSRSReviewLogModel> reviewLogs,
    FSRSParameters? currentParams,
  }) {
    currentParams ??= FSRSParameters.defaults();

    // 檢查是否有足夠的數據
    if (reviewLogs.length < minReviewsForOptimization) {
      return currentParams;
    }

    // 計算用戶的實際表現統計
    final stats = _calculateUserStats(reviewLogs);

    // 根據統計數據調整參數
    final optimizedWeights = _optimizeWeights(
      currentWeights: currentParams.w,
      userStats: stats,
    );

    // 調整目標保留率
    final optimizedRetention = _optimizeRetention(
      currentRetention: currentParams.requestRetention,
      userStats: stats,
    );

    return currentParams.copyWith(
      w: optimizedWeights,
      requestRetention: optimizedRetention,
    );
  }

  /// 計算用戶統計數據
  UserStats _calculateUserStats(List<FSRSReviewLogModel> logs) {
    int totalReviews = logs.length;
    int correctReviews = 0;
    int againCount = 0;
    int hardCount = 0;
    int goodCount = 0;
    int easyCount = 0;
    
    double totalElapsed = 0;
    int elapsedCount = 0;
    
    Map<int, int> retentionByInterval = {};
    Map<int, int> totalByInterval = {};

    for (final log in logs) {
      // 統計評分分布
      switch (log.rating) {
        case 1: // Again
          againCount++;
          break;
        case 2: // Hard
          hardCount++;
          correctReviews++;
          break;
        case 3: // Good
          goodCount++;
          correctReviews++;
          break;
        case 4: // Easy
          easyCount++;
          correctReviews++;
          break;
      }

      // 統計間隔表現
      if (log.elapsedDays > 0) {
        totalElapsed += log.elapsedDays;
        elapsedCount++;
        
        final intervalBucket = _getIntervalBucket(log.elapsedDays);
        totalByInterval[intervalBucket] = (totalByInterval[intervalBucket] ?? 0) + 1;
        
        if (log.rating >= 2) { // Hard, Good, Easy
          retentionByInterval[intervalBucket] = (retentionByInterval[intervalBucket] ?? 0) + 1;
        }
      }
    }

    // 計算各間隔段的保留率
    Map<int, double> retentionRates = {};
    for (final interval in totalByInterval.keys) {
      final retained = retentionByInterval[interval] ?? 0;
      final total = totalByInterval[interval]!;
      retentionRates[interval] = retained / total;
    }

    return UserStats(
      totalReviews: totalReviews,
      correctReviews: correctReviews,
      overallRetention: correctReviews / totalReviews,
      againRate: againCount / totalReviews,
      hardRate: hardCount / totalReviews,
      goodRate: goodCount / totalReviews,
      easyRate: easyCount / totalReviews,
      averageElapsed: elapsedCount > 0 ? totalElapsed / elapsedCount : 0,
      retentionByInterval: retentionRates,
    );
  }

  /// 將間隔天數分組到桶中
  int _getIntervalBucket(int days) {
    if (days <= 1) return 1;
    if (days <= 3) return 3;
    if (days <= 7) return 7;
    if (days <= 14) return 14;
    if (days <= 30) return 30;
    if (days <= 60) return 60;
    if (days <= 90) return 90;
    return 180;
  }

  /// 優化權重參數
  List<double> _optimizeWeights({
    required List<double> currentWeights,
    required UserStats userStats,
  }) {
    final optimized = List<double>.from(currentWeights);

    // 根據用戶的 Again 率調整初始穩定性
    // 如果用戶經常忘記，降低初始穩定性
    if (userStats.againRate > 0.3) {
      // Again 率超過 30%，降低初始穩定性
      for (int i = 0; i < 4; i++) {
        optimized[i] *= 0.9;
      }
    } else if (userStats.againRate < 0.1) {
      // Again 率低於 10%，提高初始穩定性
      for (int i = 0; i < 4; i++) {
        optimized[i] *= 1.1;
      }
    }

    // 根據 Easy 率調整 Easy bonus (w[16])
    if (userStats.easyRate > 0.3) {
      // 經常按 Easy，增加 Easy bonus
      optimized[16] = min(3.5, optimized[16] * 1.2);
    } else if (userStats.easyRate < 0.05) {
      // 很少按 Easy，減少 Easy bonus
      optimized[16] = max(1.5, optimized[16] * 0.9);
    }

    // 根據 Hard 率調整 Hard penalty (w[15])
    if (userStats.hardRate > 0.3) {
      // 經常按 Hard，增加 Hard penalty
      optimized[15] = max(0.1, optimized[15] * 0.9);
    } else if (userStats.hardRate < 0.1) {
      // 很少按 Hard，減少 Hard penalty
      optimized[15] = min(0.5, optimized[15] * 1.1);
    }

    return optimized;
  }

  /// 優化目標保留率
  double _optimizeRetention({
    required double currentRetention,
    required UserStats userStats,
  }) {
    // 根據用戶的實際保留率調整目標
    final actualRetention = userStats.overallRetention;
    
    // 如果實際保留率遠高於目標，可以提高目標（減少複習頻率）
    if (actualRetention > currentRetention + 0.1) {
      return min(0.95, currentRetention + 0.02);
    }
    
    // 如果實際保留率低於目標，降低目標（增加複習頻率）
    if (actualRetention < currentRetention - 0.1) {
      return max(0.80, currentRetention - 0.02);
    }
    
    return currentRetention;
  }

  /// 評估參數的效果
  /// 
  /// 返回一個分數，分數越高表示參數越好
  double evaluateParameters({
    required FSRSParameters params,
    required List<FSRSReviewLogModel> reviewLogs,
  }) {
    if (reviewLogs.isEmpty) return 0.0;

    double totalError = 0.0;
    int count = 0;

    final algo = FSRSAlgorithm(parameters: params);

    for (final log in reviewLogs) {
      // 重建複習前的卡片狀態
      final cardBefore = FSRSCard(
        state: CardState.values[log.stateBefore],
        scheduledDays: log.scheduledDaysBefore,
        due: log.reviewedAt.subtract(Duration(days: log.elapsedDays)),
        stability: log.stabilityBefore,
        difficulty: log.difficultyBefore,
        reps: 0, // Not stored in log, use default
        lapses: 0, // Not stored in log, use default
        lastReview: log.elapsedDays > 0 
            ? log.reviewedAt.subtract(Duration(days: log.elapsedDays))
            : null,
      );

      // 使用算法預測
      final predicted = algo.next(
        cardBefore,
        FSRSRating.values[log.rating - 1], // rating is 1-4, Rating enum is 0-3
        now: log.reviewedAt,
      );

      // 計算預測誤差
      final stabilityError = (predicted.stability - log.stabilityAfter).abs();
      final difficultyError = (predicted.difficulty - log.difficultyAfter).abs();
      
      totalError += stabilityError + difficultyError;
      count++;
    }

    // 返回平均誤差的倒數（誤差越小，分數越高）
    final avgError = totalError / count;
    return 1.0 / (1.0 + avgError);
  }

  /// 生成優化報告
  OptimizationReport generateReport({
    required FSRSParameters originalParams,
    required FSRSParameters optimizedParams,
    required List<FSRSReviewLogModel> reviewLogs,
  }) {
    final originalScore = evaluateParameters(
      params: originalParams,
      reviewLogs: reviewLogs,
    );

    final optimizedScore = evaluateParameters(
      params: optimizedParams,
      reviewLogs: reviewLogs,
    );

    final improvement = ((optimizedScore - originalScore) / originalScore * 100);

    return OptimizationReport(
      originalScore: originalScore,
      optimizedScore: optimizedScore,
      improvement: improvement,
      reviewCount: reviewLogs.length,
      originalRetention: originalParams.requestRetention,
      optimizedRetention: optimizedParams.requestRetention,
    );
  }
}

/// 用戶統計數據
class UserStats {
  final int totalReviews;
  final int correctReviews;
  final double overallRetention;
  final double againRate;
  final double hardRate;
  final double goodRate;
  final double easyRate;
  final double averageElapsed;
  final Map<int, double> retentionByInterval;

  const UserStats({
    required this.totalReviews,
    required this.correctReviews,
    required this.overallRetention,
    required this.againRate,
    required this.hardRate,
    required this.goodRate,
    required this.easyRate,
    required this.averageElapsed,
    required this.retentionByInterval,
  });
}

/// 優化報告
class OptimizationReport {
  final double originalScore;
  final double optimizedScore;
  final double improvement;
  final int reviewCount;
  final double originalRetention;
  final double optimizedRetention;

  const OptimizationReport({
    required this.originalScore,
    required this.optimizedScore,
    required this.improvement,
    required this.reviewCount,
    required this.originalRetention,
    required this.optimizedRetention,
  });

  bool get isImproved => improvement > 0;

  String get improvementText {
    if (improvement > 0) {
      return '提升 ${improvement.toStringAsFixed(1)}%';
    } else if (improvement < 0) {
      return '下降 ${(-improvement).toStringAsFixed(1)}%';
    } else {
      return '無變化';
    }
  }
}
