/// Tile efficiency (ukeire) calculation for Riichi Mahjong.
///
/// Determines how many winning-tile draws (ukeire) each possible discard
/// yields from a 14-tile closed hand.  Used by the AI to compare discard
/// candidates: higher ukeire counts mean more paths to tenpai.
///
/// Ported from backend app/engine/ukeire.py.
library ukeire_calculator;

import 'shanten_calculator.dart';

/// Calculates tile acceptance (ukeire) after discarding from a 14-tile hand.
///
/// For every unique tile in the hand, simulates removing it and then testing
/// all 34 possible draws to see whether shanten decreases.  The result tells
/// the caller which discards keep the most outs alive.
class UkeireCalculator {
  /// The 14-tile closed hand to analyze (before any discard).
  final List<String> hand14;

  /// Creates a calculator for the given 14-tile hand.
  ///
  /// Throws [ArgumentError] if [hand14] does not contain exactly 14 tile IDs.
  UkeireCalculator(this.hand14) {
    if (hand14.length != 14) throw ArgumentError('Expected 14 tiles');
  }

  /// Computes ukeire for every unique discard candidate.
  ///
  /// Returns a map keyed by the discarded tile ID, each value containing
  /// the shanten number after discard, the set of tile types that advance
  /// the hand, and the total count of remaining winning tiles.
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

  /// All 34 tile types in Riichi Mahjong (1m–9m, 1p–9p, 1s–9s, 1z–7z).
  static const _allTileIds = [
    'm1','m2','m3','m4','m5','m6','m7','m8','m9',
    'p1','p2','p3','p4','p5','p6','p7','p8','p9',
    's1','s2','s3','s4','s5','s6','s7','s8','s9',
    'z1','z2','z3','z4','z5','z6','z7',
  ];
}

/// Result for a single discard candidate.
class _DiscardResult {
  /// Shanten number after removing this tile (lower is closer to tenpai).
  final int shantenAfter;

  /// Tile types that reduce shanten when drawn.
  final List<String> ukeireTypes;

  /// Total number of remaining winning tiles (counting multiplicity).
  final int ukeireCount;

  const _DiscardResult({required this.shantenAfter, required this.ukeireTypes, required this.ukeireCount});
}
