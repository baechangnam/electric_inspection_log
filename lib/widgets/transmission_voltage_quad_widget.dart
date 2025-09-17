// lib/widgets/transmission_voltage_quad_widget.dart

import 'package:flutter/material.dart';
import 'inspection_entry.dart';
import 'judgment_picker.dart';
import '../data/models/hvItem.dart';
import 'numeric_keypad.dart';

typedef QuadLineChanged =
    void Function({
      required int index, // 7,8,9,10 등 행 인덱스
      required InspectionEntry left,
      required InspectionEntry middle,
      required double? currentGeneration, // 1-2행 입력값, 3-4행엔 null
      required double? cumulativeGeneration, // 3-4행 입력값, 1-2행엔 null
    });

class TransmissionVoltageQuadWidget extends StatefulWidget {
  final List<InspectionEntry> leftEntries; // 길이 4
  final List<InspectionEntry> middleEntries; // 길이 4
  final SimpleHvLogEntry
  entry; // currentGenerationKwh, cumulativeGenerationMwh 저장용
  final QuadLineChanged onLineChanged;
  final int tag;

  const TransmissionVoltageQuadWidget({
    Key? key,
    required this.leftEntries,
    required this.middleEntries,
    required this.entry,
    required this.onLineChanged,
    required this.tag,
  }) : assert(leftEntries.length == 4 && middleEntries.length == 4),
       super(key: key);

  @override
  _TransmissionVoltageQuadWidgetState createState() =>
      _TransmissionVoltageQuadWidgetState();
}

class _TransmissionVoltageQuadWidgetState
    extends State<TransmissionVoltageQuadWidget> {
  Future<void> _showNumberInput({
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
      onValueChanged(result);
    }
  }

  static const int baseIndex = 12;

  Widget _fourTwoThreeBlock(
    InspectionEntry entry,
    double baseFont, {
    required VoidCallback onJudgmentTap,
    required VoidCallback onRemarkTap,
  }) {
    return Row(
      children: [
        // 제목 (4)
        Expanded(
          flex: 4,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300, width: 0.5),
            ),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                entry.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: baseFont,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ),
          ),
        ),
        // 판정 (2)
        Expanded(
          flex: 2,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onJudgmentTap,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300, width: 0.5),
              ),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  entry.judgment == JudgmentOption.clear
                      ? ''
                      : entry.judgment.label,
                  style: TextStyle(
                    fontSize: baseFont,
                    fontWeight: FontWeight.normal,
                    color: entry.judgment == JudgmentOption.clear
                        ? Colors.grey
                        : Colors.black,
                  ),
                ),
              ),
            ),
          ),
        ),
        // 비고 (3)
        Expanded(
          flex: 3,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onRemarkTap,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300, width: 0.5),
              ),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 4),
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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final totalH = constraints.maxHeight;
        final rowH = totalH / 4;
        final baseFont = 8.0;

        final bool isCurrent = widget.tag == 1;
        final String genLabel = isCurrent ? '현재 발전량' : '전월 발전량';
        final String genInputTitle = '$genLabel 입력';
        final bool disableCurrentInput = isCurrent; // 현재 발전량일 때만 비활성

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── LEFT 열: 4줄
            // LEFT 열: 1행 + (2~4행 병합)
            // LEFT 열: 1행 + (2~4행 병합, flex 2:2:2:3 비율)
            Expanded(
              flex: 9,
              child: Column(
                children: [
                  // ─────────── 1행 ───────────
                  SizedBox(
                    height: rowH,
                    child: _fourTwoThreeBlock(
                      widget.leftEntries[0],
                      baseFont,
                      onJudgmentTap: () async {
                        final picked = await showJudgmentPicker(
                          context,
                          widget.leftEntries[0].judgment,
                        );
                        if (picked != null) {
                          setState(
                            () => widget.leftEntries[0].judgment = picked,
                          );
                          widget.onLineChanged(
                            index: baseIndex + 0, // 12
                            left: widget.leftEntries[0],
                            middle: widget.middleEntries[0],
                            currentGeneration: null,
                            cumulativeGeneration: null,
                          );
                        }
                      },
                      onRemarkTap: () async {
                        final ctrl = TextEditingController(
                          text: widget.leftEntries[0].remark,
                        );
                        final result = await showDialog<String>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Text(
                              '비고 입력',
                              style: TextStyle(fontSize: baseFont),
                            ),
                            content: TextField(
                              controller: ctrl,
                              maxLines: 3,
                              style: TextStyle(fontSize: baseFont),
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: Text(
                                  '취소',
                                  style: TextStyle(fontSize: baseFont * 0.9),
                                ),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(ctx, ctrl.text.trim()),
                                child: Text(
                                  '저장',
                                  style: TextStyle(fontSize: baseFont * 0.9),
                                ),
                              ),
                            ],
                          ),
                        );
                        if (result != null) {
                          setState(() => widget.leftEntries[0].remark = result);
                          widget.onLineChanged(
                            index: baseIndex + 0,
                            left: widget.leftEntries[0],
                            middle: widget.middleEntries[0],
                            currentGeneration: null,
                            cumulativeGeneration: null,
                          );
                        }
                      },
                    ),
                  ),

                  // ──────── 2~4행 병합 ────────
                  SizedBox(
                    height: rowH * 3,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 1) 발전설비 (병합 셀, flex:2)
                        Expanded(
                          flex: 2,
                          child: Container(
                            height: rowH * 3,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(
                                color: Colors.grey.shade300,
                                width: 0.5,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '발전\n설비',
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // 2) 텍스트 열 (flex:2)
                        Expanded(
                          flex: 2,
                          child: Column(
                            children: List.generate(3, (j) {
                              final entryIndex = j + 1; // 1→2행, 2→3행, 3→4행
                              final entry = widget.leftEntries[entryIndex];
                              return Container(
                                height: rowH,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                    width: 0.5,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    entry.title,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 8,
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),

                        // 3) 판정 열 (flex:2)
                        Expanded(
                          flex: 2,
                          child: Column(
                            children: List.generate(3, (j) {
                              final entryIndex = j + 1;
                              final entry = widget.leftEntries[entryIndex];
                              final globalIndex =
                                  baseIndex + (j + 1); // 13,14,15
                              return GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () async {
                                  final picked = await showJudgmentPicker(
                                    context,
                                    entry.judgment,
                                  );
                                  if (picked != null) {
                                    setState(() => entry.judgment = picked);
                                    widget.onLineChanged(
                                      index: globalIndex,
                                      left: entry,
                                      middle: widget.middleEntries[entryIndex],
                                      currentGeneration: null,
                                      cumulativeGeneration: null,
                                    );
                                  }
                                },
                                child: Container(
                                  height: rowH,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                      width: 0.5,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      entry.judgment == JudgmentOption.clear
                                          ? ''
                                          : entry.judgment.label,
                                      style: TextStyle(
                                        fontSize: baseFont,
                                        fontWeight: FontWeight.normal,
                                        color:
                                            entry.judgment ==
                                                JudgmentOption.clear
                                            ? Colors.grey
                                            : Colors.black,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),

                        // 4) 비고 열 (flex:3)
                        Expanded(
                          flex: 3,
                          child: Column(
                            children: List.generate(3, (j) {
                              final entryIndex = j + 1;
                              final entry = widget.leftEntries[entryIndex];
                              final globalIndex = baseIndex + entryIndex;
                              return GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () async {
                                  final ctrl = TextEditingController(
                                    text: entry.remark,
                                  );
                                  final result = await showDialog<String>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: Text(
                                        '비고 입력',
                                        style: TextStyle(fontSize: baseFont),
                                      ),
                                      content: TextField(
                                        controller: ctrl,
                                        maxLines: 3,
                                        style: TextStyle(fontSize: baseFont),
                                        decoration: const InputDecoration(
                                          border: OutlineInputBorder(),
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx),
                                          child: Text(
                                            '취소',
                                            style: TextStyle(
                                              fontSize: baseFont * 0.9,
                                            ),
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.pop(
                                            ctx,
                                            ctrl.text.trim(),
                                          ),
                                          child: Text(
                                            '저장',
                                            style: TextStyle(
                                              fontSize: baseFont * 0.9,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (result != null) {
                                    setState(() => entry.remark = result);
                                    widget.onLineChanged(
                                      index: globalIndex,
                                      left: entry,
                                      middle: widget.middleEntries[entryIndex],
                                      currentGeneration: null,
                                      cumulativeGeneration: null,
                                    );
                                  }
                                },
                                child: Container(
                                  height: rowH,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                      width: 0.5,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      entry.remark.isEmpty ? '' : entry.remark,
                                      style: TextStyle(
                                        fontSize: baseFont,
                                        fontStyle: entry.remark.isEmpty
                                            ? FontStyle.italic
                                            : FontStyle.normal,
                                        color: entry.remark.isEmpty
                                            ? Colors.grey
                                            : Colors.black,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── MIDDLE 열: 4줄
            Expanded(
              flex: 9,
              child: Column(
                children: List.generate(4, (i) {
                  final idx = baseIndex + i; // 12,13,14,15
                  final middle = widget.middleEntries[i];
                  return SizedBox(
                    height: rowH,
                    child: _fourTwoThreeBlock(
                      middle,
                      baseFont,
                      onJudgmentTap: () async {
                        final picked = await showJudgmentPicker(
                          context,
                          middle.judgment,
                        );
                        if (picked != null) {
                          setState(() => middle.judgment = picked);
                          widget.onLineChanged(
                            index: idx,
                            left: widget.leftEntries[i],
                            middle: middle,
                            currentGeneration: null,
                            cumulativeGeneration: null,
                          );
                        }
                      },
                      onRemarkTap: () async {
                        final ctrl = TextEditingController(text: middle.remark);
                        final result = await showDialog<String>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Text(
                              '비고 입력',
                              style: TextStyle(fontSize: baseFont),
                            ),
                            content: TextField(
                              controller: ctrl,
                              maxLines: 3,
                              style: TextStyle(fontSize: baseFont),
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: Text(
                                  '취소',
                                  style: TextStyle(fontSize: baseFont * 0.9),
                                ),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(ctx, ctrl.text.trim()),
                                child: Text(
                                  '저장',
                                  style: TextStyle(fontSize: baseFont * 0.9),
                                ),
                              ),
                            ],
                          ),
                        );
                        if (result != null) {
                          setState(() => middle.remark = result);
                          widget.onLineChanged(
                            index: idx,
                            left: widget.leftEntries[i],
                            middle: middle,
                            currentGeneration: null,
                            cumulativeGeneration: null,
                          );
                        }
                      },
                    ),
                  );
                }),
              ),
            ),

            // ── RIGHT 열: 1-2행은 “현재 발전량”, 3-4행은 “누적 발전량”
            Expanded(
              flex: 10,
              child: Column(
                children: [
                  // 1–2행 병합: 현재 발전량 (KWH)
                  SizedBox(
                    height: rowH * 2,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          // 라벨
                          Expanded(
                            flex: 4,
                            child: Center(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  genLabel,
                                  style: TextStyle(
                                    fontSize: baseFont,
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // 입력창
                          // 입력창
                          Expanded(
                            flex: 4,
                            child: AbsorbPointer(
                              // ✅ 탭 차단
                              absorbing: true, // 항상 터치 안되게
                              child: GestureDetector(
                                onTap: () => _showNumberInput(
                                  title: genInputTitle,
                                  currentValue:
                                      widget.entry.currentGenerationKwh,
                                  onValueChanged: (v) {
                                    setState(
                                      () =>
                                          widget.entry.currentGenerationKwh = v,
                                    );
                                    widget.onLineChanged(
                                      index: baseIndex + 0, // 12
                                      left: widget.leftEntries[0],
                                      middle: widget.middleEntries[0],
                                      currentGeneration: v,
                                      cumulativeGeneration: null,
                                    );
                                  },
                                ),
                                behavior: HitTestBehavior.opaque,
                                child: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 4),
                                  color: Colors.white, // ✅ 항상 흰색 유지
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      widget.entry.currentGenerationKwh == 0
                                          ? '-'
                                          : formatThousandsDynamic(
                                              widget.entry.currentGenerationKwh,
                                            ),
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                        fontSize: baseFont,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // 단위
                          Expanded(
                            flex: 2,
                            child: Center(
                              child: Text(
                                'KWH',
                                style: TextStyle(
                                  fontSize: baseFont,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // 3–4행 병합: 누적 발전량 (MWH)
                  SizedBox(
                    height: rowH * 2,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          // 라벨
                          Expanded(
                            flex: 4,
                            child: Center(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  '누적 발전량',
                                  style: TextStyle(
                                    fontSize: baseFont,
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // 입력창
                          Expanded(
                            flex: 4,
                            child: GestureDetector(
                              onTap: () => _showNumberInput(
                                title: '누적 발전량 입력',
                                currentValue:
                                    widget.entry.cumulativeGenerationMwh,
                                onValueChanged: (v) {
                                  setState(
                                    () => widget.entry.cumulativeGenerationMwh =
                                        v,
                                  );
                                  widget.onLineChanged(
                                    index: baseIndex + 1, // 13
                                    left: widget.leftEntries[1],
                                    middle: widget.middleEntries[1],
                                    currentGeneration: null,
                                    cumulativeGeneration: v,
                                  );
                                },
                              ),
                              behavior: HitTestBehavior.opaque, // 전체 셀 터치
                              child: Container(
                                alignment: Alignment.centerRight, // 오른쪽 정렬
                                padding: const EdgeInsets.only(right: 4),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    widget.entry.cumulativeGenerationMwh == 0
                                        ? '-'
                                        : formatThousandsDynamic(
                                            widget
                                                .entry
                                                .cumulativeGenerationMwh,
                                          ),
                                    textAlign: TextAlign.right,
                                    style: TextStyle(fontSize: baseFont),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // 단위
                          Expanded(
                            flex: 2,
                            child: Center(
                              child: Text(
                                'MWH',
                                style: TextStyle(
                                  fontSize: baseFont,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  String formatThousandsDynamic(double v) {
    if (v.isNaN || v.isInfinite) return '-';
    if (v == 0) return '-'; // 0이면 언더바 대신 '-' 유지 (기존 로직)

    final isNeg = v < 0;
    final abs = v.abs();

    // 소수점 두 자리까지 문자열로
    String fixed = abs.toStringAsFixed(2); // 예: "74497.20"
    // 불필요한 0 제거 → "74497.2"
    fixed = fixed.replaceAll(RegExp(r'0+$'), '');
    // 마지막이 '.'으로 끝나면 소수점 삭제 → "74497"
    if (fixed.endsWith('.')) {
      fixed = fixed.substring(0, fixed.length - 1);
    }

    final parts = fixed.split('.');
    final intPart = parts[0];
    final decPart = parts.length > 1 ? parts[1] : '';

    // 천단위 콤마 삽입
    final buf = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      final idxFromEnd = intPart.length - i;
      buf.write(intPart[i]);
      if (idxFromEnd > 1 && idxFromEnd % 3 == 1) {
        buf.write(',');
      }
    }

    final core = decPart.isEmpty
        ? buf.toString()
        : '${buf.toString()}.$decPart';
    return isNeg ? '-$core' : core;
  }
}
