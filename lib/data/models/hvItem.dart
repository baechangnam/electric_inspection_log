import 'dart:convert';
import 'dart:typed_data';

import 'package:electric_inspection_log/widgets/inspection_entry.dart';

class SimpleHvLogEntry {
  String selectedBoardId;

  List<InspectionEntry> lowVoltageItems;
  List<InspectionEntry> highVoltageItems;
  List<InspectionEntry> solarItems;

  // ── 송전 전압 ─────────────────────────────
  double transmissionRtoS; // R~S 전압 (V)
  double transmissionStoT; // S~T 전압 (V)
  double transmissionRtoT; // R~T 전압 (V)

  // ── PV 전압/발전량 ─────────────────────────
  double pvVoltage; // PV 전압 (V)
  double currentGenerationKwh; // 현재 발전량 (kWh)
  double cumulativeGenerationMwh; // 누적 발전량 (MWh)

  // ── 전력/배율/역율 ─────────────────────────
  double maxPower;
  double avgPower;
  double powerRatio;
  double powerFactor;

  // ── 측정 전압(추가) ────────────────────────
  double measuredVoltageRtoS; // R~S 측정 전압 (V)
  double measuredVoltageStoT; // S~T 측정 전압 (V)
  double measuredVoltageRtoT; // R~T 측정 전압 (V)
  double measuredVoltageN; // N   측정 전압 (V)

  // ── 점검 결과 입력 ─────────────────────────
  // 레거시: 한 덩어리 문자열 (남겨둠 / 호환용)
  String inspectionResultNumeric;

  // 새 구조: 4줄 분할 저장(번호 없이 원문만 보관)
  List<String> inspectionResultLines;

  // 터치 입력(그림)
  Uint8List? inspectionResultImage;

  // ── 지침 입력 ─────────────────────────────
  double guidelineCurrent4;
  double guidelineCurrent5;
  double guidelineCurrent6;
  double guidelineCurrentSum;

  double guidelinePrev9;
  double guidelinePrev10;
  double guidelinePrev11;
  double guidelinePrevSum;

  // 결재/확인자
  String inspectorName;
  String managerMainName;
  String managerSubName;

  Uint8List? managerMainSignature; // 안전관리자(정) 서명
  Uint8List? managerSubSignature; // 안전관리자(부) 서명

  // ── 저압 지침(추가) ────────────────────────
  double guidelineLowPre5; // 전일
  double guidelineLowCurrent9; // 현재
  double guidelineLowSum; // 지침 차
  double preMonthGenerationKwh; // 전월 발전량

  double guidelineLabel4; // ④ 라벨 탭 시 저장
  double guidelineLabel5; // ⑤ 라벨 탭 시 저장
  double guidelineLabel6; // ⑥ 라벨 탭 시 저장

  // ⬇️⬇️ [신규] 라벨 탭 전용 값 (전일⑤ / 현일⑨)
  double guidelineLowLabel5; // 전일 ⑤ 라벨에 저장되는 값
  double guidelineLowLabel9; // 현일 ⑨ 라벨에 저장되는 값

  SimpleHvLogEntry({
    required this.selectedBoardId,
    required this.lowVoltageItems,
    required this.highVoltageItems,
    required this.solarItems,

    // 송전 전압 기본값
    this.transmissionRtoS = 0.0,
    this.transmissionStoT = 0.0,
    this.transmissionRtoT = 0.0,

    // PV/발전량
    this.pvVoltage = 0.0,
    this.currentGenerationKwh = 0.0,
    this.cumulativeGenerationMwh = 0.0,

    // 전력/배율/역율
    this.maxPower = 0.0,
    this.avgPower = 0.0,
    this.powerRatio = 0.0,
    this.powerFactor = 0.0,

    // 측정 전압
    this.measuredVoltageRtoS = 0.0,
    this.measuredVoltageStoT = 0.0,
    this.measuredVoltageRtoT = 0.0,
    this.measuredVoltageN = 0.0,

    // 점검 결과(텍스트/이미지)
    this.inspectionResultNumeric = '',
    this.inspectionResultLines = const ['', '', '', ''],
    this.inspectionResultImage,

    // 지침
    this.guidelineCurrent4 = 0.0,
    this.guidelineCurrent5 = 0.0,
    this.guidelineCurrent6 = 0.0,
    this.guidelineCurrentSum = 0.0,
    this.guidelinePrev9 = 0.0,
    this.guidelinePrev10 = 0.0,
    this.guidelinePrev11 = 0.0,
    this.guidelinePrevSum = 0.0,

    // 결재/확인자
    this.inspectorName = '',
    this.managerMainName = '',
    this.managerSubName = '',
    this.managerMainSignature,
    this.managerSubSignature,

    // 저압 지침/전월발전량
    this.guidelineLowPre5 = 0.0,
    this.guidelineLowCurrent9 = 0.0,
    this.guidelineLowSum = 0.0,
    this.preMonthGenerationKwh = 0.0,

    // [신규] 라벨 탭 전용 기본값
    this.guidelineLabel4 = 0.0,
    this.guidelineLabel5 = 0.0,
    this.guidelineLabel6 = 0.0,

    this.guidelineLowLabel5 = 0.0,
    this.guidelineLowLabel9 = 0.0,
  });

  // ── JSON 역직렬화 ──────────────────────────
  factory SimpleHvLogEntry.fromJson(Map<String, dynamic> j) {
    Uint8List? _bytes(String? b64) =>
        (b64 == null || b64.isEmpty) ? null : base64Decode(b64);

    // 레거시 문자열에서 4줄 뽑는 보조(옛 데이터 호환)
    List<String> _linesFromLegacy() {
      final legacy = (j['inspectionResultNumeric'] ?? '') as String;
      if (legacy.trim().isEmpty) return ['', '', '', ''];
      final parts = legacy
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      return List.generate(4, (i) => i < parts.length ? parts[i] : '');
    }

    final linesJson = j['inspectionResultLines'];
    List<String> lines = (linesJson is List)
        ? linesJson.map((e) => (e ?? '').toString()).toList()
        : _linesFromLegacy();

    // 안전 보정: 항상 4칸
    if (lines.length < 4) {
      lines = [...lines, ...List.filled(4 - lines.length, '')];
    } else if (lines.length > 4) {
      lines = lines.sublist(0, 4);
    }

    return SimpleHvLogEntry(
      selectedBoardId: j['selectedBoardId'] ?? '',

      lowVoltageItems: (j['lowVoltageItems'] as List? ?? [])
          .map((e) => InspectionEntry.fromJson(e))
          .toList(),
      highVoltageItems: (j['highVoltageItems'] as List? ?? [])
          .map((e) => InspectionEntry.fromJson(e))
          .toList(),
      solarItems: (j['solarItems'] as List? ?? [])
          .map((e) => InspectionEntry.fromJson(e))
          .toList(),

      transmissionRtoS: _parseDouble(j['transmissionRtoS']),
      transmissionStoT: _parseDouble(j['transmissionStoT']),
      transmissionRtoT: _parseDouble(j['transmissionRtoT']),

      pvVoltage: _parseDouble(j['pvVoltage']),
      currentGenerationKwh: _parseDouble(j['currentGenerationKwh']),
      cumulativeGenerationMwh: _parseDouble(j['cumulativeGenerationMwh']),

      maxPower: _parseDouble(j['maxPower']),
      avgPower: _parseDouble(j['avgPower']),
      powerRatio: _parseDouble(j['powerRatio']),
      powerFactor: _parseDouble(j['powerFactor']),

      measuredVoltageRtoS: _parseDouble(j['measuredVoltageRtoS']),
      measuredVoltageStoT: _parseDouble(j['measuredVoltageStoT']),
      measuredVoltageRtoT: _parseDouble(j['measuredVoltageRtoT']),
      measuredVoltageN: _parseDouble(j['measuredVoltageN']),

      inspectionResultNumeric: j['inspectionResultNumeric'] ?? '',
      inspectionResultLines: lines,
      inspectionResultImage: j['inspectionResultImage'] != null
          ? base64Decode(j['inspectionResultImage'])
          : null,

      guidelineCurrent4: _parseDouble(j['guidelineCurrent4']),
      guidelineCurrent5: _parseDouble(j['guidelineCurrent5']),
      guidelineCurrent6: _parseDouble(j['guidelineCurrent6']),
      guidelineCurrentSum: _parseDouble(j['guidelineCurrentSum']),
      guidelinePrev9: _parseDouble(j['guidelinePrev9']),
      guidelinePrev10: _parseDouble(j['guidelinePrev10']),
      guidelinePrev11: _parseDouble(j['guidelinePrev11']),
      guidelinePrevSum: _parseDouble(j['guidelinePrevSum']),

      guidelineLowPre5: _parseDouble(j['guidelineLowPre5']),
      guidelineLowCurrent9: _parseDouble(j['guidelineLowCurrent9']),
      guidelineLowSum: _parseDouble(j['guidelineLowSum']),
      preMonthGenerationKwh: _parseDouble(j['preMonthGenerationKwh']),

      inspectorName: j['inspectorName'] ?? '',
      managerMainName: j['managerMainName'] ?? '',
      managerSubName: j['managerSubName'] ?? '',
      managerMainSignature: _bytes(j['managerMainSignature'] as String?),
      managerSubSignature: _bytes(j['managerSubSignature'] as String?),

      guidelineLabel4: _parseDouble(j['guidelineLabel4']),
      guidelineLabel5: _parseDouble(j['guidelineLabel5']),
      guidelineLabel6: _parseDouble(j['guidelineLabel6']),
      guidelineLowLabel5: _parseDouble(j['guidelineLowLabel5']),
      guidelineLowLabel9: _parseDouble(j['guidelineLowLabel9']),
    );
  }

  // ── JSON 직렬화 ────────────────────────────
  Map<String, dynamic> toJson() => {
    'selectedBoardId': selectedBoardId,
    'lowVoltageItems': lowVoltageItems.map((e) => e.toJson()).toList(),
    'highVoltageItems': highVoltageItems.map((e) => e.toJson()).toList(),
    'solarItems': solarItems.map((e) => e.toJson()).toList(),

    'transmissionRtoS': transmissionRtoS,
    'transmissionStoT': transmissionStoT,
    'transmissionRtoT': transmissionRtoT,

    'pvVoltage': pvVoltage,
    'currentGenerationKwh': currentGenerationKwh,
    'cumulativeGenerationMwh': cumulativeGenerationMwh,

    'maxPower': maxPower,
    'avgPower': avgPower,
    'powerRatio': powerRatio,
    'powerFactor': powerFactor,

    'measuredVoltageRtoS': measuredVoltageRtoS,
    'measuredVoltageStoT': measuredVoltageStoT,
    'measuredVoltageRtoT': measuredVoltageRtoT,
    'measuredVoltageN': measuredVoltageN,

    'inspectionResultNumeric': inspectionResultNumeric,
    'inspectionResultLines': List<String>.from(inspectionResultLines),
    'inspectionResultImage': inspectionResultImage != null
        ? base64Encode(inspectionResultImage!)
        : null,

    'guidelineCurrent4': guidelineCurrent4,
    'guidelineCurrent5': guidelineCurrent5,
    'guidelineCurrent6': guidelineCurrent6,
    'guidelineCurrentSum': guidelineCurrentSum,
    'guidelinePrev9': guidelinePrev9,
    'guidelinePrev10': guidelinePrev10,
    'guidelinePrev11': guidelinePrev11,
    'guidelinePrevSum': guidelinePrevSum,

    'guidelineLowPre5': guidelineLowPre5,
    'guidelineLowCurrent9': guidelineLowCurrent9,
    'guidelineLowSum': guidelineLowSum,
    'preMonthGenerationKwh': preMonthGenerationKwh,

    'inspectorName': inspectorName,
    'managerMainName': managerMainName,
    'managerSubName': managerSubName,

    'managerMainSignature':
        (managerMainSignature == null || managerMainSignature!.isEmpty)
        ? null
        : base64Encode(managerMainSignature!),
    'managerSubSignature':
        (managerSubSignature == null || managerSubSignature!.isEmpty)
        ? null
        : base64Encode(managerSubSignature!),
    'guidelineLabel4': guidelineLabel4,
    'guidelineLabel5': guidelineLabel5,
    'guidelineLabel6': guidelineLabel6,
    'guidelineLowLabel5': guidelineLowLabel5,
    'guidelineLowLabel9': guidelineLowLabel9,
  };

  // ── 유틸 ──────────────────────────────────
  static double _parseDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString().replaceAll(',', '')) ?? 0.0;
  }

  String? _b64(Uint8List? bytes) =>
      (bytes == null || bytes.isEmpty) ? null : base64Encode(bytes);

  // 라인 접근/설정 (범위 안전)
  String getLine(int i) => (i >= 0 && i < 4) ? inspectionResultLines[i] : '';
  void setLine(int i, String value) {
    if (i < 0 || i >= 4) return;
    inspectionResultLines[i] = value.replaceAll('\r', '').trim();
  }

  // 표시용: 번호 붙여 문자열 조합 (빈 줄은 스킵)
  String numberedResultText() {
    final b = StringBuffer();
    int shown = 0;
    for (int i = 0; i < inspectionResultLines.length; i++) {
      final t = inspectionResultLines[i].trim();
      if (t.isEmpty) continue;
      shown++;
      b.writeln('${i + 1}. $t');
    }
    // 모두 비었고, 레거시 문자열이 있으면 그대로 반환
    if (shown == 0 && inspectionResultNumeric.trim().isNotEmpty) {
      return inspectionResultNumeric;
    }
    return b.toString().trimRight();
  }
}

// (선택) 기존처럼 필드 접근에 쓰던 enum/extension 유지하고 싶으면 아래 사용
enum TransmissionVoltageField { rToS, sToT, rToT }

extension TransmissionAccess on SimpleHvLogEntry {
  double getTransmission(TransmissionVoltageField f) {
    switch (f) {
      case TransmissionVoltageField.rToS:
        return transmissionRtoS;
      case TransmissionVoltageField.sToT:
        return transmissionStoT;
      case TransmissionVoltageField.rToT:
        return transmissionRtoT;
    }
  }

  void setTransmission(TransmissionVoltageField f, double v) {
    switch (f) {
      case TransmissionVoltageField.rToS:
        transmissionRtoS = v;
        break;
      case TransmissionVoltageField.sToT:
        transmissionStoT = v;
        break;
      case TransmissionVoltageField.rToT:
        transmissionRtoT = v;
        break;
    }
  }
}
