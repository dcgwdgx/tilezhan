import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tilezhan/core/utils/consent_service.dart';

void main() {
  Hive.init('./test/hive_consent');

  setUp(() async {
    await Hive.openBox('prefs');
    // Clear any previous consent state
    await Hive.box('prefs').delete('leaderboard_consent');
  });

  tearDown(() async {
    await Hive.close();
  });

  group('Leaderboard consent', () {
    test('defaults to false when not set', () {
      expect(hasLeaderboardConsent(), isFalse);
    });

    test('returns true after setting consent', () {
      setLeaderboardConsent(true);
      expect(hasLeaderboardConsent(), isTrue);
    });

    test('returns false after setting to false', () {
      setLeaderboardConsent(true);
      setLeaderboardConsent(false);
      expect(hasLeaderboardConsent(), isFalse);
    });

    test('persists across calls within same session', () {
      setLeaderboardConsent(true);
      expect(hasLeaderboardConsent(), isTrue);
      expect(hasLeaderboardConsent(), isTrue);
      expect(hasLeaderboardConsent(), isTrue);
    });
  });
}
