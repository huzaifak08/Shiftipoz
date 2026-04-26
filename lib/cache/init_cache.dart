import 'dart:developer' as dev;
import 'package:shiftipoz/cache/tables/user_table.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalCacheManager {
  static Database? database;

  static Future<Database> getDatabase() async {
    if (database != null) {
      return database!;
    }

    database = await initDatabase();
    return database!;
  }

  static Future<Database> initDatabase() async {
    final documentsDirectory = await getDatabasesPath();
    final path = join(documentsDirectory, 'shiftipoz.db');
    dev.log("Cache Path: $path");

    return openDatabase(
      path,
      version: 1, // Increment version number when schema changes
      onCreate: (db, version) async {
        await UserTable.createTable(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {},
    );
  }

  static Future<void> deleteAllCacheData() async {
    final db = await getDatabase();
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%';",
    );
    for (var table in tables) {
      final tableName = table['name'].toString();
      await db.delete(tableName);
    }
  }
}
