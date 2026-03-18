import '../../domain/entities/entities.dart';
import '../../presentation/providers/learning_session_state.dart';
import '../models/learning_session_model.dart';

/// Mapper for converting between LearningSessionState and LearningSessionModel
class LearningSessionMapper {
  /// Convert LearningSessionState to LearningSessionModel for persistence
  static LearningSessionModel toModel(
    LearningSessionState state,
    int currentItemTimeMs,
  ) {
    // Convert queue to models
    final queueModels = state.queue.map((item) {
      return LearningItemModel(
        word: item.vocabulary.lemma,
        isNewWord: item.isNewWord,
      );
    }).toList();

    // Find current item index
    int? currentItemIndex;
    if (state.currentItem != null) {
      currentItemIndex = state.queue.indexOf(state.currentItem!);
      if (currentItemIndex == -1) {
        currentItemIndex = null;
      }
    }

    // Convert statistics
    final statisticsModel = SessionStatisticsModel(
      totalReviews: state.statistics.totalReviews,
      correctReviews: state.statistics.correctReviews,
      newWordsCount: state.statistics.newWordsCount,
      totalTimeMs: state.statistics.totalTime.inMilliseconds,
      questionTypeDistribution: Map<String, int>.from(
        state.statistics.questionTypeDistribution,
      ),
    );

    return LearningSessionModel(
      sessionId: state.sessionId ?? '',
      startTime: state.startTime ?? DateTime.now(),
      endTime: state.endTime,
      isActive: state.isActive,
      dailyGoal: state.dailyGoal,
      completedCount: state.completedCount,
      totalCount: state.totalCount,
      queue: queueModels,
      currentItemIndex: currentItemIndex,
      statistics: statisticsModel,
      currentItemTimeMs: currentItemTimeMs,
    );
  }

  /// Convert LearningSessionModel to partial state data
  /// Note: This returns a map of data that can be used to reconstruct the state
  /// The actual reconstruction requires fetching vocabulary entities from the repository
  static Map<String, dynamic> toStateData(LearningSessionModel model) {
    return {
      'sessionId': model.sessionId,
      'startTime': model.startTime,
      'endTime': model.endTime,
      'isActive': model.isActive,
      'dailyGoal': model.dailyGoal,
      'completedCount': model.completedCount,
      'totalCount': model.totalCount,
      'queue': model.queue.map((item) => {
        'word': item.word,
        'isNewWord': item.isNewWord,
      }).toList(),
      'currentItemIndex': model.currentItemIndex,
      'statistics': {
        'totalReviews': model.statistics.totalReviews,
        'correctReviews': model.statistics.correctReviews,
        'newWordsCount': model.statistics.newWordsCount,
        'totalTimeMs': model.statistics.totalTimeMs,
        'questionTypeDistribution': model.statistics.questionTypeDistribution,
      },
      'currentItemTimeMs': model.currentItemTimeMs,
    };
  }

  /// Convert statistics model to entity
  static SessionStatistics toStatisticsEntity(SessionStatisticsModel model) {
    return SessionStatistics(
      totalReviews: model.totalReviews,
      correctReviews: model.correctReviews,
      newWordsCount: model.newWordsCount,
      totalTime: Duration(milliseconds: model.totalTimeMs),
      questionTypeDistribution: Map<String, int>.from(
        model.questionTypeDistribution,
      ),
    );
  }

  /// Convert statistics entity to model
  static SessionStatisticsModel toStatisticsModel(SessionStatistics entity) {
    return SessionStatisticsModel(
      totalReviews: entity.totalReviews,
      correctReviews: entity.correctReviews,
      newWordsCount: entity.newWordsCount,
      totalTimeMs: entity.totalTime.inMilliseconds,
      questionTypeDistribution: Map<String, int>.from(
        entity.questionTypeDistribution,
      ),
    );
  }
}
