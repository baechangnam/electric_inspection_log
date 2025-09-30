// lib/widgets/guideline_input_widget.dart

import 'package:flutter/material.dart';
import 'numeric_keypad.dart';
import '../data/models/hvItem.dart';
// lib/widgets/guideline_input_widget.dart

class GuidelineInputWidgetLow extends StatefulWidget {
  final SimpleHvLogEntry entry;
  final void Function(String fieldName, double value)? onChanged;

  // 선택: 변경 즉시 저장하고 싶으면 부모에서 넘겨주세요.
  final Future<void> Function(SimpleHvLogEntry entry)? onSave;

  const GuidelineInputWidgetLow({
    Key? key,
    required this.entry,
    this.onChanged,
    this.onSave,
  }) : super(key: key);

  @override
  _GuidelineInputWidgetLowState createState() => _GuidelineInputWidgetLowState();
}

class _GuidelineInputWidgetLowState extends State<GuidelineInputWidgetLow> {
  Future<void> _showAndHandleInput({
    required String title,
    required String fieldName,             // 콜백/로그용 식별자
    required double currentValue,
    required void Function(double v) apply, // 모델 반영(합계 재계산 포함)
  }) async {
    final result = await showNumericKeypad(
      context,
      title: title,
      initialValue: currentValue,
    );
    if (result == null) return;

    setState(() => apply(result));
    widget.onChanged?.call(fieldName, result);
    if (widget.onSave != null) await widget.onSave!(widget.entry);
  }

  String _fmt(double v) {
    if (v == 0) return '_';
    final isInt = v % 1 == 0;
    String s = isInt ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
    if (!isInt && s.contains('.')) {
      s = s.replaceFirst(RegExp(r'0+$'), '');
      s = s.replaceFirst(RegExp(r'\.$'), '');
    }
    final parts = s.split('.');
    final intPart = parts[0];
    final decPart = parts.length > 1 ? parts[1] : '';
    final buf = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      final idxFromEnd = intPart.length - i;
      buf.write(intPart[i]);
      if (idxFromEnd > 1 && idxFromEnd % 3 == 1) buf.write(',');
    }
    return decPart.isEmpty ? buf.toString() : '${buf.toString()}.$decPart';
  }

  // 클릭 가능한 라벨 셀 (⑤/⑨)
  Widget _labelCell({
    required String displayText,
    required VoidCallback onTap,
    required int flex,
    required double fontSize,
  }) {
    final child = Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300, width: 0.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          displayText,
          style: TextStyle(fontSize: fontSize + 1), // 라벨은 살짝 크게
        ),
      ),
    );
    return Expanded(flex: flex, child: InkWell(onTap: onTap, child: child));
  }

  // 값(숫자) 셀
  Widget _valueCellEditable({
    required double value,
    required String fieldName,
    required String title,
    required void Function(double v) apply,
    required int flex,
    required double fontSize,
  }) {
    return Expanded(
      flex: flex,
      child: GestureDetector(
        onTap: () => _showAndHandleInput(
          title: title,
          fieldName: fieldName,
          currentValue: value,
          apply: (v) {
            apply(v);
            // 지침 차 자동 재계산
            widget.entry.guidelineLowSum =
                widget.entry.guidelineLowCurrent9 - widget.entry.guidelineLowPre5;
          },
        ),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade300, width: 0.5),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              _fmt(value),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: fontSize),
            ),
          ),
        ),
      ),
    );
  }

  // 읽기전용 합계 셀
  Widget _sumCell({
    required double value,
    required int flex,
    required double fontSize,
  }) {
    return Expanded(
      flex: flex,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300, width: 0.5),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            _fmt(value),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: fontSize),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.black, width: 1),
          left: BorderSide(color: Colors.black, width: 1),
          right: BorderSide(color: Colors.black, width: 1),
        ),
      ),
      child: LayoutBuilder(
        builder: (ctx, constraints) {
          final rowH = constraints.maxHeight;
          final fontSize = 8.0;

          return SizedBox(
            height: rowH,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 3 : 1 : 3 : 1 : 3 : 1 : 3 : 1 (총 16)
                Expanded(
                  flex: 3,
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade300, width: 0.5),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('계량기 지침', style: TextStyle(fontSize: fontSize)),
                    ),
                  ),
                ),

                // ── 전일 ⑤ (라벨 탭 → guidelineLowLabel5 수정)
                _labelCell(
                  displayText: widget.entry.guidelineLowLabel5 == 0
                      ? '⑤'
                      : _fmt(widget.entry.guidelineLowLabel5),
                  onTap: () => _showAndHandleInput(
                    title: '입력',
                    fieldName: 'guidelineLowLabel5',
                    currentValue: widget.entry.guidelineLowLabel5,
                    apply: (v) => widget.entry.guidelineLowLabel5 = v,
                  ),
                  flex: 1,
                  fontSize: fontSize,
                ),
                // 값 셀 → guidelineLowPre5 수정
                _valueCellEditable(
                  value: widget.entry.guidelineLowPre5,
                  fieldName: 'guidelineLowPre5',
                  title: '⑤',
                  apply: (v) => widget.entry.guidelineLowPre5 = v,
                  flex: 3,
                  fontSize: fontSize,
                ),

                // ── 현일 ⑨ (라벨 탭 → guidelineLowLabel9 수정)
                _labelCell(
                  displayText: widget.entry.guidelineLowLabel9 == 0
                      ? '⑨'
                      : _fmt(widget.entry.guidelineLowLabel9),
                  onTap: () => _showAndHandleInput(
                    title: '⑨',
                    fieldName: 'guidelineLowLabel9',
                    currentValue: widget.entry.guidelineLowLabel9,
                    apply: (v) => widget.entry.guidelineLowLabel9 = v,
                  ),
                  flex: 1,
                  fontSize: fontSize,
                ),
                // 값 셀 → guidelineLowCurrent9 수정
                _valueCellEditable(
                  value: widget.entry.guidelineLowCurrent9,
                  fieldName: 'guidelineLowCurrent9',
                  title: '입력',
                  apply: (v) => widget.entry.guidelineLowCurrent9 = v,
                  flex: 3,
                  fontSize: fontSize,
                ),

                // ── 지침 차 (읽기전용: ⑨ - ⑤)
                Expanded(
                  flex: 1,
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade300, width: 0.5),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('지침 차', style: TextStyle(fontSize: fontSize)),
                    ),
                  ),
                ),
                _sumCell(
                  value: widget.entry.guidelineLowSum,
                  flex: 3,
                  fontSize: fontSize,
                ),

                Expanded(
                  flex: 1,
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade300, width: 0.5),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('kWh', style: TextStyle(fontSize: fontSize)),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
