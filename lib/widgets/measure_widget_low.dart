// lib/widgets/guideline_input_widget.dart

import 'package:flutter/material.dart';
import 'numeric_keypad.dart';
import '../data/models/hvItem.dart';

/// 한전 지침 입력 전용 위젯
class GuidelineInputWidgetLow extends StatefulWidget {
  final SimpleHvLogEntry entry;
  final void Function(String fieldName, double value)? onChanged;

  const GuidelineInputWidgetLow({Key? key, required this.entry, this.onChanged})
    : super(key: key);

  @override
  _GuidelineInputWidgetState createState() => _GuidelineInputWidgetState();
}

String _fmt(double v) {
  if (v == 0) return '_';

  final isInt = v % 1 == 0;
  String s = isInt ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  if (!isInt && s.contains('.')) {
    s = s.replaceFirst(RegExp(r'0+$'), ''); // 소수부 끝 0 제거
    s = s.replaceFirst(RegExp(r'\.$'), ''); // 소수점만 남은 경우 제거
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

class _GuidelineInputWidgetState extends State<GuidelineInputWidgetLow> {
  Future<void> _showAndHandleInput({
    required String title,
    required double currentValue,
    required void Function(double v) handleValue,
  }) async {
    final result = await showNumericKeypad(
      context,
      title: title,
      initialValue: currentValue,
    );
    if (result != null) {
      // 1) 값을 할당 & 합계 재계산
      setState(() {
        handleValue(result);
      });
      // 2) 부모 콜백으로도 알림
      widget.onChanged?.call(title, result);
    }
  }

  Widget _valueCell(
    double value,
    double fontSize,
    int flex, {
    FontWeight weight = FontWeight.normal,
    TextAlign align = TextAlign.center,
  }) => Expanded(
    flex: flex,
    child: Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300, width: 0.5),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          _fmt(value), // ← 여기서만 포맷
          textAlign: align, // 요구: 가운데 맞춤
          style: TextStyle(fontSize: fontSize, fontWeight: weight),
        ),
      ),
    ),
  );

  // 텍스트 셀
  Widget _textCell(String text, double fontSize, int flex) => Expanded(
    flex: flex,
    child: Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300, width: 0.5),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          text,
          style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.normal),
        ),
      ),
    ),
  );

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
          final rowH = constraints.maxHeight; // 한 줄 뷰니까 전체 높이 = 한 행
          final fontSize = 8.0;

          // 셀 빌더
          Widget _label(
            String text, {
            int flex = 1,
            bool bold = true,
            TextAlign ta = TextAlign.center,
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
                    text,
                    textAlign: ta,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: bold ? FontWeight.normal : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            );
          }

          Widget _valueCell({
            required double value,
            required String titleForCallback, // '현 지침 ④ 입력' 등
            required void Function(double v) onSet,
            int flex = 1,
          }) {
            return Expanded(
              flex: flex,
              child: GestureDetector(
                onTap: () => _showAndHandleInput(
                  title: titleForCallback,
                  currentValue: value,
                  handleValue: (v) {
                    // 1) 입력값 저장
                    onSet(v);

                    // 2) 지침 차(= current5 - current4) 및 합계 재계산
                    final v1 = widget.entry.guidelineLowPre5;
                    final v2 = widget.entry.guidelinePrev9;
                    final diff = v2 - v1;
                    widget.entry.guidelineLowSum = diff;

                    // 3) 부모에도 ⑥ 변경 알려주기(자동 계산값)
                    widget.onChanged?.call('현 지침 ⑥ 입력', diff);
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
                      _fmt(value), // ✅ 포맷 적용
                      textAlign: TextAlign.center, // ✅ 가운데 맞춤
                      style: TextStyle(fontSize: fontSize),
                    ),
                  ),
                ),
              ),
            );
          }

          return SizedBox(
            height: rowH,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 레이아웃: 3 : 1 : 3 : 1 : 3 : 1 : 3 : 1  (총 16)
                _label('한전지침', flex: 3),
                _label('전일 ⑤', flex: 1),
                _valueCell(
                  value: widget.entry.guidelineLowPre5,
                  titleForCallback: '현 지침 ④ 입력', // 부모 switch에 맞춤
                  onSet: (v) => widget.entry.guidelineLowPre5 = v,
                  flex: 3,
                ),
                _label('현일 ⑨', flex: 1),
                _valueCell(
                  value: widget.entry.guidelineLowCurrent9,
                  titleForCallback: '현 지침 ⑤ 입력', // 부모 switch에 맞춤
                  onSet: (v) => widget.entry.guidelineLowCurrent9 = v,
                  flex: 3,
                ),
                _label('지침 차', flex: 1),
                // 자동 계산 셀(수정 불가, 터치 비활성)
                Expanded(
                  flex: 3,
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                        color: Colors.grey.shade300,
                        width: 0.5,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        _fmt(widget.entry.guidelineLowSum), // ✅ 포맷 적용
                        textAlign: TextAlign.center, // ✅ 가운데 맞춤
                        style: TextStyle(fontSize: fontSize),
                      ),
                    ),
                  ),
                ),
                _label('kWh', flex: 1),
              ],
            ),
          );
        },
      ),
    );
  }
}
