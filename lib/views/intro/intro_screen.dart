// lib/screens/intro_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/login_screen.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({Key? key}) : super(key: key);

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  @override
  void initState() {
    super.initState();
    // 2초 후에 로그인 화면으로 이동
     Timer(const Duration(seconds: 2), _checkLoginAndNavigate);
  }

  Future<void> _checkLoginAndNavigate() async {
    final prefs = await SharedPreferences.getInstance();
    final loggedIn = prefs.getBool('loggedIn') ?? false;

    if (loggedIn) {
      // 이미 로그인된 상태면 홈으로
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      // 로그인 필요하면 로그인 화면으로
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.indigo,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                '전기설비 점검',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              Text(
                '다빈 전기 기술단',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
