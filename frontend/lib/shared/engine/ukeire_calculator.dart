import 'shanten_calculator.dart';

/// Calculates tile acceptance (ukeire) after discarding from a 14-tile hand.
/// Ported from backend app/engine/ukeire.py.
class UkeireCalculator {
  final List<String> hand14;

  UkeireCalculator(this.hand14) {
    if (hand14.length != 14) throw ArgumentError('Expected 14 tiles');
  }

  /// Returns map of discardTileId → {shanten, ukeireTypes, ukeireCount}.
  Map<String, _DiscardResult> calculate() {
    final results = <String, _DiscardResult>{};
    final seen = <String>{};

    for (var i = 0; i < hand14.length; i++) {
      final discardId = hand14[i];
      if (seen.contains(discardId)) continue;
      seen.add(discardId);

      final remaining = <String>[...hand14.sublist(0, i), ...hand14.sublist(i + 1)];
      final ukeireTypes = <String>[];
      var ukeireCount = 0;
      final baseShanten = ShantenCalculator.fromIds(remaining).calculate();

      // Test all 34 possible draws
      for (final testId in _allTileIds) {
        if (remaining.where((t) => t == testId).length >= 4) continue;
        final candidate = [...remaining, testId];
        final newShanten = ShantenCalculator.fromIds(candidate).calculate();
        if (newShanten < baseShanten) {
          ukeireTypes.add(testId);
          ukeireCount += 4 - remaining.where((t) => t == testId).length;
        }
      }

      results[discardId] = _DiscardResult(
        shantenAfter: baseShanten,
        ukeireTypes: ukeireTypes,
        ukeireCount: ukeireCount,
      );
    }
    return results;
  }

  static const _allTileIds = [
    'm1','m2','m3','m4','m5','m6','m7','m8','m9',
    'p1','p2','p3','p4','p5','p6','p7','p8','p9',
    's1','s2','s3','s4','s5','s6','s7','s8','s9',
    'z1','z2','z3','z4','z5','z6','z7',
  ];
}

class _DiscardResult {
  final int shantenAfter;
  final List<String> ukeireTypes;
  final int ukeireCount;
  const _DiscardResult({required this.shantenAfter, required this.ukeireTypes, required this.ukeireCount});
}
