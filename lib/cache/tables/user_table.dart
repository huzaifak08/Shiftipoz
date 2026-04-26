import 'package:shiftipoz/cache/init_cache.dart';
import 'package:shiftipoz/models/user_model.dart';
import 'package:sqflite/sqflite.dart';

class UserTable {
  static const String tableName = "users";

  static Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableName (
        uid TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT NOT NULL,
        password TEXT,
        profilePic TEXT,
        createdAt TEXT NOT NULL,
        isEmailVerified INTEGER NOT NULL,
        isSynced INTEGER NOT NULL,
        lastSyncAttempt TEXT
      )
    ''');
  }

  /// Save or Update user in local cache
  static Future<void> saveUser(UserModel user) async {
    final db = await LocalCacheManager.getDatabase();
    await db.insert(
      tableName,
      user.toJsonDb(), // Ensure your UserModel has a toJsonDb method
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Retrieve the current user from cache
  static Future<UserModel?> getUser(String uid) async {
    final db = await LocalCacheManager.getDatabase();
    final maps = await db.query(
      tableName,
      where: 'uid = ?',
      whereArgs: [uid],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return UserModel.fromJsonDb(maps.first);
  }

  /// Delete user data (useful for Logout)
  static Future<void> deleteUser(String uid) async {
    final db = await LocalCacheManager.getDatabase();
    await db.delete(tableName, where: 'uid = ?', whereArgs: [uid]);
  }

  /// Clear entire table
  static Future<void> clearAllUsers() async {
    final db = await LocalCacheManager.getDatabase();
    await db.delete(tableName);
  }
}
