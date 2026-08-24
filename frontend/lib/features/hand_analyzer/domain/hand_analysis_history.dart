import 'dart:math' as math;

import '../../../shared/engine/shanten_calculator.dart';

/// One locally saved hand-analyzer input.
///
/// Only the user's input is persisted. Shanten, effective tiles, and discard
/// candidates are deliberately absent so reopening a record always recomputes
/// them with the current rules engine.
class HandAnalysisRecord {
  HandAnalysisRecord({
    required String id,
    required List<String> tileIds,
    required int createdAt,
    String? title,
    this.isFavorite = false,
  })  : id = _validateId(id),
        tileIds = _validateTileIds(tileIds),
        createdAt = _validateCreatedAt(createdAt),
        title = _normalizeTitle(title);

  static const maximumTitleLength = 120;

  final String id;
  final List<String> tileIds;
  final int createdAt;
  final String? title;
  final bool isFavorite;

  /// Order-independent identity for one physical hand.
  ///
  /// The UI may preserve draw order, but the same tiles entered in a different
  /// order must still be one recent analysis.
  String get handSignature {
    final canonical = List<String>.from(tileIds)..sort(_compareTileIds);
    return canonical.join(',');
  }

  HandAnalysisRecord refreshed({
    required int createdAt,
    String? title,
  }) {
    return HandAnalysisRecord(
      id: id,
      tileIds: tileIds,
      createdAt: math.max(this.createdAt, createdAt),
      title: title ?? this.title,
      isFavorite: isFavorite,
    );
  }

  HandAnalysisRecord withFavorite(bool value) => HandAnalysisRecord(
        id: id,
        tileIds: tileIds,
        createdAt: createdAt,
        title: title,
        isFavorite: value,
      );

  HandAnalysisRecord withTitle(String? value) => HandAnalysisRecord(
        id: id,
        tileIds: tileIds,
        createdAt: createdAt,
        title: value,
        isFavorite: isFavorite,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'tileIds': List<String>.from(tileIds),
        'createdAt': createdAt,
        if (title != null) 'title': title,
        'isFavorite': isFavorite,
      };

  /// Parses one record without allowing a malformed sibling to break a file.
  static HandAnalysisRecord? tryFromJson(Object? value) {
    if (value is! Map) return null;

    try {
      final json = Map<String, dynamic>.from(value);
      final rawId = json['id'];
      final rawTileIds = json['tileIds'];
      final rawCreatedAt = json['createdAt'];
      if (rawId is! String || rawTileIds is! List || rawCreatedAt is! num) {
        return null;
      }
      if (!rawCreatedAt.isFinite || rawCreatedAt != rawCreatedAt.toInt()) {
        return null;
      }
      if (rawTileIds.any((tileId) => tileId is! String)) return null;

      // Optional-field damage should not destroy an otherwise valid hand.
      final rawTitle = json['title'];
      final parsedTitle = rawTitle is String &&
              rawTitle.trim().runes.length <= maximumTitleLength
          ? rawTitle
          : null;

      return HandAnalysisRecord(
        id: rawId,
        tileIds: List<String>.from(rawTileIds),
        createdAt: rawCreatedAt.toInt(),
        title: parsedTitle,
        isFavorite:
            json['isFavorite'] is bool ? json['isFavorite'] as bool : false,
      );
    } on Object {
      return null;
    }
  }

  static String _validateId(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty || normalized.length > 128) {
      throw ArgumentError.value(value, 'id', 'Expected 1 to 128 characters');
    }
    return normalized;
  }

  static List<String> _validateTileIds(List<String> value) {
    if (value.length != 13 && value.length != 14) {
      throw ArgumentError.value(
        value.length,
        'tileIds.length',
        'Expected exactly 13 or 14 tiles',
      );
    }

    final snapshot = List<String>.unmodifiable(value);
    // This is the engine's authoritative ID and four-copy validation path.
    // Calling fromIds does not calculate or persist an analysis result.
    ShantenCalculator.fromIds(snapshot);
    return snapshot;
  }

  static int _validateCreatedAt(int value) {
    if (value < 0) {
      throw ArgumentError.value(value, 'createdAt', 'Cannot be negative');
    }
    return value;
  }

  static String? _normalizeTitle(String? value) {
    if (value == null) return null;
    final normalized = value.trim();
    if (normalized.isEmpty) return null;
    if (normalized.runes.length > maximumTitleLength) {
      throw ArgumentError.value(
        value,
        'title',
        'Cannot exceed $maximumTitleLength characters',
      );
    }
    return normalized;
  }

  static int _compareTileIds(String left, String right) {
    final bySuit = _suitIndex(left[0]).compareTo(_suitIndex(right[0]));
    if (bySuit != 0) return bySuit;
    return int.parse(left[1]).compareTo(int.parse(right[1]));
  }

  static int _suitIndex(String suit) => switch (suit) {
        'm' => 0,
        'p' => 1,
        's' => 2,
        'z' => 3,
        _ => 4,
      };
}

/// Versioned local library backing recent analyses and favorite hands.
class HandAnalysisHistory {
  HandAnalysisHistory._(List<HandAnalysisRecord> records)
      : records = List<HandAnalysisRecord>.unmodifiable(_normalize(records));

  static const schemaVersion = 1;

  /// Recent history is intentionally small and device-local.
  static const maximumRecentRecords = 20;

  /// Favorites are protected from ordinary recent-history eviction.
  static const maximumFavoriteRecords = 20;

  factory HandAnalysisHistory.empty() => HandAnalysisHistory._(const []);

  factory HandAnalysisHistory.fromRecords(
    Iterable<HandAnalysisRecord> records,
  ) {
    return HandAnalysisHistory._(List<HandAnalysisRecord>.from(records));
  }

  /// Retained union of the newest 20 records and newest 20 favorites.
  final List<HandAnalysisRecord> records;

  List<HandAnalysisRecord> get recent => List.unmodifiable(
        records.take(maximumRecentRecords),
      );

  List<HandAnalysisRecord> get favorites => List.unmodifiable(
        records
            .where((record) => record.isFavorite)
            .take(maximumFavoriteRecords),
      );

  HandAnalysisRecord? recordById(String id) {
    for (final record in records) {
      if (record.id == id) return record;
    }
    return null;
  }

  /// Adds a recent input, or moves the same physical hand to the front.
  ///
  /// Duplicate detection ignores tile order. An existing favorite and title
  /// survive a repeated analysis. No calculated result is accepted here.
  HandAnalysisHistory recordAnalysis({
    required List<String> tileIds,
    required int createdAt,
    String? title,
    String? id,
  }) {
    final validated = HandAnalysisRecord(
      id: id ?? 'pending-generated-id',
      tileIds: tileIds,
      createdAt: createdAt,
      title: title,
    );
    final proposed = id == null
        ? HandAnalysisRecord(
            id: _newId(validated.tileIds, createdAt),
            tileIds: validated.tileIds,
            createdAt: validated.createdAt,
            title: validated.title,
          )
        : validated;
    final duplicate = _recordBySignature(proposed.handSignature);
    if (duplicate != null) {
      return _replace(
        duplicate.refreshed(createdAt: createdAt, title: title),
      );
    }

    var unique = proposed;
    var suffix = 1;
    while (recordById(unique.id) != null) {
      unique = HandAnalysisRecord(
        id: '${proposed.id}-$suffix',
        tileIds: proposed.tileIds,
        createdAt: proposed.createdAt,
        title: proposed.title,
      );
      suffix += 1;
    }
    return HandAnalysisHistory.fromRecords([unique, ...records]);
  }

  HandAnalysisHistory setFavorite(String id, bool isFavorite) {
    final existing = recordById(id);
    if (existing == null || existing.isFavorite == isFavorite) return this;
    return _replace(existing.withFavorite(isFavorite));
  }

  HandAnalysisHistory rename(String id, String? title) {
    final existing = recordById(id);
    if (existing == null) return this;
    return _replace(existing.withTitle(title));
  }

  HandAnalysisHistory remove(String id) => HandAnalysisHistory.fromRecords(
        records.where((record) => record.id != id),
      );

  /// Clears ordinary recents while preserving favorite hands.
  HandAnalysisHistory clearRecent() => HandAnalysisHistory.fromRecords(
        records.where((record) => record.isFavorite),
      );

  /// Removes favorite markers, then keeps only the normal recent limit.
  HandAnalysisHistory clearFavorites() => HandAnalysisHistory.fromRecords(
        records.map((record) => record.withFavorite(false)),
      );

  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'records': records.map((record) => record.toJson()).toList(),
      };

  factory HandAnalysisHistory.fromJson(Map<String, dynamic> json) {
    final rawVersion = json['schemaVersion'];
    if (rawVersion is! num ||
        !rawVersion.isFinite ||
        rawVersion.toInt() != schemaVersion ||
        rawVersion != rawVersion.toInt()) {
      return HandAnalysisHistory.empty();
    }

    final rawRecords = json['records'];
    if (rawRecords is! List) return HandAnalysisHistory.empty();

    final validRecords = <HandAnalysisRecord>[];
    for (final rawRecord in rawRecords) {
      final record = HandAnalysisRecord.tryFromJson(rawRecord);
      if (record != null) validRecords.add(record);
    }
    return HandAnalysisHistory.fromRecords(validRecords);
  }

  HandAnalysisRecord? _recordBySignature(String signature) {
    for (final record in records) {
      if (record.handSignature == signature) return record;
    }
    return null;
  }

  HandAnalysisHistory _replace(HandAnalysisRecord replacement) {
    return HandAnalysisHistory.fromRecords([
      replacement,
      ...records.where((record) => record.id != replacement.id),
    ]);
  }

  static List<HandAnalysisRecord> _normalize(
    List<HandAnalysisRecord> input,
  ) {
    final sorted = List<HandAnalysisRecord>.from(input)
      ..sort((left, right) {
        final byCreatedAt = right.createdAt.compareTo(left.createdAt);
        if (byCreatedAt != 0) return byCreatedAt;
        return left.id.compareTo(right.id);
      });

    final bySignature = <String, HandAnalysisRecord>{};
    final seenIds = <String>{};
    for (final record in sorted) {
      if (!seenIds.add(record.id)) continue;
      final existing = bySignature[record.handSignature];
      if (existing == null) {
        bySignature[record.handSignature] = record;
        continue;
      }

      // Keep the newest identity and timestamp, while salvaging user-authored
      // favorite/title data from an older duplicate if necessary.
      var merged = existing;
      if (!merged.isFavorite && record.isFavorite) {
        merged = merged.withFavorite(true);
      }
      if (merged.title == null && record.title != null) {
        merged = merged.withTitle(record.title);
      }
      bySignature[record.handSignature] = merged;
    }

    final unique = bySignature.values.toList()
      ..sort((left, right) {
        final byCreatedAt = right.createdAt.compareTo(left.createdAt);
        if (byCreatedAt != 0) return byCreatedAt;
        return left.id.compareTo(right.id);
      });

    final retainedIds = <String>{
      ...unique.take(maximumRecentRecords).map((record) => record.id),
      ...unique
          .where((record) => record.isFavorite)
          .take(maximumFavoriteRecords)
          .map((record) => record.id),
    };
    return unique.where((record) => retainedIds.contains(record.id)).toList();
  }

  static String _newId(List<String> tileIds, int createdAt) {
    final canonical = List<String>.from(tileIds)
      ..sort(HandAnalysisRecord._compareTileIds);
    var hash = 0x811c9dc5;
    for (final codeUnit in canonical.join(',').codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return 'hand-$createdAt-${hash.toRadixString(16).padLeft(8, '0')}';
  }
}
