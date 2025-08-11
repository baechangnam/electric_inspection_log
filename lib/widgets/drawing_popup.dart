// 2) 팝업 안에서 그리기 & 저장 로직
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class DrawingDialogContent extends StatefulWidget {
  @override
  _DrawingDialogContentState createState() => _DrawingDialogContentState();
}

class _DrawingDialogContentState extends State<DrawingDialogContent> {
  final GlobalKey _boundaryKey = GlobalKey();
  List<Stroke> _strokes = [];
  Stroke? _currentStroke;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // (선택) 타이틀 바
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text('터치로 그리세요', style: TextStyle(fontSize: 18)),
        ),

        // 드로잉 캔버스
        Expanded(
          child: RepaintBoundary(
            key: _boundaryKey,
            child: GestureDetector(
              onPanStart: (e) {
                final paint = Paint()
                  ..color = Colors.black
                  ..strokeWidth = 8.0
                  ..strokeCap = StrokeCap.round;
                _currentStroke = Stroke([e.localPosition], paint);
                setState(() => _strokes.add(_currentStroke!));
              },
              onPanUpdate: (e) {
                setState(() => _currentStroke!.points.add(e.localPosition));
              },
              onPanEnd: (_) => _currentStroke = null,
              child: CustomPaint(
                painter: DrawingPainter(_strokes),
                size: Size.infinite,
              ),
            ),
          ),
        ),

        // 액션 버튼
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            TextButton(
              onPressed: () => setState(() => _strokes.clear()),
              child: Text('지우기'),
            ),
            TextButton(
              onPressed: () async {
                // 3) 해상도를 높여서 PNG로 변환
                final boundary = _boundaryKey.currentContext!
                    .findRenderObject() as RenderRepaintBoundary;
                // pixelRatio를 3.0 이상으로 설정하면 결과 이미지가 더 선명해집니다.
                final ui.Image image =
                    await boundary.toImage(pixelRatio: 3.0);
                final byteData =
                    await image.toByteData(format: ui.ImageByteFormat.png);
                final pngBytes = byteData!.buffer.asUint8List();

                Navigator.pop(context, pngBytes);
              },
              child: Text('확인'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('취소'),
            ),
          ],
        ),
      ],
    );
  }
}

// Stroke 모델과 CustomPainter
class Stroke {
  final List<Offset> points;
  final Paint paint;
  Stroke(this.points, this.paint);
}

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
