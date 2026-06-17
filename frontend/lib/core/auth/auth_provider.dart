/// 用户认证 Riverpod 状态管理层。
///
/// ## 模块定位
///
/// 本文件是整个认证模块的 **响应式状态入口**，基于 Riverpod 框架将 [AuthService]
/// 提供的原始登录态转化为可被 UI 层监听的响应式数据。它是连接「数据层」（AuthService
/// + Hive）与「UI 层」（Flutter Widget）的桥梁。
///
/// ## 架构关系
///
/// ```
/// UI (Widget)                     ← watch isLoggedInProvider
///     ↕
/// 本文件 (Riverpod Providers)      ← 依赖 AuthService，暴露响应式状态
///     ↕
/// AuthService (auth_service.dart)  ← Hive 本地持久化 + 后端 API 调用
///     ↕
/// Hive Box / 后端 API
/// ```
///
/// ## 两个 Provider
///
/// 1. [authServiceProvider] — 全局唯一的 [AuthService] 实例，负责初始化与销毁。
///    所有依赖认证功能的 Provider 都应通过此 Provider 获取 AuthService，而非
///    自行 new AuthService()，以保证全局单例一致性。
///
/// 2. [isLoggedInProvider] — 响应式的登录状态布尔值。UI 层通过 `ref.watch`
///    监听此 Provider，即可在登录/登出时自动重建对应 Widget，无需手动 setState。
///
/// ## 生命周期
///
/// - **应用启动**：main() 中调用 `await ref.read(authServiceProvider).init()`
///   初始化 Hive Box，恢复上次登录态。
/// - **运行期**：UI 通过 `ref.watch(isLoggedInProvider)` 绑定登录态，
///   通过 `ref.read(authServiceProvider).login()/register()/logout()` 执行操作。
/// - **应用退出/Wigdet销毁**：Provider 销毁时自动调用 `svc.dispose()` 关闭 Hive Box。
///
/// ## 使用示例
///
/// ```dart
/// // UI 中绑定登录状态
/// final isLoggedIn = ref.watch(isLoggedInProvider);
///
/// // UI 中间接调用登录
/// ref.read(authServiceProvider).login(email, password);
///
/// // 登录后 UI 自动重建（因为 isLoggedInProvider 依赖 authServiceProvider，
/// // AuthService 内部状态变化时 Riverpod 自动通知依赖方）
/// ```
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_service.dart';

/// 全局唯一的 [AuthService] 实例 Provider。
///
/// ## 设计意图
///
/// Riverpod `Provider` 创建懒加载单例：首次被读取时才调用创建函数，
/// 同一 Provider 在所有位置返回同一个实例，天然规避了传统 Singeton 的测试与
/// 生命周期问题。
///
/// ## 初始化流程
///
/// 创建后立即调用 [AuthService.init] 打开 Hive Box：
/// 1. `main()` 中使用 `ProviderScope` 包裹整个 App。
/// 2. App 启动时执行 `ref.read(authServiceProvider)` 即触发本 Provider 创建。
/// 3. 后续所有 `ref.watch(authServiceProvider)` 返回同一实例。
///
/// ## 销毁流程
///
/// 当 [ProviderContainer] 被销毁（如 Widget 出栈或 Scope 结束）时，
/// 通过 `ref.onDispose` 回调自动调用 [AuthService.dispose] 关闭 Hive Box，
/// 防止资源泄漏。
///
/// ## 注意
///
/// - **不要直接 `new AuthService()`** — 应始终通过本 Provider 获取实例。
/// - 本 Provider 是 `Provider` 而非 `StateNotifierProvider`，因为 AuthService
///   内部维护了可变状态（isLoggedIn 是 getter 而非字段），Riverpod 无法自动感知。
///   依赖方通过 [isLoggedInProvider] 间接监听即可。
final authServiceProvider = Provider<AuthService>((ref) {
  // 创建 AuthService 单例实例。
  final svc = AuthService();
  // 立即初始化 Hive Box，使 token/user 数据可读。
  svc.init();
  // 注册销毁回调：Provider 生命周期结束时关闭 Hive Box，防止资源泄漏。
  ref.onDispose(svc.dispose);
  return svc;
});

/// 响应式登录状态 Provider。
///
/// ## 设计意图
///
/// UI 层不应直接调用 `ref.read(authServiceProvider).isLoggedIn` 来判断登录状态，
/// 因为 AuthService 内部的可变状态（通过 getter 读取 Hive）变化时 Riverpod 无法
/// 自动感知，导致 UI 不会重建。本 Provider 通过 `ref.watch` 依赖
/// [authServiceProvider]，配合外部状态变更通知机制，使 UI 能够响应式地感知
/// 登录/登出事件。
///
/// ## 工作原理
///
/// - **依赖链**：`isLoggedInProvider` → `ref.watch(authServiceProvider)`，
///   即 isLoggedInProvider 是 authServiceProvider 的下游依赖。
/// - **重建触发**：当 authServiceProvider 被标记为"需要刷新"时（如登录/登出后），
///   isLoggedInProvider 会自动重新计算，UI 中所有 `ref.watch(isLoggedInProvider)`
///   的 Widget 即时重建。
///
/// ## 刷新机制（重要）
///
/// 由于 AuthService 内部修改 Hive 不会触发 Riverpod 的自动通知，
/// **在执行 login/register/logout 后必须手动使 authServiceProvider 失效**
/// 以触发下游重建。推荐方式：
///
/// ```dart
/// // 在调用方（如 Controller 或 Widget）
/// ref.read(authServiceProvider).logout();
/// ref.invalidate(authServiceProvider); // 触发 isLoggedInProvider 重建
/// ```
///
/// 或使用 `ref.listen` 在业务方法返回后主动刷新。
///
/// ## 返回值
///
/// - `true`：当前 Hive 中存在有效的 JWT Token，用户已登录。
/// - `false`：Token 不存在或已被清除，用户未登录。
///
/// ## 使用示例
///
/// ```dart
/// // 在 build 方法中
/// final isLoggedIn = ref.watch(isLoggedInProvider);
/// if (isLoggedIn) {
///   return HomePage();
/// } else {
///   return LoginPage();
/// }
/// ```
final isLoggedInProvider = Provider<bool>((ref) {
  // 通过 ref.watch 建立对 authServiceProvider 的响应式依赖。
  // 当 authServiceProvider 失效并重建时，本 Provider 也会自动重新计算。
  return ref.watch(authServiceProvider).isLoggedIn;
});