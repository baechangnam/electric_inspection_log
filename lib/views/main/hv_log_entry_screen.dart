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
    // ✅ excel_grid가 자체적으로 Scaffold + AppBar를 가진 ‘완전한 화면’이라면,
    // 바깥에서 또 Scaffold를 만들지 말고 그대로 반환하세요.
    return const ExcelGrid();
  }
}
