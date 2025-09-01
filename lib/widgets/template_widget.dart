import 'package:electric_inspection_log/core/db/template_db.dart';
import 'package:electric_inspection_log/core/db/template_db_solar.dart';
import 'package:flutter/material.dart';
import 'package:electric_inspection_log/data/models/template.dart';



class TemplateListPageTyped extends StatefulWidget {
  final bool solar; // true면 태양광 템플릿
  TemplateListPageTyped({required this.solar});

  @override
  State<TemplateListPageTyped> createState() => _TemplateListPageTypedState();
}

class _TemplateListPageTypedState extends State<TemplateListPageTyped> {
  late Future<List<Template>> _future;
  late ITemplateDB _db;

  @override
  void initState() {
    super.initState();
    _db = widget.solar ? TemplateDatabaseSolar() : TemplateDatabaseGeneral();
    _refresh();
  }

  void _refresh() {
    _future = () async {
      await _db.init();
      return _db.getAll();
    }();
  }

  void _showEditDialog({Template? item}) async {
    final controller = TextEditingController(text: item?.content ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(item == null ? '템플릿 추가' : '템플릿 수정'),
        content: SizedBox(
          height: 180,
          child: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.multiline,
            minLines: 3,
            maxLines: 6,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: '템플릿 내용을 입력하세요',
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('확인'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      if (item == null) {
        await _db.insert(Template(content: result));
      } else {
        await _db.update(Template(id: item.id, content: result));
      }
      setState(_refresh);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_db.title())),
      body: FutureBuilder<List<Template>>(
        future: _future,
        builder: (ctx, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final list = snap.data!;
          return ListView.separated(
            itemCount: list.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final tpl = list[i];
              return ListTile(
                title: Text(tpl.content),
                onTap: () => Navigator.pop(context, tpl.content),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _showEditDialog(item: tpl),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () async {
                      await _db.delete(tpl.id!);
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
        child: const Icon(Icons.add),
        onPressed: () => _showEditDialog(),
      ),
    );
  }
}
