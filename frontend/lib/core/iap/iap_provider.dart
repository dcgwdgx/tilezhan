import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'iap_service.dart';

/// Singleton IAP service instance, initialised on first read.
final iapServiceProvider = Provider<IapService>((ref) {
  final service = IapService();
  service.init();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Current IAP connection / purchase status.
final iapStatusProvider = StreamProvider<IapStatus>((ref) {
  final service = ref.watch(iapServiceProvider);
  return service.statusStream;
});

/// Available products with ownership flags.
final iapProductsProvider = StreamProvider<List<TzProduct>>((ref) {
  final service = ref.watch(iapServiceProvider);
  return service.productsStream;
});
