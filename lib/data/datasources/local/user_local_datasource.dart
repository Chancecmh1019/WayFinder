import 'package:hive/hive.dart';
import '../../../core/errors/exceptions.dart';
import '../../models/user_model.dart';

/// Local data source for user data using Hive
class UserLocalDataSource {
  static const String _boxName = 'user';
  static const String _userKey = 'current_user';

  final HiveInterface _hive;

  UserLocalDataSource({HiveInterface? hive}) : _hive = hive ?? Hive;

  /// Get the user box (opens it if not already open)
  Future<Box> _getBox() async {
    if (!_hive.isBoxOpen(_boxName)) {
      return await _hive.openBox(_boxName);
    }
    return _hive.box(_boxName);
  }

  /// Save user to local storage
  Future<void> saveUser(UserModel user) async {
    try {
      final box = await _getBox();
      await box.put(_userKey, user);
    } catch (e) {
      throw CacheException('Failed to save user: $e');
    }
  }

  /// Get user from local storage
  Future<UserModel?> getUser() async {
    try {
      final box = await _getBox();
      return box.get(_userKey);
    } catch (e) {
      throw CacheException('Failed to get user: $e');
    }
  }

  /// Clear user from local storage
  Future<void> clearUser() async {
    try {
      final box = await _getBox();
      await box.delete(_userKey);
    } catch (e) {
      throw CacheException('Failed to clear user: $e');
    }
  }

  /// Check if user exists in local storage
  Future<bool> hasUser() async {
    try {
      final box = await _getBox();
      return box.containsKey(_userKey);
    } catch (e) {
      return false;
    }
  }
}
