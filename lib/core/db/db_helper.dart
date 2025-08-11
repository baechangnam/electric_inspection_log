import 'package:electric_inspection_log/data/models/template.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class TemplateDatabase {
  static final TemplateDatabase _instance = TemplateDatabase._();
  late Database _db;

  TemplateDatabase._();

  factory TemplateDatabase() => _instance;

  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, 'templates.db');
    _db = await openDatabase(path, version: 1, onCreate: (db, v) async {
      await db.execute('''
        CREATE TABLE templates(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          content TEXT NOT NULL
        )
      ''');
    });

    // 기본 템플릿이 없으면 삽입
    final count = Sqflite.firstIntValue(
      await _db.rawQuery('SELECT COUNT(*) FROM templates'),
    );
    if (count == 0) {
      final defaults = [
        '절연 및 접지저항 상태 확인',
        '전선의 절연 저항 상태 확인',
        '제어장치 상태 확인',
        '각 배선의 피복 및 과열등 이상 점검 상태 확인',
        '절연저항 및 접지선의 접속 상태 확인',
      ];
      for (var s in defaults) {
        await _db.insert('templates', {'content': s});
      }
    }
  }

  Future<List<Template>> getAll() async {
    final rows = await _db.query('templates', orderBy: 'id');
    return rows.map((m) => Template.fromMap(m)).toList();
  }

  Future<void> insert(Template t) =>
      _db.insert('templates', t.toMap());

  Future<void> update(Template t) =>
      _db.update('templates', t.toMap(), where: 'id = ?', whereArgs: [t.id]);

  Future<void> delete(int id) =>
      _db.delete('templates', where: 'id = ?', whereArgs: [id]);
}
