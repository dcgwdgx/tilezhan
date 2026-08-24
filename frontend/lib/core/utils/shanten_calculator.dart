/// Closed-hand Japanese mahjong shanten calculator.
///
/// The result follows the conventional scale:
/// - `-1`: complete hand
/// - `0`: tenpai
/// - `1`: one-shanten
///
/// Tile IDs use the project-wide suit-first format (`m1`, `p5`, `s9`, `z7`).
/// The calculator evaluates standard hands, seven pairs, and thirteen orphans.

library shanten_calculator;

import 'dart:collection';
import 'dart:math' as math;

/// The thirteen terminal and honor tile indices used by kokushi musou.
const terminalIndices = [
  0,
  8,
  9,
  17,
  18,
  26,
  27,
  28,
  29,
  30,
  31,
  32,
  33,
];

/// Exact shanten values for every closed-hand family supported by the engine.
///
/// All values use the same conventional scale as [ShantenCalculator]: `-1` is
/// complete, `0` is tenpai, and positive values are that many shanten away.
class ShantenBreakdown {
  const ShantenBreakdown({
    required this.standard,
    required this.sevenPairs,
    required this.thirteenOrphans,
  });

  final int standard;
  final int sevenPairs;
  final int thirteenOrphans;

  int get minimum =>
      math.min(standard, math.min(sevenPairs, thirteenOrphans)).toInt();
}

class ShantenCalculator {
  static const _maxCacheEntries = 8192;
  static final LinkedHashMap<String, ShantenBreakdown> _cache = LinkedHashMap();

  /// Mutable private working copy of the 34-tile count vector.
  final List<int> tiles34;

  int _standardBest = 8;

  ShantenCalculator(List<int> counts) : tiles34 = List<int>.from(counts) {
    if (counts.length != 34) {
      throw ArgumentError.value(counts.length, 'counts.length', 'Must be 34');
    }
    for (var i = 0; i < counts.length; i++) {
      final count = counts[i];
      if (count < 0 || count > 4) {
        throw ArgumentError.value(
          count,
          'counts[$i]',
          'Must be between 0 and 4',
        );
      }
    }
    if (counts.fold<int>(0, (sum, count) => sum + count) > 14) {
      throw ArgumentError.value(
        counts,
        'counts',
        'A closed hand cannot exceed 14 tiles',
      );
    }
  }

  factory ShantenCalculator.fromIds(List<String> tileIds) {
    if (tileIds.length > 14) {
      throw ArgumentError.value(
        tileIds.length,
        'tileIds.length',
        'A closed hand cannot exceed 14 tiles',
      );
    }

    final counts = List<int>.filled(34, 0);
    for (final tileId in tileIds) {
      final index = _tileIdToIndex(tileId);
      counts[index] += 1;
      if (counts[index] > 4) {
        throw ArgumentError.value(
          tileId,
          'tileIds',
          'A tile cannot appear more than four times',
        );
      }
    }
    return ShantenCalculator(counts);
  }

  /// Returns the lowest shanten across standard, chiitoitsu, and kokushi shapes.
  int calculate() => calculateBreakdown().minimum;

  /// Returns each supported hand family's exact shanten and their minimum.
  ///
  /// This method is the single calculation path used by [calculate], so the
  /// aggregate result and the three values shown to users cannot diverge.
  ShantenBreakdown calculateBreakdown() {
    final cacheKey = String.fromCharCodes(tiles34);
    final cached = _cache.remove(cacheKey);
    if (cached != null) {
      _cache[cacheKey] = cached;
      return cached;
    }

    final pairKinds = tiles34.where((count) => count >= 2).length;
    final uniqueKinds = tiles34.where((count) => count > 0).length;
    final chiitoitsu = (6 - pairKinds + math.max(0, 7 - uniqueKinds)).toInt();

    var kokushiKinds = 0;
    var kokushiHasPair = false;
    for (final index in terminalIndices) {
      if (tiles34[index] > 0) kokushiKinds++;
      if (tiles34[index] >= 2) kokushiHasPair = true;
    }
    final kokushi = 13 - kokushiKinds - (kokushiHasPair ? 1 : 0);

    _standardBest = 8;
    _searchStandard(0, 0, 0, 0);
    final result = ShantenBreakdown(
      standard: _standardBest,
      sevenPairs: chiitoitsu,
      thirteenOrphans: kokushi,
    );
    _cache[cacheKey] = result;
    if (_cache.length > _maxCacheEntries) {
      _cache.remove(_cache.keys.first);
    }
    return result;
  }

  /// Enumerates every useful decomposition of the first remaining tile.
  ///
  /// Processing only the first non-zero tile avoids permutation duplicates while
  /// the final single-tile skip branch still explores every possible isolation.
  void _searchStandard(int start, int melds, int taatsu, int pair) {
    var index = start;
    while (index < 34 && tiles34[index] == 0) {
      index++;
    }

    if (index == 34) {
      final usableTaatsu = math.min(taatsu, math.max(0, 4 - melds)).toInt();
      final shanten = 8 - (melds * 2) - usableTaatsu - pair;
      if (shanten < _standardBest) _standardBest = shanten;
      return;
    }

    final count = tiles34[index];
    final isNumberTile = index < 27;
    final rank = index % 9;

    if (melds < 4 && count >= 3) {
      tiles34[index] -= 3;
      _searchStandard(index, melds + 1, taatsu, pair);
      tiles34[index] += 3;
    }

    if (melds < 4 &&
        isNumberTile &&
        rank <= 6 &&
        tiles34[index + 1] > 0 &&
        tiles34[index + 2] > 0) {
      tiles34[index]--;
      tiles34[index + 1]--;
      tiles34[index + 2]--;
      _searchStandard(index, melds + 1, taatsu, pair);
      tiles34[index]++;
      tiles34[index + 1]++;
      tiles34[index + 2]++;
    }

    if (pair == 0 && count >= 2) {
      tiles34[index] -= 2;
      _searchStandard(index, melds, taatsu, 1);
      tiles34[index] += 2;
    }

    if (taatsu < 4) {
      if (count >= 2) {
        tiles34[index] -= 2;
        _searchStandard(index, melds, taatsu + 1, pair);
        tiles34[index] += 2;
      }

      if (isNumberTile && rank <= 7 && tiles34[index + 1] > 0) {
        tiles34[index]--;
        tiles34[index + 1]--;
        _searchStandard(index, melds, taatsu + 1, pair);
        tiles34[index]++;
        tiles34[index + 1]++;
      }

      if (isNumberTile && rank <= 6 && tiles34[index + 2] > 0) {
        tiles34[index]--;
        tiles34[index + 2]--;
        _searchStandard(index, melds, taatsu + 1, pair);
        tiles34[index]++;
        tiles34[index + 2]++;
      }
    }

    tiles34[index]--;
    _searchStandard(index, melds, taatsu, pair);
    tiles34[index]++;
  }

  static int _tileIdToIndex(String tileId) {
    if (tileId.length != 2) {
      throw ArgumentError.value(
        tileId,
        'tileId',
        'Expected m1-m9, p1-p9, s1-s9, or z1-z7',
      );
    }

    final suit = tileId[0];
    final rank = int.tryParse(tileId[1]);
    final maxRank = suit == 'z' ? 7 : 9;
    if (!const {'m', 'p', 's', 'z'}.contains(suit) ||
        rank == null ||
        rank < 1 ||
        rank > maxRank) {
      throw ArgumentError.value(
        tileId,
        'tileId',
        'Expected m1-m9, p1-p9, s1-s9, or z1-z7',
      );
    }

    final base = switch (suit) {
      'm' => 0,
      'p' => 9,
      's' => 18,
      'z' => 27,
      _ => throw StateError('Unreachable suit'),
    };
    return base + rank - 1;
  }
}
