import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilezhan/core/commerce/commerce_availability.dart';

void main() {
  group('CommerceAvailability', () {
    test(
        'free release defaults are sales off, limits off and mobile restore on',
        () {
      final ios = CommerceAvailability.forPlatform(
        platform: TargetPlatform.iOS,
      );
      final android = CommerceAvailability.forPlatform(
        platform: TargetPlatform.android,
      );

      expect(ios.salesEnabled, isFalse);
      expect(android.salesEnabled, isFalse);
      expect(ios.trainingLimitsEnabled, isFalse);
      expect(android.trainingLimitsEnabled, isFalse);
      expect(ios.restoreEnabled, isTrue);
      expect(android.restoreEnabled, isTrue);
    });

    test('iOS and Android sales flags are independent', () {
      final ios = CommerceAvailability.forPlatform(
        platform: TargetPlatform.iOS,
        iosSalesEnabled: true,
        androidSalesEnabled: false,
      );
      final android = CommerceAvailability.forPlatform(
        platform: TargetPlatform.android,
        iosSalesEnabled: true,
        androidSalesEnabled: false,
      );

      expect(ios.salesEnabled, isTrue);
      expect(android.salesEnabled, isFalse);
    });

    test('restore is valid only on iOS and Android', () {
      for (final platform in const [
        TargetPlatform.macOS,
        TargetPlatform.windows,
        TargetPlatform.linux,
        TargetPlatform.fuchsia,
      ]) {
        final policy = CommerceAvailability.forPlatform(
          platform: platform,
          iosSalesEnabled: true,
          androidSalesEnabled: true,
          restoreEnabled: true,
        );

        expect(policy.salesEnabled, isFalse, reason: '$platform sales');
        expect(policy.restoreEnabled, isFalse, reason: '$platform restore');
      }
    });

    test('restore can be disabled independently from sales', () {
      final policy = CommerceAvailability.forPlatform(
        platform: TargetPlatform.iOS,
        iosSalesEnabled: true,
        restoreEnabled: false,
      );

      expect(policy.salesEnabled, isTrue);
      expect(policy.restoreEnabled, isFalse);
    });

    test('restore-only free mode does not require eager Premium resolution',
        () {
      final policy = CommerceAvailability.forPlatform(
        platform: TargetPlatform.android,
        androidSalesEnabled: false,
        trainingLimitsEnabled: false,
        restoreEnabled: true,
      );

      expect(policy.restoreEnabled, isTrue);
      expect(policy.shouldResolvePremiumStatus, isFalse);
    });
  });

  test('provider platform source is explicitly overridable', () {
    final container = ProviderContainer(
      overrides: [
        commerceTargetPlatformProvider.overrideWithValue(
          TargetPlatform.windows,
        ),
      ],
    );
    addTearDown(container.dispose);

    final policy = container.read(commerceAvailabilityProvider);
    expect(policy.platform, TargetPlatform.windows);
    expect(policy.salesEnabled, isFalse);
    expect(policy.restoreEnabled, isFalse);
  });
}
