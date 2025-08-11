// lib/widgets/excel_grid.dart
import 'dart:convert';

import 'package:electric_inspection_log/core/db/hv_helper.dart';
import 'package:electric_inspection_log/data/models/board_item.dart';
import 'package:electric_inspection_log/data/models/hvItem.dart';
import 'package:electric_inspection_log/views/main/drawing_screen.dart';
import 'package:electric_inspection_log/views/main/template_screen.dart';
import 'package:electric_inspection_log/widgets/confrim_widget.dart';
import 'package:electric_inspection_log/widgets/drawing_popup.dart';
import 'package:electric_inspection_log/widgets/empty_line.dart';
import 'package:electric_inspection_log/widgets/inspection_entry.dart';
import 'package:electric_inspection_log/widgets/inspection_line_widget.dart';
import 'package:electric_inspection_log/widgets/measure_widget.dart';
import 'package:electric_inspection_log/widgets/measurement_power_widget.dart';
import 'package:electric_inspection_log/widgets/numeric_keypad.dart';
import 'package:electric_inspection_log/widgets/trans_widget.dart';
import 'package:electric_inspection_log/widgets/transmission_voltage_quad_widget.dart';
import 'package:electric_inspection_log/widgets/two_line_dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class ExcelGrid extends StatefulWidget {
  const ExcelGrid({Key? key}) : super(key: key);

  @override
  _ExcelGridState createState() => _ExcelGridState();
}

// Future<Map<String,dynamic>> fetchWeather(double lat, double lon) async {
//   final apiKey = 'YOUR_API_KEY';
//   final url = Uri.parse(
//     'https://api.openweathermap.org/data/2.5/weather'
//     '?lat=$lat&lon=$lon&appid=$apiKey&lang=kr&units=metric'
//   );
//   final res = await http.get(url);
//   if (res.statusCode != 200) throw Exception('날씨 로드 실패');
//   return json.decode(res.body) as Map<String,dynamic>;
// }

class _ExcelGridState extends State<ExcelGrid> {
  static const int rows = 11;
  static const int columns = 28;

  late final List<List<String>> _data;
  String _selectedConsumer = '';
  late final List<InspectionEntry> lefts;
  late final List<InspectionEntry> middles;
  late final List<InspectionEntry> rights;

  final List<String> leftTitles = [
    '인입구 배선',
    '배.분전반',
    '배선용 차단기',
    '누전차단기',
    '개폐기',
    '배선',
    '전동기',
    '전열설비',
    '용접기',
    '콘덴서',
    '조명설비',
    '구내전선로',
    '기타설비',
    '원동기',
    '차단장치',
    '충전장치',
  ];
  final List<String> middleTitles = [
    '가공 전선로',
    '지중전선로',
    '수배전용개폐기',
    '배선(모선)',
    '피뢰기',
    '변성기',
    '전력휴즈',
    '변압기',
    '수.배전반',
    '계전기류',
    '차단기류',
    '전력용 콘덴서',
    '보호설비',
    '부하설비',
    '접지설비',
    '기타설비',
  ];
  final List<String> rightTitles = [
    '태양광전지 시설상태',
    '시스템가동 정지상태',
    '인버터 병렬운전상태',
    '계통연계 운전상태',
    '접속 단자함 상태',
    '접지선상태, 탈착여부',
    '보호시설의 설치상태',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
  ];

  late SimpleHvLogEntry hvLogEntry;

  @override
  void initState() {
    super.initState();
    _data = List.generate(rows, (_) => List.generate(columns, (_) => ''));
    final low = leftTitles.map((t) => InspectionEntry(title: t)).toList();
    final high = middleTitles.map((t) => InspectionEntry(title: t)).toList();
    final solar = rightTitles.map((t) => InspectionEntry(title: t)).toList();

    hvLogEntry = SimpleHvLogEntry(
      selectedBoardId: '',
      lowVoltageItems: low,
      highVoltageItems: high,
      solarItems: solar,
    );
  }

  void _onAnyLineChanged(
    int index, {
    required InspectionEntry left,
    required InspectionEntry middle,
    required InspectionEntry right,
    required double value,
  }) {
    setState(() {
      // 같은 인스턴스를 넘기고 있으니 사실 이 할당은 선택적이지만 명시적으로 동기화
      hvLogEntry.lowVoltageItems[index] = left;
      hvLogEntry.highVoltageItems[index] = middle;
      hvLogEntry.solarItems[index] = right;

      debugPrint('--- 라인 ${index} 변경 ---');

      switch (index) {
        case 7:
          hvLogEntry.transmissionRtoS = value;
          break;
        case 8:
          hvLogEntry.transmissionStoT = value;
          break;
        case 9:
          hvLogEntry.transmissionRtoT = value;
          break;
      }

      if (index == 10 || index == 11) {
        hvLogEntry.pvVoltage = value;
      }
      // 3) index 가 12(current) or 13(cumulative)이면 발전량
      else if (index == 12) {
        hvLogEntry.currentGenerationKwh = value;
      } else if (index == 13) {
        hvLogEntry.cumulativeGenerationMwh = value;
      }
    });

    // 예: 로그 찍기

    debugPrint(
      '왼쪽: ${left.title}, 판정: ${left.judgment.label}, 비고: ${left.remark} ',
    );
    debugPrint(
      '중간: ${middle.title}, 판정: ${middle.judgment.label}, 비고: ${middle.remark}',
    );
    debugPrint(
      '오른쪽: ${right.title}, 판정: ${right.judgment.label}, 비고: ${right.remark}',
    );

    debugPrint('"R_S_T: ${value}');

    saveDB();

    // 여기서 로컬/서버 저장 호출해도 좋음 (디바운스 권장)
  }

  final _inspectorController = TextEditingController();
  final _managerMainController = TextEditingController();
  final _managerSubController = TextEditingController();

  @override
  void dispose() {
    // 2) 위젯이 사라질 때 컨트롤러 해제
    _inspectorController.dispose();
    _managerMainController.dispose();
    _managerSubController.dispose();
    super.dispose();
  }

  // 3) 콜백 함수 구현
  void _onSendEmail() {
    // _inspectorController.text 에 작성된 값으로 메일 발송 로직 실행
    print('메일 발송 대상: ${_inspectorController.text}');
  }

  void _onManagerMainSign() {
    // _managerMainController.text 에 작성된 값으로 서명 처리
    print('안전관리자(정) 서명: ${_managerMainController.text}');
  }

  void _onManagerSubSign() {
    // _managerSubController.text 에 작성된 값으로 서명 처리
    print('안전관리자(부) 서명: ${_managerSubController.text}');
  }

  BoardItem? _selectedBoard;

  void saveDB() {
    if (hvLogEntry.selectedBoardId.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('수용가를 먼저 선택해주세요.')));
      return;
    }
    // 실제 저장
    HvLogDb.instance.save(hvLogEntry);
  }

  // …다른 상태 변수…

  String _endpoint = 'https://davin230406.mycafe24.com/api/list_board.php';

  /// 전체 거래처 목록을 가져옵니다.
  Future<List<BoardItem>> fetchBoardList() async {
    final res = await http.get(Uri.parse(_endpoint));
    if (res.statusCode != 200) {
      throw Exception('거래처 목록 로드 실패: ${res.statusCode}');
    }
    final body = json.decode(res.body) as Map<String, dynamic>;
    final rawList = (body['board_list'] as List).cast<Map<String, dynamic>>();
    return rawList.map((e) => BoardItem.fromJson(e)).toList();
  }

  String _selectedWeather = ''; // 여기에 선택된 날씨 문자열을 저장

  Future<void> _onTapWeather() async {
    final options = ['맑음', '구름많음', '흐림', '비', '소나기', '눈'];
    final picked = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('날씨 선택'),
        children: options.map((w) {
          return SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, w),
            child: Text(w),
          );
        }).toList(),
      ),
    );
    if (picked != null) {
      setState(() {
        _selectedWeather = picked;
      });
    }
  }

  double _parseCapacity(String s) {
    final cleaned = s.replaceAll(',', '').trim();
    return double.tryParse(cleaned) ?? 0.0;
  }

  Future<void> _onTapSelectConsumer() async {
    // 1) 거래처 리스트 가져오기
    List<BoardItem> list;
    try {
      list = await fetchBoardList();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('거래처 불러오기 실패: $e')));
      return;
    }

    // 2) 다이얼로그로 선택
    final picked = await showDialog<BoardItem>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('거래처 선택'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: list.length,
            itemBuilder: (_, i) {
              final b = list[i];

              return ListTile(
                title: Text(b.consumerName),
                subtitle: Text(b.facilityLocation),
                onTap: () => Navigator.of(ctx).pop(b),
              );
            },
          ),
        ),
      ),
    );
    if (picked == null) return;

    // 3) selectedBoardId 설정
    setState(() {
      _selectedBoard = picked;
      _selectedConsumer = picked.consumerName;
      hvLogEntry.selectedBoardId = picked.id.toString();
    });

    // 4) DB에서 로드 시도
    final loaded = await HvLogDb.instance.load(picked.id.toString());
    if (loaded != null) {
      // 4-A) 이미 있던 데이터면 덮어쓰기
      setState(() {
        hvLogEntry = loaded;
      });
    } else {
      // 4-B) 신규 엔트리면 즉시 저장
      final fresh = _freshEntryFor(picked.id.toString()); // ✅ toString으로 통일
      await HvLogDb.instance.save(fresh);
      setState(() {
        hvLogEntry = fresh; // ✅ 한 번에 교체
        _selectedBoard = picked;
        _selectedConsumer = picked.consumerName;
      });
    }
  }

  SimpleHvLogEntry _freshEntryFor(String boardId) {
    final low = leftTitles.map((t) => InspectionEntry(title: t)).toList();
    final high = middleTitles.map((t) => InspectionEntry(title: t)).toList();
    final solar = rightTitles.map((t) => InspectionEntry(title: t)).toList();

    return SimpleHvLogEntry(
      selectedBoardId: boardId,
      lowVoltageItems: low,
      highVoltageItems: high,
      solarItems: solar,
      // 다른 수치 필드들도 전부 초기값으로 (0 또는 ''/null) 들어가게 두기
    );
  }

  final borderColor = Colors.white;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ──────────────────────────
        // 1) 첫 6행 (인덱스 0~5): 병합 셀 레이아웃
        // ──────────────────────────
        Expanded(
          flex: 6,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cellW = constraints.maxWidth / columns;
              final cellH = constraints.maxHeight / 6;

              return Stack(
                children: [
                  // 1-1) 기본 6×28 그리드 그리기
                  Column(
                    children: List.generate(6, (r) {
                      return SizedBox(
                        height: cellH,
                        child: Row(
                          children: List.generate(columns, (c) {
                            return Container(
                              width: cellW,
                              height: cellH,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: borderColor,
                                  width: 0.5,
                                ),
                              ),
                            );
                          }),
                        ),
                      );
                    }),
                  ),

                  // 1-2) C3~R4 (인덱스 row 2~3, col 2~17) 병합
                  Positioned(
                    left: 2 * cellW,
                    top: 1 * cellH,
                    width: 16 * cellW,
                    height: 3 * cellH,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 25.0,
                        vertical: 2.0,
                      ),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 0.5,
                        ),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '전기설비 점검결과 통지서(고압용)',
                          style: TextStyle(
                            fontSize: 50, // 크게 잡아두면…
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 1-3) T2~T4 (인덱스 row 1~3, col 19) 병합
                  Positioned(
                    left: 21 * cellW,
                    top: 1 * cellH,
                    width: cellW,
                    height: 3 * cellH,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 2.0,
                        vertical: 2.0,
                      ),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 0.5,
                        ),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '결\n재',
                          style: TextStyle(
                            fontSize: 18, // 크게 잡아두면…
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 3) U2~W2 (row1, col20~22) – 담당
                  Positioned(
                    left: 22 * cellW,
                    top: 1 * cellH,
                    width: 3 * cellW,
                    height: cellH,
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 0.5,
                        ),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '담당',
                          style: TextStyle(
                            fontSize: 20, // 크게 잡아두면…
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 4) U3~W4 (row2~3, col20~22) – 빈칸 덮기
                  Positioned(
                    left: 22 * cellW,
                    top: 2 * cellH,
                    width: 3 * cellW,
                    height: 2 * cellH,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 0.5,
                        ),
                      ),
                    ),
                  ),

                  // 5) X2~Z2 (row1, col23~25) – 팀장
                  Positioned(
                    left: 25 * cellW,
                    top: 1 * cellH,
                    width: 3 * cellW,
                    height: cellH,
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 0.5,
                        ),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '팀장',
                          style: TextStyle(
                            fontSize: 20, // 크게 잡아두면…
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 6) X3~Z4 (row2~3, col23~25) – 빈칸 덮기
                  // X3~Z4 (row2~3, col23~25) – 빈칸 덮기
                  Positioned(
                    left: 25 * cellW,
                    top: 2 * cellH,
                    width: 3 * cellW,
                    height: 2 * cellH,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 0.5,
                        ),
                      ),
                    ),
                  ),
                  // (필요 시 더 빈 병합 영역을 추가하세요)
                ],
              );
            },
          ),
        ),

        Expanded(
          flex: 2,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cellW = constraints.maxWidth / columns;
              final cellH = constraints.maxHeight;
              final border = Border.all(color: borderColor, width: 0.5);
              final baseFont = cellH * 0.55;

              final now = DateTime.now();
              final weekdays = [
                '월요일',
                '화요일',
                '수요일',
                '목요일',
                '금요일',
                '토요일',
                '일요일',
              ];
              final weekdayLabel = weekdays[now.weekday - 1];
              final formattedDate =
                  '$weekdayLabel ${now.month}월 ${now.day}일, ${now.year}';

              return Stack(
                children: [
                  // 기본 28셀 그리드
                  Row(
                    children: List.generate(columns, (_) {
                      return Container(
                        width: cellW,
                        height: cellH,
                        decoration: BoxDecoration(border: border),
                      );
                    }),
                  ),

                  // A~B : 고객명(상호) 병합
                  Positioned(
                    left: 0,
                    top: 0,
                    width: 3 * cellW,
                    height: cellH,
                    child: GestureDetector(
                      onTap: _onTapSelectConsumer,
                      child: Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: border,
                        ),

                        child: Text(
                          '고객명(상호)',
                          style: TextStyle(
                            fontSize: baseFont / 2.2,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // C~L : 클릭 시 API 통신 영역 (TODO)
                  Positioned(
                    left: 3 * cellW,
                    top: 0,
                    width: 9 * cellW,
                    height: cellH,
                    child: Container(
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: border,
                      ),

                      child: Text(
                        _selectedConsumer,
                        style: TextStyle(fontSize: baseFont / 2),
                      ),
                    ),
                  ),

                  // M~N : 귀중 병합
                  Positioned(
                    left: 12 * cellW,
                    top: 0,
                    width: 2 * cellW,
                    height: cellH,
                    child: Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: border,
                      ),

                      child: Text(
                        '귀중',
                        style: TextStyle(fontSize: baseFont / 2),
                      ),
                    ),
                  ),

                  // P~T : 요일, 월, 년 병합
                  Positioned(
                    left: 14 * cellW,
                    top: 0,
                    width: 7 * cellW,
                    height: cellH,
                    child: Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: border,
                      ),

                      child: Text(
                        formattedDate,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: baseFont / 2),
                      ),
                    ),
                  ),

                  // U~V : 일기 텍스트 병합
                  Positioned(
                    left: 21 * cellW,
                    top: 0,
                    width: 2 * cellW,
                    height: cellH,
                    child: Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: border,
                      ),

                      child: Text(
                        '일기',
                        style: TextStyle(fontSize: baseFont / 2),
                      ),
                    ),
                  ),

                  // X~AB : 실제 날씨 병합
                  Positioned(
                    left: 23 * cellW,
                    top: 0,
                    width: 5 * cellW,
                    height: cellH,
                    child: GestureDetector(
                      onTap: _onTapWeather,
                      child: Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: border,
                        ),

                        child: Text(
                          _selectedWeather.isEmpty ? '선택' : _selectedWeather,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: baseFont / 2),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),

        // 9~10행 (두 행을 합친 영역)
        Expanded(
          flex: 2,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final totalW = constraints.maxWidth;
              final totalH = constraints.maxHeight;
              final cellW = totalW / 28; // 전체 열 기준
              final rowH = totalH / 2; // 두 행이니 각 행 높이
              final border = Border.all(
                color: Colors.grey.shade300,
                width: 0.5,
              );
              final baseFont = rowH * 0.6;

              // 안전하게 null 처리
              final board = _selectedBoard;
              String incomingCapacity = board?.incomingCapacity ?? '-';
              String generationCapacity = board?.generationCapacity ?? '-';
              String incomingPrimaryVoltage =
                  board?.incomingPrimaryVoltage ?? '-';
              String generationPrimaryVoltage =
                  board?.generationPrimaryVoltage ?? '-';
              String incomingSecondaryVoltage =
                  board?.incomingSecondaryVoltage ?? '-';
              String generationSecondaryVoltage =
                  board?.generationSecondaryVoltage ?? '-';
              String solarCapacity = board?.solarCapacity ?? '-';
              String solarVoltage = board?.solarVoltage ?? '-';

              // 기존 변수들 가져온 이후에
              final sum =
                  _parseCapacity(incomingCapacity) +
                  _parseCapacity(generationCapacity) +
                  _parseCapacity(solarCapacity);
              final sumText = sum == 0
                  ? '0'
                  : (sum % 1 == 0
                        ? sum.toInt().toString()
                        : sum.toStringAsFixed(1)); // 소수 있으면 한 자리까지

              return Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.black,
                    width: 1,
                  ), // 전체 검은 테두리
                ),
                child: Stack(
                  children: [
                    // 배경 그리드: 2행 × 28열 (필요한 경우, 아니면 생략하고 병합셀만 보여줘도 됨)
                    Column(
                      children: [
                        Row(
                          children: List.generate(28, (_) {
                            return Container(
                              width: cellW,
                              height: rowH,
                              decoration: BoxDecoration(border: border),
                            );
                          }),
                        ),
                        Row(
                          children: List.generate(28, (_) {
                            return Container(
                              width: cellW,
                              height: rowH,
                              decoration: BoxDecoration(border: border),
                            );
                          }),
                        ),
                      ],
                    ),

                    // A~B: 계약 용량 (두 행 병합)
                    Positioned(
                      left: 0,
                      top: 0,
                      width: 2 * cellW,
                      height: 2 * rowH,
                      child: Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: border,
                        ),

                        child: Text(
                          '계약\n용량',
                          style: TextStyle(
                            fontSize: baseFont,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    // 9행 C~E: 수전 (top row)
                    Positioned(
                      left: 2 * cellW,
                      top: 0,
                      width: 3 * cellW,
                      height: rowH,
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: border,
                        ),

                        child: Text('수전', style: TextStyle(fontSize: baseFont)),
                      ),
                    ),

                    // 10행 C~E: 발전 (bottom row)
                    Positioned(
                      left: 2 * cellW,
                      top: rowH,
                      width: 3 * cellW,
                      height: rowH,
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: border,
                        ),

                        child: Text('발전', style: TextStyle(fontSize: baseFont)),
                      ),
                    ),

                    // 9행 F~G: incoming_capacity
                    Positioned(
                      left: 5 * cellW,
                      top: 0,
                      width: 2 * cellW,
                      height: rowH,
                      child: Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: border,
                        ),

                        child: Text(
                          incomingCapacity,
                          style: TextStyle(fontSize: baseFont),
                        ),
                      ),
                    ),

                    // 10행 F~G: generation_capacity
                    Positioned(
                      left: 5 * cellW,
                      top: rowH,
                      width: 2 * cellW,
                      height: rowH,
                      child: Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: border,
                        ),

                        child: Text(
                          generationCapacity,
                          style: TextStyle(fontSize: baseFont),
                        ),
                      ),
                    ),

                    // 9행 H: KW
                    Positioned(
                      left: 7 * cellW,
                      top: 0,
                      width: cellW,
                      height: rowH,
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: border,
                        ),

                        child: Text(
                          'KW',
                          style: TextStyle(fontSize: baseFont * 0.8),
                        ),
                      ),
                    ),

                    // 10행 H: KW
                    Positioned(
                      left: 7 * cellW,
                      top: rowH,
                      width: cellW,
                      height: rowH,
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: border,
                        ),

                        child: Text(
                          'KW',
                          style: TextStyle(fontSize: baseFont * 0.8),
                        ),
                      ),
                    ),

                    // 9행 I~J: incoming_primary_voltage
                    Positioned(
                      left: 8 * cellW,
                      top: 0,
                      width: 2 * cellW,
                      height: rowH,
                      child: Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: border,
                        ),

                        child: Text(
                          incomingPrimaryVoltage,
                          style: TextStyle(fontSize: baseFont),
                        ),
                      ),
                    ),

                    // 10행 I~J: generation_primary_voltage
                    Positioned(
                      left: 8 * cellW,
                      top: rowH,
                      width: 2 * cellW,
                      height: rowH,
                      child: Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: border,
                        ),

                        child: Text(
                          generationPrimaryVoltage,
                          style: TextStyle(fontSize: baseFont),
                        ),
                      ),
                    ),

                    // 9행 K: /
                    Positioned(
                      left: 10 * cellW,
                      top: 0,
                      width: cellW,
                      height: rowH,
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: border,
                        ),

                        child: Text('/', style: TextStyle(fontSize: baseFont)),
                      ),
                    ),

                    // 10행 K: /
                    Positioned(
                      left: 10 * cellW,
                      top: rowH,
                      width: cellW,
                      height: rowH,
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: border,
                        ),

                        child: Text('/', style: TextStyle(fontSize: baseFont)),
                      ),
                    ),

                    // 9행 L~M: incoming_secondary_voltage
                    Positioned(
                      left: 11 * cellW,
                      top: 0,
                      width: 2 * cellW,
                      height: rowH,
                      child: Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: border,
                        ),

                        child: Text(
                          incomingSecondaryVoltage,
                          style: TextStyle(fontSize: baseFont),
                        ),
                      ),
                    ),

                    // 10행 L~M: generation_secondary_voltage
                    Positioned(
                      left: 11 * cellW,
                      top: rowH,
                      width: 2 * cellW,
                      height: rowH,
                      child: Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: border,
                        ),

                        child: Text(
                          generationSecondaryVoltage,
                          style: TextStyle(fontSize: baseFont),
                        ),
                      ),
                    ),

                    Positioned(
                      left: 13 * cellW,
                      top: 0,
                      width: 1 * cellW,
                      height: rowH,
                      child: Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: border,
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'V',
                            style: TextStyle(fontSize: baseFont * 0.8),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 13 * cellW,
                      top: rowH,
                      width: 1 * cellW,
                      height: rowH,
                      child: Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: border,
                        ),

                        child: Text(
                          'V',
                          style: TextStyle(fontSize: baseFont * 0.8),
                        ),
                      ),
                    ),

                    // O~P: 태양광 설비 (두 행 병합)
                    Positioned(
                      left: 14 * cellW,
                      top: 0,
                      width: 2 * cellW,
                      height: 2 * rowH,
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: border,
                        ),

                        child: Text(
                          '태양광\n설비',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: baseFont,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    // 9행 Q~R: solar_capacity
                    Positioned(
                      left: 16 * cellW,
                      top: 0,
                      width: 3 * cellW,
                      height: rowH,
                      child: Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: border,
                        ),

                        child: Text(
                          solarCapacity,
                          style: TextStyle(fontSize: baseFont),
                        ),
                      ),
                    ),

                    // 10행 Q~R: solar_voltage
                    Positioned(
                      left: 16 * cellW,
                      top: rowH,
                      width: 3 * cellW,
                      height: rowH,
                      child: Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: border,
                        ),

                        child: Text(
                          solarVoltage,
                          style: TextStyle(fontSize: baseFont),
                        ),
                      ),
                    ),

                    // 9행 T: KW
                    Positioned(
                      left: 19 * cellW,
                      top: 0,
                      width: cellW,
                      height: rowH,
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: border,
                        ),

                        child: Text(
                          'KW',
                          style: TextStyle(fontSize: baseFont * 0.8),
                        ),
                      ),
                    ),

                    // 10행 T: V
                    Positioned(
                      left: 19 * cellW,
                      top: rowH,
                      width: cellW,
                      height: rowH,
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: border,
                        ),

                        child: Text(
                          'V',
                          style: TextStyle(fontSize: baseFont * 0.8),
                        ),
                      ),
                    ),

                    // U: 합계 (두 행 병합)
                    Positioned(
                      left: 20 * cellW,
                      top: 0,
                      width: 2 * cellW,
                      height: 2 * rowH,
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: border,
                        ),

                        child: Text(
                          '합계',
                          style: TextStyle(
                            fontSize: baseFont,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    // V~Y: 빈칸 (두 행)
                    Positioned(
                      left: 22 * cellW,
                      top: 0,
                      width: 4 * cellW,
                      height: 2 * rowH,
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: border,
                        ),

                        child: Text(
                          sumText,
                          style: TextStyle(
                            fontSize: baseFont,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    // Z~AB: KW (두 행)
                    Positioned(
                      left: 26 * cellW,
                      top: 0,
                      width: 2 * cellW,
                      height: 2 * rowH,
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: border,
                        ),

                        child: Text(
                          'KW',
                          style: TextStyle(fontSize: baseFont * 0.8),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        // 11행 빈칸 (한 행)
        Expanded(flex: 1, child: const BlankRow()),

        Expanded(
          flex: 5, // 5행 분량
          child: LayoutBuilder(
            builder: (context, constraints) {
              final totalW = constraints.maxWidth;
              final totalH = constraints.maxHeight;
              final cellW = totalW / 28;
              final rowH = totalH / 5; // 5개 행
              final border = Border.all(
                color: Colors.grey.shade300,
                width: 0.5,
              );
              final baseFont = rowH * 0.55;

              final safetyTexts = [
                '1. 부적합 설비를 방치하시면 전기재해 및 정전으로 인한 전력손실등의 원인이 될 수 있으니 조속히 개,보수요망.',
                '2. 전기설비의 개·보수 시 전기안전관리사 통보, 전문업체 시공, 정전상태 시행, 전기안전관리법령 준수.',
                '3. 내용 년수가 경과한 전기설비는 교체 대상입니다.',
                '4. 젖은 손으로 전기코드, 차단기 및 전기기계·기구 조작 엄금',
                '5. 월 1회 이상 전직원의 전기안전교육을 실시하십시오.',
              ];

              return Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black, width: 1),
                ),
                child: Stack(
                  children: [
                    // 배경 5x28 그리드 (선택적, 있어야 셀 구분 느낌)
                    Column(
                      children: List.generate(5, (r) {
                        return SizedBox(
                          height: rowH,
                          child: Row(
                            children: List.generate(28, (c) {
                              return Container(
                                width: cellW,
                                height: rowH,
                                decoration: BoxDecoration(border: border),
                              );
                            }),
                          ),
                        );
                      }),
                    ),

                    // 왼쪽 세로 병합된 '안전교육' (5행 높이, 2열 너비)
                    Positioned(
                      left: 0,
                      top: 0,
                      width: 2 * cellW,
                      height: 5 * rowH,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: border,
                        ),
                        child: Center(
                          child: Text(
                            '안\n전\n교\n육',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: baseFont * 1.2,
                              fontWeight: FontWeight.bold,
                              height: 1.4, // 줄간격을 1.4배로 늘림
                            ),
                          ),
                        ),
                      ),
                    ),

                    // 오른쪽 항목들 (각 행마다 A~AB에서 왼쪽 2열 뺀 나머지 전체)
                    for (int i = 0; i < safetyTexts.length; i++)
                      Positioned(
                        left: 2 * cellW,
                        top: i * rowH,
                        width: (28 - 2) * cellW,
                        height: rowH,
                        child: Container(
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: border,
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              safetyTexts[i],
                              style: TextStyle(fontSize: baseFont),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),

        // 17행 빈칸 (한 행)
        Expanded(flex: 1, child: const BlankRow()),

        // 18행: 점검내역 (판정 : 양, 부)
        Expanded(
          flex: 1,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final totalW = constraints.maxWidth;
              final rowH = constraints.maxHeight;
              final cellW = totalW / 28;

              final baseFont = rowH * 0.55;

              return Stack(
                children: [
                  // 배경 1×28 그리드 (셀 구분 느낌)
                  Row(
                    children: List.generate(28, (_) {
                      return Container(width: cellW, height: rowH);
                    }),
                  ),
                  // 전체 병합된 텍스트 영역
                  Positioned(
                    left: 0,
                    top: 0,
                    width: 28 * cellW,
                    height: rowH,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      alignment: Alignment.centerLeft,
                      decoration: BoxDecoration(),
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: baseFont,
                            color: Colors.black,
                          ),
                          children: const [
                            TextSpan(
                              text: '점검내역(판정 : 양, 부)',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        Expanded(
          // 기존 flex 합계(4+2+1+6)=13 을 그대로 사용
          flex: 19,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black, width: 1),
            ),
            child: Column(
              children: [
                Expanded(
                  flex: 1,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final totalW = constraints.maxWidth;
                      final rowH = constraints.maxHeight;
                      final border = Border.all(
                        color: Colors.grey.shade300,
                        width: 0.5,
                      );
                      final baseFont = rowH * 0.55;

                      Widget cell(
                        String text, {
                        FontWeight weight = FontWeight.normal,
                      }) {
                        return Container(
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: border,
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              text,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: baseFont,
                                fontWeight: weight,
                              ),
                            ),
                          ),
                        );
                      }

                      return Row(
                        children: [
                          // 1st group: 저 압 설 비 / 판정 / 비고 (4:2:3) => total flex 9
                          Expanded(
                            flex: 9,
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 4,
                                  child: cell(
                                    '저 압 설 비',
                                    weight: FontWeight.bold,
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: cell('판정', weight: FontWeight.bold),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: cell('비고', weight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          // 2nd group: 특고(고압)설비 / 판정 / 비고 (4:2:3)
                          Expanded(
                            flex: 9,
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 4,
                                  child: cell(
                                    '특고(고압)설비',
                                    weight: FontWeight.bold,
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: cell('판정', weight: FontWeight.bold),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: cell('비고', weight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          // 3rd group: 태 양 광 설 비 / 판정 / 비고 (4:2:4) => total flex 10
                          Expanded(
                            flex: 10,
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 5,
                                  child: cell(
                                    '태양광설비', // 세로로 배치하고 싶다면 줄바꿈
                                    weight: FontWeight.bold,
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: cell('판정', weight: FontWeight.bold),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: cell('비고', weight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

                ...List.generate(7, (i) {
                  return Expanded(
                    flex: 1,
                    child: InspectionLineWidget(
                      left: hvLogEntry.lowVoltageItems[i],
                      middle: hvLogEntry.highVoltageItems[i],
                      right: hvLogEntry.solarItems[i],
                      onChanged:
                          ({
                            required left,
                            required middle,
                            required right,
                            required value,
                          }) {
                            // 변경 감지: 같은 인스턴스라 기본적으로 반영되어 있음
                            _onAnyLineChanged(
                              i,
                              left: left,
                              middle: middle,
                              right: right,
                              value: 0,
                            );
                            // 필요하면 저장 호출
                            //  _persistLocally();
                          },
                    ),
                  );
                }),

                //7_9행 송전전압
                Expanded(
                  flex: 3, // 3줄이므로 flex 비율 적절히 조절
                  child: TransmissionVoltageTripleWidget(
                    leftEntries: [
                      hvLogEntry.lowVoltageItems[7],
                      hvLogEntry.lowVoltageItems[8],
                      hvLogEntry.lowVoltageItems[9],
                    ],
                    middleEntries: [
                      hvLogEntry.highVoltageItems[7],
                      hvLogEntry.highVoltageItems[8],
                      hvLogEntry.highVoltageItems[9],
                    ],
                    rightEntries: [
                      hvLogEntry.solarItems[7],
                      hvLogEntry.solarItems[8],
                      hvLogEntry.solarItems[9],
                    ],
                    entry: hvLogEntry,
                    onLineChanged:
                        ({
                          required int index,
                          required InspectionEntry left,
                          required InspectionEntry middle,
                          required InspectionEntry right,
                          required double value,
                        }) {
                          _onAnyLineChanged(
                            index,
                            left: left,
                            middle: middle,
                            right: right,
                            value: value,
                          );
                        },
                  ),
                ),

                //10_11행 pv 전압
                Expanded(
                  flex: 2, // 3줄이므로 flex 비율 적절히 조
                  child: TransmissionVoltageDoubleWidget(
                    leftEntries: [
                      hvLogEntry.lowVoltageItems[10],
                      hvLogEntry.lowVoltageItems[11],
                    ],
                    middleEntries: [
                      hvLogEntry.highVoltageItems[10],
                      hvLogEntry.highVoltageItems[11],
                    ],
                    entry: hvLogEntry,
                    onLineChanged:
                        ({
                          required int index,
                          required InspectionEntry left,
                          required InspectionEntry middle,

                          required double value,
                        }) {
                          _onAnyLineChanged(
                            index,
                            left: left,
                            middle: middle,
                            right: hvLogEntry.solarItems[index],
                            value: value,
                          );
                        },
                  ),
                ),

                //12_15행 현재 발전량, 누적발전량
                Expanded(
                  flex: 4,
                  child: TransmissionVoltageQuadWidget(
                    leftEntries: [
                      hvLogEntry.lowVoltageItems[12],
                      hvLogEntry.lowVoltageItems[13],
                      hvLogEntry.lowVoltageItems[14],
                      hvLogEntry.lowVoltageItems[15],
                    ],
                    middleEntries: [
                      hvLogEntry.highVoltageItems[12],
                      hvLogEntry.highVoltageItems[13],
                      hvLogEntry.highVoltageItems[14],
                      hvLogEntry.highVoltageItems[15],
                    ],
                    entry: hvLogEntry,
                    onLineChanged:
                        ({
                          required int index,
                          required InspectionEntry left,
                          required InspectionEntry middle,
                          double? currentGeneration,
                          double? cumulativeGeneration,
                        }) {
                          // 어떤 값이 들어왔는지 판별
                          final bool isCurrent = currentGeneration != null;
                          final bool isCumul = cumulativeGeneration != null;
                          final double value = isCurrent
                              ? currentGeneration!
                              : cumulativeGeneration!;
                          final int idx = isCurrent ? 12 : 13;

                          _onAnyLineChanged(
                            idx,
                            left: left,
                            middle: middle,
                            right: hvLogEntry.solarItems[idx],
                            value: value,
                          );
                        },
                  ),
                ),

                Expanded(
                  flex: 2, // 3줄이므로 flex 비율 적절히 조
                  child: MeasurementPowerWidget(
                    entry: hvLogEntry,
                    onChanged: (field, value) {
                      debugPrint('[$field] 가 $value 로 변경되었습니다.');
                      if (field == 'powerRatio') {
                        // (금일지침계 - 전추지침계) * powerRatio
                        final diff =
                            hvLogEntry.guidelineCurrentSum -
                            hvLogEntry.guidelinePrevSum;
                        final generated = diff * value;
                        setState(() {
                          // 여기에 결과를 저장할 필드가 있다면 대입
                          hvLogEntry.pvVoltage = generated;
                        });

                        saveDB();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),

        Expanded(flex: 1, child: const BlankRow()),

        Expanded(
          flex: 1,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final totalW = constraints.maxWidth;
              final rowH = constraints.maxHeight;
              final cellW = totalW / 28;

              final baseFont = rowH * 0.55;

              return Stack(
                children: [
                  // 배경 1×28 그리드 (셀 구분 느낌)
                  Row(
                    children: List.generate(28, (_) {
                      return Container(width: cellW, height: rowH);
                    }),
                  ),
                  // 전체 병합된 텍스트 영역
                  Positioned(
                    left: 0,
                    top: 0,
                    width: 28 * cellW,
                    height: rowH,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      alignment: Alignment.centerLeft,
                      decoration: BoxDecoration(),
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: baseFont,
                            color: Colors.black,
                          ),
                          children: const [
                            TextSpan(
                              text: '점검결과 및 보안, 안전사항',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),

        // 3행: 점검 결과 및 보완 사항 입력 (키패드 or 터치)
        // 3행: 점검 결과 및 보완 사항 입력 (2단위)
        Expanded(
          flex: 4,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black, width: 1),
              color: Colors.white, // 배경을 흰색으로
            ),

            child: LayoutBuilder(
              builder: (context, constraints) {
                // 셀 높이 가져오기
                final rowH = constraints.maxHeight;
                // 폰트 크기의 기준으로 사용할 값 계산
                final baseFont = rowH * 0.55 / 3;

                return GestureDetector(
                  onTap: () async {
                    // 1-1) 선택 다이얼로그: String 반환
                    final method = await showDialog<String>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text('입력 방식 선택'),
                        content: Text('키보드, 터치, 템플릿 중 하나를 선택하세요.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, 'keyboard'),
                            child: Text('키보드 입력'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, 'touch'),
                            child: Text('터치 입력'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, 'template'),
                            child: Text('템플릿 입력'),
                          ),
                        ],
                      ),
                    );

                    // 2) 반환된 method 값에 따라 분기
                    if (method == 'keyboard') {
                      // 시스템 키보드 다이얼로그
                      final result = await showDialog<String>(
                        context: context,
                        builder: (ctx) {
                          String input = hvLogEntry.inspectionResultNumeric;
                          return AlertDialog(
                            title: Text('점검 결과 입력'),
                            content: TextField(
                              autofocus: true,
                              keyboardType:
                                  TextInputType.multiline, // 멀티라인용 키보드
                              maxLines: 5, // 최대 5줄
                              decoration: InputDecoration(
                                hintText: '여기에 내용을 입력하세요',
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (v) => input = v,
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: Text('취소'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, input),
                                child: Text('확인'),
                              ),
                            ],
                          );
                        },
                      );

                      if (result != null) {
                        setState(() {
                          hvLogEntry.inspectionResultImage = null; // ← 이미지 클리어
                          hvLogEntry.inspectionResultNumeric =
                              result; // ← 텍스트 저장
                        });
                        saveDB();
                      }
                    } else if (method == 'touch') {
                      final pngBytes = await showDialog<Uint8List>(
                        context: context,
                        barrierDismissible: false,
                        builder: (ctx) => Dialog(
                          // 다이얼로그 크기 조절
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width * 0.8,
                            height: MediaQuery.of(context).size.height * 0.6,
                            child: DrawingDialogContent(),
                          ),
                        ),
                      );

                      if (pngBytes != null) {
                        setState(() {
                          hvLogEntry.inspectionResultImage = pngBytes;
                        });
                        saveDB();
                      }
                    } else if (method == 'template') {
                      // 2-1) TemplateListPage 로 이동 → 선택된 템플릿 문자열을 받는다
                      final selected = await Navigator.push<String>(
                        context,
                        MaterialPageRoute(builder: (_) => TemplateListPage()),
                      );
                      if (selected != null) {
                        setState(
                          () => hvLogEntry.inspectionResultNumeric = selected,
                        );
                        saveDB();
                      }
                    }
                  },
                  child: Container(
                    alignment: Alignment.topLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: hvLogEntry.inspectionResultImage != null
                        // 이미지가 있으면 드로잉 결과를 보여준다
                        ? Image.memory(
                            hvLogEntry.inspectionResultImage!,
                            fit: BoxFit.fill,
                          )
                        // 이미지가 없으면 기존 텍스트(또는 숫자) 표시
                        : Text(
                            hvLogEntry.inspectionResultNumeric.isEmpty
                                ? '점검 결과 및 보완 사항을 입력하세요(이곳을 터치하세요)'
                                : hvLogEntry.inspectionResultNumeric,
                            style: TextStyle(fontSize: baseFont * 0.7),
                          ),
                  ),
                );
              },
            ),
          ),
        ),

        Expanded(
          flex: 2,
          child: GuidelineInputWidget(
            entry: hvLogEntry,
            onChanged: (field, value) {
              setState(() {
                // 1) 들어온 field 이름에 따라 entry 필드 업데이트
                switch (field) {
                  case '현 지침 ④ 입력':
                    hvLogEntry.guidelineCurrent4 = value;
                    break;
                  case '현 지침 ⑤ 입력':
                    hvLogEntry.guidelineCurrent5 = value;
                    break;
                  case '현 지침 ⑥ 입력':
                    hvLogEntry.guidelineCurrent6 = value;
                    break;
                  case '전 지침 ⑨ 입력':
                    hvLogEntry.guidelinePrev9 = value;
                    break;
                  case '전 지침 ⑩ 입력':
                    hvLogEntry.guidelinePrev10 = value;
                    break;
                  case '전 지침 ⑪ 입력':
                    hvLogEntry.guidelinePrev11 = value;
                    break;
                  // (powerRatio, pvVoltage 등 다른 필드도 여기에 추가 가능)
                }

                // 2) 합계 재계산
                hvLogEntry.guidelineCurrentSum =
                    hvLogEntry.guidelineCurrent4 +
                    hvLogEntry.guidelineCurrent5 +
                    hvLogEntry.guidelineCurrent6;

                hvLogEntry.guidelinePrevSum =
                    hvLogEntry.guidelinePrev9 +
                    hvLogEntry.guidelinePrev10 +
                    hvLogEntry.guidelinePrev11;

                // 3) (선택) pvVoltage 자동 계산
                final diff =
                    hvLogEntry.guidelineCurrentSum -
                    hvLogEntry.guidelinePrevSum;
                hvLogEntry.pvVoltage = diff * hvLogEntry.powerRatio;

                saveDB();
              });
            },
          ),
        ),

        Expanded(flex: 1, child: const BlankRow()),

        Expanded(
          flex: 6, // 필요에 맞게 1~3 사이로 조절

          child: ConfirmationView(
            inspectorController: _inspectorController,
            managerMainController: _managerMainController,
            managerSubController: _managerSubController,
            onSendEmail: _onSendEmail,
            onNameChanged: (field, value) {
              setState(() {
                switch (field) {
                  case '점검 확인자':
                    hvLogEntry.inspectorName = value;
                    break;
                  case '안전관리자(정)':
                    hvLogEntry.managerMainName = value;
                    break;
                  case '안전관리자(부)':
                    hvLogEntry.managerSubName = value;
                    break;
                }

                saveDB();
              });
            },
          ),
        ),
      ],
    );
  }
}
