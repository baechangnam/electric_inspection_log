// widgets/judgment_picker.dart
import 'package:electric_inspection_log/widgets/inspection_entry.dart';
import 'package:flutter/material.dart';

Future<JudgmentOption?> showJudgmentPicker(BuildContext context, JudgmentOption current) {
  final options = [
    JudgmentOption.o,
    JudgmentOption.x,
    JudgmentOption.triangle,
    JudgmentOption.slash,
    JudgmentOption.yang,
    JudgmentOption.bu,
    JudgmentOption.clear,
  ];

  return showDialog<JudgmentOption>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('판정 선택'),
      content: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: options.map((opt) {
          final isSelected = opt == current;
          return GestureDetector(
            onTap: () => Navigator.pop(ctx, opt),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              decoration: BoxDecoration(
                border: Border.all(color: isSelected ? Colors.blue : Colors.grey),
                borderRadius: BorderRadius.circular(6),
                color: isSelected ? Colors.blue.withOpacity(0.1) : null,
              ),
              child: Text(
                opt == JudgmentOption.clear ? '삭제' : opt.label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isSelected ? Colors.blue : Colors.black,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    ),
  );
}
