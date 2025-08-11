// lib/widgets/measurement_power_widget.dart

import 'package:flutter/material.dart';
import 'numeric_keypad.dart';
import '../data/models/hvItem.dart';

class MeasurementPowerWidget extends StatefulWidget {
  final SimpleHvLogEntry entry;
  /// 변경된 필드 이름과 값을 콜백으로 알림
  final void Function(String fieldName, double value)? onChanged;

  const MeasurementPowerWidget({
    Key? key,
    required this.entry,
    this.onChanged,
  }) : super(key: key);

  @override
  _MeasurementPowerWidgetState createState() =>
      _MeasurementPowerWidgetState();
}

class _MeasurementPowerWidgetState extends State<MeasurementPowerWidget> {
  Future<void> _showInput({
    required String title,
    required double currentValue,
    required ValueChanged<double> onValueChanged,
  }) async {
    final result = await showNumericKeypad(
      context,
      title: title,
      initialValue: currentValue,
    );
    if (result != null) {
      setState(() {
        onValueChanged(result);
      });
    }
  }

  Widget _buildCell(
    String label,
    double value,
    String unit,
    String dialogTitle,
    ValueChanged<double> onValueChanged,
    double fontSize,
    BoxDecoration decoration,
  ) {
    return Expanded(
      flex: 1,
      child: Row(
        children: [
          // 레이블 3
          Expanded(
            flex: 3,
            child: Container(
              decoration: decoration,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 4),
             
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
           
            ),
          ),
          // 입력창 2
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: () => _showInput(
                title: dialogTitle,
                currentValue: value,
                onValueChanged: onValueChanged,
              ),
              child: Container(
                decoration: decoration,
                alignment: Alignment.center,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value == 0 ? '-' : value.toStringAsFixed(0),
                    style: TextStyle(fontSize: fontSize),
                  ),
                ),
              ),
            ),
          ),
          // 단위 2
          Expanded(
            flex: 2,
            child: Container(
              decoration: decoration,
              alignment: Alignment.center,
          
                child: Text(
                  unit,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
             
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, constraints) {
      final totalH = constraints.maxHeight;
      final rowH = totalH / 2;
      final baseFont = rowH * 0.55;
      final cellDecor = BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300, width: 0.5),
      );

      return Column(
        children: [
          // 1행: 측정 전압 4종
          SizedBox(
            height: rowH,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildCell(
                  '측정전압R~S',
                  widget.entry.measuredVoltageRtoS,
                  'V',
                  'R~S 측정전압 입력',
                  (v) {
                    widget.entry.measuredVoltageRtoS = v;
                    widget.onChanged?.call('measuredVoltageRtoS', v);
                  },
                  baseFont,
                  cellDecor,
                ),
                _buildCell(
                  'S~T',
                  widget.entry.measuredVoltageStoT,
                  'V',
                  'S~T 측정전압 입력',
                  (v) {
                    widget.entry.measuredVoltageStoT = v;
                    widget.onChanged?.call('measuredVoltageStoT', v);
                  },
                  baseFont,
                  cellDecor,
                ),
                _buildCell(
                  'R~T',
                  widget.entry.measuredVoltageRtoT,
                  'V',
                  'R~T 측정전압 입력',
                  (v) {
                    widget.entry.measuredVoltageRtoT = v;
                    widget.onChanged?.call('measuredVoltageRtoT', v);
                  },
                  baseFont,
                  cellDecor,
                ),
                _buildCell(
                  'N',
                  widget.entry.measuredVoltageN,
                  'V',
                  'N 측정전압 입력',
                  (v) {
                    widget.entry.measuredVoltageN = v;
                    widget.onChanged?.call('measuredVoltageN', v);
                  },
                  baseFont,
                  cellDecor,
                ),
              ],
            ),
          ),

          // 2행: 전력 4종
          SizedBox(
            height: rowH,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildCell(
                  '최대전력',
                  widget.entry.maxPower,
                  'KW',
                  '최대전력 입력',
                  (v) {
                    widget.entry.maxPower = v;
                    widget.onChanged?.call('maxPower', v);
                  },
                  baseFont,
                  cellDecor,
                ),
                _buildCell(
                  '평균전력',
                  widget.entry.avgPower,
                  'KW',
                  '평균전력 입력',
                  (v) {
                    widget.entry.avgPower = v;
                    widget.onChanged?.call('avgPower', v);
                  },
                  baseFont,
                  cellDecor,
                ),
                _buildCell(
                  '배율',
                  widget.entry.powerRatio,
                  '%',
                  '배율 입력',
                  (v) {
                    widget.entry.powerRatio = v;
                    widget.onChanged?.call('powerRatio', v);
                  },
                  baseFont,
                  cellDecor,
                ),
                _buildCell(
                  '역율',
                  widget.entry.powerFactor,
                  '%',
                  '역율 입력',
                  (v) {
                    widget.entry.powerFactor = v;
                    widget.onChanged?.call('powerFactor', v);
                  },
                  baseFont,
                  cellDecor,
                ),
              ],
            ),
          ),
        ],
      );
    });
  }
}
