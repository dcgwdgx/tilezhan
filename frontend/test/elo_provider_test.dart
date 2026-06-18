import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tilezhan/core/elo/elo_provider.dart';

void main() {
  group('EloNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('initial ELO is 800 when no storage', () {
      final elo = container.read(eloProvider);
      // When StorageService is unavailable, defaults to 800
      expect(elo, 800);
    });

    test('correct answer adds 10 ELO', () {
      final notifier = container.read(eloProvider.notifier);
      notifier.recordResult(isCorrect: true, isSkip: false);
      expect(container.read(eloProvider), 810);
    });

    test('wrong answer subtracts 5 ELO', () {
      final notifier = container.read(eloProvider.notifier);
      notifier.recordResult(isCorrect: false, isSkip: false);
      expect(container.read(eloProvider), 795);
    });

    test('skip subtracts 3 ELO', () {
      final notifier = container.read(eloProvider.notifier);
      notifier.recordResult(isCorrect: false, isSkip: true);
      expect(container.read(eloProvider), 797);
    });

    test('ELO does not drop below 0', () {
      final notifier = container.read(eloProvider.notifier);
      // Simulate many wrong answers to push below 0
      for (var i = 0; i < 200; i++) {
        notifier.recordResult(isCorrect: false, isSkip: false);
      }
      expect(container.read(eloProvider), 0);
    });

    test('ELO caps at 3000', () {
      final notifier = container.read(eloProvider.notifier);
      // Simulate many correct answers to push above 3000
      for (var i = 0; i < 500; i++) {
        notifier.recordResult(isCorrect: true, isSkip: false);
      }
      expect(container.read(eloProvider), 3000);
    });

    test('mixed results produce expected ELO', () {
      final notifier = container.read(eloProvider.notifier);
      // 5 correct (+50), 2 wrong (-10), 1 skip (-3) → 800+50-10-3 = 837
      for (var i = 0; i < 5; i++) {
        notifier.recordResult(isCorrect: true, isSkip: false);
      }
      notifier.recordResult(isCorrect: false, isSkip: false);
      notifier.recordResult(isCorrect: false, isSkip: false);
      notifier.recordResult(isCorrect: false, isSkip: true);
      expect(container.read(eloProvider), 837);
    });
  });
}
