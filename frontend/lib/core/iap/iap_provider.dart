/// IAP 状态管理的 Riverpod Provider。
///
/// [iapServiceProvider] 持有全局 [IapService] 单例，
/// [iapStateProvider] 暴拉实时 IAP 状态流供 UI 绑定，
/// [isPremiumProvider] / [maxDifficultyProvider] 用于付费墙判断。

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../commerce/commerce_availability.dart';
import '../commerce/training_access_policy.dart';
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
  final availability = ref.watch(commerceAvailabilityProvider);
  if (!availability.shouldResolvePremiumStatus) return false;
  return ref.watch(iapStateProvider).valueOrNull?.isPremium ?? false;
});

/// Unified access policy for hearts, difficulty and answer-time consumption.
final trainingAccessProvider = Provider<TrainingAccessPolicy>((ref) {
  final availability = ref.watch(commerceAvailabilityProvider);
  return TrainingAccessPolicy(
    limitsEnabled: availability.trainingLimitsEnabled,
    isPremium: ref.watch(isPremiumProvider),
  );
});

/// Unlimited releases and Premium users have no difficulty ceiling.
final maxDifficultyProvider = Provider<double>((ref) {
  return ref.watch(trainingAccessProvider).maxDifficulty();
});
