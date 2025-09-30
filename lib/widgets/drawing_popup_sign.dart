// lib/pages/components/drawing_popup.dart
// 전체 소스: 기존 로직은 유지하고, 캔버스 영역만 AspectRatio(기본 3:1)로 고정했습니다.

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class DrawingDialogContentSign extends StatefulWidget {
  const DrawingDialogContentSign({
    super.key,
    this.aspectRatio = 3 / 1, // ✅ 기본 비율: 가로 3 : 세로 1
  });

  final double aspectRatio;

  @override
  State<DrawingDialogContentSign> createState() => _DrawingDialogContentSignState();
}

class _DrawingDialogContentSignState extends State<DrawingDialogContentSign> {
  final GlobalKey _boundaryKey = GlobalKey();
  final List<Stroke> _strokes = [];
  Stroke? _currentStroke;

  double _strokeWidth = 3.0; // 선 굵기

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 타이틀
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text('터치로 입력하세요.', style: TextStyle(fontSize: 18)),
        ),

        // 드로잉 캔버스 (비율 고정)
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: widget.aspectRatio, // ✅ 비율만 여기서 제어
              child: RepaintBoundary(
                key: _boundaryKey,
                child: ColoredBox( // 배경 흰색(투명 PNG 축소시 얼룩 방지)
                  color: Colors.white,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanStart: (e) {
                      final paint = Paint()
                        ..color = Colors.black
                        ..strokeWidth = _strokeWidth
                        ..style = PaintingStyle.stroke
                        ..strokeCap = StrokeCap.round
                        ..strokeJoin = StrokeJoin.round
                        ..isAntiAlias = true;

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
          ),
        ),

        // 하단 액션
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Row(
            children: [
              // 굵기 슬라이더
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
                  Navigator.pop(context, bytes); // PNG 바이트 반환
                },
                child: const Text('확인'),
              ),
              const SizedBox(width: 4),
              TextButton(
                onPressed: () => Navigator.pop(context), // 취소(null 반환)
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

    // 저해상 단말에서도 선명하게: DPR과 3.0 중 큰 값 사용
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
      if (pts.isEmpty) continue;

      // 탭만 하고 뗀 경우 점 처리
      if (pts.length == 1) {
        canvas.drawPoints(ui.PointMode.points, pts, stroke.paint);
        continue;
      }

      // 인접한 점들을 선으로 연결
      for (int i = 0; i < pts.length - 1; i++) {
        canvas.drawLine(pts[i], pts[i + 1], stroke.paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant DrawingPainter oldDelegate) => true;
}
