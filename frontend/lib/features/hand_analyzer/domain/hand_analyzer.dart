import '../../../shared/engine/shanten_calculator.dart';
import '../../../shared/engine/ukeire_calculator.dart';

/// Immutable result shared by the 13-tile and 14-tile analysis flows.
///
/// [shantenBreakdown] contains the existing exact engine's standard,
/// seven-pairs, and thirteen-orphans values. [minimumShanten] is their minimum,
/// so the aggregate result and the per-shape values always share one source.
sealed class HandAnalysis {
  HandAnalysis({
    required List<String> handTiles,
    required this.shantenBreakdown,
  }) : handTiles = List<String>.unmodifiable(handTiles);

  final List<String> handTiles;
  final ShantenBreakdown shantenBreakdown;

  int get minimumShanten => shantenBreakdown.minimum;
}

/// One draw that lowers the minimum shanten of a 13-tile hand.
class EffectiveDraw {
  const EffectiveDraw({
    required this.tileId,
    required this.minimumShantenAfterDraw,
    required this.theoreticalRemainingCopies,
  });

  final String tileId;
  final int minimumShantenAfterDraw;

  /// Four copies minus copies already present in [HandAnalysis.handTiles].
  ///
  /// Discards, calls, and other players' visible tiles are intentionally not
  /// available to this closed-hand analyzer, so this is a theoretical maximum.
  final int theoreticalRemainingCopies;
}

/// Analysis of a 13-tile hand before the next draw.
class DrawHandAnalysis extends HandAnalysis {
  factory DrawHandAnalysis({
    required List<String> handTiles,
    required ShantenBreakdown shantenBreakdown,
    required List<EffectiveDraw> effectiveDraws,
  }) {
    final drawSnapshot = List<EffectiveDraw>.unmodifiable(effectiveDraws);
    return DrawHandAnalysis._(
      handTiles: handTiles,
      shantenBreakdown: shantenBreakdown,
      effectiveDraws: drawSnapshot,
      effectiveTileIds: List<String>.unmodifiable(
        drawSnapshot.map((draw) => draw.tileId),
      ),
      totalEffectiveTileCount: drawSnapshot.fold<int>(
        0,
        (total, draw) => total + draw.theoreticalRemainingCopies,
      ),
    );
  }

  DrawHandAnalysis._({
    required super.handTiles,
    required super.shantenBreakdown,
    required this.effectiveDraws,
    required this.effectiveTileIds,
    required this.totalEffectiveTileCount,
  });

  final List<EffectiveDraw> effectiveDraws;
  final List<String> effectiveTileIds;
  final int totalEffectiveTileCount;

  int get effectiveTileTypeCount => effectiveDraws.length;
}

/// One unique discard kind and its exact post-discard acceptance.
class DiscardCandidate {
  DiscardCandidate({
    required this.tileId,
    required this.rank,
    required this.minimumShantenAfterDiscard,
    required List<String> effectiveTileIds,
    required this.effectiveTileCount,
  }) : effectiveTileIds = List<String>.unmodifiable(effectiveTileIds);

  final String tileId;

  /// Competition rank: equally strong candidates share a rank (1, 1, 3).
  final int rank;
  final int minimumShantenAfterDiscard;
  final List<String> effectiveTileIds;
  final int effectiveTileCount;

  int get effectiveTileTypeCount => effectiveTileIds.length;
  bool get isOptimal => rank == 1;
}

/// Ranked discard analysis of a 14-tile hand.
class DiscardHandAnalysis extends HandAnalysis {
  factory DiscardHandAnalysis({
    required List<String> handTiles,
    required ShantenBreakdown shantenBreakdown,
    required List<DiscardCandidate> candidates,
  }) {
    final candidateSnapshot = List<DiscardCandidate>.unmodifiable(candidates);
    if (candidateSnapshot.isEmpty) {
      throw ArgumentError.value(candidates, 'candidates', 'Cannot be empty');
    }

    return DiscardHandAnalysis._(
      handTiles: handTiles,
      shantenBreakdown: shantenBreakdown,
      candidates: candidateSnapshot,
      bestCandidates: List<DiscardCandidate>.unmodifiable(
        candidateSnapshot.where((candidate) => candidate.rank == 1),
      ),
      byDiscard: Map<String, DiscardCandidate>.unmodifiable({
        for (final candidate in candidateSnapshot) candidate.tileId: candidate,
      }),
    );
  }

  DiscardHandAnalysis._({
    required super.handTiles,
    required super.shantenBreakdown,
    required this.candidates,
    required this.bestCandidates,
    required this.byDiscard,
  });

  /// Every unique discard kind, ordered by minimum shanten, remaining copies,
  /// effective-tile types, and finally canonical tile order for determinism.
  final List<DiscardCandidate> candidates;
  final List<DiscardCandidate> bestCandidates;
  final Map<String, DiscardCandidate> byDiscard;
}

/// Exact closed-hand analysis for manually entered 13- or 14-tile hands.
class HandAnalyzer {
  const HandAnalyzer._();

  static HandAnalysis analyze(List<String> tileIds) {
    if (tileIds.length != 13 && tileIds.length != 14) {
      throw ArgumentError.value(
        tileIds.length,
        'tileIds.length',
        'Expected exactly 13 or 14 tiles',
      );
    }

    // Creates the authoritative count vector and validates both tile IDs and
    // the physical four-copy limit before any result objects are constructed.
    final handTiles = List<String>.unmodifiable(tileIds);
    final shantenBreakdown =
        ShantenCalculator.fromIds(handTiles).calculateBreakdown();

    if (handTiles.length == 13) {
      return _analyzeDraws(handTiles, shantenBreakdown);
    }
    return _analyzeDiscards(handTiles, shantenBreakdown);
  }

  static DrawHandAnalysis _analyzeDraws(
    List<String> handTiles,
    ShantenBreakdown shantenBreakdown,
  ) {
    final counts = <String, int>{};
    for (final tileId in handTiles) {
      counts[tileId] = (counts[tileId] ?? 0) + 1;
    }

    final effectiveDraws = <EffectiveDraw>[];
    for (final tileId in _allTileIds) {
      final remainingCopies = 4 - (counts[tileId] ?? 0);
      if (remainingCopies == 0) continue;

      final shantenAfterDraw =
          ShantenCalculator.fromIds([...handTiles, tileId]).calculate();
      if (shantenAfterDraw < shantenBreakdown.minimum) {
        effectiveDraws.add(EffectiveDraw(
          tileId: tileId,
          minimumShantenAfterDraw: shantenAfterDraw,
          theoreticalRemainingCopies: remainingCopies,
        ));
      }
    }

    return DrawHandAnalysis(
      handTiles: handTiles,
      shantenBreakdown: shantenBreakdown,
      effectiveDraws: effectiveDraws,
    );
  }

  static DiscardHandAnalysis _analyzeDiscards(
    List<String> handTiles,
    ShantenBreakdown shantenBreakdown,
  ) {
    final ordered = UkeireCalculator(handTiles).calculate().entries.toList()
      ..sort(_compareDiscardResults);

    final candidates = <DiscardCandidate>[];
    MapEntry<String, DiscardResult>? previous;
    var rank = 0;
    for (var index = 0; index < ordered.length; index++) {
      final entry = ordered[index];
      if (previous == null || !_sameQuality(previous.value, entry.value)) {
        rank = index + 1;
      }
      previous = entry;

      candidates.add(DiscardCandidate(
        tileId: entry.key,
        rank: rank,
        minimumShantenAfterDiscard: entry.value.shantenAfter,
        effectiveTileIds: entry.value.ukeireTypes,
        effectiveTileCount: entry.value.ukeireCount,
      ));
    }

    return DiscardHandAnalysis(
      handTiles: handTiles,
      shantenBreakdown: shantenBreakdown,
      candidates: candidates,
    );
  }

  static int _compareDiscardResults(
    MapEntry<String, DiscardResult> left,
    MapEntry<String, DiscardResult> right,
  ) {
    final byShanten =
        left.value.shantenAfter.compareTo(right.value.shantenAfter);
    if (byShanten != 0) return byShanten;

    final byCount = right.value.ukeireCount.compareTo(left.value.ukeireCount);
    if (byCount != 0) return byCount;

    final byTypes =
        right.value.ukeireTypes.length.compareTo(left.value.ukeireTypes.length);
    if (byTypes != 0) return byTypes;

    return _tileIndex(left.key).compareTo(_tileIndex(right.key));
  }

  static bool _sameQuality(DiscardResult left, DiscardResult right) =>
      left.shantenAfter == right.shantenAfter &&
      left.ukeireCount == right.ukeireCount &&
      left.ukeireTypes.length == right.ukeireTypes.length;

  static int _tileIndex(String tileId) {
    final suit = tileId[0];
    final rank = int.parse(tileId[1]);
    final base = switch (suit) {
      'm' => 0,
      'p' => 9,
      's' => 18,
      'z' => 27,
      _ => throw StateError('Validated tile ID has an unknown suit'),
    };
    return base + rank - 1;
  }

  static const _allTileIds = [
    'm1',
    'm2',
    'm3',
    'm4',
    'm5',
    'm6',
    'm7',
    'm8',
    'm9',
    'p1',
    'p2',
    'p3',
    'p4',
    'p5',
    'p6',
    'p7',
    'p8',
    'p9',
    's1',
    's2',
    's3',
    's4',
    's5',
    's6',
    's7',
    's8',
    's9',
    'z1',
    'z2',
    'z3',
    'z4',
    'z5',
    'z6',
    'z7',
  ];
}
