// lib/services/pdf_exporter.dart
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfExporter {
  static Future<File> exportFromBoundary(
    GlobalKey boundaryKey, {
    double pixelRatio = 3.0,
  }) async {
    // 프레임 안정화 약간 대기
    await Future.delayed(const Duration(milliseconds: 50));

    final boundary = boundaryKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null) {
      throw Exception('RepaintBoundary를 찾을 수 없습니다.');
    }

    final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
    final byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) throw Exception('이미지 변환 실패');

    final pngBytes = byteData.buffer.asUint8List();

    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        margin: pw.EdgeInsets.zero,
        build: (ctx) => pw.Center(
          child: pw.Image(pw.MemoryImage(pngBytes), fit: pw.BoxFit.contain),
        ),
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/inspection_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    await file.writeAsBytes(await pdf.save(), flush: true);
    return file;
  }
}
