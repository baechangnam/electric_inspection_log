import 'dart:typed_data';

import 'package:electric_inspection_log/data/models/hvItem.dart';
import 'package:electric_inspection_log/widgets/inspection_entry.dart';
import 'package:image/image.dart' as img;
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;

class KoHighHeaderLow {
  static void apply(xlsio.Worksheet s) {
    s.name = '저압일지';
    s.showGridlines = false;

    for (int c = 1; c <= 28; c++) {
      s.getRangeByIndex(1, c).columnWidth = 4.0;
    }
    for (int r = 1; r <= 6; r++) {
      s.getRangeByIndex(r, 1).rowHeight = 24;
    }

    xlsio.Range rg(String a1) => s.getRangeByName(a1);

    void borderAll(xlsio.Range r) {
      final b = r.cellStyle.borders;
      b.all.lineStyle = xlsio.LineStyle.thin;
    }

    void mergeLabel(
      String a1,
      String text, {
      bool bold = false,
      double? size,
      xlsio.HAlignType h = xlsio.HAlignType.center,
      xlsio.VAlignType v = xlsio.VAlignType.center,
      bool withBorder = true,
      int? rotation, // 세로 회전(필요시)
    }) {
      final r = rg(a1)..merge();
      r.setText(text);
      r.cellStyle
        ..bold = bold
        ..hAlign = h
        ..vAlign = v
        ..wrapText = true;
      if (size != null) r.cellStyle.fontSize = size;
      if (rotation != null) r.cellStyle.rotation = rotation;
      if (withBorder) borderAll(r);
    }

    // 1) 제목
    mergeLabel('C3:O4', '전기설비 점검결과 통지서', bold: true, size: 16);

    // 2) 결재/담당/팀장
    mergeLabel('T2:T5', '결재', rotation: 255); // 세로 배치
    rg('U2:W2').merge();
    rg('U2').setText('담당');
    rg('U2:W2').cellStyle
      ..bold = true
      ..hAlign = xlsio.HAlignType.center
      ..vAlign = xlsio.VAlignType.center;
    borderAll(rg('U2:W2'));

    rg('U3:W5').merge();
    rg('U3:W5').cellStyle
      ..hAlign = xlsio.HAlignType.center
      ..vAlign = xlsio.VAlignType.center;
    borderAll(rg('U3:W5'));

    rg('X2:Z2').merge();
    rg('X2').setText('팀장');
    rg('X2:Z2').cellStyle
      ..bold = true
      ..hAlign = xlsio.HAlignType.center
      ..vAlign = xlsio.VAlignType.center;
    borderAll(rg('X2:Z2'));

    rg('X3:Z5').merge();
    rg('X3:Z5').cellStyle
      ..hAlign = xlsio.HAlignType.center
      ..vAlign = xlsio.VAlignType.center;
    borderAll(rg('X3:Z5'));

    // 6행 비움

    // 3) 7행(보더 없음, 폰트 작게)
    mergeLabel('A8:C8', '고객명(상호)', bold: true, size: 10, withBorder: false);
    mergeLabel('M8:N8', '귀중', bold: true, size: 10, withBorder: false);
    mergeLabel('U8:V8', '일기', bold: true, size: 10, withBorder: false);

    rg('D8:L8').merge();
    rg('D8:L8').cellStyle
      ..fontSize = 10
      ..hAlign = xlsio.HAlignType.left
      ..vAlign = xlsio.VAlignType.center;

    rg('O8:T8').merge();
    rg('O8:T8').cellStyle
      ..fontSize = 10
      ..hAlign = xlsio.HAlignType.center
      ..vAlign = xlsio.VAlignType.center;

    rg('W8:AB8').merge();
    rg('W8:AB8').cellStyle
      ..fontSize = 10
      ..hAlign = xlsio.HAlignType.center
      ..vAlign = xlsio.VAlignType.center
      ..wrapText = true;
  }

  /// 7행 값 채우기
  static void fillRow7(
    xlsio.Worksheet s, {
    String consumerName = '',
    String dateText = '',
    String weatherText = '',
  }) {
    s.getRangeByName('D8:L8').setText(consumerName);
    s.getRangeByName('O8:T8').setText(dateText);
    s.getRangeByName('W8:AB8').setText(weatherText);
  }

  /// 9~10행 표 레이아웃 구성(보더 포함)
  static void applyRow910(xlsio.Worksheet s) {
    xlsio.Range rgRC(int r1, int c1, int r2, int c2) =>
        s.getRangeByIndex(r1, c1, r2, c2);
    int startRow = 9;
    int rowCount = 2;
    int startCol = 1; // A
    int endCol = 28; // AB

    final area = rgRC(startRow, startCol, startRow + rowCount - 1, endCol)
      ..merge();
    final b = area.cellStyle.borders;
    b.all.lineStyle = xlsio.LineStyle.thin;
    b.all.color = '#000000';
    b.top.lineStyle = xlsio.LineStyle.thick;
    b.bottom.lineStyle = xlsio.LineStyle.thick;
    b.left.lineStyle = xlsio.LineStyle.thick;
    b.right.lineStyle = xlsio.LineStyle.thick;

    xlsio.Range rg(String a1) => s.getRangeByName(a1);
    void borderAll(xlsio.Range r) {
      final b = r.cellStyle.borders;
      b.all.lineStyle = xlsio.LineStyle.thin;
    }

    // 높이(선택): 보기 좋게 살짝 키우기
    s.getRangeByIndex(9, 1).rowHeight = 22;
    s.getRangeByIndex(10, 1).rowHeight = 22;

    // 계약 용량 (두 행 병합)
    final rContract = rg('A9:B10')..merge();
    rContract.setText('계약\n용량');
    rContract.cellStyle
      ..hAlign = xlsio.HAlignType.center
      ..vAlign = xlsio.VAlignType.center
      ..wrapText = true
      ..bold = true;
    borderAll(rContract);

    // 수전 / 발전 라벨
    final rSu = rg('C9:E9')..merge();
    rSu.setText('수전');
    rSu.cellStyle
      ..hAlign = xlsio.HAlignType.center
      ..vAlign = xlsio.VAlignType.center
      ..bold = true;
    borderAll(rSu);

    final rBal = rg('C10:E10')..merge();
    rBal.setText('발전');
    rBal.cellStyle
      ..hAlign = xlsio.HAlignType.center
      ..vAlign = xlsio.VAlignType.center
      ..bold = true;
    borderAll(rBal);

    // 입력값: F~G (수전/발전)
    final rInCap = rg('F9:G9')..merge();
    final rGenCap = rg('F10:G10')..merge();
    [rInCap, rGenCap].forEach((r) {
      r.cellStyle
        ..hAlign = xlsio.HAlignType.center
        ..vAlign = xlsio.VAlignType.center;
      borderAll(r);
    });

    // KW 라벨: H9, H10
    final rKW1 = rg('H9');
    rKW1.setText('KW');
    final rKW2 = rg('H10');
    rKW2.setText('KW');
    [rKW1, rKW2].forEach((r) {
      r.cellStyle
        ..hAlign = xlsio.HAlignType.center
        ..vAlign = xlsio.VAlignType.center
        ..bold = true;
      borderAll(r);
    });

    // 1차 전압: I~J (수전/발전)
    final rInPri = rg('I9:J9')..merge();
    final rGenPri = rg('I10:J10')..merge();
    [rInPri, rGenPri].forEach((r) {
      r.cellStyle
        ..hAlign = xlsio.HAlignType.center
        ..vAlign = xlsio.VAlignType.center;
      borderAll(r);
    });

    // 슬래시: K9, K10
    final rSlash1 = rg('K9');
    rSlash1.setText('/');
    final rSlash2 = rg('K10');
    rSlash2.setText('/');
    [rSlash1, rSlash2].forEach((r) {
      r.cellStyle
        ..hAlign = xlsio.HAlignType.center
        ..vAlign = xlsio.VAlignType.center;
      borderAll(r);
    });

    // 2차 전압: L~M (수전/발전)
    final rInSec = rg('L9:M9')..merge();
    final rGenSec = rg('L10:M10')..merge();
    [rInSec, rGenSec].forEach((r) {
      r.cellStyle
        ..hAlign = xlsio.HAlignType.center
        ..vAlign = xlsio.VAlignType.center;
      borderAll(r);
    });

    // V 라벨: N9, N10
    final rV1 = rg('N9');
    rV1.setText('V');
    final rV2 = rg('N10');
    rV2.setText('V');
    [rV1, rV2].forEach((r) {
      r.cellStyle
        ..hAlign = xlsio.HAlignType.center
        ..vAlign = xlsio.VAlignType.center
        ..bold = true;
      borderAll(r);
    });

    // 태양광 설비 (두 행 병합)
    final rSolarTitle = rg('O9:P10')..merge();
    rSolarTitle.setText('태양광\n설비');
    rSolarTitle.cellStyle
      ..hAlign = xlsio.HAlignType.center
      ..vAlign = xlsio.VAlignType.center
      ..wrapText = true
      ..bold = true;
    borderAll(rSolarTitle);

    // 태양광 값: Q~R
    final rSolarCap = rg('Q9:R9')..merge();
    final rSolarVolt = rg('Q10:R10')..merge();
    [rSolarCap, rSolarVolt].forEach((r) {
      r.cellStyle
        ..hAlign = xlsio.HAlignType.center
        ..vAlign = xlsio.VAlignType.center;
      borderAll(r);
    });

    // T: KW / V
    final rTkw = rg('S9');
    rTkw.setText('KW');
    final rTv = rg('S10');
    rTv.setText('V');
    [rTkw, rTv].forEach((r) {
      r.cellStyle
        ..hAlign = xlsio.HAlignType.center
        ..vAlign = xlsio.VAlignType.center
        ..bold = true;
      borderAll(r);
    });

    // 합계 (두 행 병합): U~V
    final rSumLabel = rg('T9:V10')..merge();
    rSumLabel.setText('합계');
    rSumLabel.cellStyle
      ..hAlign = xlsio.HAlignType.center
      ..vAlign = xlsio.VAlignType.center
      ..bold = true;
    borderAll(rSumLabel);

    // 합계 텍스트: W~Z (두 행 병합)
    final rSumText = rg('W9:Z10')..merge();
    rSumText.cellStyle
      ..hAlign = xlsio.HAlignType.center
      ..vAlign = xlsio.VAlignType.center
      ..bold = true;
    borderAll(rSumText);

    // AB: KW (두 행 병합)
    final rEndKW = rg('AB9:AB10')..merge();
    rEndKW.setText('KW');
    rEndKW.cellStyle
      ..hAlign = xlsio.HAlignType.center
      ..vAlign = xlsio.VAlignType.center
      ..bold = true;
    borderAll(rEndKW);
  }

  static void drawOuterBorderCellwise(
    xlsio.Worksheet s, {
    required int r1, // top row
    required int c1, // left col
    required int r2, // bottom row
    required int c2, // right col
    xlsio.LineStyle style = xlsio.LineStyle.medium,
    String color = '#000000',
  }) {
    // Top edge
    for (int c = c1; c <= c2; c++) {
      final b = s.getRangeByIndex(r1, c).cellStyle.borders;
      b.top.lineStyle = style;
      b.top.color = color;
    }
    // Bottom edge
    for (int c = c1; c <= c2; c++) {
      final b = s.getRangeByIndex(r2, c).cellStyle.borders;
      b.bottom.lineStyle = style;
      b.bottom.color = color;
    }
    // Left edge
    for (int r = r1; r <= r2; r++) {
      final b = s.getRangeByIndex(r, c1).cellStyle.borders;
      b.left.lineStyle = style;
      b.left.color = color;
    }
    // Right edge
    for (int r = r1; r <= r2; r++) {
      final b = s.getRangeByIndex(r, c2).cellStyle.borders;
      b.right.lineStyle = style;
      b.right.color = color;
    }
  }

  static void setOuterBorder(
    xlsio.Worksheet s,
    String a1, {
    xlsio.LineStyle style = xlsio.LineStyle.thick, // medium도 OK
    String color = '#000000',
  }) {
    final b = s.getRangeByName(a1).cellStyle.borders;
    for (final side in [b.top, b.bottom, b.left, b.right]) {
      side.lineStyle = style;
      side.color = color;
    }
  }

  static void applyRow12to16(xlsio.Worksheet s) {
    xlsio.Range rg(String a1) => s.getRangeByName(a1);

    void thinBlackAll(xlsio.Range r) {
      final b = r.cellStyle.borders;
      b.all.lineStyle = xlsio.LineStyle.thin;
      b.all.color = '#000000';
    }

    void outerMediumBlack(String a1) {
      final b = rg(a1).cellStyle.borders;
      for (final side in [b.top, b.bottom, b.left, b.right]) {
        side.lineStyle = xlsio.LineStyle.thick;
        side.color = '#000000';
      }
    }

    // 보기 좋은 높이
    for (var r = 12; r <= 16; r++) {
      s.getRangeByIndex(r, 1).rowHeight = 22;
    }

    // A12:A16 병합 — '안전교육' 세로 배치
    final title = rg('A12:A16')..merge();
    title.setText('안전교육');
    title.cellStyle
      ..hAlign = xlsio.HAlignType.center
      ..vAlign = xlsio.VAlignType.center
      ..rotation =
          255 // 세로(쌓은) 텍스트
      ..bold = true
      ..wrapText = true;
    thinBlackAll(title);

    // 각 행: B~AB 병합 + 얇은 검은 보더
    for (var r = 12; r <= 16; r++) {
      final line = rg('B$r:AB$r')..merge();
      line.cellStyle
        ..hAlign = xlsio.HAlignType.left
        ..vAlign = xlsio.VAlignType.center
        ..wrapText = true;
      thinBlackAll(line);
    }

    // 블록 전체 바깥 테두리 "조금 굵은" 검은색
    outerMediumBlack('A12:AB16');
  }

  static void fillRow12to16(xlsio.Worksheet s, {List<String>? lines}) {
    final items =
        lines ??
        const [
          ' 1. 부적합 설비를 방치하시면 전기재해 및 정전으로 인한 전력손실 등의 원인이 될 수 있으니 조속히 개·보수 요망.',
          ' 2. 전기설비의 개·보수 시 전기안전관리사 통보, 전문업체 시공, 정전상태 시행, 전기안전관리법령 준수.',
          ' 3. 내용 년수가 경과한 전기설비는 교체 대상입니다.',
          ' 4. 젖은 손으로 전기코드, 차단기 및 전기기계·기구 조작 엄금.',
          ' 5. 월 1회 이상 전직원의 전기안전교육을 실시하십시오.',
        ];

    for (var i = 0; i < 5; i++) {
      final row = 12 + i;
      s.getRangeByName('B$row:AB$row').setText(items[i]);
    }
  }

  static void emphasizeRow910OuterBorder(xlsio.Worksheet s) {
    void top(String a1) {
      final b = s.getRangeByName(a1).cellStyle.borders;
      b.top.lineStyle = xlsio.LineStyle.thick;
      b.top.color = '#000000';
    }

    void bottom(String a1) {
      final b = s.getRangeByName(a1).cellStyle.borders;
      b.bottom.lineStyle = xlsio.LineStyle.thick;
      b.bottom.color = '#000000';
    }

    void left(String a1) {
      final b = s.getRangeByName(a1).cellStyle.borders;
      b.left.lineStyle = xlsio.LineStyle.thick;
      b.left.color = '#000000';
    }

    void right(String a1) {
      final b = s.getRangeByName(a1).cellStyle.borders;
      b.right.lineStyle = xlsio.LineStyle.thick;
      b.right.color = '#000000';
    }

    // 9~10 블록의 네 변을 개별로 강제
    top('A9:AB9');
    bottom('A10:AB10');
    left('A9:A10');
    right('AB9:AB10');
  }

  static void applyThinGrayBorders(xlsio.Worksheet s, String rangeA1) {
    final r = s.getRangeByName(rangeA1);
    final b = r.cellStyle.borders;
    b.all.lineStyle = xlsio.LineStyle.thin;
    // 경계색(연한 회색) — 필요 없으면 이 줄 지워도 됨
    b.all.color = '#BFBFBF'; // or '#D9D9D9'
  }

  /// 9~10행 값 채우기 (메인 뷰 값 주입)
  static void fillRow910(
    xlsio.Worksheet s, {
    String incomingCapacity = '',
    String generationCapacity = '',
    String incomingPrimaryVoltage = '',
    String generationPrimaryVoltage = '',
    String incomingSecondaryVoltage = '',
    String generationSecondaryVoltage = '',
    String solarCapacity = '',
    String solarVoltage = '',
    String sumText = '',
  }) {
    s.getRangeByName('F9:G9').setText(incomingCapacity);
    s.getRangeByName('F10:G10').setText(generationCapacity);

    s.getRangeByName('I9:J9').setText(incomingPrimaryVoltage);
    s.getRangeByName('I10:J10').setText(generationPrimaryVoltage);

    s.getRangeByName('L9:M9').setText(incomingSecondaryVoltage);
    s.getRangeByName('L10:M10').setText(generationSecondaryVoltage);

    s.getRangeByName('Q9:R9').setText(solarCapacity);
    s.getRangeByName('Q10:R10').setText(solarVoltage);

    s.getRangeByName('W9:Z10').setText(sumText);
  }

  static void applyRow18(xlsio.Worksheet s) {
    // 보기 좋게 높이 조정 (선택)
    s.getRangeByIndex(18, 1).rowHeight = 22;

    final r = s.getRangeByName('A18:AB18')..merge();
    r.setText('점검내역(판정 : 양, 부)');
    r.cellStyle
      ..bold = true
      ..hAlign = xlsio.HAlignType.left
      ..vAlign = xlsio.VAlignType.center
      ..fontSize = 11
      ..wrapText = false;

    // 보더 제거 (전체 회색 보더를 깔았다면 반드시 border none으로 덮어쓰기)
    final b = r.cellStyle.borders;
    b.all.lineStyle = xlsio.LineStyle.none;
  }

  // KoHighHeader 안에 추가
  static void applyRow19(xlsio.Worksheet s) {
    xlsio.Range rg(String a1) => s.getRangeByName(a1);

    void thinBlackAll(xlsio.Range r) {
      final b = r.cellStyle.borders;
      b.all.lineStyle = xlsio.LineStyle.thin;
      b.all.color = '#000000';
    }

    void outerMediumBlack(String a1) {
      final b = rg(a1).cellStyle.borders;
      for (final side in [b.top, b.bottom, b.left, b.right]) {
        side.lineStyle = xlsio.LineStyle.medium; // 굵게
        side.color = '#000000';
      }
    }

    // 보기 좋은 높이(선택)
    s.getRangeByIndex(19, 1).rowHeight = 22;

    // ───── 그룹1: A..I (4:2:3) ─────
    final rLTitle = rg('A19:D19')..merge();
    rLTitle.setText('저 압 설 비');
    rLTitle.cellStyle
      ..bold = true
      ..hAlign = xlsio.HAlignType.center
      ..vAlign = xlsio.VAlignType.center
      ..wrapText = true;
    thinBlackAll(rLTitle);

    final rLJudge = rg('E19:F19')..merge();
    rLJudge.setText('판정');
    rLJudge.cellStyle
      ..bold = true
      ..hAlign = xlsio.HAlignType.center
      ..vAlign = xlsio.VAlignType.center;
    thinBlackAll(rLJudge);

    final rLRemark = rg('G19:I19')..merge();
    rLRemark.setText('비고');
    rLRemark.cellStyle
      ..bold = true
      ..hAlign = xlsio.HAlignType.center
      ..vAlign = xlsio.VAlignType.center;
    thinBlackAll(rLRemark);

    // ───── 그룹2: J..R (4:2:3) ─────
    final rMTitle = rg('J19:M19')..merge();
    rMTitle.setText('특고(고압)설비');
    rMTitle.cellStyle
      ..bold = true
      ..hAlign = xlsio.HAlignType.center
      ..vAlign = xlsio.VAlignType.center
      ..wrapText = true;
    thinBlackAll(rMTitle);

    final rMJudge = rg('N19:O19')..merge();
    rMJudge.setText('판정');
    rMJudge.cellStyle
      ..bold = true
      ..hAlign = xlsio.HAlignType.center
      ..vAlign = xlsio.VAlignType.center;
    thinBlackAll(rMJudge);

    final rMRemark = rg('P19:R19')..merge();
    rMRemark.setText('비고');
    rMRemark.cellStyle
      ..bold = true
      ..hAlign = xlsio.HAlignType.center
      ..vAlign = xlsio.VAlignType.center;
    thinBlackAll(rMRemark);

    // ───── 그룹3: S..AB (5:2:3) ─────
    final rRTitle = rg('S19:W19')..merge();
    rRTitle.setText('태양광설비');
    rRTitle.cellStyle
      ..bold = true
      ..hAlign = xlsio.HAlignType.center
      ..vAlign = xlsio.VAlignType.center
      ..wrapText = true;
    thinBlackAll(rRTitle);

    final rRJudge = rg('X19:Y19')..merge();
    rRJudge.setText('판정');
    rRJudge.cellStyle
      ..bold = true
      ..hAlign = xlsio.HAlignType.center
      ..vAlign = xlsio.VAlignType.center;
    thinBlackAll(rRJudge);

    final rRRemark = rg('Z19:AB19')..merge();
    rRRemark.setText('비고');
    rRRemark.cellStyle
      ..bold = true
      ..hAlign = xlsio.HAlignType.center
      ..vAlign = xlsio.VAlignType.center;
    thinBlackAll(rRRemark);

    // 19행 전체 외곽선 굵게
    outerMediumBlack('A19:AB19');
  }

  static void applyRows20to26FromEntry(
    xlsio.Worksheet s,
    SimpleHvLogEntry entry,
  ) {
    applyRows20to26(
      s,
      left: entry.lowVoltageItems,
      middle: entry.highVoltageItems,
      right: entry.solarItems,
    );
  }

  // 20~26행: 리스트로 채우기 (실제 구현)
  static void applyRows20to26(
    xlsio.Worksheet s, {
    required List<InspectionEntry> left,
    required List<InspectionEntry> middle,
    required List<InspectionEntry> right,
  }) {
    xlsio.Range rg(String a1) => s.getRangeByName(a1);

    void thinBlackAll(xlsio.Range r) {
      final b = r.cellStyle.borders;
      b.all.lineStyle = xlsio.LineStyle.thin;
      b.all.color = '#000000';
    }

    String jLabel(InspectionEntry e) =>
        (e.judgment == JudgmentOption.clear) ? '' : e.judgment.label;

    // 보기 좋은 높이
    for (var row = 20; row <= 26; row++) {
      s.getRangeByIndex(row, 1).rowHeight = 22;
    }

    // 최대 7줄(0..6)을 20..26행에 매핑
    for (int i = 0; i < 7; i++) {
      final row = 20 + i;

      final l = i < left.length
          ? left[i]
          : InspectionEntry(title: '', remark: '');
      final m = i < middle.length
          ? middle[i]
          : InspectionEntry(title: '', remark: '');
      final r = i < right.length
          ? right[i]
          : InspectionEntry(title: '', remark: '');

      // ── 왼쪽 그룹 A..I (4:2:3)
      final lTitle = rg('A$row:D$row')..merge();
      lTitle.setText(l.title);
      lTitle.cellStyle
        ..hAlign = xlsio.HAlignType.center
        ..vAlign = xlsio.VAlignType.center
        ..bold = true
        ..wrapText = true;
      thinBlackAll(lTitle);

      final lJudge = rg('E$row:F$row')..merge();
      lJudge.setText(jLabel(l));
      lJudge.cellStyle
        ..hAlign = xlsio.HAlignType.center
        ..vAlign = xlsio.VAlignType.center;
      thinBlackAll(lJudge);

      final lRemark = rg('G$row:I$row')..merge();
      lRemark.setText(l.remark);
      lRemark.cellStyle
        ..hAlign = xlsio.HAlignType.left
        ..vAlign = xlsio.VAlignType.center
        ..wrapText = true;
      thinBlackAll(lRemark);

      // ── 가운데 그룹 J..R (4:2:3)
      final mTitle = rg('J$row:M$row')..merge();
      mTitle.setText(m.title);
      mTitle.cellStyle
        ..hAlign = xlsio.HAlignType.center
        ..vAlign = xlsio.VAlignType.center
        ..bold = true
        ..wrapText = true;
      thinBlackAll(mTitle);

      final mJudge = rg('N$row:O$row')..merge();
      mJudge.setText(jLabel(m));
      mJudge.cellStyle
        ..hAlign = xlsio.HAlignType.center
        ..vAlign = xlsio.VAlignType.center;
      thinBlackAll(mJudge);

      final mRemark = rg('P$row:R$row')..merge();
      mRemark.setText(m.remark);
      mRemark.cellStyle
        ..hAlign = xlsio.HAlignType.left
        ..vAlign = xlsio.VAlignType.center
        ..wrapText = true;
      thinBlackAll(mRemark);

      // ── 오른쪽 그룹 S..AB (4:2:4)  ← 19행 헤더와 동일 비율
      final rTitle = rg('S$row:W$row')..merge();
      rTitle.setText(r.title);
      rTitle.cellStyle
        ..hAlign = xlsio.HAlignType.center
        ..vAlign = xlsio.VAlignType.center
        ..bold = true
        ..wrapText = true;
      thinBlackAll(rTitle);

      final rJudge = rg('X$row:Y$row')..merge();
      rJudge.setText(jLabel(r));
      rJudge.cellStyle
        ..hAlign = xlsio.HAlignType.center
        ..vAlign = xlsio.VAlignType.center;
      thinBlackAll(rJudge);

      final rRemark = rg('Z$row:AB$row')..merge();
      rRemark.setText(r.remark);
      rRemark.cellStyle
        ..hAlign = xlsio.HAlignType.left
        ..vAlign = xlsio.VAlignType.center
        ..wrapText = true;
      thinBlackAll(rRemark);
    }
  }

  // KoHighHeader에 추가
  static void applyRows27to29(xlsio.Worksheet s) {
    xlsio.Range rg(String a1) => s.getRangeByName(a1);
    void thin(xlsio.Range r) {
      final b = r.cellStyle.borders;
      b.all.lineStyle = xlsio.LineStyle.thin;
      b.all.color = '#000000'; // ← 색을 명시해야 확실히 보입니다
    }

    final startRow = 27;
    for (var r = startRow; r <= startRow + 2; r++) {
      s.getRangeByIndex(r, 1).rowHeight = 22;
    }

    // ── LEFT A..I : 4:2:3  (A..D / E..F / G..I)
    for (var i = 0; i < 3; i++) {
      final row = startRow + i;
      final t = rg('A$row:D$row')..merge(); // 제목
      t.cellStyle
        ..hAlign = xlsio.HAlignType.center
        ..vAlign = xlsio.VAlignType.center
        ..wrapText = true
        ..bold = true;
      thin(t);

      final j = rg('E$row:F$row')..merge(); // 판정
      j.cellStyle
        ..hAlign = xlsio.HAlignType.center
        ..vAlign = xlsio.VAlignType.center
        ..bold = true;
      thin(j);

      final rmk = rg('G$row:I$row')..merge(); // 비고
      rmk.cellStyle
        ..hAlign = xlsio.HAlignType.center
        ..vAlign = xlsio.VAlignType.center
        ..wrapText = true;
      thin(rmk);
    }

    // ── MIDDLE J..R : 4:2:3 (J..M / N..O / P..R)
    for (var i = 0; i < 3; i++) {
      final row = startRow + i;
      final t = rg('J$row:M$row')..merge();
      t.cellStyle
        ..hAlign = xlsio.HAlignType.center
        ..vAlign = xlsio.VAlignType.center
        ..wrapText = true
        ..bold = true;
      thin(t);

      final j = rg('N$row:O$row')..merge();
      j.cellStyle
        ..hAlign = xlsio.HAlignType.center
        ..vAlign = xlsio.VAlignType.center
        ..bold = true;
      thin(j);

      final rmk = rg('P$row:R$row')..merge();
      rmk.cellStyle
        ..hAlign = xlsio.HAlignType.left
        ..vAlign = xlsio.VAlignType.center
        ..wrapText = true;
      thin(rmk);
    }
    // 특고 1행 비고에 '℃' 고정
    final deg = rg('P$startRow:R$startRow');
    deg.setText('℃');
    deg.cellStyle
      ..hAlign = xlsio.HAlignType.center
      ..vAlign = xlsio.VAlignType.center
      ..bold = true;

    // ── RIGHT S..AB : 5:2:3
    // 1) 송전전압 타이틀(3행 병합)
    final txTitle = rg('S$startRow:T${startRow + 2}')..merge();
    txTitle.setText('송전\n전압');
    txTitle.cellStyle
      ..hAlign = xlsio.HAlignType.center
      ..vAlign = xlsio.VAlignType.center
      ..wrapText = true
      ..bold = true;
    thin(txTitle);

    // 라벨 X..Y (행별)
    const labels = ['R~S', 'S~T', 'R~T'];
    for (var i = 0; i < 3; i++) {
      final row = startRow + i;
      final lab = rg('U$row:W$row')..merge();
      lab.setText(labels[i]);
      lab.cellStyle
        ..hAlign = xlsio.HAlignType.center
        ..vAlign = xlsio.VAlignType.center
        ..bold = true;
      thin(lab);
    }

    // 값 Z..AB — 행별로 각각 병합(더 이상 3행 통합 X)
    for (var i = 0; i < 3; i++) {
      final row = startRow + i;
      final vcell = rg('X$row:AB$row')..merge();
      vcell.cellStyle
        ..hAlign = xlsio
            .HAlignType
            .center // 원하면 left로
        ..vAlign = xlsio.VAlignType.center;
      thin(vcell);
    }
  }

  static void fillRows27to29(
    xlsio.Worksheet s, {
    required List<InspectionEntry> left, // 길이 3
    required List<InspectionEntry> middle, // 길이 3
    required double vRS,
    required double vST,
    required double vRT,
  }) {
    xlsio.Range rg(String a1) => s.getRangeByName(a1);

    String fmt(double v) {
      if (v == 0) return ''; // 값 없으면 빈칸
      // 정수면 정수로, 아니면 소수 1자리(원하면 자리수 조정)
      return (v % 1 == 0) ? v.toInt().toString() : v.toStringAsFixed(1);
    }

    final startRow = 27;

    // LEFT A..I
    for (var i = 0; i < 3; i++) {
      final row = startRow + i;
      final e = left[i];
      rg('A$row:D$row').setText(e.title);
      rg(
        'E$row:F$row',
      ).setText(e.judgment == JudgmentOption.clear ? '' : e.judgment.label);
      rg('G$row:I$row').setText(e.remark);
    }

    // MIDDLE J..R  (첫 행 비고는 '℃' 고정이므로 건드리지 않음)
    for (var i = 0; i < 3; i++) {
      final row = startRow + i;
      final e = middle[i];
      rg('J$row:M$row').setText(e.title);
      rg(
        'N$row:O$row',
      ).setText(e.judgment == JudgmentOption.clear ? '' : e.judgment.label);
      if (i != 0) {
        rg('P$row:R$row').setText(e.remark);
      }
    }

    // RIGHT S..AB — 값만 행별로
    rg('X$startRow:AB$startRow').setText(fmt(vRS)); // R~S
    rg('X${startRow + 1}:AB${startRow + 1}').setText(fmt(vST)); // S~T
    rg('X${startRow + 2}:AB${startRow + 2}').setText(fmt(vRT)); // R~T
  }

  static void applyRows30to35(
    xlsio.Worksheet s, {
    required List<InspectionEntry> left6, // 길이 6
    required List<InspectionEntry> middle6, // 길이 6
    required double pvVoltage,
    required double preMonthGenerationKwh,
    required double cumulativeGenerationMwh,
  }) {
    xlsio.Range rg(String a1) => s.getRangeByName(a1);
    void thin(xlsio.Range r) {
      final b = r.cellStyle.borders;
      b.all.lineStyle = xlsio.LineStyle.thin;
      b.all.color = '#000000';
    }

    String jLabel(InspectionEntry e) =>
        (e.judgment == JudgmentOption.clear) ? '' : e.judgment.label;
    String fmt(double v) {
      if (v == 0) return '';
      return (v % 1 == 0) ? v.toInt().toString() : v.toStringAsFixed(1);
    }

    // 보기 좋은 높이
    for (var row = 30; row <= 35; row++) {
      s.getRangeByIndex(row, 1).rowHeight = 22;
    }

    // ───────── LEFT A..I ─────────
    // 30~32: 4:2:3 그대로
    for (var i = 0; i < 3; i++) {
      final row = 30 + i;
      final e = left6[i];

      final t = rg('A$row:D$row')..merge();
      t.setText(e.title);
      t.cellStyle
        ..hAlign = xlsio.HAlignType.center
        ..vAlign = xlsio.VAlignType.center
        ..wrapText = true
        ..bold = true;
      thin(t);

      final j = rg('E$row:F$row')..merge();
      j.setText(jLabel(e));
      j.cellStyle
        ..hAlign = xlsio.HAlignType.center
        ..vAlign = xlsio.VAlignType.center;
      thin(j);

      final rmk = rg('G$row:I$row')..merge();
      rmk.setText(e.remark);
      rmk.cellStyle
        ..hAlign = xlsio.HAlignType.left
        ..vAlign = xlsio.VAlignType.center
        ..wrapText = true;
      thin(rmk);
    }

    // 33~35: A..B 에 '발전설비'(세로 3행 병합), C..D 에 각 행 title
    final genLabel = rg('A33:B35')..merge();
    genLabel.setText('발전설비');
    genLabel.cellStyle
      ..hAlign = xlsio.HAlignType.center
      ..vAlign = xlsio.VAlignType.center
      ..wrapText = true
      ..bold = true;
    thin(genLabel);

    for (var i = 0; i < 3; i++) {
      final row = 33 + i;
      final e = left6[3 + i];

      final t = rg('C$row:D$row')..merge();
      t.setText(e.title);
      t.cellStyle
        ..hAlign = xlsio.HAlignType.center
        ..vAlign = xlsio.VAlignType.center
        ..wrapText = true
        ..bold = true;
      thin(t);

      final j = rg('E$row:F$row')..merge();
      j.setText(jLabel(e));
      j.cellStyle
        ..hAlign = xlsio.HAlignType.center
        ..vAlign = xlsio.VAlignType.center;
      thin(j);

      final rmk = rg('G$row:I$row')..merge();
      rmk.setText(e.remark);
      rmk.cellStyle
        ..hAlign = xlsio.HAlignType.left
        ..vAlign = xlsio.VAlignType.center
        ..wrapText = true;
      thin(rmk);
    }

    // ───────── MIDDLE J..R (6행 공통 4:2:3) ─────────
    for (var i = 0; i < 6; i++) {
      final row = 30 + i;
      final e = middle6[i];

      final t = rg('J$row:M$row')..merge();
      t.setText(e.title);
      t.cellStyle
        ..hAlign = xlsio.HAlignType.center
        ..vAlign = xlsio.VAlignType.center
        ..wrapText = true
        ..bold = true;
      thin(t);

      final j = rg('N$row:O$row')..merge();
      j.setText(jLabel(e));
      j.cellStyle
        ..hAlign = xlsio.HAlignType.center
        ..vAlign = xlsio.VAlignType.center;
      thin(j);

      final rmk = rg('P$row:R$row')..merge();
      rmk.setText(e.remark);
      rmk.cellStyle
        ..hAlign = xlsio.HAlignType.left
        ..vAlign = xlsio.VAlignType.center
        ..wrapText = true;
      thin(rmk);
    }

    // ───────── RIGHT S..AB (5:3:2) — 2행씩 3블록 ─────────
    void block({
      required int topRow, // 30, 32, 34
      required String title, // 블록 타이틀
      required String value, // 값 문자열(이미 fmt 처리)
      required String unit, // 단위
    }) {
      final bottomRow = topRow + 1;

      final t = rg('S$topRow:W$bottomRow')..merge();
      t.setText(title);
      t.cellStyle
        ..hAlign = xlsio.HAlignType.center
        ..vAlign = xlsio.VAlignType.center
        ..wrapText = true
        ..bold = true;
      thin(t);

      final v = rg('X$topRow:Z$bottomRow')..merge();
      v.setText(value);
      v.cellStyle
        ..hAlign = xlsio.HAlignType.center
        ..vAlign = xlsio.VAlignType.center;
      thin(v);

      final u = rg('AA$topRow:AB$bottomRow')..merge();
      u.setText(unit);
      u.cellStyle
        ..hAlign = xlsio.HAlignType.center
        ..vAlign = xlsio.VAlignType.center
        ..bold = true;
      thin(u);
    }

    block(
      topRow: 30,
      title: 'P . V  전 압 (DC)',
      value: fmt(pvVoltage),
      unit: 'V',
    );

    block(
      topRow: 32,
      title: '전월  발 전 량',
      value: fmt(preMonthGenerationKwh),
      unit: 'KWH',
    );

    block(
      topRow: 34,
      title: '누적  발 전 량',
      value: fmt(cumulativeGenerationMwh),
      unit: 'KWH',
    );
  }

  // 엔트리로 바로 채우고 싶으면 이 헬퍼도 추가
  static void applyRows30to35FromEntry(
    xlsio.Worksheet s,
    SimpleHvLogEntry entry, {
    required List<InspectionEntry> left6,
    required List<InspectionEntry> middle6,
  }) {
    applyRows30to35(
      s,
      left6: left6,
      middle6: middle6,
      pvVoltage: entry.pvVoltage,
      preMonthGenerationKwh: entry.preMonthGenerationKwh,
      cumulativeGenerationMwh: entry.cumulativeGenerationMwh,
    );
  }

  // KoHighHeader 안에 추가
  static void applyRowsVoltageAndPower(
    xlsio.Worksheet s,
    SimpleHvLogEntry e, {
    int startRow = 30, // 원하는 시작행
  }) {
    xlsio.Range rg(String a1) => s.getRangeByName(a1);
    void thin(xlsio.Range r) {
      final b = r.cellStyle.borders;
      b.all.lineStyle = xlsio.LineStyle.thin;
      b.all.color = '#000000';
    }

    String fmt(double v) {
      // 0이면 빈칸
      if (v == 0) return '';
      // 정수면 정수로, 아니면 소수1자리
      return (v % 1 == 0) ? v.toInt().toString() : v.toStringAsFixed(1);
    }

    void style(xlsio.Range r, {bool bold = false}) {
      r.cellStyle
        ..hAlign = xlsio.HAlignType.center
        ..vAlign = xlsio.VAlignType.center
        ..wrapText = true
        ..bold = bold;
      thin(r);
    }

    // 보기 좋은 높이
    s.getRangeByIndex(startRow, 1).rowHeight = 22;
    s.getRangeByIndex(startRow + 1, 1).rowHeight = 22;

    // ───────── 1행: 측정전압 4세트 (Group1 4:2:2, Group4 3:2:1) ─────────
    final r1 = startRow;

    // Group1: A..H => [라벨 A..D][값 E..F][단위 G..H]
    style(rg('A$r1:D$r1')..merge(), bold: true);
    rg('A$r1').setText('측정전압R~S');
    style(rg('E$r1:F$r1')..merge());
    rg('E$r1').setText(fmt(e.measuredVoltageRtoS));
    style(rg('G$r1:H$r1')..merge(), bold: true);
    rg('G$r1').setText('V');

    // Group2: I..O => [라벨 I..K][값 L..M][단위 N..O]
    style(rg('I$r1:K$r1')..merge(), bold: true);
    rg('I$r1').setText('S~T');
    style(rg('L$r1:M$r1')..merge());
    rg('L$r1').setText(fmt(e.measuredVoltageStoT));
    style(rg('N$r1:O$r1')..merge(), bold: true);
    rg('N$r1').setText('V');

    // Group3: P..V => [라벨 P..R][값 S..T][단위 U..V]
    style(rg('P$r1:R$r1')..merge(), bold: true);
    rg('P$r1').setText('R~T');
    style(rg('S$r1:T$r1')..merge());
    rg('S$r1').setText(fmt(e.measuredVoltageRtoT));
    style(rg('U$r1:V$r1')..merge(), bold: true);
    rg('U$r1').setText('V');

    // Group4: W..AB => [라벨 W..Y][값 Z..AA][단위 AB]
    style(rg('W$r1:Y$r1')..merge(), bold: true);
    rg('W$r1').setText('N');
    style(rg('Z$r1:AA$r1')..merge());
    rg('Z$r1').setText(fmt(e.measuredVoltageN));
    style(rg('AB$r1:AB$r1')..merge(), bold: true);
    rg('AB$r1').setText('V');

    // ───────── 2행: 전력/배율/역율 4세트 (Group1 4:2:2, Group4 3:2:1) ─────────
    final r2 = startRow + 1;

    // Group1: A..H
    style(rg('A$r2:D$r2')..merge(), bold: true);
    rg('A$r2').setText('최대전력');
    style(rg('E$r2:F$r2')..merge());
    rg('E$r2').setText(fmt(e.maxPower));
    style(rg('G$r2:H$r2')..merge(), bold: true);
    rg('G$r2').setText('KW');

    // Group2: I..O
    style(rg('I$r2:K$r2')..merge(), bold: true);
    rg('I$r2').setText('평균전력');
    style(rg('L$r2:M$r2')..merge());
    rg('L$r2').setText(fmt(e.avgPower));
    style(rg('N$r2:O$r2')..merge(), bold: true);
    rg('N$r2').setText('KW');

    // Group3: P..V
    style(rg('P$r2:R$r2')..merge(), bold: true);
    rg('P$r2').setText('배율');
    style(rg('S$r2:T$r2')..merge());
    rg('S$r2').setText(fmt(e.powerRatio));
    style(rg('U$r2:V$r2')..merge(), bold: true);
    rg('U$r2').setText('%');

    // Group4: W..AB
    style(rg('W$r2:Y$r2')..merge(), bold: true);
    rg('W$r2').setText('역율');
    style(rg('Z$r2:AA$r2')..merge());
    rg('Z$r2').setText(fmt(e.powerFactor));
    style(rg('AB$r2:AB$r2')..merge(), bold: true);
    rg('AB$r2').setText('%');
  }

  static void applyRow39Header(
    xlsio.Worksheet s, {
    bool withBorder = false, // 테두리 줄지 여부
    double fontSize = 12, // 글자 크기
  }) {
    xlsio.Range rg(String a1) => s.getRangeByName(a1);

    // 보기 좋은 높이
    s.getRangeByIndex(39, 1).rowHeight = 22;

    // A39:AB39 병합 + 텍스트
    final r = rg('A39:AB39')..merge();
    r.setText('점검결과 및 보안, 안전사항');
    r.cellStyle
      ..bold = true
      ..fontSize = fontSize
      ..hAlign = xlsio.HAlignType.left
      ..vAlign = xlsio.VAlignType.center
      ..wrapText = true;

    if (withBorder) {
      final b = r.cellStyle.borders;
      b.all.lineStyle = xlsio.LineStyle.thin; // 원하면 medium/thick 로 변경
      b.all.color = '#000000';
    }
  }

  static void applyResultBlock(
    xlsio.Worksheet s, {
    Uint8List? imageBytes,
    String? text,
    int startRow = 40, // 시작 행
    int rowCount = 3, // 3행 사용
    int startCol = 1, // A
    int endCol = 28, // AB
    double padding = 6.0, // 가장자리 여백(px)
    double fill = 0.98, // 영역 대비 차지 비율(0~1)
  }) {
    xlsio.Range rgRC(int r1, int c1, int r2, int c2) =>
        s.getRangeByIndex(r1, c1, r2, c2);

    // 보기 좋은 높이(필요시만 증가)
    for (int r = startRow; r < startRow + rowCount; r++) {
      final h = s.getRangeByIndex(r, 1).rowHeight;
      if (h == 0 || h < 24) {
        s.getRangeByIndex(r, 1).rowHeight = 24;
      }
    }

    // 병합 + 보더(바깥 굵게, 안쪽 얇게)
    final area = rgRC(startRow, startCol, startRow + rowCount - 1, endCol)
      ..merge();
    final b = area.cellStyle.borders;
    b.all.lineStyle = xlsio.LineStyle.thin;
    b.all.color = '#000000';
    b.top.lineStyle = xlsio.LineStyle.thick;
    b.bottom.lineStyle = xlsio.LineStyle.thick;
    b.left.lineStyle = xlsio.LineStyle.thick;
    b.right.lineStyle = xlsio.LineStyle.thick;

    area.cellStyle
      ..hAlign = xlsio.HAlignType.left
      ..vAlign = xlsio.VAlignType.top
      ..wrapText = true
      ..fontSize = 11;

    // 이미지 없으면 텍스트로
    if (imageBytes == null || imageBytes.isEmpty) {
      final content = (text ?? '').trim();
      area.setText(content.isEmpty ? '' : content);
      return;
    }

    // ── 이미지 모드 ─────────────────────────────────────────────
    // 1) 영역 픽셀 크기 추정(Excel 폭/높이 → px 근사)
    double colToPx(double colWidth) => colWidth * 7.0 + 5.0; // 근사식
    double ptToPx(double pt) => pt * (96.0 / 72.0); // 96dpi 가정

    // 너비(px)
    double areaWidthPx = 0;
    for (int c = startCol; c <= endCol; c++) {
      areaWidthPx += colToPx(s.getRangeByIndex(1, c).columnWidth);
    }
    // 높이(px)
    double areaHeightPx = 0;
    for (int r = startRow; r < startRow + rowCount; r++) {
      areaHeightPx += ptToPx(s.getRangeByIndex(r, 1).rowHeight);
    }

    final maxW = (areaWidthPx - padding * 2).clamp(20, 100000).toDouble();
    final maxH = (areaHeightPx - padding * 2).clamp(20, 100000).toDouble();

    // 2) 원본 이미지 크기 추출 (package:image)
    int w = 0, h = 0;
    final decoded = img.decodeImage(imageBytes);
    if (decoded != null) {
      w = decoded.width;
      h = decoded.height;
    } else {
      // 디코딩 실패 시, 영역 크기에 맞춘 대략값으로
      w = maxW.toInt();
      h = maxH.toInt();
    }

    // 3) 비율 유지 스케일
    final sx = maxW / w;
    final sy = maxH / h;
    final scale = (sx < sy ? sx : sy) * fill;

    final outW = (w * scale).round();
    final outH = (h * scale).round();

    // 4) 그림 추가 후 중앙 오프셋
    final pic = s.pictures.addStream(startRow, startCol, imageBytes);
    pic.width = outW;
    pic.height = outH;
  }

  static void applyGuidelineRows(
    xlsio.Worksheet s,
    SimpleHvLogEntry e, {
    int startRow = 43,
  }) {
    xlsio.Range rg(String a1) => s.getRangeByName(a1);

    String fmt(num? v) {
      if (v == null) return '';
      final d = v.toDouble();
      if (d == 0) return '';
      return (d % 1 == 0) ? d.toInt().toString() : d.toStringAsFixed(1);
    }

    xlsio.Range cell(
      String a1, {
      String? text,
      bool bold = false,
      xlsio.HAlignType h = xlsio.HAlignType.center,
      xlsio.VAlignType v = xlsio.VAlignType.center,
      double? fontSize,
    }) {
      final r = rg(a1)..merge();
      if (text != null) r.setText(text);
      final st = r.cellStyle
        ..hAlign = h
        ..vAlign = v
        ..wrapText = true
        ..bold = bold;
      if (fontSize != null) st.fontSize = fontSize;
      final b = st.borders;
      b.all.lineStyle = xlsio.LineStyle.thin;
      b.all.color = '#000000';
      return r;
    }

    if (s.getRangeByIndex(startRow, 1).rowHeight < 22) {
      s.getRangeByIndex(startRow, 1).rowHeight = 22;
    }

    // 입력값1/2/차
    final val1 = e.guidelineLowPre5; // 전일(⑤)
    final val2 = e.guidelineLowCurrent9; // 현일(⑨)
    final diff = (val2 - val1);

    final r = startRow;

    // 3:1:3:1:3:1:3:3:3:나머지 => 총 28열 맞춤
    cell('A$r:C$r', text: '계량기 지침', bold: true); // 3
    cell('D$r:F$r', text: '전일 ⑤', bold: true); // 1
    cell('G$r:J$r', text: fmt(val1)); // 3

    cell('K$r:M$r', text: '현일 ⑨', bold: true); // 1
    cell('N$r:Q$r', text: fmt(val2)); // 3

    cell('R$r:T$r', text: '지침 차', bold: true); // 1
    cell('U$r:X$r', text: fmt(diff)); // 3

    cell('Y$r:AB$r', text: '㎾h', bold: true); // 3


  }

  static void applyFinalConfirmBlock(
    xlsio.Worksheet s, {
    required int startRow,
    required Uint8List logoPng,
    required String inspectorName,
    required String managerMainName,
    required String managerSubName,
    Uint8List? managerMainSigPng,
    Uint8List? managerSubSigPng,
  }) {
    xlsio.Range rg(String a1) => s.getRangeByName(a1);

    void thin(xlsio.Range r) {
      final b = r.cellStyle.borders;
      b.all.lineStyle = xlsio.LineStyle.thin;
      b.all.color = '#000000';
    }

    void outerThick(String a1) {
      final b = rg(a1).cellStyle.borders;
      for (final side in [b.top, b.bottom, b.left, b.right]) {
        side.lineStyle = xlsio.LineStyle.thick;
        side.color = '#000000';
      }
    }

    void style(
      xlsio.Range r, {
      bool bold = false,
      xlsio.HAlignType h = xlsio.HAlignType.center,
      xlsio.VAlignType v = xlsio.VAlignType.center,
      bool wrap = true,
    }) {
      r.cellStyle
        ..bold = bold
        ..hAlign = h
        ..vAlign = v
        ..wrapText = wrap;
      thin(r);
    }

    // 보기 좋은 행 높이
    for (var r = startRow; r <= startRow + 2; r++) {
      s.getRangeByIndex(r, 1).rowHeight = 26;
    }

    // ── 전체 블록 바깥 굵은 테두리
    outerThick('A$startRow:AB${startRow + 2}');

    // ── 1:1 분할 (왼쪽 A..N, 오른쪽 O..AB) 중간 경계선 강조
    // 왼쪽(A..N) 전체, 오른쪽(O..AB) 전체에 얇은 보더, 경계선은 굵게
    thin(rg('A$startRow:N${startRow + 2}'));
    thin(rg('O$startRow:AB${startRow + 2}'));
    // 경계선(열 N과 O 사이)을 굵게
    final leftEdge = rg('N$startRow:N${startRow + 2}').cellStyle.borders;
    leftEdge.right.lineStyle = xlsio.LineStyle.thick;
    leftEdge.right.color = '#000000';
    final rightEdge = rg('O$startRow:O${startRow + 2}').cellStyle.borders;
    rightEdge.left.lineStyle = xlsio.LineStyle.thick;
    rightEdge.left.color = '#000000';

    // ─────────────────────────────
    // 왼쪽: 로고 (A..N, 3행 병합)
    // ─────────────────────────────
    final leftLogo = rg('A$startRow:N${startRow + 2}')..merge();
    style(leftLogo, h: xlsio.HAlignType.center, v: xlsio.VAlignType.center);
    // 그림 추가 (대략 영역 크기에 맞춤)
    final pic = s.pictures.addStream(startRow, 1, logoPng); // A열, startRow에 앵커
    // 영역 대략 크기 계산해서 맞춰주기
    double _rangeWidthPx(int c1, int c2) {
      double px = 0;
      for (var c = c1; c <= c2; c++) {
        px += s.getRangeByIndex(1, c).columnWidth * 7; // 대략 환산
      }
      return px;
    }

    double _rangeHeightPx(int r1, int r2) {
      double px = 0;
      for (var r = r1; r <= r2; r++) {
        px += s.getRangeByIndex(r, 1).rowHeight * 1.33; // 대략 환산
      }
      return px;
    }

    final boxW = _rangeWidthPx(1, 14); // A..N
    final boxH = _rangeHeightPx(startRow, startRow + 2);
    // 가로세로 중 짧은 쪽 기준으로 균등 축소 (중앙정렬 느낌)
    // (xlsio는 정밀한 중앙 배치 API가 없어서 크기만 영역에 맞춰줌)
    pic.width = boxW.toInt();
    pic.height = boxH.toInt();

    // ─────────────────────────────
    // 오른쪽: 확인/이름/메일·서명 (O..AB)
    // ─────────────────────────────
    // "확인" 세로 텍스트 (O..P, 3행 병합)
    final confirm = rg('O$startRow:O${startRow + 2}')..merge();
    confirm.setText('확\n인');
    confirm.cellStyle
      ..bold = true
      ..hAlign = xlsio.HAlignType.center
      ..vAlign = xlsio.VAlignType.center
      ..rotation = 0
      ..wrapText = true;
    // 내부 보더

    // 오른쪽 내부는 [라벨 4] [이름 8] [액션/서명 2] = 총 14열(O..AB 중 O..P가 확인이니 Q..AB = 12열)
    // → 라벨(Q..T, 4col), 이름(U..Z, 6col), 액션/서명(AA..AB, 2col)
    void _row(
      int r,
      String label,
      String name, {
      String? actionText,
      Uint8List? signPng,
    }) {
      final lab = rg('P$r:T$r')..merge(); // 라벨
      lab.setText(label);
      style(lab, bold: true);

      final nameCell = rg('U$r:Z$r')..merge(); // 이름
      nameCell.setText(name);
      style(nameCell, h: xlsio.HAlignType.center);

      final act = rg('AA$r:AB$r')..merge(); // 메일발송 or (서명 이미지)
      style(act);
      if (signPng != null) {
        // 서명 이미지 삽입
        final p = s.pictures.addStream(r, 27, signPng); // AA=27열
        // 칸 크기 대략에 맞춤
        final w = _rangeWidthPx(27, 28);
        final h = _rangeHeightPx(r, r);
        p.width = w.toInt();
        p.height = h.toInt();
      } else if (actionText != null && actionText.isNotEmpty) {
        act.setText(actionText);
        // 빨간 텍스트 원하면:
        act.cellStyle.fontColor = '#D32F2F';
        act.cellStyle.bold = true;
      }
    }

    // 1행: 점 검 확 인 자 / 이름 / 메일발송
    _row(startRow, '점 검 확 인 자', inspectorName, actionText: '메일발송');

    // 2행: 안전관리자(정) / 이름 / 서명 이미지
    _row(
      startRow + 1,
      '안 전 관 리 자(정)',
      managerMainName,
      signPng: managerMainSigPng,
    );

    // 3행: 안전관리자(부) / 이름 / 서명 이미지
    _row(startRow + 2, '안전관리자(부)', managerSubName, signPng: managerSubSigPng);
  }
}
