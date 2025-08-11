// lib/data/models/login_response.dart
class LoginResponse {
  final String flag; // "1" or "0"
  final String message; // 서버가 보내주는 메시지
  final String memName;
  final String? memPhone;
  final String memLevel;

  LoginResponse({
    required this.flag,
    required this.message,
    required this.memName,
    this.memPhone,
    required this.memLevel,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    final f = json['flag'] as Map<String, dynamic>;
    return LoginResponse(
      flag: f['flag'] as String,
      message: f['message'] as String,
      memName: f['mem_name'] as String,
      memPhone: f['mem_phone'] as String?,
      memLevel: f['mem_level'] as String,
    );
  }

  bool get success => flag == '1';
}
