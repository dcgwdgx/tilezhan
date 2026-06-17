/// 用户认证服务 — JWT Token 本地持久化 + 后端 API 调用。
///
/// 登录/注册成功后 token 和用户信息存入 Hive Box，
/// 每次启动自动恢复登录态。登出时清除本地数据。
import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../constants/api_endpoints.dart';

/// 用户认证服务 — 整个应用的认证中枢。
///
/// **架构角色**：位于 core/auth 层，封装所有认证相关逻辑，向上层（UI/Riverpod）
/// 提供统一的登录态查询与操作方法。
///
/// **数据流**：
/// - 登录/注册成功后：JWT Token + 用户信息 → 写入 Hive 本地持久化。
/// - 应用启动时：调用 [init] 打开 Hive Box，通过 [isLoggedIn]/[token]/[user]
///   即可立即恢复登录态，无需再次请求后端。
/// - 登出时：清除 Hive 中的 token 和用户数据。
///
/// **依赖**：
/// - [Hive]：本地轻量 KV 存储，用于离线持久化 token。
/// - DioClient（待接入）：实际网络请求由 DioClient 统一管理，当前为占位代码。
class AuthService {
  // Hive Box 名称，所有认证数据存储在此 Box 中。
  static const _boxName = 'auth';
  // Hive 中 token 的键名。
  static const _keyToken = 'token';
  // Hive 中用户信息（JSON 字符串）的键名。
  static const _keyUser = 'user_json';

  // Hive Box 实例，由 [init] 方法延迟初始化。
  late Box _box;

  /// 当前是否处于已登录状态。
  ///
  /// 判断依据：本地 Hive 中是否存在有效的 token。
  /// 注意：此方法仅检查 token 是否存在，不验证 token 是否过期；
  /// token 过期校验由后端中间件或 Dio 拦截器处理。
  bool get isLoggedIn => token != null;

  /// 当前存储的 JWT Token。
  ///
  /// 从 Hive Box 中读取，如果用户未登录或已登出则返回 `null`。
  /// 所有需要认证的 API 请求应在 Authorization 头中携带此 token。
  String? get token => _box.get(_keyToken);

  /// 当前登录用户的信息（解析后的 Map）。
  ///
  /// Hive 中以 JSON 字符串形式存储，每次读取时实时解析。
  /// 返回 `null` 表示用户未登录或用户数据不存在。
  ///
  /// 典型返回结构：
  /// ```dart
  /// {
  ///   'id': 1,
  ///   'email': 'user@example.com',
  ///   'name': '用户名',
  ///   'avatar': 'https://...',   // 可选
  /// }
  /// ```
  Map<String, dynamic>? get user {
    final raw = _box.get(_keyUser);
    if (raw == null || raw.isEmpty) return null;
    // Hive 存储的是 JSON 字符串，读取时实时反序列化为 Map。
    return jsonDecode(raw);
  }

  /// 初始化认证服务 — 打开 Hive Box。
  ///
  /// **必须在应用启动时、任何其他方法调用之前执行。**
  /// 通常在 `main()` 函数中 `Hive.initFlutter()` 之后调用。
  ///
  /// 调用后即可通过 [isLoggedIn]、[token]、[user] 读取本地持久化的登录态。
  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
  }

  /// 用户登录。
  ///
  /// 向后端 `POST /auth/login` 发送邮箱 + 密码，验证成功后：
  /// 1. 将返回的 JWT Token 写入 Hive（键名 [_keyToken]）。
  /// 2. 将返回的用户信息 JSON 序列化后写入 Hive（键名 [_keyUser]）。
  ///
  /// 参数：
  /// - [email]：用户注册邮箱。
  /// - [password]：用户密码（明文传输，依赖 HTTPS 加密）。
  ///
  /// 返回值：登录成功返回 `true`，失败返回 `false`。
  ///
  /// TODO: 接入 DioClient 后取消注释实际网络请求代码。
  Future<bool> login(String email, String password) async {
    // 占位：DioClient 接入前的临时实现，始终返回 false。
    // 接入后流程：
    // 1. DioClient.instance.post(ApiEndpoints.login, data: {...})
    // 2. 将 res.data['token'] 写入 _box.put(_keyToken, ...)
    // 3. 将 res.data['user'] JSON 序列化后写入 _box.put(_keyUser, ...)
    // final res = await DioClient.instance.post(ApiEndpoints.login,
    //     data: {'email': email, 'password': password});
    // _box.put(_keyToken, res.data['token']);
    // _box.put(_keyUser, jsonEncode(res.data['user']));
    return false;
  }

  /// 用户注册。
  ///
  /// 向后端 `POST /auth/register` 发送邮箱 + 密码 + 昵称，注册成功后：
  /// 1. 将返回的 JWT Token 写入 Hive（键名 [_keyToken]）。
  /// 2. 将返回的用户信息 JSON 序列化后写入 Hive（键名 [_keyUser]）。
  ///
  /// 参数：
  /// - [email]：用户注册邮箱，需唯一。
  /// - [password]：用户密码（明文传输，依赖 HTTPS 加密）。
  /// - [name]：用户显示名称/昵称。
  ///
  /// 返回值：注册成功返回 `true`，失败（如邮箱已被占用）返回 `false`。
  Future<bool> register(String email, String password, String name) async {
    // 占位：DioClient 接入前的临时实现，始终返回 false。
    // 接入后流程与 [login] 一致：调用 API → 写入 token + user。
    // final res = await DioClient.instance.post(ApiEndpoints.register,
    //     data: {'email': email, 'password': password, 'name': name});
    // _box.put(_keyToken, res.data['token']);
    // _box.put(_keyUser, jsonEncode(res.data['user']));
    return false;
  }

  /// 用户登出。
  ///
  /// 从本地 Hive 中删除 token 和用户数据。
  /// 登出后 [isLoggedIn] 返回 `false`，[token] 和 [user] 均返回 `null`。
  ///
  /// 注意：此方法仅清除本地状态，不调用后端登出接口。
  /// 如需通知后端（如使 token 失效），应在调用此方法前额外请求 `POST /auth/logout`。
  void logout() {
    _box.delete(_keyToken);
    _box.delete(_keyUser);
  }

  /// 释放认证服务占用的资源。
  ///
  /// 关闭 Hive Box，通常在应用退出或 Widget 销毁时调用。
  /// 调用后如需再次使用认证功能，需要重新调用 [init]。
  Future<void> dispose() => _box.close();
}
