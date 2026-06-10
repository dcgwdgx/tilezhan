import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilezhan/core/providers/tile_data_provider.dart';
import 'package:tilezhan/features/nanikiru/domain/nanikiru_provider.dart';
import 'package:tilezhan/features/nanikiru/domain/nanikiru_state.dart';
import 'package:tilezhan/shared/models/tile_model.dart';
import 'test_utils.dart';
import 'flashcard_provider_test.dart' show StubTileRepo;

ProviderContainer _nanikiruContainer(List<TileModel> tiles) {
  final container = ProviderContainer(overrides: [
    tileRepositoryProvider.overrideWithValue(StubTileRepo(tiles)),
  ]);
  addTearDown(container.dispose);
  return container;
}

void main() {
  late List<TileModel> tiles;

  setUp(() {
    // Build all 34 tiles so PuzzleGenerator has full coverage
    final suits = ['m','p','s','z'];
    tiles = [];
    for (final s in suits) {
      final count = s == 'z' ? 7 : 9;
      for (var n = 1; n <= count; n++) {
        final id = '$s$n';
        tiles.add(makeTile(id, TileSuit.values[suits.indexOf(s)], id));
      }
    }
  });

  group('NanikiruNotifier', () {
    test('initPuzzle populates hand and state', () async {
      final container = _nanikiruContainer(tiles);
      final notifier = container.read(nanikiruProvider.notifier);

      await notifier.initPuzzle();

      final state = container.read(nanikiruProvider);
      expect(state.handTiles, isNotEmpty);
      expect(state.handTiles.length, 14);
      expect(state.phase, NaniKiruPhase.ready);
      expect(state.countdownValue, 10.0);
      expect(state.isFinished, false);
      expect(state.correctDiscardId, isNotEmpty);
      expect(state.puzzleId, contains('nanikiru'));
    });

    test('tickCountdown decreases value', () async {
      final container = _nanikiruContainer(tiles);
      final notifier = container.read(nanikiruProvider.notifier);
      await notifier.initPuzzle();

      notifier.tickCountdown(1.0);
      expect(container.read(nanikiruProvider).countdownValue, closeTo(9.0, 0.01));
    });

    test('tickCountdown to 0 auto-confirms', () async {
      final container = _nanikiruContainer(tiles);
      final notifier = container.read(nanikiruProvider.notifier);
      await notifier.initPuzzle();

      notifier.tickCountdown(10.0);
      expect(container.read(nanikiruProvider).isFinished, true);
    });

    test('onTileTapped selects tile on first tap', () async {
      final container = _nanikiruContainer(tiles);
      final notifier = container.read(nanikiruProvider.notifier);
      await notifier.initPuzzle();

      final firstTileId = container.read(nanikiruProvider).handTiles[0].id;
      notifier.onTileTapped(firstTileId);

      final state = container.read(nanikiruProvider);
      expect(state.selectedTileId, firstTileId);
      expect(state.phase, NaniKiruPhase.selecting);
    });

    test('onTileTapped same tile twice confirms discard', () async {
      final container = _nanikiruContainer(tiles);
      final notifier = container.read(nanikiruProvider.notifier);
      await notifier.initPuzzle();

      final firstTileId = container.read(nanikiruProvider).handTiles[0].id;
      notifier.onTileTapped(firstTileId);
      notifier.onTileTapped(firstTileId);

      expect(container.read(nanikiruProvider).isFinished, true);
    });

    test('onTileTapped ignored during feedback phase', () async {
      final container = _nanikiruContainer(tiles);
      final notifier = container.read(nanikiruProvider.notifier);
      await notifier.initPuzzle();

      final firstTileId = container.read(nanikiruProvider).handTiles[0].id;
      notifier.onTileTapped(firstTileId);
      notifier.onTileTapped(firstTileId);

      final secondTileId = container.read(nanikiruProvider).handTiles[1].id;
      notifier.onTileTapped(secondTileId);

      expect(container.read(nanikiruProvider).isFinished, true);
    });

    test('confirmDiscard with correct answer sets isPerfect true', () async {
      final container = _nanikiruContainer(tiles);
      final notifier = container.read(nanikiruProvider.notifier);
      await notifier.initPuzzle();

      final correctId = container.read(nanikiruProvider).correctDiscardId;
      notifier.confirmDiscard(correctId);

      final state = container.read(nanikiruProvider);
      expect(state.isPerfect, true);
    });

    test('confirmDiscard with wrong answer sets isPerfect false', () async {
      final container = _nanikiruContainer(tiles);
      final notifier = container.read(nanikiruProvider.notifier);
      await notifier.initPuzzle();

      final correctId = container.read(nanikiruProvider).correctDiscardId;
      // Pick any other tile in hand as wrong answer
      final wrongId = container.read(nanikiruProvider).handTiles
          .map((t) => t.id)
          .firstWhere((id) => id != correctId);
      notifier.confirmDiscard(wrongId);

      final state = container.read(nanikiruProvider);
      expect(state.isPerfect, false);
    });
  });
}
