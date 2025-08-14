import 'package:electric_inspection_log/widgets/excel_grid.dart';
import 'package:electric_inspection_log/widgets/excel_grid_low.dart';
import 'package:flutter/material.dart';

class HvLogEntryLowScreen extends StatefulWidget {
  const HvLogEntryLowScreen({Key? key}) : super(key: key);
  @override
  State<HvLogEntryLowScreen> createState() => _HvLogEntryScreenStates();
}

class _HvLogEntryScreenStates extends State<HvLogEntryLowScreen> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('저압 점검일지 등록')),
      body: const SafeArea(
        child: Padding(
          padding: EdgeInsets.all(8),
          child: ExcelGridLow(), // 여기에 엑셀 그리드를 넣으면 끝!
        ),
      ),
    );
  }
}
