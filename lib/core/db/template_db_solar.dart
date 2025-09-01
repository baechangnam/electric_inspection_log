import 'package:electric_inspection_log/core/db/template_db.dart';
import 'package:electric_inspection_log/data/models/template.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

// 2) 태양광 템플릿 (별도 파일)
class TemplateDatabaseSolar implements ITemplateDB {
  static final TemplateDatabaseSolar _i = TemplateDatabaseSolar._();
  late Database _db;
  bool _inited = false;
  TemplateDatabaseSolar._();
  factory TemplateDatabaseSolar() => _i;

  @override
  String title() => '항목을 선택하세요(태양광)';

  @override
  Future<void> init() async {
    if (_inited) return;
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, 'templates_solar.db'); // ★ 별도 파일
    _db = await openDatabase(path, version: 1, onCreate: (db, v) async {
      await db.execute('''
        CREATE TABLE templates(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          content TEXT NOT NULL
        )
      ''');
    });

    final count = Sqflite.firstIntValue(
      await _db.rawQuery('SELECT COUNT(*) FROM templates'),
    );
    if (count == 0) {
      final defaults = [
        '인버터 모듈 접속부 점검',
        '차단기 단자점검',
        '인버터 동작표시 확인',
      ];
      for (var s in defaults) {
        await _db.insert('templates', {'content': s});
      }
    }
    _inited = true;
  }

  @override
  Future<List<Template>> getAll() async {
    final rows = await _db.query('templates', orderBy: 'id');
    return rows.map((m) => Template.fromMap(m)).toList();
  }

  @override
  Future<void> insert(Template t) => _db.insert('templates', t.toMap());

  @override
  Future<void> update(Template t) =>
      _db.update('templates', t.toMap(), where: 'id = ?', whereArgs: [t.id]);

  @override
  Future<void> delete(int id) =>
      _db.delete('templates', where: 'id = ?', whereArgs: [id]);
}
