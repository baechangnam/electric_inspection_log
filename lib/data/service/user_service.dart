// lib/data/service/user_service.dart
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:electric_inspection_log/data/models/board_item.dart';
import 'package:http/http.dart' as http;
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../models/login_response.dart';

class UserService {
  final Dio _dio = ApiClient().dio;

 Future<LoginResponse> login(String id, String pw) async {
    final resp = await _dio.get(
      ApiEndpoints.login,
      queryParameters: {'mem_id': id, 'mem_pw': pw},
    );

    if (resp.statusCode == 200) {
      // resp.data 가 String 일 수도 있으니 안전하게 파싱
      final dynamic data = resp.data;
      final Map<String, dynamic> json = data is String
        ? jsonDecode(data) as Map<String, dynamic>
        : data as Map<String, dynamic>;

      return LoginResponse.fromJson(json);
    } else {
      throw Exception('로그인 서버 오류: ${resp.statusCode}');
    }
  }
}
 const _endpoint = 'https://davin230406.mycafe24.com/api/list_board.php';

/// 전체 거래처 목록을 가져옵니다.
   Future<List<BoardItem>> fetchBoardList() async {
    final res = await http.get(Uri.parse(_endpoint));
    if (res.statusCode != 200) {
      throw Exception('거래처 목록 로드 실패: ${res.statusCode}');
    }
    final body = json.decode(res.body) as Map<String, dynamic>;
    final rawList = (body['board_list'] as List).cast<Map<String, dynamic>>();
    return rawList.map((e) => BoardItem.fromJson(e)).toList();
  }
