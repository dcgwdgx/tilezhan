import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Immutable release policy for store access and training limits.
///
/// Sales are platform-specific because App Store and Google Play can become
/// available independently. Training limits are deliberately independent from
/// sales so a release can be made fully free without deleting the heart system.
/// Restore remains available on mobile even when new sales are disabled, which
/// preserves a path for users who bought an earlier release.
@immutable
class CommerceAvailability {
  const CommerceAvailability({
    required this.platform,
    required this.salesEnabled,
    required this.trainingLimitsEnabled,
    required this.restoreEnabled,
  });

  /// Resolve the policy for [platform]. Optional flag parameters make this
  /// constructor deterministic in pure tests while production uses
  /// `--dart-define` values.
  factory CommerceAvailability.forPlatform({
    required TargetPlatform platform,
    bool iosSalesEnabled = const bool.fromEnvironment(
      'TZ_IAP_SALES_IOS',
      defaultValue: false,
    ),
    bool androidSalesEnabled = const bool.fromEnvironment(
      'TZ_IAP_SALES_ANDROID',
      defaultValue: false,
    ),
    bool trainingLimitsEnabled = const bool.fromEnvironment(
      'TZ_TRAINING_LIMITS_ENABLED',
      defaultValue: false,
    ),
    bool restoreEnabled = const bool.fromEnvironment(
      'TZ_IAP_RESTORE_ENABLED',
      defaultValue: true,
    ),
  }) {
    final isIos = platform == TargetPlatform.iOS;
    final isAndroid = platform == TargetPlatform.android;
    final supportsMobileStore = isIos || isAndroid;

    return CommerceAvailability(
      platform: platform,
      salesEnabled:
          isIos ? iosSalesEnabled : (isAndroid ? androidSalesEnabled : false),
      trainingLimitsEnabled: trainingLimitsEnabled,
      restoreEnabled: supportsMobileStore && restoreEnabled,
    );
  }

  final TargetPlatform platform;

  /// Whether this platform may show and initiate new purchases.
  final bool salesEnabled;

  /// Whether free users are subject to hearts and difficulty limits.
  final bool trainingLimitsEnabled;

  /// Whether an explicit restore action may connect to the mobile store.
  final bool restoreEnabled;

  /// Reading Premium status only needs to connect to a store when it affects
  /// either a live sales surface or an enabled training gate.
  ///
  /// Restore-only mode stays lazy: the explicit restore action can initialize
  /// IAP, while ordinary app surfaces do not contact the store.
  bool get shouldResolvePremiumStatus => salesEnabled || trainingLimitsEnabled;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CommerceAvailability &&
          platform == other.platform &&
          salesEnabled == other.salesEnabled &&
          trainingLimitsEnabled == other.trainingLimitsEnabled &&
          restoreEnabled == other.restoreEnabled;

  @override
  int get hashCode => Object.hash(
        platform,
        salesEnabled,
        trainingLimitsEnabled,
        restoreEnabled,
      );
}

/// Overridable platform source for deterministic provider tests.
final commerceTargetPlatformProvider = Provider<TargetPlatform>((ref) {
  return defaultTargetPlatform;
});

/// Single source of truth for the current release's commerce availability.
final commerceAvailabilityProvider = Provider<CommerceAvailability>((ref) {
  return CommerceAvailability.forPlatform(
    platform: ref.watch(commerceTargetPlatformProvider),
  );
});
