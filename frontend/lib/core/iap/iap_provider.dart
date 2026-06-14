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

/// Convenience: is the user premium?
final isPremiumProvider = Provider<bool>((ref) {
  return ref.watch(iapStateProvider).valueOrNull?.isPremium ?? false;
});
