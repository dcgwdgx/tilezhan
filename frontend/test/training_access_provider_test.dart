import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilezhan/core/commerce/commerce_availability.dart';
import 'package:tilezhan/core/commerce/training_access_policy.dart';
import 'package:tilezhan/core/hearts/heart_provider.dart';
import 'package:tilezhan/core/hearts/heart_service.dart';
import 'package:tilezhan/core/iap/iap_provider.dart';
import 'package:tilezhan/core/iap/iap_service.dart';

class _ZeroHeartService extends HeartService {
  @override
  int get hearts => 0;

  @override
  bool get hasHearts => false;

  @override
  Future<void> init() async {}
}

class _FakeIapService implements IapService {
  final _controller = StreamController<IapState>.broadcast();

  @override
  IapState get state => const IapState(status: IapStatus.ready);

  @override
  Stream<IapState> get stateStream => _controller.stream;

  @override
  Future<void> init() async {}

  @override
  Future<void> purchase(String productId) async {}

  @override
  Future<void> restore() async {}

  @override
  void dispose() => _controller.close();
}

CommerceAvailability _availability({
  required bool limitsEnabled,
  bool salesEnabled = false,
}) {
  return CommerceAvailability.forPlatform(
    platform: TargetPlatform.android,
    androidSalesEnabled: salesEnabled,
    trainingLimitsEnabled: limitsEnabled,
    restoreEnabled: true,
  );
}

void main() {
  group('TrainingAccessPolicy', () {
    test('limits off is unlimited without Premium', () {
      const policy = TrainingAccessPolicy(
        limitsEnabled: false,
        isPremium: false,
      );

      expect(policy.hasUnlimitedTraining, isTrue);
      expect(policy.shouldConsumeHearts, isFalse);
      expect(policy.canPlay(hasHearts: false), isTrue);
      expect(policy.maxDifficulty(), double.infinity);
    });

    test('limits on uses hearts and free difficulty for non-Premium users', () {
      const policy = TrainingAccessPolicy(
        limitsEnabled: true,
        isPremium: false,
      );

      expect(policy.hasUnlimitedTraining, isFalse);
      expect(policy.shouldConsumeHearts, isTrue);
      expect(policy.canPlay(hasHearts: false), isFalse);
      expect(policy.canPlay(hasHearts: true), isTrue);
      expect(policy.maxDifficulty(), 800.0);
    });

    test('Premium bypasses enabled limits', () {
      const policy = TrainingAccessPolicy(
        limitsEnabled: true,
        isPremium: true,
      );

      expect(policy.hasUnlimitedTraining, isTrue);
      expect(policy.shouldConsumeHearts, isFalse);
      expect(policy.canPlay(hasHearts: false), isTrue);
      expect(policy.maxDifficulty(), double.infinity);
    });
  });

  test('free release drives canPlay and maxDifficulty from one policy', () {
    final container = ProviderContainer(
      overrides: [
        commerceAvailabilityProvider.overrideWithValue(
          _availability(limitsEnabled: false),
        ),
        heartServiceProvider.overrideWith((ref) => _ZeroHeartService()),
      ],
    );
    addTearDown(container.dispose);

    final access = container.read(trainingAccessProvider);
    expect(access.hasUnlimitedTraining, isTrue);
    expect(container.read(canPlayProvider), isTrue);
    expect(container.read(maxDifficultyProvider), double.infinity);
  });

  test('enabled limits consistently gate zero-heart free users', () {
    final container = ProviderContainer(
      overrides: [
        commerceAvailabilityProvider.overrideWithValue(
          _availability(limitsEnabled: true),
        ),
        isPremiumProvider.overrideWithValue(false),
        heartServiceProvider.overrideWith((ref) => _ZeroHeartService()),
      ],
    );
    addTearDown(container.dispose);

    final access = container.read(trainingAccessProvider);
    expect(access.shouldConsumeHearts, isTrue);
    expect(container.read(canPlayProvider), isFalse);
    expect(container.read(maxDifficultyProvider), 800.0);
  });

  test('Premium consistently bypasses enabled limits', () {
    final container = ProviderContainer(
      overrides: [
        commerceAvailabilityProvider.overrideWithValue(
          _availability(limitsEnabled: true),
        ),
        isPremiumProvider.overrideWithValue(true),
        heartServiceProvider.overrideWith((ref) => _ZeroHeartService()),
      ],
    );
    addTearDown(container.dispose);

    final access = container.read(trainingAccessProvider);
    expect(access.shouldConsumeHearts, isFalse);
    expect(container.read(canPlayProvider), isTrue);
    expect(container.read(maxDifficultyProvider), double.infinity);
  });

  test('reading isPremium in default free mode does not create IAP service',
      () {
    var serviceCreations = 0;
    final container = ProviderContainer(
      overrides: [
        commerceAvailabilityProvider.overrideWithValue(
          _availability(limitsEnabled: false),
        ),
        iapServiceProvider.overrideWith((ref) {
          serviceCreations++;
          return _FakeIapService();
        }),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(isPremiumProvider), isFalse);
    expect(serviceCreations, 0);
  });
}
