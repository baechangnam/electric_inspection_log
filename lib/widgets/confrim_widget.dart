import 'dart:typed_data';
import 'package:electric_inspection_log/widgets/drawing_popup.dart';
import 'package:flutter/material.dart';

/// 3행짜리 확인/입력/액션 뷰
class ConfirmationView extends StatefulWidget {
  final TextEditingController inspectorController;
  final TextEditingController managerMainController;
  final TextEditingController managerSubController;
  final Uint8List? initialManagerMainSignature;
  final Uint8List? initialManagerSubSignature;
  final void Function(String label, Uint8List? bytes)? onSignatureChanged;

  final void Function(String fieldName, String value)? onNameChanged;
  final String? customerEmail; // ⬅️ 추가
  final String? mainName;

  /// 메일 발송 콜백
  final VoidCallback onSendEmail;

  const ConfirmationView({
    Key? key,
    required this.inspectorController,
    required this.managerMainController,
    required this.managerSubController,
    required this.onSendEmail,
    this.onNameChanged,
    this.initialManagerMainSignature,
    this.initialManagerSubSignature,
    this.onSignatureChanged,
    this.customerEmail,
    this.mainName, // ✅ 추가
  }) : super(key: key);

  @override
  _ConfirmationViewState createState() => _ConfirmationViewState();
}

class _ConfirmationViewState extends State<ConfirmationView> {
  Uint8List? _inspectorSignature;
  Uint8List? _managerMainSignature;
  Uint8List? _managerSubSignature;

  @override
  void initState() {
    super.initState();
    _managerMainSignature = widget.initialManagerMainSignature;
    _managerSubSignature = widget.initialManagerSubSignature;
    _prefillManagerMain(); // ✅ 초기값 반영
  }

  @override
  void didUpdateWidget(covariant ConfirmationView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.initialManagerMainSignature !=
        widget.initialManagerMainSignature) {
      _managerMainSignature = widget.initialManagerMainSignature;
    }
    if (oldWidget.initialManagerSubSignature !=
        widget.initialManagerSubSignature) {
      _managerSubSignature = widget.initialManagerSubSignature;
    }

    // ✅ mainName이 바뀌었거나, (중요) 현재 컨트롤러가 비어있으면 다시 프리필
    if (oldWidget.mainName != widget.mainName ||
        widget.managerMainController.text.isEmpty) {
      _prefillManagerMain();
    }
  }

  void _prefillManagerMain() {
    final m = widget.mainName;
    if (m != null &&
        m.isNotEmpty &&
        widget.managerMainController.text.isEmpty) {
      widget.managerMainController.text = m;
      // 초기 표시만 하고 저장/서명 정책 건드리지 않음.
      // 만약 DB 동기화도 원하면 아래 주석 해제:
      // widget.onNameChanged?.call('안전관리자', m);
      setState(() {}); // 화면 갱신
    }
  }

  Future<void> _showInspectorDialog() async {
    final nameCtrl = TextEditingController(
      text: widget.inspectorController.text,
    );

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('점검 확인자'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. 이름 입력
              TextField(
                controller: nameCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: '점검 확인자 이름',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // 2. 메일발송 & 서명 버튼
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      child: const Text('메일발송'),
                      onPressed: () {
                        final email = widget.customerEmail;
                        if (email == null || email.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('등록된 메일주소가 없습니다. 서명을 하세요!'),
                            ),
                          );
                          return;
                        }

                        widget.inspectorController.text = nameCtrl.text;
                        widget.onNameChanged?.call('점검 확인자', nameCtrl.text);

                        // 2) ✅ 서명 제거 → 액션 셀에 ‘메일발송’(빨강) 복귀
                        setState(() {
                          _inspectorSignature = null;
                        });
                        widget.onSignatureChanged?.call('점검 확인자', null); //
                        // setState(
                        //   () => _inspectorSignature = null,
                        // ); // 이름 바꾸면 서명 초기화
                        Navigator.of(ctx).pop();
                        //widget.onSendEmail(); // 콜백 호출
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      child: const Text('서명'),
                      onPressed: () async {
                        final pngBytes = await showDialog<Uint8List>(
                          context: context,
                          barrierDismissible: false,
                          builder: (_) => Dialog(
                            child: SizedBox(
                              width: MediaQuery.of(context).size.width * 0.8,
                              height: MediaQuery.of(context).size.height * 0.6,
                              child: DrawingDialogContent(),
                            ),
                          ),
                        );
                        if (pngBytes != null) {
                          setState(() {
                            _inspectorSignature = pngBytes;
                          });
                          widget.onSignatureChanged?.call('점검 확인자', pngBytes);
                          Navigator.of(ctx).pop(); // 닫기
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                widget.inspectorController.text = nameCtrl.text;
                widget.onNameChanged?.call('점검 확인자', nameCtrl.text);
                // setState(() => _inspectorSignature = null); // 이름 바꾸면 서명 초기화
                Navigator.of(ctx).pop();
              },
              child: const Text('입력'),
            ),
          ],
        );
      },
    );
  }

  static const _cellBorder = BorderSide(color: Colors.black, width: 0.5);

  @override
  Widget build(BuildContext context) {
    return Container(
      // decoration: BoxDecoration(border: Border.fromBorderSide(_cellBorder)),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // 전체 높이를 3등분한 값에 0.55 비율을 곱해 baseFont 결정
          final rowH = constraints.maxHeight;
          final baseFont = 8.0;

          return Row(
            children: [
              // ── 로고 영역 ──
              Expanded(
                flex: 9,
                child: Container(
                  decoration: BoxDecoration(color: Colors.white),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Image.asset(
                    'assets/images/logos.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              // ── '확인' 레이블 및 3행 입력/서명 뷰 ──
              Expanded(
                flex: 10,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // '확인' 레이블
                    Expanded(
                      flex: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.fromBorderSide(_cellBorder),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '확\n인',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ),

                    // 3행 입력/서명 뷰
                    Expanded(
                      flex: 9,
                      child: Column(
                        children: [
                          _buildRow(
                            label: '점검 확인자',
                            controller: widget.inspectorController,
                            actionLabel: '메일발송',
                            signature: _inspectorSignature,
                            onSignatureAdded: (b) =>
                                setState(() => _inspectorSignature = b),
                            onMailTap: () => _showInspectorDialog(),
                            baseFont: baseFont,
                            //  onRowTap: _showInspectorDialog, // ✅ 이 행만 전체 터치 → 팝업
                          ),
                          _buildRow(
                            label: '안전관리자',
                            controller: widget.managerMainController,
                            actionLabel: '(인)',
                            signature: _managerMainSignature,
                            onSignatureAdded: (b) =>
                                setState(() => _managerMainSignature = b),
                            baseFont: baseFont,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRow({
    required String label,
    required TextEditingController controller,
    required String actionLabel,
    required Uint8List? signature,
    required ValueChanged<Uint8List?> onSignatureAdded,
    required double baseFont,
    VoidCallback? onRowTap, // ✅ 로우 전체 터치 콜백(점검확인자 전용 등)
    VoidCallback? onMailTap, // ✅ 메일발송 콜백
  }) {
    final placeholder = '';
    final displayText = controller.text.isEmpty ? placeholder : controller.text;

    Future<void> _showSignatureDialog() async {
      final pngBytes = await showDialog<Uint8List>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => Dialog(
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.height * 0.6,
            child: DrawingDialogContent(),
          ),
        ),
      );
      if (pngBytes != null) {
        onSignatureAdded(pngBytes); // 로컬 상태 갱신
        widget.onSignatureChanged?.call(label, pngBytes); // 상위에도 전파
        setState(() {}); // 리빌드
      }
    }

    // ─────────────────────────────────────────────────────────────
    // 행 내부 UI (라벨 / 입력 / 액션)
    // ─────────────────────────────────────────────────────────────
    final rowChild = Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 라벨 셀
        Expanded(
          flex: 2,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.fromBorderSide(_cellBorder),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(fontWeight: FontWeight.normal, fontSize: 8),
            ),
          ),
        ),

        // 입력 셀
        Expanded(
          flex: 2, // 요청대로 이름칸 축소
          child: GestureDetector(
            onTap: () async {
              String input = controller.text;
              if (onRowTap != null) {
                onRowTap();
                return;
              }

              final result = await showDialog<String>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(label),
                  content: TextField(
                    controller: TextEditingController(text: controller.text),
                    autofocus: true,
                    keyboardType: TextInputType.text,
                    decoration: const InputDecoration(
                      hintText: '',
                      border: InputBorder.none,
                    ),
                    onChanged: (v) => input = v,
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('취소'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, input),
                      child: const Text('확인'),
                    ),
                  ],
                ),
              );

              if (result != null) {
                // 이름 바꾸면 해당 행의 서명 초기화(정책 유지)
                // onSignatureAdded(null);
                // widget.onSignatureChanged?.call(label, null);

                controller.text = result;
                widget.onNameChanged?.call(label, result);
                setState(() {});
              }
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.fromBorderSide(_cellBorder),
              ),
              alignment: Alignment.center, // 가로 왼쪽, 세로 중앙
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                displayText,
                style: TextStyle(fontSize: baseFont),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ),
        ),

        // 액션 셀: 메일발송 or (인)
        Expanded(
          flex: 3, // 요청대로 서명/액션 칸 확장
          child: GestureDetector(
            onTap: () async {
              if (actionLabel == '메일발송') {
                // ✅ onRowTap이 있으면 동일 팝업으로 라우팅
                if (onRowTap != null) {
                  onRowTap();
                  return;
                }
                // ⬇️ 기존 메일 동작(관리자 행 등)
                onMailTap?.call();
                return;
              }
              if (actionLabel == '(인)') {
                await _showSignatureDialog();
              }
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.fromBorderSide(_cellBorder),
              ),
              // alignment 지우세요 (Center 효과가 루즈 제약을 줌)
              child: signature != null
                  ? ClipRect(
                      child: SizedBox.expand(
                        // 🔹 부모 영역을 꽉 채우는 타이트 제약
                        child: Image.memory(
                          signature,
                          fit: BoxFit.cover, // 🔹 전체 채움(일부 크롭 가능)
                          filterQuality: FilterQuality.high,
                        ),
                      ),
                    )
                  : Center(
                      // 텍스트는 센터에
                      child: Text(
                        actionLabel,
                        style: TextStyle(
                          color: actionLabel == '메일발송'
                              ? Colors.red
                              : Colors.black,
                          fontSize: baseFont,
                          fontWeight: actionLabel == '메일발송'
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ],
    );

    // ─────────────────────────────────────────────────────────────
    // 로우 전체 터치(점검확인자 등) 지원: onRowTap이 있으면 InkWell로 감싸기
    // ─────────────────────────────────────────────────────────────
    return Expanded(
      child: onRowTap != null
          ? InkWell(onTap: onRowTap, child: rowChild)
          : rowChild,
    );
  }
}
