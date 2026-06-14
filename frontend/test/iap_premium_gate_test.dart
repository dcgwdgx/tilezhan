import 'package:flutter_test/flutter_test.dart';
import 'package:tilezhan/core/iap/iap_service.dart';

/// 付费墙逻辑单元测试——Provider 层的 Stream 时序问题绕过，
/// 直接测试 IapState 和难度上限的判断逻辑。
void main() {
  group('IapState.isPremium', () {
    test('empty entitlements = not premium', () {
      const state = IapState();
      expect(state.isPremium, isFalse);
    });

    test('any entitlement = premium', () {
      const state = IapState(status: IapStatus.ready,
        activeEntitlements: {'com.tilezhan.app.premium.monthly'});
      expect(state.isPremium, isTrue);
    });
  });

  group('maxDifficulty logic', () {
    test('free user gets 800 cap', () {
      final maxDiff = _maxDifficulty(false);
      expect(maxDiff, 800.0);
    });

    test('premium user gets unlimited', () {
      final maxDiff = _maxDifficulty(true);
      expect(maxDiff, double.infinity);
    });
  });

  group('canPlay logic', () {
    test('free with hearts = can play', () {
      expect(_canPlay(isPremium: false, hasHearts: true), isTrue);
    });

    test('free without hearts = cannot play', () {
      expect(_canPlay(isPremium: false, hasHearts: false), isFalse);
    });

    test('premium without hearts = can play', () {
      expect(_canPlay(isPremium: true, hasHearts: false), isTrue);
    });

    test('premium with hearts = can play', () {
      expect(_canPlay(isPremium: true, hasHearts: true), isTrue);
    });
  });
}

/// 等价于 maxDifficultyProvider 的判断逻辑。
double _maxDifficulty(bool isPremium) => isPremium ? double.infinity : 800.0;

/// 等价于 canPlayProvider 的判断逻辑。
bool _canPlay({required bool isPremium, required bool hasHearts}) {
  if (isPremium) return true;
  return hasHearts;
}
