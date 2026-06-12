import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'revenuecat_service.dart';

final offeringsProvider = FutureProvider<Offerings?>((ref) async {
  await RevenueCatService.init();
  return RevenueCatService.getOfferings();
});

final isProProvider = FutureProvider<bool>((ref) async {
  return RevenueCatService.isPro();
});
