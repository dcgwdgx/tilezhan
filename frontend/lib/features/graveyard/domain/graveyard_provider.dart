/// Providers for the Graveyard (墓地) feature — the "wrong-answer graveyard"
/// screen where users review due SRS items across all suits and view
/// per-suit error-rate analytics via a radar chart.
///
/// Two providers are exposed:
/// - [graveyardDueProvider] — pairs each due [SrsItem] with its [TileModel]
///   for display in the graveyard review list.
/// - [suitErrorRatesProvider] — aggregates error rates by mahjong suit
///   (man, pin, sou, wind, dragon) for the radar chart.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/srs/srs_item.dart';
import '../../../core/srs/srs_provider.dart';
import '../../../core/providers/tile_data_provider.dart';
import '../../../shared/models/tile_model.dart';

/// Pairs each due [SrsItem] with its corresponding [TileModel] for display
/// on the Graveyard review screen.
///
/// Watches [dueItemsProvider] and [tileDataProvider] to produce a list of
/// `(SrsItem, TileModel?)` tuples. A `null` tile means the backing tile was
/// deleted or could not be resolved — callers should handle this gracefully
/// (e.g. skip the row or show a placeholder).
final graveyardDueProvider = Provider<List<(SrsItem, TileModel?)>>((ref) {
  final dueItems = ref.watch(dueItemsProvider);
  final tilesAsync = ref.watch(tileDataProvider);
  final tiles = tilesAsync.valueOrNull ?? [];
  final result = <(SrsItem, TileModel?)>[];
  for (final item in dueItems) {
    TileModel? tile;
    try { tile = tiles.firstWhere((t) => t.id == item.itemId); } catch (_) { tile = null; }
    result.add((item, tile));
  }
  return result;
});

/// Computes per-suit error rates for the Graveyard radar chart.
///
/// Iterates over all flashcard-type [SrsItem]s and groups error counts by
/// mahjong suit (man, pin, sou, wind, dragon). The error rate for each suit
/// is `errors / (repetitions + 1)`. Suits with no flashcard data default to 0.0.
final suitErrorRatesProvider = Provider<Map<String, double>>((ref) {
  final itemsAsync = ref.watch(srsItemsProvider);
  final items = itemsAsync.valueOrNull ?? {};
  final tilesAsync = ref.watch(tileDataProvider);
  final tiles = tilesAsync.valueOrNull ?? [];
  final errorsBySuit = <String, int>{};
  final totalBySuit = <String, int>{};

  for (final item in items.values) {
    if (item.type != 'flashcard') continue;
    TileModel? tile;
    try { tile = tiles.firstWhere((t) => t.id == item.itemId); } catch (_) { continue; }
    final suit = tile.suit.name;
    totalBySuit[suit] = (totalBySuit[suit] ?? 0) + (item.reps + 1);
    errorsBySuit[suit] = (errorsBySuit[suit] ?? 0) + item.errors;
  }

  return {
    for (final s in ['man', 'pin', 'sou', 'wind', 'dragon'])
      s: totalBySuit.containsKey(s)
          ? (errorsBySuit[s] ?? 0) / (totalBySuit[s] ?? 1)
          : 0.0,
  };
});
