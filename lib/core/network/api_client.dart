import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../constants/api_endpoints.dart';

class ApiClient {
  static final _instance = ApiClient._();
  final Dio dio;

  factory ApiClient() => _instance;
  ApiClient._()
    : dio = Dio(
        BaseOptions(
          baseUrl: ApiEndpoints.baseUrl,
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 3),
        ),
      ) {
    dio.interceptors.add(
      LogInterceptor(
        request: true,            // 요청 라인 (METHOD & URL)
        requestHeader: true,      // 요청 헤더
        requestBody: true,        // 요청 바디
        responseHeader: false,    // 응답 헤더
        responseBody: true,       // 응답 바디
        error: true,              // 에러 시 로깅
        logPrint: (obj) => debugPrint(obj.toString()),
      ),
    );
  }
}
