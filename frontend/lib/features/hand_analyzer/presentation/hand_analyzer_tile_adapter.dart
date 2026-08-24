/// Presentation state for selecting a physical 13- or 14-tile hand.
///
/// TileZhan's engine IDs, `tiles.json` IDs, and SVG filenames intentionally
/// share the same canonical IDs (`m1`..`z7`). Keeping that contract here makes
/// the picker testable without duplicating or translating tile identities.
class HandAnalyzerTileCatalog {
  HandAnalyzerTileCatalog._();

  static const manTileIds = <String>[
    'm1',
    'm2',
    'm3',
    'm4',
    'm5',
    'm6',
    'm7',
    'm8',
    'm9',
  ];

  static const pinTileIds = <String>[
    'p1',
    'p2',
    'p3',
    'p4',
    'p5',
    'p6',
    'p7',
    'p8',
    'p9',
  ];

  static const souTileIds = <String>[
    's1',
    's2',
    's3',
    's4',
    's5',
    's6',
    's7',
    's8',
    's9',
  ];

  static const honorTileIds = <String>[
    'z1',
    'z2',
    'z3',
    'z4',
    'z5',
    'z6',
    'z7',
  ];

  static const allTileIds = <String>[
    ...manTileIds,
    ...pinTileIds,
    ...souTileIds,
    ...honorTileIds,
  ];

  static bool contains(String tileId) => allTileIds.contains(tileId);

  static int compare(String left, String right) =>
      allTileIds.indexOf(left).compareTo(allTileIds.indexOf(right));
}

/// Why a tile could not be appended to the selected hand.
enum HandAnalyzerSelectionIssue {
  unsupportedTile,
  fourCopyLimit,
  handFull,
}

/// Result of attempting to append one tile.
class HandAnalyzerSelectionUpdate {
  const HandAnalyzerSelectionUpdate({
    required this.selection,
    this.issue,
  });

  final HandAnalyzerSelection selection;
  final HandAnalyzerSelectionIssue? issue;

  bool get added => issue == null;
}

/// Immutable, physically-valid presentation state for a hand being entered.
class HandAnalyzerSelection {
  HandAnalyzerSelection._(List<String> tileIds)
      : tileIds = List<String>.unmodifiable(tileIds);

  factory HandAnalyzerSelection.empty() => HandAnalyzerSelection._(<String>[]);

  factory HandAnalyzerSelection.fromTileIds(Iterable<String> tileIds) {
    final sorted = List<String>.of(tileIds);
    if (sorted.length > maximumTileCount) {
      throw ArgumentError.value(
        sorted.length,
        'tileIds.length',
      );
    }

    final counts = <String, int>{};
    for (final tileId in sorted) {
      if (!HandAnalyzerTileCatalog.contains(tileId)) {
        throw ArgumentError.value(tileId, 'tileIds');
      }
      final nextCount = (counts[tileId] ?? 0) + 1;
      if (nextCount > maximumCopiesPerTile) {
        throw ArgumentError.value(
          tileId,
          'tileIds',
        );
      }
      counts[tileId] = nextCount;
    }

    sorted.sort(HandAnalyzerTileCatalog.compare);
    return HandAnalyzerSelection._(sorted);
  }

  static const minimumTileCount = 13;
  static const maximumTileCount = 14;
  static const maximumCopiesPerTile = 4;

  final List<String> tileIds;

  int get count => tileIds.length;

  /// The next meaningful count displayed by the picker.
  int get targetCount => count <= minimumTileCount
      ? minimumTileCount
      : maximumTileCount;

  bool get canAnalyze =>
      count == minimumTileCount || count == maximumTileCount;

  bool get isFull => count == maximumTileCount;

  int copiesOf(String tileId) =>
      tileIds.where((id) => id == tileId).length;

  HandAnalyzerSelectionUpdate add(String tileId) {
    if (!HandAnalyzerTileCatalog.contains(tileId)) {
      return HandAnalyzerSelectionUpdate(
        selection: this,
        issue: HandAnalyzerSelectionIssue.unsupportedTile,
      );
    }
    if (isFull) {
      return HandAnalyzerSelectionUpdate(
        selection: this,
        issue: HandAnalyzerSelectionIssue.handFull,
      );
    }
    if (copiesOf(tileId) >= maximumCopiesPerTile) {
      return HandAnalyzerSelectionUpdate(
        selection: this,
        issue: HandAnalyzerSelectionIssue.fourCopyLimit,
      );
    }

    final next = <String>[...tileIds, tileId]
      ..sort(HandAnalyzerTileCatalog.compare);
    return HandAnalyzerSelectionUpdate(
      selection: HandAnalyzerSelection._(next),
    );
  }

  HandAnalyzerSelection removeAt(int index) {
    RangeError.checkValidIndex(index, tileIds, 'index');
    final next = List<String>.of(tileIds)..removeAt(index);
    return HandAnalyzerSelection._(next);
  }

  HandAnalyzerSelection clear() => HandAnalyzerSelection.empty();
}
