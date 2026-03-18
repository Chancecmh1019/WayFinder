import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/backup_service.dart';
import '../services/database_recovery_service.dart';
import '../services/sync_conflict_resolver.dart';

/// Provider for BackupService instance
final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService();
});

/// Provider for DatabaseRecoveryService instance
final databaseRecoveryServiceProvider = Provider<DatabaseRecoveryService>((ref) {
  final backupService = ref.watch(backupServiceProvider);
  return DatabaseRecoveryService(backupService: backupService);
});

/// Provider for SyncConflictResolver instance
final syncConflictResolverProvider = Provider<SyncConflictResolver>((ref) {
  return SyncConflictResolver();
});

/// Provider for checking database corruption
final databaseCorruptionCheckProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(databaseRecoveryServiceProvider);
  return await service.isDatabaseCorrupted();
});

/// Provider for database integrity verification
final databaseIntegrityProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(databaseRecoveryServiceProvider);
  return await service.verifyDatabaseIntegrity();
});

/// Provider for available backups
final availableBackupsProvider = FutureProvider((ref) async {
  final service = ref.watch(backupServiceProvider);
  return await service.getAvailableBackups();
});

/// Provider for creating backup
final createBackupProvider = FutureProvider.autoDispose((ref) async {
  final service = ref.watch(backupServiceProvider);
  return await service.createBackup();
});

/// Provider for automatic backup (called periodically)
final automaticBackupProvider = FutureProvider.autoDispose((ref) async {
  final service = ref.watch(backupServiceProvider);
  await service.createAutomaticBackup();
});
