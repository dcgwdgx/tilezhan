import '../../../shared/engine/ukeire_calculator.dart';

/// Stable semantic tags for teaching copy and analytics.
///
/// The domain layer intentionally exposes enums instead of localized strings.
/// Presentation code can map these values to copy without changing the rules.
enum NanikiruTeachingTag {
  isolatedTileHandling,
  taatsuOverload,
  pairProtection,
  chiitoitsuCompetition,
  kokushiTendency,
  generalTileEfficiency,
}

/// Engine-backed teaching data for one discard candidate.
class NanikiruCandidateAnalysis {
  const NanikiruCandidateAnalysis({
    required this.discardId,
    required this.rank,
    required this.shantenAfter,
    required this.ukeireTileIds,
    required this.ukeireCount,
    required this.shantenDifferenceFromBest,
    required this.ukeireLossFromBest,
    required this.isOptimal,
    required this.tags,
  });

  final String discardId;

  /// Competition rank under the engine's ordering.
  ///
  /// Equal shanten and equal uke-ire share a rank; tile order is used only to
  /// make output deterministic and never to claim that one tied move is better.
  final int rank;
  final int shantenAfter;
  final List<String> ukeireTileIds;
  final int ukeireCount;
  final int shantenDifferenceFromBest;

  /// Uke-ire loss is meaningful only while shanten is equal to the best move.
  ///
  /// A worse-shanten move may expose more nominal effective tiles, but that raw
  /// count is not comparable to the best move's next-step acceptance. Such a
  /// candidate therefore reports `null` instead of a misleading zero loss.
  final int? ukeireLossFromBest;
  final bool isOptimal;
  final Set<NanikiruTeachingTag> tags;

  int get ukeireTypes => ukeireTileIds.length;
}

/// Complete teaching result for a user's discard decision.
class NanikiruTeachingAnalysis {
  const NanikiruTeachingAnalysis({
    required this.topCandidates,
    required this.selectedCandidate,
    required this.byDiscard,
    required this.evaluatedCandidateCount,
  });

  /// Up to three candidates ordered by shanten, then uke-ire.
  final List<NanikiruCandidateAnalysis> topCandidates;

  /// The user's move, retained even when it is outside [topCandidates].
  ///
  /// `null` represents a skipped question or a timeout without a selection.
  final NanikiruCandidateAnalysis? selectedCandidate;

  /// Immutable candidate directory for post-answer lookup by tile ID.
  final Map<String, NanikiruCandidateAnalysis> byDiscard;
  final int evaluatedCandidateCount;

  NanikiruCandidateAnalysis get bestCandidate => topCandidates.first;

  /// Returns the same immutable catalog with a different user move attached.
  ///
  /// Puzzle initialization can build the catalog before the player chooses a
  /// tile. Confirm/timeout then attaches the final (or pending) choice without
  /// recalculating shanten or uke-ire.
  NanikiruTeachingAnalysis withSelectedDiscard(String? discardId) {
    if (discardId != null && !byDiscard.containsKey(discardId)) {
      throw ArgumentError.value(discardId, 'discardId');
    }
    return NanikiruTeachingAnalysis(
      topCandidates: topCandidates,
      selectedCandidate: discardId == null ? null : byDiscard[discardId],
      byDiscard: byDiscard,
      evaluatedCandidateCount: evaluatedCandidateCount,
    );
  }

  /// Teaching topics represented by every engine-optimal discard.
  Set<NanikiruTeachingTag> get optimalTags {
    final tags = <NanikiruTeachingTag>{};
    for (final candidate in byDiscard.values.where((item) => item.isOptimal)) {
      tags.addAll(candidate.tags);
    }
    if (tags.length > 1) {
      tags.remove(NanikiruTeachingTag.generalTileEfficiency);
    }
    if (tags.isEmpty) {
      tags.add(NanikiruTeachingTag.generalTileEfficiency);
    }
    return Set<NanikiruTeachingTag>.unmodifiable(tags);
  }
}

/// Converts existing [UkeireCalculator] results into explainable teaching data.
///
/// This class never recalculates shanten or uke-ire and does not maintain a
/// second answer engine. Candidate quality comes exclusively from [results]:
/// lower `shantenAfter` wins, followed by higher `ukeireCount`.
class NanikiruTeachingAnalyzer {
  const NanikiruTeachingAnalyzer._();

  static NanikiruTeachingAnalysis analyze({
    required List<String> hand14,
    required String? selectedDiscardId,
    required Map<String, DiscardResult> results,
  }) {
    if (hand14.length != 14) {
      throw ArgumentError.value(hand14.length, 'hand14.length', 'Must be 14');
    }

    final handKinds = hand14.toSet();
    final resultKinds = results.keys.toSet();
    if (results.isEmpty ||
        resultKinds.length != handKinds.length ||
        !resultKinds.containsAll(handKinds)) {
      throw ArgumentError.value(
        results.keys,
        'results',
        'Must contain one result for every discard kind in hand14',
      );
    }
    if (selectedDiscardId != null && !results.containsKey(selectedDiscardId)) {
      throw ArgumentError.value(
        selectedDiscardId,
        'selectedDiscardId',
        'Must be a discard kind in hand14',
      );
    }

    final ordered = results.entries.toList()..sort(_compareEntries);
    final best = ordered.first.value;
    final counts = <String, int>{};
    for (final tileId in hand14) {
      counts[tileId] = (counts[tileId] ?? 0) + 1;
    }

    final handTags = <NanikiruTeachingTag>{};
    if (_hasTaatsuOverloadSignal(ordered, best.shantenAfter)) {
      handTags.add(NanikiruTeachingTag.taatsuOverload);
    }
    if (_chiitoitsuShanten(counts) <= 1) {
      handTags.add(NanikiruTeachingTag.chiitoitsuCompetition);
    }
    if (_kokushiShanten(counts) <= 2) {
      handTags.add(NanikiruTeachingTag.kokushiTendency);
    }

    final analyses = <String, NanikiruCandidateAnalysis>{};
    var currentRank = 0;
    MapEntry<String, DiscardResult>? previous;
    for (var index = 0; index < ordered.length; index++) {
      final entry = ordered[index];
      if (previous == null || !_sameQuality(previous.value, entry.value)) {
        currentRank = index + 1;
      }
      previous = entry;

      final tags = <NanikiruTeachingTag>{...handTags};
      if (_isIsolated(entry.key, counts)) {
        tags.add(NanikiruTeachingTag.isolatedTileHandling);
      }
      if (_protectsPair(entry, ordered, counts)) {
        tags.add(NanikiruTeachingTag.pairProtection);
      }
      if (tags.isEmpty) {
        tags.add(NanikiruTeachingTag.generalTileEfficiency);
      }

      final sameShanten = entry.value.shantenAfter == best.shantenAfter;
      analyses[entry.key] = NanikiruCandidateAnalysis(
        discardId: entry.key,
        rank: currentRank,
        shantenAfter: entry.value.shantenAfter,
        ukeireTileIds: List<String>.unmodifiable(entry.value.ukeireTypes),
        ukeireCount: entry.value.ukeireCount,
        shantenDifferenceFromBest: entry.value.shantenAfter - best.shantenAfter,
        ukeireLossFromBest:
            sameShanten ? best.ukeireCount - entry.value.ukeireCount : null,
        isOptimal: _sameQuality(entry.value, best),
        tags: Set<NanikiruTeachingTag>.unmodifiable(tags),
      );
    }

    final topCandidates = ordered
        .take(3)
        .map((entry) => analyses[entry.key]!)
        .toList(growable: false);
    return NanikiruTeachingAnalysis(
      topCandidates:
          List<NanikiruCandidateAnalysis>.unmodifiable(topCandidates),
      selectedCandidate:
          selectedDiscardId == null ? null : analyses[selectedDiscardId]!,
      byDiscard: Map<String, NanikiruCandidateAnalysis>.unmodifiable(analyses),
      evaluatedCandidateCount: ordered.length,
    );
  }

  static int _compareEntries(
    MapEntry<String, DiscardResult> left,
    MapEntry<String, DiscardResult> right,
  ) {
    final byShanten =
        left.value.shantenAfter.compareTo(right.value.shantenAfter);
    if (byShanten != 0) return byShanten;
    final byUkeire = right.value.ukeireCount.compareTo(left.value.ukeireCount);
    if (byUkeire != 0) return byUkeire;
    return _tileIndex(left.key).compareTo(_tileIndex(right.key));
  }

  static bool _sameQuality(DiscardResult left, DiscardResult right) =>
      left.shantenAfter == right.shantenAfter &&
      left.ukeireCount == right.ukeireCount;

  /// Multiple same-shanten choices with different acceptance is the observable
  /// engine signal for an excess-block/taatsu-selection lesson.
  static bool _hasTaatsuOverloadSignal(
    List<MapEntry<String, DiscardResult>> ordered,
    int bestShanten,
  ) {
    final sameShanten = ordered
        .where((entry) => entry.value.shantenAfter == bestShanten)
        .toList();
    return sameShanten.length >= 3 &&
        sameShanten.map((entry) => entry.value.ukeireCount).toSet().length >= 2;
  }

  static bool _protectsPair(
    MapEntry<String, DiscardResult> candidate,
    List<MapEntry<String, DiscardResult>> ordered,
    Map<String, int> counts,
  ) {
    if ((counts[candidate.key] ?? 0) != 1) return false;
    return ordered.any((other) =>
        (counts[other.key] ?? 0) == 2 &&
        _compareQuality(candidate.value, other.value) < 0);
  }

  static int _compareQuality(DiscardResult left, DiscardResult right) {
    final byShanten = left.shantenAfter.compareTo(right.shantenAfter);
    return byShanten != 0
        ? byShanten
        : right.ukeireCount.compareTo(left.ukeireCount);
  }

  static bool _isIsolated(String tileId, Map<String, int> counts) {
    if ((counts[tileId] ?? 0) != 1) return false;
    final suit = tileId[0];
    if (suit == 'z') return true;
    final rank = int.parse(tileId[1]);
    for (var distance = 1; distance <= 2; distance++) {
      for (final neighborRank in [rank - distance, rank + distance]) {
        if (neighborRank >= 1 &&
            neighborRank <= 9 &&
            (counts['$suit$neighborRank'] ?? 0) > 0) {
          return false;
        }
      }
    }
    return true;
  }

  static int _chiitoitsuShanten(Map<String, int> counts) {
    final pairs = counts.values.where((count) => count >= 2).length;
    final uniqueKinds = counts.length;
    final missingKinds = 7 - uniqueKinds;
    return 6 - pairs + (missingKinds > 0 ? missingKinds : 0);
  }

  static int _kokushiShanten(Map<String, int> counts) {
    var kinds = 0;
    var hasPair = false;
    for (final tileId in _terminalAndHonorIds) {
      final count = counts[tileId] ?? 0;
      if (count > 0) kinds++;
      if (count >= 2) hasPair = true;
    }
    return 13 - kinds - (hasPair ? 1 : 0);
  }

  static int _tileIndex(String tileId) {
    final suit = tileId[0];
    final rank = int.parse(tileId[1]);
    final base = switch (suit) {
      'm' => 0,
      'p' => 9,
      's' => 18,
      'z' => 27,
      _ => throw ArgumentError.value(tileId, 'tileId'),
    };
    return base + rank - 1;
  }

  static const _terminalAndHonorIds = {
    'm1',
    'm9',
    'p1',
    'p9',
    's1',
    's9',
    'z1',
    'z2',
    'z3',
    'z4',
    'z5',
    'z6',
    'z7',
  };
}
