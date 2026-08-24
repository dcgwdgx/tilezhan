import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tilezhan/core/hearts/heart_service.dart';
import 'package:tilezhan/core/hearts/heart_provider.dart';

void main() {
  setUpAll(() async {
    Hive.init('./test/hive_temp');
  });

  late HeartService svc;

  setUp(() async {
    if (!Hive.isBoxOpen('hearts')) {
      await Hive.openBox('hearts');
    }
    svc = HeartService();
    await svc.init();
  });

  tearDown(() async {
    svc.dispose();
    if (Hive.isBoxOpen('hearts')) {
      await Hive.box('hearts').close();
      await Hive.deleteBoxFromDisk('hearts');
    }
  });

  group('HeartService', () {
    test('defaults to 10 hearts', () {
      expect(svc.hearts, 10);
      expect(svc.hasHearts, isTrue);
    });

    test('consume reduces hearts by 1', () {
      svc.consume();
      expect(svc.hearts, 9);
      expect(svc.hasHearts, isTrue);
    });

    test('consume all 10 hearts returns depleted on last one', () {
      for (int i = 0; i < 10; i++) {
        final depleted = svc.consume();
        if (i < 9) {
          expect(depleted, isFalse);
        } else {
          expect(depleted, isTrue);
        }
      }
      expect(svc.hearts, 0);
      expect(svc.hasHearts, isFalse);
    });

    test('recordCorrect updates stats', () {
      svc.recordCorrect();
      svc.recordCorrect();
      svc.recordWrong();
      expect(svc.correct, 2);
      expect(svc.wrong, 1);
      expect(svc.total, 3);
    });

    test('recordCorrect builds combo, recordWrong resets', () {
      svc.recordCorrect();
      svc.recordCorrect();
      expect(svc.combo, 2);
      expect(svc.maxCombo, 2);
      svc.recordWrong();
      expect(svc.combo, 0);
      expect(svc.maxCombo, 2);
    });

    test('accuracy calculates correctly', () {
      svc.recordCorrect();
      svc.recordCorrect();
      svc.recordWrong();
      expect(svc.accuracy, 2 / 3);
    });

    test('accuracy is 0 with no attempts', () {
      expect(svc.accuracy, 0);
    });
  });

  group('DailyChallenge', () {
    test('defaults to 3 remaining', () {
      expect(svc.dailyChallengeRemaining, 3);
      expect(svc.canUseDailyChallenge, isTrue);
    });

    test('useDailyChallenge reduces remaining', () {
      expect(svc.useDailyChallenge(), isTrue);
      expect(svc.dailyChallengeRemaining, 2);
      expect(svc.useDailyChallenge(), isTrue);
      expect(svc.dailyChallengeRemaining, 1);
      expect(svc.useDailyChallenge(), isTrue);
      expect(svc.dailyChallengeRemaining, 0);
    });

    test('useDailyChallenge returns false when depleted', () {
      svc.useDailyChallenge(); // 2 left
      svc.useDailyChallenge(); // 1 left
      svc.useDailyChallenge(); // 0 left
      expect(svc.canUseDailyChallenge, isFalse);
      expect(svc.useDailyChallenge(), isFalse);
    });

    test('records exactly three attempts and counts correct answers', () {
      final first = svc.recordDailyChallengeResult(isCorrect: true);
      expect(first.attempted, 1);
      expect(first.correct, 1);
      expect(first.remaining, 2);
      expect(first.completed, isFalse);
      expect(first.wasRecorded, isTrue);

      final second = svc.recordDailyChallengeResult(isCorrect: false);
      expect(second.attempted, 2);
      expect(second.correct, 1);
      expect(second.remaining, 1);

      final third = svc.recordDailyChallengeResult(isCorrect: true);
      expect(third.attempted, 3);
      expect(third.correct, 2);
      expect(third.remaining, 0);
      expect(third.completed, isTrue);
      expect(third.accuracy, closeTo(2 / 3, 0.0001));

      final duplicate = svc.recordDailyChallengeResult(isCorrect: true);
      expect(duplicate.wasRecorded, isFalse);
      expect(duplicate.attempted, 3);
      expect(duplicate.correct, 2);
      expect(svc.dailyChallengeAttempted, 3);
      expect(svc.dailyChallengeCorrect, 2);
    });

    test('completion streak advances once after a yesterday completion', () async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      String dayKey(DateTime date) =>
          '${date.year.toString().padLeft(4, '0')}-'
          '${date.month.toString().padLeft(2, '0')}-'
          '${date.day.toString().padLeft(2, '0')}';

      final box = Hive.box('hearts');
      await box.put('last_reset_date', dayKey(today));
      await box.put('daily_challenge_used', 0);
      await box.put('daily_challenge_correct', 0);
      await box.put('daily_challenge_streak', 4);
      await box.put('daily_challenge_last_completed', dayKey(yesterday));

      final fresh = HeartService();
      fresh.recordDailyChallengeResult(isCorrect: true);
      fresh.recordDailyChallengeResult(isCorrect: true);
      final completed = fresh.recordDailyChallengeResult(isCorrect: false);

      expect(completed.completed, isTrue);
      expect(completed.streak, 5);

      final duplicate = fresh.recordDailyChallengeResult(isCorrect: true);
      expect(duplicate.wasRecorded, isFalse);
      expect(duplicate.streak, 5);
      expect(fresh.dailyChallengeStreak, 5);
    });
  });

  group('ComboPromo', () {
    test('allTimeCombo increments on correct', () {
      svc.recordCorrect();
      expect(svc.allTimeCombo, 1);
      svc.recordCorrect();
      expect(svc.allTimeCombo, 2);
    });

    test('allTimeCombo resets on wrong', () {
      svc.recordCorrect();
      svc.recordCorrect();
      svc.recordWrong();
      expect(svc.allTimeCombo, 0);
    });

    test('allTimeCombo hits 10 = promo trigger', () {
      for (int i = 0; i < 10; i++) {
        svc.recordCorrect();
      }
      expect(svc.allTimeCombo, 10);
    });
  });

  group('Persistence across recreation', () {
    test('hearts survive provider dispose/recreate (simulates app navigation)', () async {
      // Simulate main() opening the box
      await Hive.openBox('hearts');

      // First "provider" — consume 3 hearts
      var svc = HeartService();
      svc.consume();
      svc.consume();
      svc.consume();
      expect(svc.hearts, 7);
      svc.dispose();

      // "Provider disposed" — recreate
      svc = HeartService();
      expect(svc.hearts, 7, reason: 'hearts should persist across recreation');
      svc.consume();
      expect(svc.hearts, 6);
      svc.dispose();

      await Hive.box('hearts').close();
    });

    test('daily challenge uses persist across recreation', () async {
      await Hive.openBox('hearts');
      var svc = HeartService();
      // Use all 3 daily challenges
      expect(svc.useDailyChallenge(), isTrue);
      expect(svc.useDailyChallenge(), isTrue);
      expect(svc.useDailyChallenge(), isTrue);
      expect(svc.dailyChallengeRemaining, 0);
      svc.dispose();

      // Recreate — daily challenge should still be used up
      svc = HeartService();
      expect(svc.dailyChallengeRemaining, 0);
      expect(svc.canUseDailyChallenge, isFalse);
      svc.dispose();
      await Hive.box('hearts').close();
    });
  });

  group('LifetimePromo', () {
    test('isLifetimePromoActive true for free user within 48h', () {
      expect(svc.isLifetimePromoActive(false), isTrue);
    });

    test('isLifetimePromoActive false for premium user', () {
      expect(svc.isLifetimePromoActive(true), isFalse);
    });
  });

  group('BattleReport', () {
    test('calculates total and accuracy', () {
      const report = BattleReport(
        correct: 7, wrong: 3, maxCombo: 4, heartsRemaining: 0,
      );
      expect(report.total, 10);
      expect(report.accuracy, 0.7);
    });

    test('total 0 accuracy is 0', () {
      const report = BattleReport(
        correct: 0, wrong: 0, maxCombo: 0, heartsRemaining: 5,
      );
      expect(report.accuracy, 0);
    });
  });
}
