/// 用户认证服务 — JWT Token 本地持久化 + 后端 API 调用。
///
/// 登录/注册成功后 token 和用户信息存入 Hive Box，
/// 每次启动自动恢复登录态。登出时清除本地数据。
import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../constants/api_endpoints.dart';

/// 用户认证服务 — Hive 持久化 JWT Token + Dio 调用后端 API。
class AuthService {
  static const _boxName = 'auth';
  static const _keyToken = 'token';
  static const _keyUser = 'user_json';

  late Box _box;

  /// 是否已登录。
  bool get isLoggedIn => token != null;
  /// 当前 JWT Token。
  String? get token => _box.get(_keyToken);
  /// 用户信息 JSON。
  Map<String, dynamic>? get user {
    final raw = _box.get(_keyUser);
    if (raw == null || raw.isEmpty) return null;
    return jsonDecode(raw);
  }

  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
  }

  /// 登录 — 调用后端 /auth/login，存储 token。
  /// TODO: 接入 DioClient 后取消注释
  Future<bool> login(String email, String password) async {
    // final res = await DioClient.instance.post(ApiEndpoints.login,
    //     data: {'email': email, 'password': password});
    // _box.put(_keyToken, res.data['token']);
    // _box.put(_keyUser, jsonEncode(res.data['user']));
    return false;
  }

  /// 注册 — 调用后端 /auth/register。
  Future<bool> register(String email, String password, String name) async {
    // final res = await DioClient.instance.post(ApiEndpoints.register,
    //     data: {'email': email, 'password': password, 'name': name});
    // _box.put(_keyToken, res.data['token']);
    // _box.put(_keyUser, jsonEncode(res.data['user']));
    return false;
  }

  /// 登出 — 清除本地 token。
  void logout() {
    _box.delete(_keyToken);
    _box.delete(_keyUser);
  }

  Future<void> dispose() => _box.close();
}
