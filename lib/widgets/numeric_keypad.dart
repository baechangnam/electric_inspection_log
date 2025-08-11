import 'package:flutter/material.dart';

Future<double?> showNumericKeypad(
  BuildContext context, {
  required String title,
  required double initialValue,
}) {
  return showModalBottomSheet<double>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    builder: (ctx) {
      return _NumericKeypadContent(
        title: title,
        initialValue: initialValue,
      );
    },
  );
}

class _NumericKeypadContent extends StatefulWidget {
  final String title;
  final double initialValue;

  const _NumericKeypadContent({
    required this.title,
    required this.initialValue,
  });

  @override
  State<_NumericKeypadContent> createState() => _NumericKeypadContentState();
}

class _NumericKeypadContentState extends State<_NumericKeypadContent> {
  String input = '';

  @override
  void initState() {
    super.initState();
    input = widget.initialValue == 0
        ? ''
        : widget.initialValue.toStringAsFixed(0);
  }

  void _append(String s) {
    setState(() {
      if (s == '.' && input.contains('.')) return;
      input += s;
    });
  }

  void _backspace() {
    setState(() {
      if (input.isNotEmpty) input = input.substring(0, input.length - 1);
    });
  }

  void _clear() {
    setState(() {
      input = '';
    });
  }

  double _toDouble() {
    return double.tryParse(input.replaceAll(',', '').trim()) ?? 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final display = input.isEmpty ? '-' : input;
    return SafeArea(
      child: Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Text(widget.title,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                display,
                style: const TextStyle(
                    fontSize: 36, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Column(
                children: [
                  for (var row in [
                    ['1', '2', '3'],
                    ['4', '5', '6'],
                    ['7', '8', '9'],
                    ['.', '0', '⌫'],
                  ])
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: row.map((label) {
                          return Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  backgroundColor: Colors.grey.shade100,
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                  elevation: 0,
                                ),
                                onPressed: () {
                                  if (label == '⌫') {
                                    _backspace();
                                  } else if (label == '.') {
                                    _append('.');
                                  } else {
                                    _append(label);
                                  }
                                },
                                child: Text(
                                  label,
                                  style: const TextStyle(fontSize: 20),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: _clear,
                          child: const Text('지우기'),
                        ),
                      ),
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context, null),
                          child: const Text('취소'),
                        ),
                      ),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context, _toDouble());
                          },
                          child: const Text('확인'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
