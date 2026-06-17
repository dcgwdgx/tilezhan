/// 用户认证服务 — JWT Token 本地持久化 + 后端 API 调用。
///
/// **模块定位**：core/auth 层的核心服务，是所有认证相关功能（登录/注册/登出/登录态查询）
/// 的唯一入口。所有 UI 层和 Riverpod Provider 均通过本服务获取认证状态，禁止直接操作
/// Hive Box 或拼接 API URL。
///
/// **数据持久化策略**：
/// - 登录/注册成功后 token 和用户信息存入 Hive Box（本地轻量 KV 存储）。
/// - 每次应用启动时调用 [init] 打开 Box，上层即可通过 [isLoggedIn]/[token]/[user]
///   立即恢复登录态，无需再次请求后端。
/// - 登出时清除 Hive 中的 token 和用户数据，回到未登录状态。
///
/// **安全注意事项**：
/// - Token 以明文存储在本地 Hive 中，Hive 文件位于应用沙盒内，依赖操作系统文件保护。
/// - Token 过期校验由后端中间件或 Dio 拦截器处理，本服务不做主动校验。
/// - 密码在登录/注册时明文传入方法参数，实际传输依赖 HTTPS 加密。
///
/// **当前状态**：API 调用部分为占位代码，待 DioClient 接入后启用。
import 'dart:convert'; // 用于 user JSON 字符串 ↔ Map 的序列化/反序列化（jsonEncode / jsonDecode）。
import 'package:hive_flutter/hive_flutter.dart'; // 本地轻量 KV 存储，用于离线持久化 token 和用户信息。
import '../constants/api_endpoints.dart'; // 后端 API 路径常量（如 /auth/login、/auth/register），当前为占位引用。

/// 用户认证服务 — 整个应用的认证中枢。
///
/// **架构角色**：位于 core/auth 层，封装所有认证相关逻辑（登录、注册、登出、
/// Token 持久化、用户信息缓存），向上层（UI Widget / Riverpod Provider）
/// 提供统一的登录态查询与操作方法。
///
/// **设计原则**：
/// - **单一入口**：所有认证状态读写必须通过本服务，禁止 UI 层直接操作 Hive。
/// - **延迟初始化**：Hive Box 通过 [init] 延迟打开，确保在 `Hive.initFlutter()`
///   之后才访问存储。
/// - **即时可用**：[isLoggedIn]、[token]、[user] 均为同步 getter，
///   在 [init] 调用后即可立即获取本地持久化的登录态，无需等待网络请求。
///
/// **数据流**：
/// ```text
/// 登录成功（后端返回 token + user）
///   ├─→ _box.put(keyToken, token)       // JWT Token 持久化
///   └─→ _box.put(keyUser, jsonEncode)   // 用户信息 JSON → 持久化
///
/// 应用启动
///   └─→ init() → Hive.openBox('auth')   // 打开已有 Box，数据立即可读
///
/// 登出
///   ├─→ _box.delete(keyToken)           // 清除 Token
///   └─→ _box.delete(keyUser)            // 清除用户信息
/// ```
///
/// **依赖**：
/// - [hive_flutter]：本地轻量 KV 存储，用于离线持久化 token 和用户数据。
/// - DioClient（待接入）：实际 HTTP 请求由 DioClient 统一管理，当前为占位代码。
/// - [api_endpoints.dart]：后端 API 路径常量定义。
class AuthService {
  // Hive Box 名称字符串。
  // 所有认证相关的 KV 数据（token、user_json）均存储在此 Box 中，
  // 与项目中其他 Box（如设置缓存）隔离，避免键名冲突。
  static const _boxName = 'auth';
  // Hive 中 JWT Token 的键名。
  // 存储值为 String 类型，即后端返回的原始 token 字符串（如 "eyJhbGciOi..."）。
  static const _keyToken = 'token';
  // Hive 中用户信息的键名。
  // 存储值为 JSON 字符串（通过 jsonEncode 序列化后的 Map），
  // 读取时通过 jsonDecode 反序列化为 Map<String, dynamic>。
  static const _keyUser = 'user_json';

  // Hive Box 实例，由 [init] 方法延迟初始化。
  // 使用 `late` 关键字声明，表示在 [init] 完成前不访问此字段，
  // 若未调用 [init] 直接访问任何 getter 将抛出 LateInitializationError。
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
  /// 通常在 `main()` 函数中 `Hive.initFlutter()` 之后、`runApp()` 之前调用。
  ///
  /// **调用时机约束**：
  /// - 必须在 `Hive.initFlutter()` 之后调用，否则 `Hive.openBox()` 会抛出异常。
  /// - 必须在任何 [isLoggedIn]、[token]、[user] 访问之前调用，否则触发
  ///   `LateInitializationError`（因为 [_box] 尚未赋值）。
  ///
  /// **幂等性**：如果 Box 已打开（如应用热重启场景），`Hive.openBox()` 会返回
  /// 已存在的 Box 实例，不会重复创建。
  ///
  /// 调用后即可通过 [isLoggedIn]、[token]、[user] 同步读取本地持久化的登录态。
  Future<void> init() async {
    // 打开名为 'auth' 的 Hive Box。如果 Box 不存在则自动创建空 Box；
    // 如果 Box 已存在（即之前登录过），则加载已有数据，token 和 user 立即可读。
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
  /// **注意**：此方法仅清除本地持久化状态，不调用后端登出接口。
  /// 如需通知后端（如使服务端 token 失效、清理服务端会话），
  /// 应在调用此方法前额外请求 `POST /auth/logout`。
  ///
  /// **设计决策**：本地优先清除是出于用户体验考虑——即使后端登出请求失败，
  /// 用户也应能立刻看到登出后的 UI 状态，避免用户困惑。
  void logout() {
    // 删除 Hive 中的 token 键：token getter 将返回 null，isLoggedIn 变为 false。
    _box.delete(_keyToken);
    // 删除 Hive 中的 user_json 键：user getter 将返回 null。
    _box.delete(_keyUser);
    // 注意：Hive 的 delete() 是同步操作（Box 已在内存中），无需 await。
  }

  /// 释放认证服务占用的资源。
  ///
  /// 关闭 Hive Box，释放其持有的文件句柄和内存缓存。
  /// 通常在应用退出（`WidgetsBindingObserver.didDetach`）或测试 tearDown 中调用。
  ///
  /// **注意**：调用后 Box 被关闭，[_box] 变为不可用状态。
  /// 如需再次使用认证功能（如应用从后台恢复），必须重新调用 [init] 打开 Box。
  ///
  /// **设计决策**：AuthService 通常以单例形式存在，[dispose] 在实际生产环境中
  /// 很少调用——Hive Box 可在整个应用生命周期内保持打开状态。
  Future<void> dispose() async {
    // 关闭 Hive Box，刷新所有未写入的变更到磁盘并释放内存中的缓存数据。
    await _box.close();
  }
}
