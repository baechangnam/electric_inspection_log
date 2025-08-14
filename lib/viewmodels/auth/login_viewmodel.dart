// lib/viewmodels/auth/login_viewmodel.dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/login_response.dart';
import '../../data/repository/user_repository.dart';

class LoginViewModel extends ChangeNotifier {
  final UserRepository _repo;
  LoginViewModel(this._repo);

  bool isLoading = false;
  String? errorMessage;
  LoginResponse? loginResult;

  Future<void> login(String id, String pw) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final resp = await _repo.login(id, pw);
      loginResult = resp;

      if (resp.success) {
        // 로그인 성공 플래그 저장
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('loggedIn', true);
        await prefs.setString('memName', resp.memName);
        await prefs.setString('mem_id', id);
      } else {
        errorMessage = resp.message;
      }
    } on DioError catch (e) {
      // 네트워크/타임아웃/BadResponse 등 DioError만 잡아서 메시지 처리
      errorMessage = '네트워크 오류: ${e.message}';
    } catch (e, st) {
      // 파싱 에러나 그 외 예외가 있다면 로그를 남기고 UI에는 일반 오류로
      debugPrint('login() Exception: $e\n$st');
      errorMessage = '알 수 없는 오류가 발생했습니다.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('loggedIn');
    await prefs.remove('memName');
    await prefs.remove('mem_id');
    loginResult = null;
    notifyListeners();
  }
}
