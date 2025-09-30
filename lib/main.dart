import 'package:electric_inspection_log/core/db/db_helper.dart';
import 'package:electric_inspection_log/views/intro/intro_screen.dart';
import 'package:electric_inspection_log/views/main/home_screen.dart';
import 'package:electric_inspection_log/views/main/hv_log_entry_low_screen.dart';
import 'package:electric_inspection_log/views/main/hv_log_entry_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:electric_inspection_log/views/auth/login_screen.dart';

import 'data/service/user_service.dart';
import 'data/repository/user_repository.dart';
import 'viewmodels/auth/login_viewmodel.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_localizations/flutter_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final svc = UserService();
  final repo = UserRepositoryImpl(svc);

  await TemplateDatabase().init();

  runApp(
    ChangeNotifierProvider(
      create: (_) => LoginViewModel(repo),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '전기점검일지',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ko', 'KR'), // ← 한국어 Locale 지정
      supportedLocales: const [Locale('en', 'US'), Locale('ko', 'KR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      initialRoute: '/intro',
      routes: {
        '/intro': (_) => const IntroScreen(),
        '/login': (_) => const LoginScreen(),
        '/home': (_) => const HomeScreen(), // 여기를 HomeScreen 으로
        '/hv-log': (_) => const HvLogEntryScreen(), // ← 추가
        '/hv-log_low': (_) => const HvLogEntryLowScreen(), // ← 추가
      },
    );
  }
}
