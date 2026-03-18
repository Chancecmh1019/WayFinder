import 'dart:io';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import '../utils/logger.dart';
import '../errors/exceptions.dart';
import 'backup_service.dart';

/// Service for recovering from database corruption
class DatabaseRecoveryService {
  final BackupService _backupService;

  DatabaseRecoveryService({BackupService? backupService})
      : _backupService = backupService ?? BackupService();

  /// Check if database is corrupted
  Future<bool> isDatabaseCorrupted() async {
    try {
      // Try to open critical boxes
      await Hive.openBox('progress');
      await Hive.openBox('settings');
      await Hive.openBox('sessions');
      
      return false;
    } catch (e) {
      AppLogger.error('Database corruption detected', e);
      return true;
    }
  }

  /// Attempt to recover from database corruption
  Future<DatabaseRecoveryResult> recoverDatabase() async {
    try {
      AppLogger.info('Starting database recovery');

      // Step 1: Check if database is actually corrupted
      if (!await isDatabaseCorrupted()) {
        AppLogger.info('Database is not corrupted');
        return DatabaseRecoveryResult(
          success: true,
          method: RecoveryMethod.noRecoveryNeeded,
          message: 'Database is healthy',
        );
      }

      // Step 2: Try to recover from latest backup
      final backups = await _backupService.getAvailableBackups();
      if (backups.isNotEmpty) {
        try {
          AppLogger.info('Attempting recovery from backup');
          await _recoverFromBackup(backups.first);
          
          return DatabaseRecoveryResult(
            success: true,
            method: RecoveryMethod.fromBackup,
            message: 'Recovered from backup',
          );
        } catch (e) {
          AppLogger.error('Failed to recover from backup', e);
        }
      }

      // Step 3: Try to repair corrupted boxes
      try {
        AppLogger.info('Attempting to repair corrupted boxes');
        await _repairCorruptedBoxes();
        
        return DatabaseRecoveryResult(
          success: true,
          method: RecoveryMethod.repair,
          message: 'Repaired corrupted boxes',
        );
      } catch (e) {
        AppLogger.error('Failed to repair corrupted boxes', e);
      }

      // Step 4: Last resort - delete and reinitialize
      AppLogger.warning('Performing full database reset');
      await _resetDatabase();
      
      return DatabaseRecoveryResult(
        success: true,
        method: RecoveryMethod.reset,
        message: 'Database reset (data lost)',
      );
    } catch (e, stackTrace) {
      AppLogger.error('Database recovery failed', e, stackTrace);
      
      return DatabaseRecoveryResult(
        success: false,
        method: RecoveryMethod.failed,
        message: 'Recovery failed: $e',
      );
    }
  }

  /// Recover from backup file
  Future<void> _recoverFromBackup(File backupFile) async {
    // Close all boxes
    await Hive.close();

    // Delete corrupted database files
    await _deleteCorruptedFiles();

    // Restore from backup
    await _backupService.restoreFromBackup(backupFile);

    AppLogger.info('Successfully recovered from backup');
  }

  /// Repair corrupted boxes
  Future<void> _repairCorruptedBoxes() async {
    final boxNames = ['progress', 'settings', 'sessions', 'vocabulary'];

    for (final boxName in boxNames) {
      try {
        // Try to open box
        final box = await Hive.openBox(boxName);
        
        // Try to compact box (may fix some corruption)
        await box.compact();
        
        AppLogger.info('Repaired box: $boxName');
      } catch (e) {
        AppLogger.warning('Failed to repair box: $boxName', e);
        
        // Delete corrupted box file
        try {
          await _deleteBoxFile(boxName);
          AppLogger.info('Deleted corrupted box: $boxName');
        } catch (deleteError) {
          AppLogger.error('Failed to delete corrupted box: $boxName', deleteError);
        }
      }
    }
  }

  /// Reset database (delete all data)
  Future<void> _resetDatabase() async {
    // Close all boxes
    await Hive.close();

    // Delete all database files
    await _deleteCorruptedFiles();

    // Reinitialize Hive
    final appDocDir = await getApplicationDocumentsDirectory();
    Hive.init(appDocDir.path);

    AppLogger.info('Database reset completed');
  }

  /// Delete corrupted database files
  Future<void> _deleteCorruptedFiles() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final hiveDir = Directory(appDir.path);

      if (await hiveDir.exists()) {
        final files = await hiveDir
            .list()
            .where((entity) => 
                entity is File && 
                (entity.path.endsWith('.hive') || entity.path.endsWith('.lock')))
            .cast<File>()
            .toList();

        for (final file in files) {
          try {
            await file.delete();
            AppLogger.info('Deleted corrupted file: ${file.path}');
          } catch (e) {
            AppLogger.error('Failed to delete file: ${file.path}', e);
          }
        }
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to delete corrupted files', e, stackTrace);
    }
  }

  /// Delete specific box file
  Future<void> _deleteBoxFile(String boxName) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final boxFile = File('${appDir.path}/$boxName.hive');
      final lockFile = File('${appDir.path}/$boxName.lock');

      if (await boxFile.exists()) {
        await boxFile.delete();
      }

      if (await lockFile.exists()) {
        await lockFile.delete();
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to delete box file: $boxName', e, stackTrace);
      throw DatabaseException('Failed to delete box file', stackTrace);
    }
  }

  /// Verify database integrity
  Future<bool> verifyDatabaseIntegrity() async {
    try {
      AppLogger.info('Verifying database integrity');

      // Check if critical boxes can be opened and read
      final progressBox = await Hive.openBox('progress');
      final settingsBox = await Hive.openBox('settings');
      final sessionsBox = await Hive.openBox('sessions');

      // Try to read from each box
      progressBox.keys.take(1).toList();
      settingsBox.keys.take(1).toList();
      sessionsBox.keys.take(1).toList();

      AppLogger.info('Database integrity verified');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error('Database integrity check failed', e, stackTrace);
      return false;
    }
  }
}

/// Result of database recovery operation
class DatabaseRecoveryResult {
  final bool success;
  final RecoveryMethod method;
  final String message;

  const DatabaseRecoveryResult({
    required this.success,
    required this.method,
    required this.message,
  });

  @override
  String toString() {
    return 'DatabaseRecoveryResult(success: $success, method: $method, message: $message)';
  }
}

/// Method used for database recovery
enum RecoveryMethod {
  noRecoveryNeeded,
  fromBackup,
  repair,
  reset,
  failed;

  String get displayName {
    switch (this) {
      case RecoveryMethod.noRecoveryNeeded:
        return '無需恢復';
      case RecoveryMethod.fromBackup:
        return '從備份恢復';
      case RecoveryMethod.repair:
        return '修復損壞';
      case RecoveryMethod.reset:
        return '重置資料庫';
      case RecoveryMethod.failed:
        return '恢復失敗';
    }
  }
}
