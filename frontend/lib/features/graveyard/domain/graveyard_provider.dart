import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/srs/srs_item.dart';
import '../../../core/srs/srs_provider.dart';
import '../../../core/providers/tile_data_provider.dart';
import '../../../shared/models/tile_model.dart';

/// Due SRS items for the Graveyard screen.
final graveyardDueProvider = Provider<List<(SrsItem, TileModel?)>>((ref) {
  final dueItems = ref.watch(dueItemsProvider);
  final tilesAsync = ref.watch(tileDataProvider);
  final tiles = tilesAsync.valueOrNull ?? [];
  final result = <(SrsItem, TileModel?)>[];
  for (final item in dueItems) {
    TileModel? tile;
    try {
      tile = tiles.firstWhere((t) => t.id == item.itemId);
    } catch (_) {
      tile = null;
    }
    result.add((item, tile));
  }
  return result;
});

/// Suit error rates for radar chart.
final suitErrorRatesProvider = Provider<Map<String, double>>((ref) {
  final items = ref.watch(srsItemsProvider);
  final tilesAsync = ref.watch(tileDataProvider);
  final tiles = tilesAsync.valueOrNull ?? [];
  final errorsBySuit = <String, int>{};
  final totalBySuit = <String, int>{};

  for (final item in items.values) {
    if (item.type != 'flashcard') continue;
    TileModel? tile;
    try {
      tile = tiles.firstWhere((t) => t.id == item.itemId);
    } catch (_) {
      continue;
    }
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
