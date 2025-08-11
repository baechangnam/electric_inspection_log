import 'dart:convert';
import 'dart:typed_data';

import 'package:electric_inspection_log/widgets/inspection_entry.dart';

class SimpleHvLogEntry {
  String selectedBoardId;

  List<InspectionEntry> lowVoltageItems;
  List<InspectionEntry> highVoltageItems;
  List<InspectionEntry> solarItems;

  double transmissionRtoS; // R~S 전압 (V)
  double transmissionStoT; // S~T 전압
  double transmissionRtoT; // R~T 전압

  double pvVoltage; // PV 전압 (V)

  double currentGenerationKwh; // 현재 발전량 (kWh)
  double cumulativeGenerationMwh; // 누적 발전량 (MWh)

  // ————— 기존 전력/배율/역율 필드 —————
  double maxPower;
  double avgPower;
  double powerRatio;
  double powerFactor;

  // ————— 새로 추가하는 측정 전압 필드 —————
  double measuredVoltageRtoS; // R~S 측정 전압 (V)
  double measuredVoltageStoT; // S~T 측정 전압 (V)
  double measuredVoltageRtoT; // R~T 측정 전압 (V)
  double measuredVoltageN; // N 측정 전압   (V)

  String inspectionResultNumeric;
  // 여기에 추가: 터치 입력으로 그린 이미지를 Uint8List로 보관
  Uint8List? inspectionResultImage;

  double guidelineCurrent4;
  double guidelineCurrent5;
  double guidelineCurrent6;
  double guidelineCurrentSum;

  double guidelinePrev9;
  double guidelinePrev10;
  double guidelinePrev11;
  double guidelinePrevSum;
  String inspectorName = '';
  String managerMainName = '';
  String managerSubName = '';

  SimpleHvLogEntry({
    required this.selectedBoardId,
    required this.lowVoltageItems,
    required this.highVoltageItems,
    required this.solarItems,

    // 송전 전압 기본값
    this.transmissionRtoS = 0.0,
    this.transmissionStoT = 0.0,
    this.transmissionRtoT = 0.0,

    this.pvVoltage = 0.0,

    this.currentGenerationKwh = 0.0,
    this.guidelineCurrent4 = 0.0,
    this.guidelineCurrent5 = 0.0,
    this.guidelineCurrent6 = 0.0,
    this.guidelineCurrentSum = 0.0,
    this.guidelinePrev9 = 0.0,
    this.guidelinePrev10 = 0.0,
    this.guidelinePrev11 = 0.0,
    this.guidelinePrevSum = 0.0,

    // 발전량 기본값
    this.cumulativeGenerationMwh = 0.0,

    // 전력/배율/역율 기본값
    this.maxPower = 0.0,
    this.avgPower = 0.0,
    this.powerRatio = 0.0,
    this.powerFactor = 0.0,

    // 측정 전압 기본값
    this.measuredVoltageRtoS = 0.0,
    this.measuredVoltageStoT = 0.0,
    this.measuredVoltageRtoT = 0.0,
    this.measuredVoltageN = 0.0,
    this.inspectionResultNumeric = '',
    this.inspectionResultImage, 
    this.inspectorName ='',
     this.managerMainName ='',
      this.managerSubName ='',
    
  });

 factory SimpleHvLogEntry.fromJson(Map<String, dynamic> j) {
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

    inspectorName: j['inspectorName'] ?? '',
    managerMainName: j['managerMainName'] ?? '',
    managerSubName: j['managerSubName'] ?? '',
  );
}


Map<String, dynamic> toJson() => {
  'selectedBoardId': selectedBoardId,
  'lowVoltageItems': lowVoltageItems.map((e) => e.toJson()).toList(),
  'highVoltageItems': highVoltageItems.map((e) => e.toJson()).toList(),
  'solarItems': solarItems.map((e) => e.toJson()).toList(),

  // 송전 전압
  'transmissionRtoS': transmissionRtoS,
  'transmissionStoT': transmissionStoT,
  'transmissionRtoT': transmissionRtoT,

  // PV 전압
  'pvVoltage': pvVoltage,

  // 발전량
  'currentGenerationKwh': currentGenerationKwh,
  'cumulativeGenerationMwh': cumulativeGenerationMwh,

  // 전력/배율/역율
  'maxPower': maxPower,
  'avgPower': avgPower,
  'powerRatio': powerRatio,
  'powerFactor': powerFactor,

  // 측정 전압
  'measuredVoltageRtoS': measuredVoltageRtoS,
  'measuredVoltageStoT': measuredVoltageStoT,
  'measuredVoltageRtoT': measuredVoltageRtoT,
  'measuredVoltageN': measuredVoltageN,

  // 점검 결과
  'inspectionResultNumeric': inspectionResultNumeric,
  'inspectionResultImage': inspectionResultImage != null
      ? base64Encode(inspectionResultImage!)
      : null,

  // 지침
  'guidelineCurrent4': guidelineCurrent4,
  'guidelineCurrent5': guidelineCurrent5,
  'guidelineCurrent6': guidelineCurrent6,
  'guidelineCurrentSum': guidelineCurrentSum,
  'guidelinePrev9': guidelinePrev9,
  'guidelinePrev10': guidelinePrev10,
  'guidelinePrev11': guidelinePrev11,
  'guidelinePrevSum': guidelinePrevSum,

  // 결재자 이름
  'inspectorName': inspectorName,
  'managerMainName': managerMainName,
  'managerSubName': managerSubName,
};

  static double _parseDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString().replaceAll(',', '')) ?? 0.0;
  }
}

enum TransmissionVoltageField { rToS, sToT, rToT }

extension TransmissionAccess on SimpleHvLogEntry {
  double getTransmission(TransmissionVoltageField f) {
    return switch (f) {
      TransmissionVoltageField.rToS => transmissionRtoS,
      TransmissionVoltageField.sToT => transmissionStoT,
      TransmissionVoltageField.rToT => transmissionRtoT,
    };
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
