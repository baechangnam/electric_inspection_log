// lib/widgets/excel_grid.dart
import 'dart:convert';
import 'dart:io';

import 'package:electric_inspection_log/core/db/hv_helper.dart';
import 'package:electric_inspection_log/core/utils/pdf_maker.dart';
import 'package:electric_inspection_log/core/utils/save_utils.dart';
import 'package:electric_inspection_log/data/models/board_item.dart';
import 'package:electric_inspection_log/data/models/hvItem.dart';
import 'package:electric_inspection_log/views/main/drawing_screen.dart';
import 'package:electric_inspection_log/views/main/template_screen.dart';
import 'package:electric_inspection_log/widgets/confrim_widget.dart';
import 'package:electric_inspection_log/widgets/drawing_popup.dart';
import 'package:electric_inspection_log/widgets/empty_line.dart';
import 'package:electric_inspection_log/widgets/export_excel.dart';
import 'package:electric_inspection_log/widgets/export_excel_low.dart';
import 'package:electric_inspection_log/widgets/inspection_entry.dart';
import 'package:electric_inspection_log/widgets/inspection_line_widget.dart';
import 'package:electric_inspection_log/widgets/measure_widget.dart';
import 'package:electric_inspection_log/widgets/measure_widget_low.dart';
import 'package:electric_inspection_log/widgets/measurement_power_widget.dart';
import 'package:electric_inspection_log/widgets/numeric_keypad.dart';
import 'package:electric_inspection_log/widgets/template_widget.dart';
import 'package:electric_inspection_log/widgets/trans_widget.dart';
import 'package:electric_inspection_log/widgets/transmission_voltage_quad_widget.dart';
import 'package:electric_inspection_log/widgets/transmission_voltage_quad_widget_low.dart';
import 'package:electric_inspection_log/widgets/two_line_dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;

class ExcelGridLow extends StatefulWidget {
  const ExcelGridLow({Key? key}) : super(key: key);

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

class _ExcelGridState extends State<ExcelGridLow> {
  static const int rows = 11;
  static const int columns = 28;

  late final List<List<String>> _data;
  String _selectedConsumer = '';
  late final List<InspectionEntry> lefts;
  late final List<InspectionEntry> middles;
  late final List<InspectionEntry> rights;

  late final String weekdayLabel;
  late final String formattedDate;

  String incomingCapacity = '';
  String generationCapacity = '';
  String incomingPrimaryVoltage = '';
  String generationPrimaryVoltage = '';
  String incomingSecondaryVoltage = '';
  String generationSecondaryVoltage = '';
  String solarCapacity = '';
  String solarVoltage = '';
  String sumText = '0';
  String mainName = '';

  // excel_grid.dart (State 안)
  final _exportKey = GlobalKey();
  String reg_id = '';

  Future<void> _loadName() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('mem_id');
    if (stored != null && stored.isNotEmpty) {
      setState(() => reg_id = stored);
    }
  }

  // 간단 이메일 포맷 체크
  bool _isValidEmail(String s) {
    final re = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return re.hasMatch(s);
  }

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
    '접지선상태,탈착여부',
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

    final now = DateTime.now();
    formattedDate = '${now.year}년${now.month}월${now.day}일';
    _loadName();

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
    required double? value,
  }) {
    setState(() {
      // 같은 인스턴스를 넘기고 있으니 사실 이 할당은 선택적이지만 명시적으로 동기화
      hvLogEntry.lowVoltageItems[index] = left;
      hvLogEntry.highVoltageItems[index] = middle;
      hvLogEntry.solarItems[index] = right;

      debugPrint('--- 라인 ${index} 변경 ---');

      switch (index) {
        case 7:
          if (value != null) {
            hvLogEntry.transmissionRtoS = value;
          }

          break;
        case 8:
          if (value != null) {
            hvLogEntry.transmissionStoT = value;
          }

          break;
        case 9:
          if (value != null) {
            hvLogEntry.transmissionRtoT = value;
          }
          break;
      }

      if (index == 10 || index == 11) {
        if (value != null) {
          //hvLogEntry.pvVoltage = value;
        }
      }
      // 3) index 가 12(current) or 13(cumulative)이면 발전량
      else if (index == 12) {
        if (value != null) {
          hvLogEntry.preMonthGenerationKwh = value;
        }
      } else if (index == 13) {
        if (value != null) {
          hvLogEntry.cumulativeGenerationMwh = value;
        }
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
  Future<void> _onSendEmail() async {
    // _inspectorController.text 에 작성된 값으로 메일 발송 로직 실행
    // print('메일 발송 대상: ${_inspectorController.text}');
    exportPdfAndExcel();
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

  Future<Uint8List> _buildExcelBytes() async {
    final logoBytes = (await rootBundle.load(
      'assets/logo_new.png',
    )).buffer.asUint8List();

    final wb = xlsio.Workbook();
    final s = wb.worksheets[0];
    KoHighHeaderLow.applyThinGrayBorders(s, 'A1:AB60');
    KoHighHeaderLow.apply(s);

    KoHighHeaderLow.fillRow7(
      s,
      consumerName: _selectedConsumer,
      dateText: formattedDate,
      weatherText: _selectedWeather,
    );

    KoHighHeaderLow.fillRow910(
      s,
      incomingCapacity: incomingCapacity,
      generationCapacity: generationCapacity,
      incomingPrimaryVoltage: incomingPrimaryVoltage,
      generationPrimaryVoltage: generationPrimaryVoltage,
      incomingSecondaryVoltage: incomingSecondaryVoltage,
      generationSecondaryVoltage: generationSecondaryVoltage,
      solarCapacity: solarCapacity,
      solarVoltage: solarVoltage,
      sumText: sumText,
    );

    KoHighHeaderLow.applyRow910(s);
    KoHighHeaderLow.applyRow12to16(s);
    KoHighHeaderLow.fillRow12to16(s);

    KoHighHeaderLow.drawOuterBorderCellwise(
      s,
      r1: 9,
      c1: 1,
      r2: 10,
      c2: 28,
    ); // 9~10행 전체(s);

    KoHighHeaderLow.applyRow18(s);
    KoHighHeaderLow.applyRow19(s); // 19행 헤더 (요청사항)
    KoHighHeaderLow.applyRows20to26FromEntry(s, hvLogEntry);

    // 레이아웃
    KoHighHeaderLow.applyRows27to29(s);

    // 값 채우기: 저압 7~9, 특고 7~9 아이템 사용 예
    KoHighHeaderLow.fillRows27to29(
      s,
      left: hvLogEntry.lowVoltageItems.sublist(7, 10),
      middle: hvLogEntry.highVoltageItems.sublist(7, 10),
      vRS: hvLogEntry.transmissionRtoS,
      vST: hvLogEntry.transmissionStoT,
      vRT: hvLogEntry.transmissionRtoT,
    );

    KoHighHeaderLow.applyRows30to35(
      s,
      left6: hvLogEntry.lowVoltageItems.sublist(10, 16),
      middle6: hvLogEntry.highVoltageItems.sublist(10, 16),
      pvVoltage: 0,
      preMonthGenerationKwh: hvLogEntry.preMonthGenerationKwh,
      cumulativeGenerationMwh: hvLogEntry.cumulativeGenerationMwh,
    );

    KoHighHeaderLow.applyRowsVoltageAndPower(s, hvLogEntry, startRow: 36);
    KoHighHeaderLow.applyRow39Header(s, withBorder: false);

    KoHighHeaderLow.applyResultBlock(
      s,
      imageBytes: hvLogEntry.inspectionResultImage,
      text: hvLogEntry.inspectionResultNumeric,
    );

    KoHighHeaderLow.applyGuidelineRows(s, hvLogEntry, startRow: 43);

    KoHighHeaderLow.applyFinalConfirmBlock(
      s,
      startRow: 45, // 원하는 위치
      logoPng: logoBytes,
      inspectorName: hvLogEntry.inspectorName ?? '',
      managerMainName: hvLogEntry.managerMainName ?? '',
      managerSubName: hvLogEntry.managerSubName ?? '',
      managerMainSigPng: hvLogEntry.managerMainSignature,
      managerSubSigPng: hvLogEntry.managerSubSignature,
    );

    // final bytes = Uint8List.fromList(wb.saveSync());
    // wb.dispose();

    // final ts = DateTime.now().millisecondsSinceEpoch;

    // final savedPath = await saveBytesToDownloads(
    //   bytes: bytes,
    //   fileName: '고압일지_${_selectedConsumer}_${_ts()}.xlsx',
    // );

    // print('저장 완료: $savedPath');

    final bytes = Uint8List.fromList(wb.saveSync());
    wb.dispose();
    return bytes;
  }

  DateTime now = DateTime.now();

  String formatCapacity(String raw) {
    // 숫자로 변환
    final v = double.tryParse(raw.replaceAll(',', '').trim());
    if (v == null) return raw; // 숫자 아님 → 그대로 표시
    if (v == 0) return '_'; // 0 → 언더바 처리

    // 소수점 있는지 확인
    final hasDecimal = raw.contains('.') && double.tryParse(raw) != null;

    // 표시값 계산
    String fixed;
    if (hasDecimal) {
      // 소수점 있는 값 → 둘째자리까지
      fixed = v.toStringAsFixed(2);
      // 12345.20 같은 경우 뒤에 0 지우기
      if (fixed.endsWith('0')) fixed = fixed.replaceAll(RegExp(r'0+$'), '');
      if (fixed.endsWith('.')) fixed = fixed.substring(0, fixed.length - 1);
    } else {
      // 정수 값 → 소수점 없이
      fixed = v.toStringAsFixed(0);
    }

    // 천단위 콤마 삽입
    final parts = fixed.split('.');
    final intPart = parts[0];
    final decPart = parts.length > 1 ? parts[1] : '';

    final buffer = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      final idxFromEnd = intPart.length - i;
      buffer.write(intPart[i]);
      if (idxFromEnd > 1 && idxFromEnd % 3 == 1) {
        buffer.write(',');
      }
    }

    return decPart.isEmpty
        ? buffer.toString()
        : '${buffer.toString()}.$decPart';
  }

  String _ts() {
    final n = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${n.year}${two(n.month)}${two(n.day)}${two(n.hour)}${two(n.minute)}${two(n.second)}';
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

  String _selectedDate = ''; // 여기에 선택된 날씨 문자열을 저장
  String _selectedWeather = ''; // 여기에 선택된 날씨 문자열을 저장
  String _selectedEmail = ''; // 이메일

  bool _validateBeforeExport() {
    if (_selectedConsumer.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('고객명(상호)을 먼저 선택하세요.')));
      return false;
    }
    if ((_selectedEmail == null) ||
        _selectedEmail!.isEmpty ||
        !_isValidEmail(_selectedEmail!)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('유효한 이메일 주소가 없습니다.')));
      return false;
    }
    return true;
  }

  Future<void> exportPdfAndExcel() async {
    if (!_validateBeforeExport()) return;

    // 진행중 다이얼로그
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Dialog(
        insetPadding: EdgeInsets.symmetric(horizontal: 48),
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('업로드 중입니다...'),
            ],
          ),
        ),
      ),
    );

    try {
      // 1) PDF 생성
      final pdfFile = await PdfExporter.exportFromBoundary(_exportKey);

      // 2) 엑셀 bytes 생성
      final excelBytes = await _buildExcelBytes();
      final excelFileName = '저얍일지_${_selectedConsumer}_${_ts()}.xlsx';

      // 3) 서버 업로드 (PDF+엑셀 동시)
      await uploadPdfAndExcelRegister(
        pdfFile: pdfFile,
        excelBytes: excelBytes,
        excelFileName: excelFileName,
        regId: reg_id,
        email: _selectedEmail,
        contents: hvLogEntry.inspectionResultNumeric,
      );

      // 진행중 닫기
      Navigator.of(context, rootNavigator: true).pop();

      // 완료 팝업
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('완료'),
          content: Text('메일발송이 완료되었습니다.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('확인'),
            ),
          ],
        ),
      );
    } catch (e) {
      // 진행중 닫기
      Navigator.of(context, rootNavigator: true).pop();

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('오류'),
          content: Text('업로드 실패: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('닫기'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> uploadPdfAndExcelRegister({
    required File pdfFile,
    required Uint8List excelBytes,
    required String excelFileName,
    required String regId,
    required String email,
    String contents = '',
  }) async {
    final uri = Uri.parse('https://davin230406.mycafe24.com/api/register.php');

    final req = http.MultipartRequest('POST', uri)
      ..fields['reg_id'] = regId
      ..fields['pid'] = '3'
      ..fields['tag'] = '2'
      ..fields['email'] = email
      ..fields['contents'] = _selectedConsumer
      // 파일명 필드
      ..fields['filename'] = p.basename(pdfFile.path)
      ..fields['filename2'] = excelFileName
      // PDF 파일(디스크 경로에서)
      ..files.add(await http.MultipartFile.fromPath('file', pdfFile.path))
      // 엑셀 파일(메모리 바이트에서)
      ..files.add(
        http.MultipartFile.fromBytes(
          'file2',
          excelBytes,
          filename: excelFileName,
          // contentType 지정이 꼭 필요하면 아래 주석 해제하고 http_parser 추가
          // contentType: MediaType('application','vnd.openxmlformats-officedocument.spreadsheetml.sheet'),
        ),
      );

    final res = await req.send();
    final body = await res.stream.bytesToString();

    if (res.statusCode != 200) {
      throw Exception('업로드 실패(${res.statusCode}) $body');
    }
  }

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

  // 거래처 선택: 모달 바텀시트 (검색 포함, 키보드 안전)
  Future<BoardItem?> showBoardPickerBottomSheet(
    BuildContext context,
    List<BoardItem> list,
  ) async {
    final controller = TextEditingController();
    String query = '';

    return showModalBottomSheet<BoardItem>(
      context: context,
      isScrollControlled: true, // ✅ 키보드/전체 높이 제어
      backgroundColor: Colors.transparent, // 둥근 모서리 컨테이너를 따로 그림
      builder: (ctx) {
        final mq = MediaQuery.of(ctx);

        return StatefulBuilder(
          builder: (ctx, setState) {
            final kb = mq.viewInsets.bottom; // 키보드 높이
            final q = query.toLowerCase();
            final filtered = q.isEmpty
                ? list
                : list
                      .where((b) => b.consumerName.toLowerCase().contains(q))
                      .toList();

            return Padding(
              // ✅ 키보드가 나오면 그만큼 올려서 내용이 가려지지 않게
              padding: EdgeInsets.only(bottom: kb),
              child: DraggableScrollableSheet(
                expand: false,
                initialChildSize: 0.7, // 초기 높이 비율
                minChildSize: 0.4,
                maxChildSize: 0.95,
                builder: (ctx, scrollCtrl) {
                  return Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                    ),
                    child: SafeArea(
                      top: false,
                      child: Column(
                        children: [
                          // 상단 핸들
                          const SizedBox(height: 8),
                          Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.black26,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // 제목
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '거래처 선택',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // 검색창
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: TextField(
                              controller: controller,
                              autofocus: false, // ✅ 자동 키보드 방지
                              textInputAction: TextInputAction.search,
                              decoration: InputDecoration(
                                hintText: '거래처명 검색',
                                prefixIcon: const Icon(Icons.search),
                                suffixIcon: query.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear),
                                        onPressed: () {
                                          controller.clear();
                                          setState(() => query = '');
                                        },
                                      )
                                    : null,
                                border: const OutlineInputBorder(),
                                isDense: true,
                              ),
                              onChanged: (v) =>
                                  setState(() => query = v.trim()),
                            ),
                          ),

                          const SizedBox(height: 8),

                          // 리스트 (DraggableScrollableSheet의 controller 사용!)
                          Expanded(
                            child: filtered.isEmpty
                                ? const Center(child: Text('검색 결과가 없습니다.'))
                                : ListView.separated(
                                    controller: scrollCtrl,
                                    itemCount: filtered.length,
                                    separatorBuilder: (_, __) =>
                                        const Divider(height: 1),
                                    itemBuilder: (_, i) {
                                      final b = filtered[i];
                                      return ListTile(
                                        dense: true,
                                        title: Text(b.consumerName),
                                        subtitle: Text(b.facilityLocation),
                                        onTap: () =>
                                            Navigator.of(context).pop(b),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  bool _hasValidEmail() =>
      _selectedEmail.isNotEmpty && _isValidEmail(_selectedEmail);

  Future<void> _confirmAndSend() async {
    if (_selectedConsumer.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('고객명(상호)을 먼저 선택하세요.')));
      return;
    }

    final hasEmail = _hasValidEmail();
    final emailText = hasEmail ? _selectedEmail : '미등록';
    final bodyText = hasEmail ? '서버 저장 및 수용자 메일로 발송합니다.' : '서버에만 저장합니다.';

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('전송 확인'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('수용가 등록 메일 : $emailText'),
            const SizedBox(height: 8),
            Text(bodyText),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('확인'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    if (hasEmail) {
      await exportPdfAndExcel(); // 기존: 서버 저장 + 메일 발송
    } else {
      await exportPdfAndExcelServerOnly(); // 신규: 서버 저장만
    }
  }

  Future<void> exportPdfAndExcelServerOnly() async {
    // 진행중 다이얼로그
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Dialog(
        insetPadding: EdgeInsets.symmetric(horizontal: 48),
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('업로드 중입니다...'),
            ],
          ),
        ),
      ),
    );

    try {
      // 1) PDF 생성
      final pdfFile = await PdfExporter.exportFromBoundary(_exportKey);

      // 2) 엑셀 생성
      final excelBytes = await _buildExcelBytes();
      final excelFileName = '고압일지_${_selectedConsumer}_${_ts()}.xlsx';

      // 3) 서버 업로드 (메일은 빈 문자열로)
      await uploadPdfAndExcelRegister(
        pdfFile: pdfFile,
        excelBytes: excelBytes,
        excelFileName: excelFileName,
        regId: reg_id,
        email: '', // ← 메일 미전송
        contents: hvLogEntry.inspectionResultNumeric,
      );

      // 진행중 닫기
      Navigator.of(context, rootNavigator: true).pop();

      // 완료 팝업
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('완료'),
          content: const Text('서버 저장이 완료되었습니다.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('확인'),
            ),
          ],
        ),
      );
    } catch (e) {
      // 진행중 닫기
      Navigator.of(context, rootNavigator: true).pop();

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('오류'),
          content: Text('업로드 실패: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('닫기'),
            ),
          ],
        ),
      );
    }
  }

  String sRatio = '0';

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

    final picked = await showBoardPickerBottomSheet(context, list);
    if (picked == null) return;

    // 3) selectedBoardId 설정
    setState(() {
      _selectedBoard = picked;
      _selectedConsumer = picked.consumerName;
      _selectedEmail = picked.email;
      hvLogEntry.selectedBoardId = picked.id.toString();
      // ✅ 이름들 즉시 초기화(신규 대비)
      _inspectorController.clear();
      _managerMainController.clear();
      _managerSubController.clear();
      hvLogEntry.inspectorName = '';
      hvLogEntry.managerMainName = '';
      hvLogEntry.managerSubName = '';

      final board = _selectedBoard;
      incomingCapacity = board?.incomingCapacity ?? '-';
      generationCapacity = board?.generationCapacity ?? '-';
      incomingPrimaryVoltage = board?.incomingPrimaryVoltage ?? '-';
      generationPrimaryVoltage = board?.generationPrimaryVoltage ?? '-';
      incomingSecondaryVoltage = board?.incomingSecondaryVoltage ?? '-';
      generationSecondaryVoltage = board?.generationSecondaryVoltage ?? '-';
      mainName = board?.supervisorName ?? '-';
      solarCapacity = board?.solarCapacity ?? '-';
      solarVoltage = board?.solarVoltage ?? '-';
      sRatio = board?.ratio ?? '0';

      final sum =
          _parseCapacity(incomingCapacity) +
          _parseCapacity(generationCapacity) +
          _parseCapacity(solarCapacity);
      sumText = sum == 0
          ? '0'
          : (sum % 1 == 0
                ? sum.toInt().toString()
                : sum.toStringAsFixed(1)); // 소수 있으면 한 자리까지
    });

    // 4) DB에서 로드 시도
    final loaded = await HvLogDb.instance.load(picked.id.toString());
    if (loaded != null) {
      // 4-A) 이미 있던 데이터면 덮어쓰기
      setState(() {
        hvLogEntry = loaded;
        _inspectorController.text = loaded.inspectorName ?? '';
        _managerMainController.text = loaded.managerMainName ?? '';
        _managerSubController.text = loaded.managerSubName ?? '';
      });
    } else {
      // 4-B) 신규 엔트리면 즉시 저장
      final fresh = _freshEntryFor(picked.id.toString()); // ✅ toString으로 통일
      await HvLogDb.instance.save(fresh);
      setState(() {
        hvLogEntry = fresh; // ✅ 한 번에 교체
        _selectedBoard = picked;
        _selectedConsumer = picked.consumerName;
        _inspectorController.clear();
        _managerMainController.clear();
        _managerSubController.clear();
      });
    }

    hvLogEntry.powerRatio = double.tryParse(sRatio) ?? 0;

    if (mounted) {
      await _onTapWeather();
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
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 40, // 기본 56dp → 40dp로 줄이기
        title: const Text(
          '저압 점검일지 등록',
          style: TextStyle(fontSize: 16), // 높이에 맞게 글자 크기도 조정
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: const Icon(Icons.send),
              tooltip: '전송하기',
              onPressed: _confirmAndSend,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              padding: EdgeInsets.zero, // 높이가 줄었으니 패딩 최소화
              splashRadius: 20,
              iconSize: 20, // 아이콘 크기도 살짝 줄여서 균형 맞추기
            ),
          ),
        ],
      ),
      body: RepaintBoundary(
        key: _exportKey,
        child: Container(
          padding: const EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: 66,
          ),
          color: Colors.white, // 캡처시 배경색 유지 (투명 방지)
          child: Column(
            children: [
              // ──────────────────────────
              // 1) 첫 6행 (인덱스 0~5): 병합 셀 레이아웃
              // ──────────────────────────
              Expanded(
                flex: 5,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final cellW = constraints.maxWidth / columns;
                    final cellH = constraints.maxHeight / 6;

                    return Stack(
                      children: [
                        // 1-2) C3~R4 (인덱스 row 2~3, col 2~17) 병합
                        Positioned(
                          left: 2 * cellW,
                          top: 2.5 * cellH,
                          width: 16 * cellW,
                          height: 2 * cellH,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 25.0,
                              vertical: 2.0,
                            ),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(color: Colors.white),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '전기설비 점검결과 통지서',
                                style: TextStyle(
                                  fontSize: 22, //
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // 1-3) T2~T4 (인덱스 row 1~3, col 19) 병합
                        Positioned(
                          left: 21 * cellW,
                          top: 2.5 * cellH,
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
                              border: Border.fromBorderSide(
                                BorderSide(color: Colors.black, width: 1),
                              ),
                            ),

                            child: Text(
                              '결\n재',
                              style: TextStyle(
                                fontSize: 10, // 크게 잡아두면…
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ),
                        ),

                        // 3) U2~W2 (row1, col20~22) – 담당
                        Positioned(
                          left: 22 * cellW,
                          top: 2.5 * cellH,
                          width: 3 * cellW,
                          height: cellH,
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border(
                                top: BorderSide(color: Colors.black, width: 1),
                                right: BorderSide(
                                  color: Colors.black,
                                  width: 1,
                                ),
                                // bottom 없음 → 아래 박스 top이 대신 그림
                              ),
                            ),

                            child: Text(
                              '담당',
                              style: TextStyle(
                                fontSize: 9, // 크게 잡아두면…
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ),
                        ),

                        // 4) U3~W4 (row2~3, col20~22) – 빈칸 덮기
                        Positioned(
                          left: 22 * cellW,
                          top: 3.5 * cellH,
                          width: 3 * cellW,
                          height: 2 * cellH,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border(
                                top: BorderSide(
                                  color: Colors.black,
                                  width: 1,
                                ), // ↑ 이 선이 담당 밑줄 역할
                                right: BorderSide(
                                  color: Colors.black,
                                  width: 1,
                                ),
                                bottom: BorderSide(
                                  color: Colors.black,
                                  width: 1,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // 5) X2~Z2 (row1, col23~25) – 팀장
                        Positioned(
                          left: 25 * cellW,
                          top: 2.5 * cellH,
                          width: 3 * cellW,
                          height: cellH,
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border(
                                top: BorderSide(color: Colors.black, width: 1),
                                right: BorderSide(
                                  color: Colors.black,
                                  width: 1,
                                ),
                                // left/bottom 없음 (bottom은 아래 큰 박스 top이 담당)
                              ),
                            ),

                            child: Text(
                              '팀장',
                              style: TextStyle(
                                fontSize: 9, // 크게 잡아두면…
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ),
                        ),

                        Positioned(
                          left: 25 * cellW,
                          top: 3.5 * cellH,
                          width: 3 * cellW,
                          height: 2 * cellH,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border(
                                top: BorderSide(color: Colors.black, width: 1),
                                right: BorderSide(
                                  color: Colors.black,
                                  width: 1,
                                ),
                                bottom: BorderSide(
                                  color: Colors.black,
                                  width: 1,
                                ),
                                // left 없음  ← 여기서가 포인트! (겹침 방지)
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
                flex: 1,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final cellW = constraints.maxWidth / columns;
                    final cellH = constraints.maxHeight;
                    final border = Border.all(color: borderColor, width: 0.5);
                    final baseFont = cellH * 0.55;

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
                              alignment: Alignment.centerLeft,

                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: border,
                              ),

                              child: Text(
                                '고객명',
                                style: TextStyle(
                                  fontSize: 9, // 크게 잡아두면…
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
                          width: 12 * cellW,
                          height: cellH,
                          child: GestureDetector(
                            onTap: _onTapSelectConsumer, // ← 동일 제스처 추가
                            child: Container(
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: border,
                              ),

                              child: Text(
                                _selectedConsumer.isEmpty
                                    ? '수용가 선택'
                                    : _selectedConsumer,
                                maxLines: 2,
                                style: TextStyle(
                                  fontSize: 9, // 크게 잡아두면…
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // M~N : 귀중 병합
                        Positioned(
                          left: 15 * cellW,
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
                              style: TextStyle(
                                fontSize: 9, // 크게 잡아두면…
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ),
                        ),

                        // P~T : 요일, 월, 년 병합
                        Positioned(
                          left: 17 * cellW,
                          top: 0,
                          width: 6 * cellW,
                          height: cellH,
                          child: GestureDetector(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: now,
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                                locale: const Locale("ko", "KR"), // 한국어 달력
                              );

                              if (picked != null) {
                                setState(() {
                                  now = picked;
                                  formattedDate =
                                      '${picked.year}년${picked.month}월${picked.day}일';
                                });
                              }
                            },
                            child: Container(
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: border,
                              ),
                              child: Text(
                                formattedDate,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // U~V : 일기 텍스트 병합
                        Positioned(
                          left: 23 * cellW,
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

                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '일기',
                                style: TextStyle(
                                  fontSize: 9, // 크게 잡아두면…
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // X~AB : 실제 날씨 병합
                        Positioned(
                          left: 25 * cellW,
                          top: 0,
                          width: 3 * cellW,
                          height: cellH,
                          child: GestureDetector(
                            onTap: _onTapWeather,
                            child: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: border,
                              ),

                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  _selectedWeather.isEmpty
                                      ? '선택'
                                      : _selectedWeather,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 9, // 크게 잡아두면…
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
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
                    final baseFont = rowH * 0.5;

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
                            width: 3 * cellW,
                            height: 2 * rowH,
                            child: Container(
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: border,
                              ),

                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  '계약\n용량',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 9, // 크게 잡아두면…
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // 9행 C~E: 수전 (top row)
                          Positioned(
                            left: 3 * cellW,
                            top: 0,
                            width: 1.5 * cellW,
                            height: rowH,
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: border,
                              ),

                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  '수전',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 9, // 크게 잡아두면…
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // 10행 C~E: 발전 (bottom row)
                          Positioned(
                            left: 3 * cellW,
                            top: rowH,
                            width: 1.5 * cellW,
                            height: rowH,
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: border,
                              ),

                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  '발전',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 9, // 크게 잡아두면…
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // 9행 F~G: incoming_capacity
                          Positioned(
                            left: 4.5 * cellW,
                            top: 0,
                            width: 2.5 * cellW,
                            height: rowH,
                            child: Container(
                              alignment: Alignment.centerRight, // 오른쪽 맞춤
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: border,
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  formatCapacity(incomingCapacity), // 포맷 적용
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    fontSize: 9, // 크게 잡아두면…
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // 10행 F~G: generation_capacity
                          Positioned(
                            left: 4.5 * cellW,
                            top: rowH,
                            width: 2.5 * cellW,
                            height: rowH,
                            child: Container(
                              alignment: Alignment.centerRight, // 오른쪽 맞춤
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: border,
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  formatCapacity(generationCapacity), // 포맷 적용
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    fontSize: 9, // 크게 잡아두면…
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
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

                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'KW',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 8, // 크게 잡아두면…
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
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

                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'KW',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 8, // 크게 잡아두면…
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // 9행 I~J: incoming_primary_voltage
                          Positioned(
                            left: 8 * cellW,
                            top: 0,
                            width: 5 * cellW,
                            height: rowH,
                            child: Container(
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: border,
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  formatCapacity(incomingPrimaryVoltage) +
                                      ' / ' +
                                      formatCapacity(incomingSecondaryVoltage),
                                  style: TextStyle(
                                    fontSize: 9, // 크게 잡아두면…
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // 10행 I~J: generation_primary_voltage
                          Positioned(
                            left: 8 * cellW,
                            top: rowH,
                            width: 5 * cellW,
                            height: rowH,
                            child: Container(
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: border,
                              ),

                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  formatCapacity(generationPrimaryVoltage) +
                                      ' / ' +
                                      formatCapacity(
                                        generationSecondaryVoltage,
                                      ),

                                  style: TextStyle(
                                    fontSize: 9, // 크게 잡아두면…
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // 9행 K: /
                          Positioned(
                            left: 13 * cellW,
                            top: 0,
                            width: 1 * cellW,
                            height: rowH,
                            child: Container(
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: border,
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text('V', style: TextStyle(fontSize: 8)),
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: border,
                              ),

                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text('V', style: TextStyle(fontSize: 8)),
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

                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  '태양광\n설비',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
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
                              alignment: Alignment.centerRight, // ← 오른쪽 맞춤
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: border,
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  formatCapacity(
                                    solarCapacity,
                                  ), // ← 포맷 적용 (천단위/소수/0→'_')
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
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
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: border,
                              ),

                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  formatCapacity(
                                    solarVoltage,
                                  ), // ← 포맷 적용 (천단위/소수/0→'_')
                                  textAlign: TextAlign.right,

                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
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

                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'KW',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 8, // 크게 잡아두면…
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
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

                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'V',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 8, // 크게 잡아두면…
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
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
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 9, // 크게 잡아두면…
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),

                          Positioned(
                            left: 22 * cellW,
                            top: 0,
                            width: 4 * cellW,
                            height: 2 * rowH,
                            child: Container(
                              alignment: Alignment.centerRight, // ← 오른쪽 맞춤
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: border,
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  formatCapacity(
                                    sumText,
                                  ), // ← 포맷 적용 (천단위 / 소수점 둘째자리 / 0→'_')
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    fontSize: 9, // 크게 잡아두면…
                                    fontWeight: FontWeight.normal,
                                  ),
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

                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'KW',
                                  style: TextStyle(
                                    fontSize: 9, // 크게 잡아두면…
                                    fontWeight: FontWeight.normal,
                                  ),
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

              // 11행 빈칸 (한 행)
              const SizedBox(height: 8),

              Expanded(
                flex: 4, // 5행 분량
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: border,
                              ),
                              child: Center(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    '안\n전\n교\n육',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 9, // 크게 잡아두면…
                                      fontWeight: FontWeight.bold,
                                    ),
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: border,
                                ),

                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    safetyTexts[i],

                                    style: TextStyle(
                                      fontSize: 7, // 크게 잡아두면…
                                      fontWeight: FontWeight.normal,
                                    ),
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
              const SizedBox(height: 8),

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
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '점검내역(판정 : O, △ , X , 양, 부) 해당없음 /',

                                style: TextStyle(
                                  fontSize: 9, // 크게 잡아두면…
                                  fontWeight: FontWeight.bold,
                                ),
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
                            final rowH = constraints.maxHeight;

                            // 선 두께/색
                            final thin = BorderSide(
                              color: Colors.grey.shade300,
                              width: 0.5,
                            );
                            final thick = BorderSide(
                              color: Colors.grey.shade300,
                              width: 1,
                            );

                            // 헤더 셀 헬퍼: 오른쪽 보더만 그림
                            Widget headerCell(
                              String text, {
                              bool thickRight = false,
                            }) {
                              return Container(
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border(
                                    right: thickRight ? thick : thin,
                                  ),
                                ),
                                child: Text(
                                  text,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            }

                            return Row(
                              children: [
                                // ─ 1st group: 저 압 설 비 / 판정 / 비고 (4:2:3)
                                Expanded(
                                  flex: 9,
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 4,
                                        child: headerCell('저 압 설 비'),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: headerCell('판정'),
                                      ),
                                      // ✅ 그룹 마지막 '비고'만 두껍게
                                      Expanded(
                                        flex: 3,
                                        child: headerCell(
                                          '비고',
                                          thickRight: false,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // ─ 2nd group: 특고(고압)설비 / 판정 / 비고 (4:2:3)
                                Expanded(
                                  flex: 9,
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 4,
                                        child: headerCell('특고(고압)설비'),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: headerCell('판정'),
                                      ),
                                      Expanded(
                                        flex: 3,
                                        child: headerCell(
                                          '비고',
                                          thickRight: false,
                                        ),
                                      ), // ✅
                                    ],
                                  ),
                                ),

                                // ─ 3rd group: 태양광설비 / 판정 / 비고 (5:2:3)  ← 현재 코드 기준
                                Expanded(
                                  flex: 10,
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 5,
                                        child: headerCell('태양광설비'),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: headerCell('판정'),
                                      ),
                                      Expanded(
                                        flex: 3,
                                        child: headerCell(
                                          '비고',
                                          thickRight: false,
                                        ),
                                      ), // ✅
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
                        child: TransmissionVoltageQuadWidgetLow(
                          tag: 2,
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
                                final v =
                                    currentGeneration ??
                                    cumulativeGeneration; // 값이 없으면 null
                                _onAnyLineChanged(
                                  index,
                                  left: left,
                                  middle: middle,
                                  right: hvLogEntry.solarItems[index],
                                  value: v, // <- null 허용으로 전달
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
                                  hvLogEntry.guidelineLowCurrent9 -
                                  hvLogEntry.guidelineLowPre5;
                              final generated = diff * value;
                              setState(() {
                                // 여기에 결과를 저장할 필드가 있다면 대입
                                hvLogEntry.preMonthGenerationKwh = generated;
                              });
                            }

                            saveDB();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),

              Expanded(
                flex: 1,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final totalW = constraints.maxWidth;
                    final rowH = constraints.maxHeight;
                    final cellW = totalW / 28;

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
                            padding: const EdgeInsets.symmetric(horizontal: 0),
                            alignment: Alignment.centerLeft,
                            decoration: BoxDecoration(),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '점검결과 및 보안, 안전사항',

                                style: TextStyle(
                                  fontSize: 9, // 크게 잡아두면…
                                  fontWeight: FontWeight.bold,
                                ),
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
                flex: 3,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black, width: 1),
                    color: Colors.white,
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final rowH = constraints.maxHeight;
                      final baseFont = rowH * 0.55 / 3;

                      // 4줄 분해/병합 헬퍼
                      List<String> _getLines() {
                        final raw = hvLogEntry.inspectionResultNumeric;
                        final lines = (raw.isEmpty
                            ? <String>[]
                            : raw.split('\n'));
                        // 항상 4줄 보장
                        while (lines.length < 4) lines.add('');
                        if (lines.length > 4) return lines.sublist(0, 4);
                        return lines;
                      }

                      void _setLine(int idx, String value) {
                        final lines = _getLines();
                        lines[idx] = value;
                        setState(() {
                          hvLogEntry.inspectionResultImage =
                              null; // 텍스트 입력 시 이미지 제거
                          hvLogEntry.inspectionResultNumeric = lines.join('\n');
                        });
                        saveDB();
                      }

                      // 템플릿 선택 공통 핸들러
                      Future<void> _pickTemplate({
                        required bool solar,
                        required int idx,
                      }) async {
                        // solar=true → 태양광 DB, false → 일반 DB
                        final selected = await Navigator.push<String>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TemplateListPageTyped(solar: solar),
                          ),
                        );
                        if (selected != null) {
                          _setLine(idx, selected);
                        }
                      }

                      // 한 줄 편집 다이얼로그 (펜/템플릿 선택)
                      Future<void> _editLine(int idx) async {
                        final method = await showDialog<String>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('입력 방식 선택'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, 'touch'),
                                child: const Text('펜으로 쓰기'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, 'template'),
                                child: const Text('입력견본 선택(일반)'),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(ctx, 'template1'),
                                child: const Text('입력견본 선택(태양광)'),
                              ),
                            ],
                          ),
                        );

                        if (method == null) return;

                        if (method == 'touch') {
                          final pngBytes = await showDialog<Uint8List>(
                            context: context,
                            barrierDismissible: false,
                            builder: (ctx) => Dialog(
                              child: SizedBox(
                                width: MediaQuery.of(context).size.width * 0.8,
                                height:
                                    MediaQuery.of(context).size.height * 0.3,
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
                          await _pickTemplate(solar: false, idx: idx);
                        } else if (method == 'template1') {
                          await _pickTemplate(solar: true, idx: idx);
                        }
                      }

                      final lines = _getLines();

                      return Stack(
                        children: [
                          // 배경: 이미지가 있으면 이미지, 아니면 4줄 텍스트
                          Positioned.fill(
                            child: hvLogEntry.inspectionResultImage != null
                                ? Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    child: ClipRect(
                                      child: FittedBox(
                                        fit: BoxFit.contain, // ✅ 비율 유지
                                        alignment:
                                            Alignment.topLeft, // 오버레이와 정렬 맞춤
                                        child: Image.memory(
                                          hvLogEntry.inspectionResultImage!,
                                          filterQuality: FilterQuality.high,
                                        ),
                                      ),
                                    ),
                                  )
                                : Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: List.generate(4, (i) {
                                        final text = lines[i].isEmpty
                                            ? ' ${i + 1}'
                                            : '${i + 1}. ${lines[i]}';
                                        return Expanded(
                                          child: Align(
                                            alignment: Alignment.topLeft,
                                            child: Text(
                                              text,
                                              style: TextStyle(fontSize: 8),
                                              maxLines: 4,
                                              overflow: TextOverflow.visible,
                                            ),
                                          ),
                                        );
                                      }),
                                    ),
                                  ),
                          ),
                          // 투명 오버레이: 4줄 각각 터치 영역
                          Positioned.fill(
                            child: Column(
                              children: List.generate(4, (i) {
                                return Expanded(
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () => _editLine(i),
                                    onLongPress: () async {
                                      // 길게 누르면 해당 라인 직접 키보드 입력도 제공 (선택사항)
                                      String input = lines[i];
                                      final result = await showDialog<String>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: Text('${i + 1}  입력'),
                                          content: TextField(
                                            autofocus: true,
                                            keyboardType:
                                                TextInputType.multiline,
                                            maxLines: 4,
                                            decoration: const InputDecoration(
                                              hintText: '내용을 입력하세요',
                                              border: OutlineInputBorder(),
                                            ),
                                            controller: TextEditingController(
                                              text: input,
                                            ),
                                            onChanged: (v) => input = v,
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(ctx),
                                              child: const Text('취소'),
                                            ),
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(ctx, input),
                                              child: const Text('확인'),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (result != null) _setLine(i, result);
                                    },
                                    child: Container(
                                      // 시각적 가이드(선택): 줄 구분선
                                      decoration: const BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(
                                            color: Colors.black12,
                                            width: 0.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),

              Expanded(
                flex: 1,
                child: GuidelineInputWidgetLow(
                  entry: hvLogEntry,
                  onChanged: (field, value) {
                    setState(() {
                      // 1) 들어온 field 이름에 따라 entry 필드 업데이트

                      hvLogEntry.guidelineLowSum =
                          hvLogEntry.guidelineLowCurrent9 -
                          hvLogEntry.guidelineLowPre5;
                      hvLogEntry.preMonthGenerationKwh =
                          hvLogEntry.guidelineLowSum * hvLogEntry.powerRatio;

                      // 3) (선택) pvVoltage 자동 계산
                      // final diff =
                      //     hvLogEntry.guidelineCurrentSum -
                      //     hvLogEntry.guidelinePrevSum;
                      // hvLogEntry.pvVoltage = diff * hvLogEntry.powerRatio;

                      saveDB();
                    });
                  },
                ),
              ),

              const SizedBox(height: 16),
              Expanded(
                flex: 3, // 필요에 맞게 1~3 사이로 조절

                child: ConfirmationView(
                  key: ValueKey('confirm-${hvLogEntry.selectedBoardId}'),
                  inspectorController: _inspectorController,
                  managerMainController: _managerMainController,
                  managerSubController: _managerSubController,
                  onSendEmail: _onSendEmail,
                  customerEmail: _selectedEmail,
                  mainName: mainName,

                  // ⬇️ 이미 저장된 서명을 내려보내 화면에 보여주기
                  initialManagerMainSignature: hvLogEntry.managerMainSignature,
                  initialManagerSubSignature: hvLogEntry.managerSubSignature,

                  // ⬇️ 이름 변경(기존대로)
                  onNameChanged: (field, value) {
                    setState(() {
                      switch (field) {
                        case '점검확인자':
                          hvLogEntry.inspectorName = value;
                          break;
                        case '안전관리자':
                          hvLogEntry.managerMainName = value;
                          break;
                      }
                      saveDB();
                    });
                  },

                  // ⬇️ 서명 변경을 메인에 반영
                  onSignatureChanged: (who, bytes) {
                    setState(() {
                      switch (who) {
                        case '점검확인자':
                          hvLogEntry.managerSubSignature = bytes;
                          break;
                        case '안전관리자':
                          hvLogEntry.managerMainSignature = bytes;
                          break;
                      }
                      saveDB();
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
