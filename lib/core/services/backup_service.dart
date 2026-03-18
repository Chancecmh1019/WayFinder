import 'dart:convert';
import 'dart:io';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import '../utils/logger.dart';
import '../errors/exceptions.dart';

/// Service for backing up and restoring application data
class BackupService {
  static const String _backupDirName = 'backups';

  /// Create a backup of all user data
  Future<File> createBackup() async {
    try {
      AppLogger.info('Creating backup');

      final backupData = <String, dynamic>{};
      final timestamp = DateTime.now().toIso8601String();

      // Backup progress data
      final progressBox = await Hive.openBox('progress');
      backupData['progress'] = progressBox.toMap();
      backupData['progress_count'] = progressBox.length;

      // Backup user settings
      final settingsBox = await Hive.openBox('settings');
      backupData['settings'] = settingsBox.toMap();

      // Backup session history
      final sessionBox = await Hive.openBox('sessions');
      backupData['sessions'] = sessionBox.toMap();
      backupData['sessions_count'] = sessionBox.length;

      // Add metadata
      backupData['metadata'] = {
        'timestamp': timestamp,
        'version': '1.0.0',
        'app': 'WayFinder',
      };

      // Convert to JSON
      final jsonString = jsonEncode(backupData);

      // Save to file
      final file = await _getBackupFile(timestamp);
      await file.writeAsString(jsonString);

      AppLogger.info('Backup created successfully: ${file.path}');
      return file;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to create backup', e, stackTrace);
      throw DatabaseException('Failed to create backup: $e', stackTrace);
    }
  }

  /// Restore data from a backup file
  Future<void> restoreFromBackup(File backupFile) async {
    try {
      AppLogger.info('Restoring from backup: ${backupFile.path}');

      // Read backup file
      final jsonString = await backupFile.readAsString();
      final backupData = jsonDecode(jsonString) as Map<String, dynamic>;

      // Validate backup
      if (!_isValidBackup(backupData)) {
        throw DatabaseException('Invalid backup file');
      }

      // Restore progress data
      if (backupData.containsKey('progress')) {
        final progressBox = await Hive.openBox('progress');
        await progressBox.clear();
        final progressData = backupData['progress'] as Map<String, dynamic>;
        for (final entry in progressData.entries) {
          await progressBox.put(entry.key, entry.value);
        }
        AppLogger.info('Restored ${progressData.length} progress entries');
      }

      // Restore user settings
      if (backupData.containsKey('settings')) {
        final settingsBox = await Hive.openBox('settings');
        await settingsBox.clear();
        final settingsData = backupData['settings'] as Map<String, dynamic>;
        for (final entry in settingsData.entries) {
          await settingsBox.put(entry.key, entry.value);
        }
        AppLogger.info('Restored settings');
      }

      // Restore session history
      if (backupData.containsKey('sessions')) {
        final sessionBox = await Hive.openBox('sessions');
        await sessionBox.clear();
        final sessionsData = backupData['sessions'] as Map<String, dynamic>;
        for (final entry in sessionsData.entries) {
          await sessionBox.put(entry.key, entry.value);
        }
        AppLogger.info('Restored ${sessionsData.length} session entries');
      }

      AppLogger.info('Backup restored successfully');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to restore backup', e, stackTrace);
      throw DatabaseException('Failed to restore backup: $e', stackTrace);
    }
  }

  /// Get list of available backups
  Future<List<File>> getAvailableBackups() async {
    try {
      final backupDir = await _getBackupDirectory();
      
      if (!await backupDir.exists()) {
        return [];
      }

      final files = await backupDir
          .list()
          .where((entity) => entity is File && entity.path.endsWith('.json'))
          .cast<File>()
          .toList();

      // Sort by modification time (newest first)
      files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

      return files;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get available backups', e, stackTrace);
      return [];
    }
  }

  /// Delete old backups, keeping only the most recent N backups
  Future<void> cleanupOldBackups({int keepCount = 5}) async {
    try {
      final backups = await getAvailableBackups();
      
      if (backups.length <= keepCount) {
        return;
      }

      // Delete old backups
      for (var i = keepCount; i < backups.length; i++) {
        await backups[i].delete();
        AppLogger.info('Deleted old backup: ${backups[i].path}');
      }

      AppLogger.info('Cleaned up ${backups.length - keepCount} old backups');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to cleanup old backups', e, stackTrace);
    }
  }

  /// Create automatic backup (called periodically)
  Future<void> createAutomaticBackup() async {
    try {
      AppLogger.info('Creating automatic backup');
      
      await createBackup();
      await cleanupOldBackups();
      
      AppLogger.info('Automatic backup completed');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to create automatic backup', e, stackTrace);
    }
  }

  /// Get backup file path
  Future<File> _getBackupFile(String timestamp) async {
    final backupDir = await _getBackupDirectory();
    
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }

    final fileName = 'backup_${timestamp.replaceAll(':', '-')}.json';
    return File('${backupDir.path}/$fileName');
  }

  /// Get backup directory
  Future<Directory> _getBackupDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    return Directory('${appDir.path}/$_backupDirName');
  }

  /// Validate backup data structure
  bool _isValidBackup(Map<String, dynamic> backupData) {
    // Check for required fields
    if (!backupData.containsKey('metadata')) {
      return false;
    }

    final metadata = backupData['metadata'] as Map<String, dynamic>?;
    if (metadata == null || !metadata.containsKey('timestamp')) {
      return false;
    }

    // Check for at least one data section
    return backupData.containsKey('progress') ||
        backupData.containsKey('settings') ||
        backupData.containsKey('sessions');
  }
}
