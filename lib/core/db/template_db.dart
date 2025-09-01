import 'package:electric_inspection_log/data/models/template.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

// 공통 인터페이스
abstract class ITemplateDB {
  Future<void> init();
  Future<List<Template>> getAll();
  Future<void> insert(Template t);
  Future<void> update(Template t);
  Future<void> delete(int id);
  String title();
}

// 1) 일반 템플릿 (기존과 동일 동작, 파일명만 명시)
class TemplateDatabaseGeneral implements ITemplateDB {
  static final TemplateDatabaseGeneral _i = TemplateDatabaseGeneral._();
  late Database _db;
  bool _inited = false;
  TemplateDatabaseGeneral._();
  factory TemplateDatabaseGeneral() => _i;

  @override
  String title() => '항목을 선택하세요(일반)';

  @override
  Future<void> init() async {
    if (_inited) return;
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, 'templates.db'); // 기존 파일명
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

