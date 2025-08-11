import 'package:electric_inspection_log/data/models/stoke.dart';
import 'package:flutter/material.dart';

class DrawingPainter extends CustomPainter {
  final List<Stroke> strokes;
  DrawingPainter(this.strokes);
  @override
  void paint(Canvas canvas, Size size) {
    for (var stroke in strokes) {
      for (int i = 0; i < stroke.points.length - 1; i++) {
        canvas.drawLine(
          stroke.points[i],
          stroke.points[i + 1],
          stroke.paint,
        );
      }
    }
  }
  @override
  bool shouldRepaint(covariant DrawingPainter old) => true;
}
