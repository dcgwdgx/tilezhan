import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'revenuecat_service.dart';

/// Available subscription packages
final offeringsProvider = FutureProvider<List<Package>>((ref) async {
  await RevenueCatService.init();
  return RevenueCatService.getOfferings();
});

/// Whether user has Pro entitlement
final isProProvider = FutureProvider<bool>((ref) async {
  return RevenueCatService.isPro();
});

/// Purchase a package
final purchaseProvider = FutureProvider.family<CustomerInfo, Package>((ref, pkg) async {
  return RevenueCatService.purchase(pkg);
});
