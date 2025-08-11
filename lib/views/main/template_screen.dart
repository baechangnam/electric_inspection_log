import 'package:electric_inspection_log/core/db/db_helper.dart';
import 'package:electric_inspection_log/data/models/template.dart';
import 'package:flutter/material.dart';

class TemplateListPage extends StatefulWidget {
  @override
  _TemplateListPageState createState() => _TemplateListPageState();
}

class _TemplateListPageState extends State<TemplateListPage> {
  late Future<List<Template>> _futureTemplates;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    _futureTemplates = TemplateDatabase().getAll();
  }

  void _showEditDialog({Template? item}) async {
  final controller = TextEditingController(text: item?.content ?? '');
  final result = await showDialog<String>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(item == null ? '템플릿 추가' : '템플릿 수정'),
      content: SizedBox(
        // 다이얼로그 안에서 높이 지정 (원하는 크기로 조절)
        height: 180,
        child: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.multiline, // 멀티라인용 키보드
          minLines: 3,   // 최소 3줄
          maxLines: 6,   // 최대 6줄
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            hintText: '템플릿 내용을 입력하세요',
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('취소')),
        TextButton(
          onPressed: () => Navigator.pop(context, controller.text.trim()),
          child: Text('확인'),
        ),
      ],
    ),
  );
  if (result != null && result.isNotEmpty) {
    if (item == null) {
      await TemplateDatabase().insert(Template(content: result));
    } else {
      await TemplateDatabase().update(Template(id: item.id, content: result));
    }
    setState(_refresh);
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('템플릿 관리')),
      body: FutureBuilder<List<Template>>(
        future: _futureTemplates,
        builder: (ctx, snap) {
          if (!snap.hasData) return Center(child: CircularProgressIndicator());
          final list = snap.data!;
          return ListView.separated(
            itemCount: list.length,
            separatorBuilder: (_, __) => Divider(height: 1),
            itemBuilder: (_, i) {
              final tpl = list[i];
              return ListTile(
                title: Text(tpl.content),
                onTap: () {
                  // 선택 시 호출하거나 상위 화면으로 값 전달 가능
                  Navigator.pop(context, tpl.content);
                },
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () => _showEditDialog(item: tpl),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () async {
                      await TemplateDatabase().delete(tpl.id!);
                      setState(_refresh);
                    },
                  ),
                ]),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () => _showEditDialog(),
      ),
    );
  }
}
