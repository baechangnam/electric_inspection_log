// lib/widgets/inspection_line_widget.dart
import 'package:flutter/material.dart';
import 'inspection_entry.dart'; // 경로가 다르면 조정
import 'judgment_picker.dart';

typedef LineChanged =
    void Function({
      required InspectionEntry left,
      required InspectionEntry middle,
      required InspectionEntry right,
       required double value,   
      
    });

class InspectionLineWidget extends StatefulWidget {
  final InspectionEntry left;
  final InspectionEntry middle;
  final InspectionEntry right;
  final LineChanged onChanged;

  const InspectionLineWidget({
    super.key,
    required this.left,
    required this.middle,
    required this.right,
    required this.onChanged,
  });

  @override
  State<InspectionLineWidget> createState() => _InspectionLineWidgetState();
}

class _InspectionLineWidgetState extends State<InspectionLineWidget> {
  Future<void> _editRemark(
    InspectionEntry entry,
    String title,
    double baseFont,
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
      widget.onChanged(
        left: widget.left,
        middle: widget.middle,
        right: widget.right, value: 0
      );
    }
  }

  Widget _buildBlock(
    InspectionEntry entry,
    double baseFont, {
    bool isRightGroup = false,
  }) {
    return Expanded(
      flex: isRightGroup ? 10 : 9,
      child: Row(
        children: [
          // 제목 (4)
          Expanded(
            flex: isRightGroup ? 5 : 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              alignment: Alignment.center,
                   decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300, width: 0.5),
                  color: Colors.white,
                ),
           
                child: Text(
                  entry.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                     
                    fontSize: baseFont,
               
                ),
              ),
            ),
          ),
          // 판정 (2)
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: () async {
                final picked = await showJudgmentPicker(
                  context,
                  entry.judgment,
                );
                if (picked != null) {
                  setState(() {
                    entry.judgment = picked;
                  });
                  widget.onChanged(
                    left: widget.left,
                    middle: widget.middle,
                    right: widget.right, value: 0
                  );
                }
              },
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300, width: 0.5),
                  color: Colors.white,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4),
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
          // 비고 (3 or 4)
          Expanded(
            flex: isRightGroup ? 3 : 3,
            child: GestureDetector(
              onTap: () => _editRemark(entry, '비고 입력', baseFont),
              child: Container(
                alignment: Alignment.center, // 가로+세로 중앙
             
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300, width: 0.5),
                  color: Colors.white,
                ),
                child: Text(
                  entry.remark.isEmpty ? '' : entry.remark,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
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
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final rowH = constraints.maxHeight;
        final baseFont = rowH * 0.55;
        return Row(
          children: [
            _buildBlock(widget.left, baseFont),
            _buildBlock(widget.middle, baseFont),
            _buildBlock(widget.right, baseFont, isRightGroup: true),
          ],
        );
      },
    );
  }
}
