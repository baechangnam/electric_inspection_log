// lib/views/home/home_screen.dart
import 'dart:convert';

import 'package:electric_inspection_log/data/models/board_item.dart';
import 'package:electric_inspection_log/viewmodels/auth/login_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _name = '사용자';

  @override
  void initState() {
    super.initState();
    _loadName();
  }

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
                                '수용가 선택',
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
                                hintText: '수용가명 검색',
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

  static const String memoUpdateEndpoint =
      'https://davin230406.mycafe24.com/api/memo_update.php';

  /// 메모 저장 (또는 갱신)
  static Future<void> updateMemo({
    required int idx,
    required String memo,
  }) async {
    // Uri로 안전하게 쿼리 파라미터 인코딩
    final uri = Uri.parse(memoUpdateEndpoint).replace(
      queryParameters: {
        'idx': idx.toString(),
        'memo': memo, // Uri가 내부적으로 퍼센트 인코딩 처리
      },
    );

    final res = await http
        .get(uri, headers: {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 10));

    if (res.statusCode != 200) {
      throw Exception('메모 저장 실패 (HTTP ${res.statusCode})');
    }

    // 서버가 JSON을 주는 경우/안 주는 경우 모두 허용
    // { "success": true } 같은 응답이면 체크
    try {
      final decoded = json.decode(res.body);
      if (decoded is Map && decoded.containsKey('success')) {
        final ok = decoded['success'] == true || decoded['success'] == 'true';
        if (!ok) throw Exception('메모 저장 실패: ${res.body}');
      }
    } catch (_) {
      // JSON이 아니면(예: "OK") 여기서 무시하고 성공으로 간주
    }
  }

  /// 메모 삭제(비우기) — 동일 엔드포인트에 memo='' 로 전송
  static Future<void> clearMemo({required int idx}) async {
    await updateMemo(idx: idx, memo: '');
  }

  String _endpoint = 'https://davin230406.mycafe24.com/api/list_board.php';

  /// 전체 수용가 목록을 가져옵니다.
  Future<List<BoardItem>> fetchBoardList() async {
    final res = await http.get(Uri.parse(_endpoint));
    if (res.statusCode != 200) {
      throw Exception('수용가 목록 로드 실패: ${res.statusCode}');
    }
    final body = json.decode(res.body) as Map<String, dynamic>;
    final rawList = (body['board_list'] as List).cast<Map<String, dynamic>>();
    return rawList.map((e) => BoardItem.fromJson(e)).toList();
  }

  Future<void> _loadName() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('memName');
    if (stored != null && stored.isNotEmpty) {
      setState(() => _name = stored);
    }
  }

  Future<void> _onLogoutPressed() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('로그아웃 하시겠어요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('확인'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    await context.read<LoginViewModel>().logout();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final bg = Colors.indigo.shade700;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        title: const Text(
          '전기점검일지',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 40,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 상단 타이틀
                      Text(
                        '$_name님, 반갑습니다!',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 40),
                      // 👇 수용가 정보보기 버튼 (중앙 정렬, 넓은 가로)
                      Center(
                        child: SizedBox(
                          width:
                              MediaQuery.of(context).size.width *
                              0.8, // 화면의 80% 너비
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(
                                vertical: 14,
                              ), // 세로 padding만 지정
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () async {
                              List<BoardItem> list;
                              try {
                                list = await fetchBoardList();
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('수용가 불러오기 실패: $e')),
                                );
                                return;
                              }

                              final picked = await showBoardPickerBottomSheet(
                                context,
                                list,
                              );
                              if (picked == null) return;

                              // 3) 선택 결과 처리 (옵션)
                              if (picked != null && mounted) {
                                final updated = await showConsumerDetailDialog(
                                  context: context,
                                  item: picked,
                                  onSaveMemo: (u) async {
                                    await updateMemo(
                                      idx: u.id,
                                      memo: u.memo ?? "",
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('메모가 저장되었습니다.'),
                                      ),
                                    );
                                  },
                                  onClearMemo: (u) async {
                                    // TODO: DB에서 메모 제거
                                    await clearMemo(idx: u.id);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('메모가 삭제되었습니다.'),
                                      ),
                                    );
                                  },
                                );
                              }
                            },
                            child: const Text(
                              '수용가 정보보기',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),

                      const Text(
                        '전기설비 점검결과통지서 선택',
                        style: TextStyle(color: Colors.white, fontSize: 17),
                      ),
                      const SizedBox(height: 8),

                      // 고압 버튼 (빨간 배경 + 화이트 보더)
                      _ChoiceButton(
                        bgColor: Colors.red.shade600,
                        title: '고압 점검일지',
                        bulletLines: const ['일  반: 100 KW이상', '태양광: 500 KW이상'],
                        onTap: () => Navigator.of(context).pushNamed('/hv-log'),
                      ),

                      const SizedBox(height: 22),

                      // 저압 버튼 (파란 배경 + 화이트 보더)
                      _ChoiceButton(
                        bgColor: Colors.blue.shade700,
                        title: '저압 점검일지',
                        bulletLines: const ['일  반: 100 KW이하', '태양광: 500 KW이하'],
                        onTap: () =>
                            Navigator.of(context).pushNamed('/hv-log_low'),
                      ),

                      const Spacer(),

                      // 하단 로그아웃 버튼
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: Colors.white,
                            width: 1.5,
                          ),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: _onLogoutPressed,
                        icon: const Icon(Icons.logout),
                        label: const Text(
                          '로그아웃',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

Future<BoardItem?> showConsumerDetailDialog({
  required BuildContext context,
  required BoardItem item,
  Future<void> Function(BoardItem updated)? onSaveMemo, // 저장 훅(옵션)
  Future<void> Function(BoardItem cleared)? onClearMemo, // 비우기 훅(옵션)
}) {
  final memoCtrl = TextEditingController(text: item.memo);

  return showDialog<BoardItem>(
    context: context,
    barrierDismissible: false,
    builder: (dialogCtx) {
      return AlertDialog(
        insetPadding: const EdgeInsets.all(16),
        title: const Text('수용가 상세 정보'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ▼ 읽기 전용 정보들
              _InfoRow(label: '수용가명', value: item.consumerName),
              _InfoRow(label: '설비위치', value: item.facilityLocation),
              _InfoRow(label: '대표자', value: item.representativeName),
              _InfoRow(label: '전화번호', value: item.phoneNumber),
              _InfoRow(label: '발전용량', value: item.generationCapacity),
              _InfoRow(label: '태양광용량', value: item.solarCapacity),
              _InfoRow(label: 'E-mail', value: item.email),
              const SizedBox(height: 12),

              // ▼ 메모 편집
              const Text('메모', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              TextField(
                controller: memoCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '메모 입력',
                ),
              ),

              const SizedBox(height: 8),

              // ✅ 메모 저장/삭제 버튼 (가로 배치)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      label: const Text(
                        '메모 삭제',
                        style: TextStyle(color: Colors.red),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                      ),
                      onPressed: () async {
                        final ok = await showDialog<bool>(
                          context: dialogCtx,
                          builder: (confirmCtx) => AlertDialog(
                            title: const Text('삭제 확인'),
                            content: const Text('메모를 비우시겠습니까?'),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(confirmCtx, false),
                                child: const Text('취소'),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(confirmCtx, true),
                                child: const Text('삭제'),
                              ),
                            ],
                          ),
                        );
                        if (ok != true) return;

                        final cleared = item.copyWith(memo: '');
                        if (onClearMemo != null) await onClearMemo(cleared);
                        if (dialogCtx.mounted)
                          Navigator.pop(dialogCtx, cleared);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text('메모 저장'),
                      onPressed: () async {
                        final updated = item.copyWith(
                          memo: memoCtrl.text.trim(),
                        );
                        if (onSaveMemo != null) await onSaveMemo(updated);
                        if (dialogCtx.mounted)
                          Navigator.pop(dialogCtx, updated);
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ✅ 하단 닫기 버튼 (조금 띄우고, 맨 아래 전체 너비)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(dialogCtx, null),
                  child: const Text('닫기'),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// 간단한 정보 행 위젯
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value, Key? key})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(child: Text(value.isNotEmpty ? value : '-', maxLines: 3)),
        ],
      ),
    );
  }
}

String? _req(String? v) => (v == null || v.trim().isEmpty) ? '필수 입력입니다.' : null;

class _LabeledField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final int maxLines;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  const _LabeledField({
    super.key,
    required this.label,
    required this.controller,
    this.validator,
    this.maxLines = 1,
    this.keyboardType,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  final Color bgColor;
  final String title;
  final List<String> bulletLines;
  final VoidCallback onTap;

  const _ChoiceButton({
    Key? key,
    required this.bgColor,
    required this.title,
    required this.bulletLines,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(12);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: borderRadius,
            border: Border.all(color: Colors.white, width: 2), // 화이트 보더
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.description, color: Colors.white, size: 30),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 제목
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // 라인들
                    for (final line in bulletLines)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          '• $line',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: Colors.white, size: 28),
            ],
          ),
        ),
      ),
    );
  }
}
