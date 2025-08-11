
// models/inspection_entry.dart
enum JudgmentOption {
  o('O'),
  x('X'),
  triangle('△'),
  slash('/'),
  yang('양'),
  bu('부'),
  clear('');

  final String label;
  const JudgmentOption(this.label);

  /// 문자열로부터 enum 복원. 일치하는 게 없으면 clear 반환
  static JudgmentOption fromLabel(String l) {
    return JudgmentOption.values.firstWhere(
      (e) => e.label == l,
      orElse: () => JudgmentOption.clear,
    );
  }
}

extension JudgmentExtension on JudgmentOption {
  String get label {
    switch (this) {
      case JudgmentOption.o:
        return 'O';
      case JudgmentOption.x:
        return 'X';
      case JudgmentOption.triangle:
        return '△';
      case JudgmentOption.slash:
        return '/';
      case JudgmentOption.yang:
        return '양';
      case JudgmentOption.bu:
        return '부';
      case JudgmentOption.clear:
        return '';
    }
  }
}

class InspectionEntry {
  String title; // ex: '인입구배선'
  JudgmentOption judgment;
  String remark;

  InspectionEntry({
    required this.title,
    this.judgment = JudgmentOption.clear,
    this.remark = '',
  });

   factory InspectionEntry.fromJson(Map<String, dynamic> j) => InspectionEntry(
        title: j['title'] as String,
        judgment: JudgmentOption.fromLabel(j['judgment'] as String? ?? ''),
        remark: j['remark'] as String? ?? '',
      );

  

  Map<String, dynamic> toJson() => {
        'title': title,
        'judgment': judgment.label,
        'remark': remark,
      };
}
