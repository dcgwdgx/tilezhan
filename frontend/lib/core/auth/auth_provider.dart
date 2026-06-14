/// 用户认证 Riverpod 状态管理。
///
/// [authServiceProvider] 全局 AuthService 单例，
/// [isLoggedInProvider] 响应式登录状态供 UI 绑定。
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_service.dart';

/// 全局 AuthService 单例。
final authServiceProvider = Provider<AuthService>((ref) {
  final svc = AuthService();
  svc.init();
  ref.onDispose(svc.dispose);
  return svc;
});

/// 当前登录状态。
final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(authServiceProvider).isLoggedIn;
});
