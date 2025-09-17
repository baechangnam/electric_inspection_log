// drawing_popup.dart
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class DrawingDialogContent extends StatefulWidget {
  const DrawingDialogContent({super.key});

  @override
  State<DrawingDialogContent> createState() => _DrawingDialogContentState();
}

class _DrawingDialogContentState extends State<DrawingDialogContent> {
  final GlobalKey _boundaryKey = GlobalKey();
  final List<Stroke> _strokes = [];
  Stroke? _currentStroke;

  double _strokeWidth = 3.0; // 선 굵기 조절(원하면 슬라이더로 바꿔도 됨)

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 타이틀
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text('터치로 서명하세요', style: TextStyle(fontSize: 18)),
        ),

        // 드로잉 캔버스
        Expanded(
          child: RepaintBoundary(
            key: _boundaryKey,
            child: ColoredBox( // ✅ 배경 흰색 (투명 PNG 축소시 생기는 얼룩 방지)
              color: Colors.white,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanStart: (e) {
                  final paint = Paint()
                    ..color = Colors.black
                    ..strokeWidth = _strokeWidth
                    ..style = PaintingStyle.stroke
                    ..strokeCap = StrokeCap.round
                    ..strokeJoin = StrokeJoin.round // ✅ 꼭 추가
                    ..isAntiAlias = true;            // ✅ 부드럽게

                  _currentStroke = Stroke([e.localPosition], paint);
                  setState(() => _strokes.add(_currentStroke!));
                },
                onPanUpdate: (e) {
                  setState(() => _currentStroke?.points.add(e.localPosition));
                },
                onPanEnd: (_) => _currentStroke = null,
                child: CustomPaint(
                  painter: DrawingPainter(_strokes),
                  size: Size.infinite,
                ),
              ),
            ),
          ),
        ),

        // 하단 액션
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Row(
            children: [
              // 굵기 (선택)
              Expanded(
                child: Row(
                  children: [
                    const Text('굵기'),
                    Expanded(
                      child: Slider(
                        value: _strokeWidth,
                        min: 1.5,
                        max: 8.0,
                        onChanged: (v) => setState(() => _strokeWidth = v),
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => setState(() => _strokes.clear()),
                child: const Text('지우기'),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () async {
                  final bytes = await _exportPng(context);
                  if (!mounted) return;
                  Navigator.pop(context, bytes);
                },
                child: const Text('확인'),
              ),
              const SizedBox(width: 4),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('취소'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 고해상도 PNG로 내보내기
  Future<Uint8List> _exportPng(BuildContext context) async {
    final boundary =
        _boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

    // ✅ DPR과 3.0 중 큰 값 사용 (저해상도 단말에서도 선명하게)
    final dpr = MediaQuery.of(context).devicePixelRatio;
    final pixelRatio = dpr < 3.0 ? 3.0 : dpr;

    final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }
}

/// Stroke & Painter
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
    for (final stroke in strokes) {
      final pts = stroke.points;
      if (pts.length < 2) continue;

      // 기본: 인접 점들을 선으로 연결(StrokeJoin.round + isAntiAlias로 충분히 매끈)
      for (int i = 0; i < pts.length - 1; i++) {
        canvas.drawLine(pts[i], pts[i + 1], stroke.paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant DrawingPainter oldDelegate) => true;
}
