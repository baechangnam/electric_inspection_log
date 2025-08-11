import 'package:electric_inspection_log/widgets/excel_grid.dart';
import 'package:flutter/material.dart';

class HvLogEntryScreen extends StatefulWidget {
  const HvLogEntryScreen({Key? key}) : super(key: key);
  @override
  State<HvLogEntryScreen> createState() => _HvLogEntryScreenState();
}

class _HvLogEntryScreenState extends State<HvLogEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  // TODO: Define controllers and state variables for each field

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('고압 점검일지 등록')),
      body: const SafeArea(
        child: Padding(
          padding: EdgeInsets.all(8),
          child: ExcelGrid(), // 여기에 엑셀 그리드를 넣으면 끝!
        ),
      ),
    );
  }
}
