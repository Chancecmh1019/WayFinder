import 'package:hive/hive.dart';
import '../../models/learning_session_model.dart';
import '../../services/hive_service.dart';

/// Local data source for persisting learning session state
class SessionLocalDataSource {
  static const String _activeSessionKey = 'active_session';
  static const String _sessionHistoryPrefix = 'session_';

  /// Get the session box (assumes it's already opened by HiveService)
  Future<Box<dynamic>> _getBox() async {
    return await HiveService.openSessionBox();
  }

  /// Save the current active session state
  Future<void> saveActiveSession(LearningSessionModel session) async {
    final box = await _getBox();
    await box.put(_activeSessionKey, session);
  }

  /// Get the active session state (if any)
  Future<LearningSessionModel?> getActiveSession() async {
    final box = await _getBox();
    final session = box.get(_activeSessionKey);
    
    if (session == null) {
      return null;
    }
    
    // Ensure it's the correct type
    if (session is LearningSessionModel) {
      return session;
    }
    
    return null;
  }

  /// Check if there's an active session
  Future<bool> hasActiveSession() async {
    final box = await _getBox();
    return box.containsKey(_activeSessionKey);
  }

  /// Clear the active session (when session ends or is abandoned)
  Future<void> clearActiveSession() async {
    final box = await _getBox();
    await box.delete(_activeSessionKey);
  }

  /// Save a completed session to history
  Future<void> saveSessionToHistory(LearningSessionModel session) async {
    final box = await _getBox();
    final key = '$_sessionHistoryPrefix${session.sessionId}';
    await box.put(key, session);
  }

  /// Get a session from history by ID
  Future<LearningSessionModel?> getSessionFromHistory(String sessionId) async {
    final box = await _getBox();
    final key = '$_sessionHistoryPrefix$sessionId';
    final session = box.get(key);
    
    if (session is LearningSessionModel) {
      return session;
    }
    
    return null;
  }

  /// Get all session history
  Future<List<LearningSessionModel>> getAllSessionHistory() async {
    final box = await _getBox();
    final sessions = <LearningSessionModel>[];
    
    for (final key in box.keys) {
      if (key.toString().startsWith(_sessionHistoryPrefix)) {
        final session = box.get(key);
        if (session is LearningSessionModel) {
          sessions.add(session);
        }
      }
    }
    
    // Sort by start time (most recent first)
    sessions.sort((a, b) => b.startTime.compareTo(a.startTime));
    
    return sessions;
  }

  /// Delete old session history (keep only last N sessions)
  Future<void> cleanupOldSessions({int keepCount = 30}) async {
    final box = await _getBox();
    final sessions = await getAllSessionHistory();
    
    // If we have more than keepCount sessions, delete the oldest ones
    if (sessions.length > keepCount) {
      final sessionsToDelete = sessions.skip(keepCount);
      for (final session in sessionsToDelete) {
        final key = '$_sessionHistoryPrefix${session.sessionId}';
        await box.delete(key);
      }
    }
  }

  /// Clear all session data (for testing or reset)
  Future<void> clearAllSessions() async {
    final box = await _getBox();
    await box.clear();
  }

  /// Close the box
  Future<void> close() async {
    // Box is managed by HiveService, no need to close here
  }
}
