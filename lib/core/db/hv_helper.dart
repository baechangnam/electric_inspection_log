import 'dart:convert';

import 'package:electric_inspection_log/data/models/hvItem.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class HvLogDb {
  // 싱글톤
  static final HvLogDb instance = HvLogDb._();
  HvLogDb._();

  Future<Database> get _db async {
    // sqflite 열기/생성
    return openDatabase(
      join(await getDatabasesPath(), 'hvlog.db'),
      onCreate: (db, version) => db.execute('''
        CREATE TABLE hvlog (
          boardId TEXT PRIMARY KEY,
          jsonData TEXT NOT NULL
        )
      '''),
      version: 1,
    );
  }

  Future<void> save(SimpleHvLogEntry entry) async {
    final db = await _db;
    final jsonString = jsonEncode(entry.toJson());
    await db.insert(
      'hvlog',
      {'boardId': entry.selectedBoardId, 'jsonData': jsonString},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<SimpleHvLogEntry?> load(String boardId) async {
    final db = await _db;
    final maps = await db.query(
      'hvlog',
      where: 'boardId = ?',
      whereArgs: [boardId],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    final j = jsonDecode(maps.first['jsonData'] as String) as Map<String, dynamic>;
    return SimpleHvLogEntry.fromJson(j);
  }
}
