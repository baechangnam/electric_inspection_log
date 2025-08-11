// lib/data/repository/user_repository.dart
import 'package:electric_inspection_log/data/service/user_service.dart';

import '../models/login_response.dart';
abstract class UserRepository {
  Future<LoginResponse> login(String id, String pw);
}
class UserRepositoryImpl implements UserRepository {
  final UserService _service;
  UserRepositoryImpl(this._service);
  @override
  Future<LoginResponse> login(String id, String pw) =>
    _service.login(id, pw);
}
