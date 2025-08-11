class Template {
  final int? id;
  final String content;

  Template({this.id, required this.content});

  Map<String, dynamic> toMap() => {
        'id': id,
        'content': content,
      };

  factory Template.fromMap(Map<String, dynamic> m) => Template(
        id: m['id'] as int?,
        content: m['content'] as String,
      );
}
