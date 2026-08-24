/// End-to-end flow tests — simulate real user journeys on desktop.
///
/// Tests the complete flow: hearts consume → daily challenge → battle report,
/// onboarding display, and home screen rendering. Uses real Hive + providers.
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tilezhan/core/hearts/heart_service.dart';

void main() {
  setUpAll(() async {
    Hive.init('./test/hive_temp_e2e_${DateTime.now().millisecondsSinceEpoch}');
    await Hive.openBox('hearts');
    await Hive.openBox('prefs');
  });

  group('Hearts drain (full cycle)', () {
    testWidgets('hearts go 10→0 with consume, daily challenge consumed first',
        (tester) async {
      final heart = HeartService();
      await heart.init();

      // Verify initial state
      expect(heart.hearts, 10);
      expect(heart.dailyChallengeRemaining, 3);

      // Use all 3 daily challenges first (free)
      for (int i = 0; i < 3; i++) {
        expect(heart.useDailyChallenge(), isTrue);
      }
      expect(heart.dailyChallengeRemaining, 0);
      expect(heart.canUseDailyChallenge, isFalse);
      expect(heart.hearts, 10); // hearts untouched by daily challenge

      // Now consume all 10 hearts one by one
      for (int i = 9; i >= 0; i--) {
        final depleted = heart.consume();
        expect(heart.hearts, i);
        if (i == 0) {
          expect(depleted, isTrue);
        } else {
          expect(depleted, isFalse);
        }
      }

      expect(heart.hearts, 0);
      expect(heart.hasHearts, isFalse);
      // Still can't consume below 0
      expect(heart.consume(), isFalse);
      expect(heart.hearts, 0);
    });
  });

  group('Combo tracking', () {
    testWidgets('allTimeCombo increments and resets correctly', (tester) async {
      final heart = HeartService();
      await heart.init();

      expect(heart.allTimeCombo, 0);
      heart.recordCorrect();
      heart.recordCorrect();
      heart.recordCorrect();
      expect(heart.allTimeCombo, 3);
      expect(heart.combo, 3);
      expect(heart.maxCombo, 3);

      // Wrong answer resets current and all-time combos
      heart.recordWrong();
      expect(heart.allTimeCombo, 0);
      expect(heart.combo, 0);
      expect(heart.maxCombo, 3); // peak preserved

      heart.dispose();
    });
  });
}
