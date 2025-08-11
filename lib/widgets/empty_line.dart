import 'package:flutter/material.dart';

class BlankRow extends StatelessWidget {
  final int columns;
  final Color borderColor;

  const BlankRow({
    super.key,
    this.columns = 28,
    this.borderColor = const Color(0xFFDDDDDD),
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(columns, (_) {
        return Expanded(
          child: Container(
            decoration: BoxDecoration(
            
            ),
          ),
        );
      }),
    );
  }
}