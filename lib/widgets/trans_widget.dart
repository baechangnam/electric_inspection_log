// lib/widgets/transmission_voltage_triple_widget.dart
import 'package:flutter/material.dart';
import 'inspection_entry.dart';
import 'judgment_picker.dart';
import '../data/models/hvItem.dart';
import 'numeric_keypad.dart'; // showNumericKeypad 정의된 파일 경로 맞춰

typedef LineChanged =
    void Function({
      required int index, // 7,8,9
      required InspectionEntry left,
      required InspectionEntry middle,
      required InspectionEntry right,
      required double value,
    });

class TransmissionVoltageTripleWidget extends StatefulWidget {
  final List<InspectionEntry> leftEntries; // [7,8,9]
  final List<InspectionEntry> middleEntries;
  final List<InspectionEntry> rightEntries; // solarItems 대응
  final SimpleHvLogEntry entry; // rToS, sToT, rToT
  final LineChanged onLineChanged;

  const TransmissionVoltageTripleWidget({
    super.key,
    required this.leftEntries,
    required this.middleEntries,
    required this.rightEntries,
    required this.entry,
    required this.onLineChanged,
  }) : assert(
         leftEntries.length == 3 &&
             middleEntries.length == 3 &&
             rightEntries.length == 3,
       );

  @override
  State<TransmissionVoltageTripleWidget> createState() =>
      _TransmissionVoltageTripleWidgetState();
}

class _TransmissionVoltageTripleWidgetState
    extends State<TransmissionVoltageTripleWidget> {
  Future<void> _editRemark(
    InspectionEntry entry,
    String title,
    double baseFont,
    int overallIndex,
    InspectionEntry left,
    InspectionEntry middle,
    InspectionEntry right,
  ) async {
    final controller = TextEditingController(text: entry.remark);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: TextStyle(fontSize: baseFont)),
        content: TextField(
          controller: controller,
          maxLines: 3,
          style: TextStyle(fontSize: baseFont),
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: Text('취소', style: TextStyle(fontSize: baseFont * 0.9)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text('저장', style: TextStyle(fontSize: baseFont * 0.9)),
          ),
        ],
      ),
    );
    if (result != null) {
      setState(() {
        entry.remark = result;
      });
      widget.onLineChanged(
        index: overallIndex,
        left: left,
        middle: middle,
        right: right,
        value: 0,
      );
    }
  }

  Widget _fourTwoThreeEditableBlock(
    InspectionEntry entry,
    double baseFont, {
    required int overallIndex,
    required InspectionEntry left,
    required InspectionEntry middle,
    required InspectionEntry right,
  }) {
    // 4:2:3 (title / judgment / remark), 호출 시마다 관련 전체 라인 콜백
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300, width: 0.5),
            ),

            child: Text(
              entry.title,
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: baseFont),
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: GestureDetector(
            onTap: () async {
              final picked = await showJudgmentPicker(context, entry.judgment);
              if (picked != null) {
                setState(() {
                  entry.judgment = picked;
                });
                widget.onLineChanged(
                  index: overallIndex,
                  left: left,
                  middle: middle,
                  right: right,
                  value: 0,
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300, width: 0.5),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  entry.judgment == JudgmentOption.clear
                      ? ''
                      : entry.judgment.label,
                  style: TextStyle(
                    fontSize: baseFont,
                    fontWeight: FontWeight.bold,
                    color: entry.judgment == JudgmentOption.clear
                        ? Colors.grey
                        : Colors.black,
                  ),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: GestureDetector(
            onTap: () => _editRemark(
              entry,
              '비고 입력',
              baseFont,
              overallIndex,
              left,
              middle,
              right,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300, width: 0.5),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  entry.remark.isEmpty ? '' : entry.remark,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: TextStyle(
                    fontSize: baseFont,
                    fontStyle: entry.remark.isEmpty
                        ? FontStyle.italic
                        : FontStyle.normal,
                    color: entry.remark.isEmpty ? Colors.grey : Colors.black,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showNumberInput(
    TransmissionVoltageField field,
    double currentValue,
    int overallIndex,
  ) async {
    final title = field == TransmissionVoltageField.rToS
        ? 'R~S 입력'
        : field == TransmissionVoltageField.sToT
        ? 'S~T 입력'
        : 'R~T 입력';

    final result = await showNumericKeypad(
      context,
      title: title,
      initialValue: currentValue,
    );

    if (result != null) {
      setState(() {
        widget.entry.setTransmission(field, result);
      });
      widget.onLineChanged(
        index: overallIndex,
        left: widget.leftEntries[overallIndex - 7],
        middle: widget.middleEntries[overallIndex - 7],
        right: widget.rightEntries[overallIndex - 7],
        value: result,
      );
    }
  }

  Widget _simpleTransmissionRow({
    required String label,
    required TransmissionVoltageField field,
    required double baseFont,
    required int overallIndex,
  }) {
    final value = widget.entry.getTransmission(field);
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Container(
            decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300, width: 0.5),
                  color: Colors.white, // 배경을 흰색으로
                ),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 2),
          
            child: Text(label, style: TextStyle(fontSize: baseFont * 0.9)),
          ),
        ),
        Expanded(
          flex: 5,
          child: GestureDetector(
            onTap: () => _showNumberInput(field, value, overallIndex),
            child: Container(
              margin: const EdgeInsets.only(left: 2),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade300, width: 0.5),
                ),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value == 0 ? '-' : value.toStringAsFixed(0),
                  style: TextStyle(
                    fontSize: baseFont,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // 순서: R~S, S~T, R~T
    final order = [
      TransmissionVoltageField.rToS,
      TransmissionVoltageField.sToT,
      TransmissionVoltageField.rToT,
    ];
    final labels = ['R~S', 'S~T', 'R~T'];

    return LayoutBuilder(
      builder: (ctx, constraints) {
        final totalH = constraints.maxHeight;
        final lineH = totalH / 3;
        final baseFont = lineH * 0.55;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // left block (각 줄)
            Expanded(
              flex: 9,
              child: Column(
                children: List.generate(3, (i) {
                  final overallIndex = 7 + i;
                  final left = widget.leftEntries[i];
                  final middle = widget.middleEntries[i];
                  final right = widget.rightEntries[i];
                  return SizedBox(
                    height: lineH,
                    child: _fourTwoThreeEditableBlock(
                      left,
                      baseFont,
                      overallIndex: overallIndex,
                      left: left,
                      middle: middle,
                      right: right,
                    ),
                  );
                }),
              ),
            ),

            // middle block (각 줄)
            Expanded(
              flex: 9,
              child: Column(
                children: List.generate(3, (i) {
                  final overallIndex = 7 + i;
                  final left = widget.leftEntries[i];
                  final middle = widget.middleEntries[i];
                  final right = widget.rightEntries[i];
                  return SizedBox(
                    height: lineH,
                    child: _fourTwoThreeEditableBlock(
                      middle,
                      baseFont,
                      overallIndex: overallIndex,
                      left: left,
                      middle: middle,
                      right: right,
                    ),
                  );
                }),
              ),
            ),

            // 송전전압 라벨 (flex 2)
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300, width: 0.5),
                  color: Colors.white, // 배경을 흰색으로
                ),

                alignment: Alignment.center,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '송전\n전압',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: baseFont * 0.8,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),
                ),
              ),
            ),

            // transmission rows (R~S, S~T, R~T)
            Expanded(
              flex: 7,
              child: Column(
                children: List.generate(3, (i) {
                  final field = order[i];
                  final label = labels[i];
                  final overallIndex = 7 + i;
                  return SizedBox(
                    height: lineH,
                    child: _simpleTransmissionRow(
                      label: label,
                      field: field,
                      baseFont: baseFont,
                      overallIndex: overallIndex,
                    ),
                  );
                }),
              ),
            ),
          ],
        );
      },
    );
  }
}
