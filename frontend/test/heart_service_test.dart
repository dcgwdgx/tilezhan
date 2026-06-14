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
    svc = HeartService();
    await svc.init();
  });

  tearDown(() async {
    await svc.dispose();
    await Hive.deleteBoxFromDisk('hearts');
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
