// lib/widgets/guideline_input_widget.dart

import 'package:flutter/material.dart';
import 'numeric_keypad.dart';
import '../data/models/hvItem.dart';

/// 모델(hvItem.dart)에 아래 필드를 추가하세요:
/// double guidelineCurrent4;
/// double guidelineCurrent5;
/// double guidelineCurrent6;
/// double guidelineCurrentSum;
///
/// double guidelinePrev9;
/// double guidelinePrev10;
/// double guidelinePrev11;
/// double guidelinePrevSum;

/// 한전 지침 입력 전용 위젯
class GuidelineInputWidget extends StatefulWidget {
  final SimpleHvLogEntry entry;
  final void Function(String fieldName, double value)? onChanged;

  const GuidelineInputWidget({Key? key, required this.entry, this.onChanged})
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

class _GuidelineInputWidgetState extends State<GuidelineInputWidget> {
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

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.black, width: 1),
          left: BorderSide(color: Colors.black, width: 1),
          right: BorderSide(color: Colors.black, width: 1),
        ),
      ),
      child: LayoutBuilder(
        builder: (ctx, constraints) {
          // ✅ 한 행만 쓰므로 전체 높이를 그대로 사용
          final rowH = constraints.maxHeight;
          final fontSize = 8.0;

          return Column(
            children: [
              // ── 1행: 한전(현 지침) ──
              SizedBox(
                height: rowH,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                     _textCell('계량기 지침', fontSize, 3),
                    
                    _labelCell(
                      text: widget.entry.guidelineLabel4 == 0
                          ? '④'
                          : _fmt(
                              widget.entry.guidelineLabel4,
                            ), // 값 있으면 DB값, 없으면 '④'
                      fontSize: 8.0,
                      flex: 1,
                      onTap: () => _showAndHandleInput1(
                        title: '④',
                        fieldName: 'guidelineLabel4',
                        currentValue: widget.entry.guidelineLabel4, // ← 새 필드
                        apply: (v) {
                          widget.entry.guidelineLabel4 = v; // ← 새 필드에 저장
                          // 합계는 기존 current 4/5/6 기반이면 건드리지 않음
                        },
                      ),
                    ),
                    // 값 셀은 기존대로 guidelineCurrent4 표시/편집 유지
                    Expanded(
                      flex: 3,
                      child: GestureDetector(
                        onTap: () => _showAndHandleInput1(
                          title: '④',
                          fieldName: 'guidelineCurrent4',
                          currentValue: widget.entry.guidelineCurrent4,
                          apply: (v) {
                            widget.entry.guidelineCurrent4 = v;
                            widget.entry.guidelineCurrentSum =
                                widget.entry.guidelineCurrent4 +
                                widget.entry.guidelineCurrent5 +
                                widget.entry.guidelineCurrent6;
                          },
                        ),
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.grey.shade300,
                              width: 0.5,
                            ),
                            color: Colors.white,
                          ),
                          child: Text(
                            _fmt(widget.entry.guidelineCurrent4),
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: fontSize),
                          ),
                        ),
                      ),
                    ),

                    // ⑤
                    _labelCell(
                      text: widget.entry.guidelineLabel4 == 0
                          ? '⑤'
                          : _fmt(
                              widget.entry.guidelineLabel5,
                            ), // 값 있으면 DB값, 없으면 '④'

                      fontSize: 8.0,
                      flex: 1,
                      onTap: () => _showAndHandleInput1(
                        title: '입력',
                        fieldName: 'guidelineLabel5',
                        currentValue: widget.entry.guidelineLabel5,
                        apply: (v) => widget.entry.guidelineLabel5 = v,
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: GestureDetector(
                        onTap: () => _showAndHandleInput1(
                          title: '입력',
                          fieldName: 'guidelineCurrent5',
                          currentValue: widget.entry.guidelineCurrent5,
                          apply: (v) {
                            widget.entry.guidelineCurrent5 = v;
                            widget.entry.guidelineCurrentSum =
                                widget.entry.guidelineCurrent4 +
                                widget.entry.guidelineCurrent5 +
                                widget.entry.guidelineCurrent6;
                          },
                        ),
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.grey.shade300,
                              width: 0.5,
                            ),
                            color: Colors.white,
                          ),
                          child: Text(
                            _fmt(widget.entry.guidelineCurrent5),
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: fontSize),
                          ),
                        ),
                      ),
                    ),

                    // ⑥
                    _labelCell(
                       text: widget.entry.guidelineLabel4 == 0
                          ? '⑥'
                          : _fmt(
                              widget.entry.guidelineLabel6,
                            ), // 값 있으면 DB값, 없으면 '④'
                      fontSize: 8.0,
                      flex: 1,
                      onTap: () => _showAndHandleInput1(
                        title: '입력',
                        fieldName: 'guidelineLabel6',
                        currentValue: widget.entry.guidelineLabel6,
                        apply: (v) => widget.entry.guidelineLabel6 = v,
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: GestureDetector(
                        onTap: () => _showAndHandleInput1(
                          title: '⑥',
                          fieldName: 'guidelineCurrent6',
                          currentValue: widget.entry.guidelineCurrent6,
                          apply: (v) {
                            widget.entry.guidelineCurrent6 = v;
                            widget.entry.guidelineCurrentSum =
                                widget.entry.guidelineCurrent4 +
                                widget.entry.guidelineCurrent5 +
                                widget.entry.guidelineCurrent6;
                          },
                        ),
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.grey.shade300,
                              width: 0.5,
                            ),
                            color: Colors.white,
                          ),
                          child: Text(
                            _fmt(widget.entry.guidelineCurrent6),
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: fontSize),
                          ),
                        ),
                      ),
                    ),

                    _textCell('금일지침계', fontSize, 3),
                    _valueCell(widget.entry.guidelineCurrentSum, fontSize, 3),
                    _textCell('kWh', fontSize, 1),
                  ],
                ),
              ),

              // ❌ 아래 2행(한전 전 지침) 블록은 통째로 제거했습니다.
            ],
          );
        },
      ),
    );
  }

  Future<void> _showAndHandleInput1({
    required String title,
    required String fieldName, // 부모 콜백용 식별자
    required double currentValue,
    required void Function(double v) apply,
  }) async {
    final result = await showNumericKeypad(
      context,
      title: title,
      initialValue: currentValue,
    );
    if (result == null) return;

    setState(() => apply(result)); // 모델에 반영
    widget.onChanged?.call(fieldName, result);
    // 필요 시: await widget.onSave?.call(widget.entry);
  }

  Widget _labelCell({
    required String text,
    required double fontSize,
    required int flex,
    required VoidCallback onTap,
  }) {
    final child = Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300, width: 0.5),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(text, style: TextStyle(fontSize: fontSize)),
      ),
    );
    return Expanded(
      flex: flex,
      child: InkWell(onTap: onTap, child: child),
    );
  }
}
