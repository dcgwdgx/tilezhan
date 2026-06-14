/// IAP 状态管理的 Riverpod Provider。
///
/// [iapServiceProvider] 持有全局 [IapService] 单例，
/// [iapStateProvider] 暴拉实时 IAP 状态流供 UI 绑定，
/// [isPremiumProvider] / [maxDifficultyProvider] 用于付费墙判断。

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'iap_service.dart';

/// Singleton IAP service, initialised on first read and kept alive.
final iapServiceProvider = Provider<IapService>((ref) {
  final svc = IapService();
  svc.init();
  ref.onDispose(svc.dispose);
  return svc;
});

/// Reactive IAP state stream.
final iapStateProvider = StreamProvider<IapState>((ref) {
  return ref.watch(iapServiceProvider).stateStream;
});

/// 用户是否是付费会员。
final isPremiumProvider = Provider<bool>((ref) {
  return ref.watch(iapStateProvider).valueOrNull?.isPremium ?? false;
});

/// 付费用户无难度上限，免费用户限制基础难度 (800 ELO 以下)。
final maxDifficultyProvider = Provider<double>((ref) {
  final isPremium = ref.watch(isPremiumProvider);
  return isPremium ? double.infinity : 800.0;
});
