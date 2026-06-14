import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'heart_service.dart';
import '../iap/iap_provider.dart';

/// Singleton HeartService.
final heartServiceProvider = Provider<HeartService>((ref) {
  final svc = HeartService();
  svc.init();
  ref.onDispose(svc.dispose);
  return svc;
});

/// Hearts remaining (polls every minute for daily reset check).
final heartsRemainingProvider = StreamProvider<int>((ref) {
  final svc = ref.watch(heartServiceProvider);
  // Re-check daily reset every 60s
  return Stream.periodic(const Duration(seconds: 60), (i) => svc.hearts)
    .asBroadcastStream();
});

/// Can the user play? (premium → always, free → has hearts)
final canPlayProvider = Provider<bool>((ref) {
  final isPremium = ref.watch(isPremiumProvider);
  if (isPremium) return true;
  return ref.watch(heartServiceProvider).hasHearts;
});

/// Session battle report data (resets daily).
class BattleReport {
  final int correct;
  final int wrong;
  final int maxCombo;
  final int heartsRemaining;

  const BattleReport({
    required this.correct,
    required this.wrong,
    required this.maxCombo,
    required this.heartsRemaining,
  });

  int get total => correct + wrong;
  double get accuracy => total == 0 ? 0 : correct / total;
}

final battleReportProvider = Provider<BattleReport>((ref) {
  final svc = ref.watch(heartServiceProvider);
  return BattleReport(
    correct: svc.correct,
    wrong: svc.wrong,
    maxCombo: svc.maxCombo,
    heartsRemaining: svc.hearts,
  );
});
