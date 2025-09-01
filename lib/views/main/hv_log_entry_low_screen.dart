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
    // ✅ excel_grid가 자체적으로 Scaffold + AppBar를 가진 ‘완전한 화면’이라면,
    // 바깥에서 또 Scaffold를 만들지 말고 그대로 반환하세요.
    return const ExcelGridLow();
  }
}
