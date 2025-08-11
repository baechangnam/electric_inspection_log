import 'dart:typed_data';
import 'package:electric_inspection_log/widgets/drawing_popup.dart';
import 'package:flutter/material.dart';

/// 3행짜리 확인/입력/액션 뷰
class ConfirmationView extends StatefulWidget {
  final TextEditingController inspectorController;
  final TextEditingController managerMainController;
  final TextEditingController managerSubController;

  final void Function(String fieldName, String value)? onNameChanged;

  /// 메일 발송 콜백
  final VoidCallback onSendEmail;

  const ConfirmationView({
    Key? key,
    required this.inspectorController,
    required this.managerMainController,
    required this.managerSubController,
    required this.onSendEmail, this.onNameChanged,
  }) : super(key: key);

  @override
  _ConfirmationViewState createState() => _ConfirmationViewState();
}

class _ConfirmationViewState extends State<ConfirmationView> {
  Uint8List? _inspectorSignature;
  Uint8List? _managerMainSignature;
  Uint8List? _managerSubSignature;

  static const _cellBorder = BorderSide(color: Colors.black, width: 0.5);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(border: Border.fromBorderSide(_cellBorder)),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // 전체 높이를 3등분한 값에 0.55 비율을 곱해 baseFont 결정
          final rowH = constraints.maxHeight;
          final baseFont = (rowH / 6) * 0.55;

          return Row(
            children: [
              // ── 로고 영역 ──
              Expanded(
                flex: 1,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.fromBorderSide(_cellBorder),
                  ),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Image.asset('assets/images/logos.png', fit: BoxFit.contain),
                ),
              ),

              // ── '확인' 레이블 및 3행 입력/서명 뷰 ──
              Expanded(
                flex: 1,
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
                            fontSize: baseFont,
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
                            onSignatureAdded: (b) => setState(() => _inspectorSignature = b),
                            onMailTap: widget.onSendEmail,
                            baseFont: baseFont,
                          ),
                          _buildRow(
                            label: '안전관리자(정)',
                            controller: widget.managerMainController,
                            actionLabel: '(인)',
                            signature: _managerMainSignature,
                            onSignatureAdded: (b) => setState(() => _managerMainSignature = b),
                            baseFont: baseFont,
                          ),
                          _buildRow(
                            label: '안전관리자(부)',
                            controller: widget.managerSubController,
                            actionLabel: '(인)',
                            signature: _managerSubSignature,
                            onSignatureAdded: (b) => setState(() => _managerSubSignature = b),
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
    VoidCallback? onMailTap,
    required double baseFont,
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
      if (pngBytes != null) onSignatureAdded(pngBytes);
    }

    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 라벨 셀
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.fromBorderSide(_cellBorder),
              ),
              alignment: Alignment.center,
              child: Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: baseFont)),
            ),
          ),

          // 입력 셀 (텍스트만)
          Expanded(
            flex: 3,
            child: GestureDetector(
              onTap: () async {
                final result = await showDialog<String>(
                  context: context,
                  builder: (ctx) {
                    String input = controller.text;
                    return AlertDialog(
                      title: Text(label),
                      content: TextField(
                        controller: TextEditingController(text: controller.text),
                        autofocus: true,
                        keyboardType: TextInputType.text,
                        decoration: InputDecoration(hintText: placeholder, border: InputBorder.none),
                        onChanged: (v) => input = v,
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: Text('취소')),
                        TextButton(onPressed: () => Navigator.pop(ctx, input), child: Text('확인')),
                      ],
                    );
                  },
                );
                if (result != null) {
                  setState(() {
                   
                    
                    onSignatureAdded(null);
                  });

                   controller.text = result;
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.fromBorderSide(_cellBorder),
                ),
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(displayText, style: TextStyle(fontSize: baseFont)),
              ),
            ),
          ),

          // 액션 셀: 메일발송 or (인)
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: () {
                if (actionLabel == '메일발송') {
                  onMailTap?.call();
                } else if (actionLabel == '(인)') {
                  _showSignatureDialog();
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.fromBorderSide(_cellBorder),
                ),
                alignment: Alignment.center,
                child: actionLabel == '(인)'
                    ? (signature != null
                        ? SizedBox.expand(child: Image.memory(signature, fit: BoxFit.fill))
                        : Text('(인)', style: TextStyle(color: Colors.black, fontSize: baseFont)))
                    : Text('메일발송', style: TextStyle(color: Colors.red, fontSize: baseFont, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
