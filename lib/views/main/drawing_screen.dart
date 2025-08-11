import 'dart:ui' as ui;

import 'package:electric_inspection_log/core/utils/paint.dart';
import 'package:electric_inspection_log/data/models/stoke.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class DrawingPage extends StatefulWidget {
  @override
  _DrawingPageState createState() => _DrawingPageState();
}
class _DrawingPageState extends State<DrawingPage> {
  List<Stroke> _strokes = [];
  Stroke? _current;
  final GlobalKey _boundaryKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('터치 입력(드로잉)'),
        actions: [
          IconButton(
            icon: Icon(Icons.check),
            onPressed: _saveDrawing,
          ),
          IconButton(
            icon: Icon(Icons.clear),
            onPressed: () => setState(() => _strokes.clear()),
          ),
        ],
      ),
      body: RepaintBoundary(
        key: _boundaryKey,
        child: GestureDetector(
          onPanStart: (e) {
            final paint = Paint()
              ..color = Colors.black
              ..strokeWidth = 2.0
              ..strokeCap = StrokeCap.round;
            _current = Stroke([e.localPosition], paint);
            setState(() => _strokes.add(_current!));
          },
          onPanUpdate: (e) {
            setState(() => _current!.points.add(e.localPosition));
          },
          onPanEnd: (_) => _current = null,
          child: CustomPaint(
            painter: DrawingPainter(_strokes),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }

  Future<void> _saveDrawing() async {
    // RepaintBoundary를 이미지로 변환
    final boundary = _boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final pngBytes = byteData!.buffer.asUint8List();

    // 호출한 쪽으로 이미지 바이트 반환
    Navigator.pop(context, pngBytes);
  }
}
