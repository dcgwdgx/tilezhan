import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'revenuecat_service.dart';

final offeringsProvider = FutureProvider<List<ProductDetails>>((ref) async {
  return RevenueCatService.getOfferings();
});

final isProProvider = FutureProvider<bool>((ref) async {
  return RevenueCatService.isPro();
});
