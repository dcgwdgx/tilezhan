/// Heart 相关提供者的 Riverpod 状态管理测试
/// 测试覆盖：canPlay（心数>0）、每日挑战剩余、连击促销触发（combo>=10）、战斗报告统计
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilezhan/core/hearts/heart_provider.dart';
import 'package:tilezhan/core/hearts/heart_service.dart';
import 'package:tilezhan/core/iap/iap_provider.dart';
import 'package:tilezhan/core/iap/iap_service.dart';

/// 伪 IapService — 始终返回免费用户状态
class _FakeIap implements IapService {
  @override Stream<IapState> get stateStream => Stream.value(const IapState());
  @override IapState get state => const IapState();
  @override Future<void> init() async {}
  @override Future<void> purchase(String id) async {}
  @override Future<void> restore() async {}
  @override void dispose() {}
}

/// 伪 HeartService，可控制心数和连击数
class _FakeHeartSvc extends HeartService {
  @override int get hearts => h;
  @override bool get hasHearts => h > 0;
  @override int get allTimeCombo => combo;
  @override int get dailyChallengeRemaining => dc;
  @override int get correct => 0;
  @override int get wrong => 0;
  @override int get maxCombo => 0;
  @override Future<void> init() async {}
  @override void recordCorrect() {}
  @override void recordWrong() {}
  @override bool consume() => false;
  @override bool useDailyChallenge() => false;

  int h = 5;
  int combo = 0;
  int dc = 2;
}

/// 统一的 Provider 重写配置
List<Override> _overrides(_FakeHeartSvc hsvc) => [
  heartServiceProvider.overrideWith((r) => hsvc),
  iapServiceProvider.overrideWith((r) => _FakeIap()),
];

void main() {
  group('canPlayProvider', () {
    // 心数 > 0 时 canPlay 为 true
    test('true when hearts > 0', () {
      final c = ProviderContainer(overrides: _overrides(_FakeHeartSvc()..h = 5));
      expect(c.read(canPlayProvider), isTrue);
      c.dispose();
    });

    // 心数为 0 时 canPlay 为 false
    test('false when hearts == 0', () {
      final c = ProviderContainer(overrides: _overrides(_FakeHeartSvc()..h = 0));
      expect(c.read(canPlayProvider), isFalse);
      c.dispose();
    });
  });

  group('dailyChallengeRemainingProvider', () {
    // 每日挑战剩余次数反映 HeartService 实际值
    test('reflects HeartService value', () {
      final c = ProviderContainer(overrides: _overrides(_FakeHeartSvc()..dc = 2));
      expect(c.read(dailyChallengeRemainingProvider), 2);
      c.dispose();
    });
  });

  group('showComboPromoProvider', () {
    // combo < 10 不触发促销弹窗
    test('false when combo < 10', () {
      final c = ProviderContainer(overrides: _overrides(_FakeHeartSvc()..combo = 5));
      expect(c.read(showComboPromoProvider), isFalse);
      c.dispose();
    });

    // combo >= 10 触发促销弹窗
    test('true when combo >= 10', () {
      final c = ProviderContainer(overrides: _overrides(_FakeHeartSvc()..combo = 10));
      expect(c.read(showComboPromoProvider), isTrue);
      c.dispose();
    });
  });

  group('BattleReport', () {
    // 战斗报告正确计算总数和正确率
    test('correct total and accuracy', () {
      const r = BattleReport(correct: 7, wrong: 3, maxCombo: 4, heartsRemaining: 0);
      expect(r.total, 10);
      expect(r.accuracy, 0.7);
    });
  });
}
