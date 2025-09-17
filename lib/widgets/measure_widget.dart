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
      // 상/좌/우 검은 테두리, 하단 생략
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.black, width: 1),
          left: BorderSide(color: Colors.black, width: 1),
          right: BorderSide(color: Colors.black, width: 1),
        ),
      ),
      child: LayoutBuilder(
        builder: (ctx, constraints) {
          final rowH = constraints.maxHeight / 2;
          final fontSize = 8.0;

          return Column(
            children: [
              // ── 1행: 한전(현 지침) ──
              SizedBox(
                height: rowH,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _textCell('한전(현 지침)', fontSize, 3),

                    _textCell('④', fontSize, 1),
                    // ④ 입력
                    Expanded(
                      flex: 3,
                      child: GestureDetector(
                        onTap: () => _showAndHandleInput(
                          title: '현지침 4입력',
                          currentValue: widget.entry.guidelineCurrent4,
                          handleValue: (v) {
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

                    _textCell('⑤', fontSize, 1),
                    // ⑤ 입력
                    Expanded(
                      flex: 3,
                      child: GestureDetector(
                        onTap: () => _showAndHandleInput(
                          title: '현지침 5입력',
                          currentValue: widget.entry.guidelineCurrent5,
                          handleValue: (v) {
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

                    _textCell('⑥', fontSize, 1),
                    // ⑥ 입력
                    Expanded(
                      flex: 3,
                      child: GestureDetector(
                        onTap: () => _showAndHandleInput(
                          title: '현지침 6입력',
                          currentValue: widget.entry.guidelineCurrent6,
                          handleValue: (v) {
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
                    _valueCell(
                      widget.entry.guidelineCurrentSum,
                      fontSize,
                      3,
                    ),

                    _textCell('kWh', fontSize, 1),
                  ],
                ),
              ),

              // ── 2행: 한전(전 지침) ──
              SizedBox(
                height: rowH,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _textCell('한전(전 지침)', fontSize, 3),

                    _textCell('⑨', fontSize, 1),
                    // ⑨ 입력
                    Expanded(
                      flex: 3,
                      child: GestureDetector(
                        onTap: () => _showAndHandleInput(
                          title: '전지침 4입력',
                          currentValue: widget.entry.guidelinePrev9,
                          handleValue: (v) {
                            widget.entry.guidelinePrev9 = v;
                            widget.entry.guidelinePrevSum =
                                widget.entry.guidelinePrev9 +
                                widget.entry.guidelinePrev10 +
                                widget.entry.guidelinePrev11;
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
                            _fmt(widget.entry.guidelinePrev9),
                            textAlign: TextAlign.center,

                            style: TextStyle(fontSize: fontSize),
                          ),
                        ),
                      ),
                    ),

                    _textCell('⑩', fontSize, 1),
                    // ⑩ 입력
                    Expanded(
                      flex: 3,
                      child: GestureDetector(
                        onTap: () => _showAndHandleInput(
                          title: '전지침 10입력',
                          currentValue: widget.entry.guidelinePrev10,
                          handleValue: (v) {
                            widget.entry.guidelinePrev10 = v;
                            widget.entry.guidelinePrevSum =
                                widget.entry.guidelinePrev9 +
                                widget.entry.guidelinePrev10 +
                                widget.entry.guidelinePrev11;
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
                            _fmt(widget.entry.guidelinePrev10),
                            textAlign: TextAlign.center,

                            style: TextStyle(fontSize: fontSize),
                          ),
                        ),
                      ),
                    ),

                    _textCell('⑪', fontSize, 1),
                    // ⑪ 입력
                    Expanded(
                      flex: 3,
                      child: GestureDetector(
                        onTap: () => _showAndHandleInput(
                          title: '전지침 11입력',
                          currentValue: widget.entry.guidelinePrev11,
                          handleValue: (v) {
                            widget.entry.guidelinePrev11 = v;
                            widget.entry.guidelinePrevSum =
                                widget.entry.guidelinePrev9 +
                                widget.entry.guidelinePrev10 +
                                widget.entry.guidelinePrev11;
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
                            _fmt(widget.entry.guidelinePrev11),
                            textAlign: TextAlign.center,

                            style: TextStyle(fontSize: fontSize),
                          ),
                        ),
                      ),
                    ),

                    _textCell('전추지침계', fontSize, 3),
                    _valueCell(
                      widget.entry.guidelinePrevSum,
                      fontSize,
                      3,
                    ),

                    _textCell('kWh', fontSize, 1),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
