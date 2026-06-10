import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilezhan/core/providers/tile_data_provider.dart';
import 'package:tilezhan/features/nanikiru/domain/nanikiru_provider.dart';
import 'package:tilezhan/features/nanikiru/domain/nanikiru_state.dart';
import 'package:tilezhan/shared/data/tile_repository.dart';
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
    // Build enough tiles to cover the demo hand: m1-m9, s7
    tiles = [
      makeTile('m1', TileSuit.man, '1-Man'),
      makeTile('m2', TileSuit.man, '2-Man'),
      makeTile('m3', TileSuit.man, '3-Man'),
      makeTile('m4', TileSuit.man, '4-Man'),
      makeTile('m5', TileSuit.man, '5-Man'),
      makeTile('m6', TileSuit.man, '6-Man'),
      makeTile('m7', TileSuit.man, '7-Man'),
      makeTile('m8', TileSuit.man, '8-Man'),
      makeTile('m9', TileSuit.man, '9-Man'),
      makeTile('s7', TileSuit.sou, '7-Sou'),
    ];
  });

  group('NanikiruNotifier', () {
    test('initPuzzle populates hand and state', () async {
      final container = _nanikiruContainer(tiles);
      final notifier = container.read(nanikiruProvider.notifier);

      await notifier.initPuzzle();

      final state = container.read(nanikiruProvider);
      expect(state.handTiles, isNotEmpty);
      expect(state.handTiles.length, 14); // 13 demo + 1 drawn
      expect(state.phase, NaniKiruPhase.ready);
      expect(state.countdownValue, 10.0);
      expect(state.isFinished, false);
    });

    test('tickCountdown decreases value', () async {
      final container = _nanikiruContainer(tiles);
      final notifier = container.read(nanikiruProvider.notifier);
      await notifier.initPuzzle();

      notifier.tickCountdown(1.0);

      final state = container.read(nanikiruProvider);
      expect(state.countdownValue, closeTo(9.0, 0.01));
    });

    test('tickCountdown to 0 auto-confirms correct answer', () async {
      final container = _nanikiruContainer(tiles);
      final notifier = container.read(nanikiruProvider.notifier);
      await notifier.initPuzzle();

      notifier.tickCountdown(10.0);

      final state = container.read(nanikiruProvider);
      expect(state.isFinished, true);
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
      notifier.onTileTapped(firstTileId); // select
      notifier.onTileTapped(firstTileId); // confirm

      final state = container.read(nanikiruProvider);
      expect(state.isFinished, true);
    });

    test('onTileTapped ignored during feedback phase', () async {
      final container = _nanikiruContainer(tiles);
      final notifier = container.read(nanikiruProvider.notifier);
      await notifier.initPuzzle();

      // Force feedback phase by confirming
      final firstTileId = container.read(nanikiruProvider).handTiles[0].id;
      notifier.onTileTapped(firstTileId);
      notifier.onTileTapped(firstTileId);

      // Try tapping during feedback
      final secondTileId = container.read(nanikiruProvider).handTiles[1].id;
      notifier.onTileTapped(secondTileId);

      // Should still be in feedback
      expect(container.read(nanikiruProvider).isFinished, true);
    });

    test('confirmDiscard correct answer sets isPerfect true', () async {
      final container = _nanikiruContainer(tiles);
      final notifier = container.read(nanikiruProvider.notifier);
      await notifier.initPuzzle();

      notifier.confirmDiscard('m4'); // correct answer for demo

      final state = container.read(nanikiruProvider);
      expect(state.isPerfect, true);
      expect(state.ukeireCount, 11);
      expect(state.ukeireTypes, 3);
    });

    test('confirmDiscard wrong answer sets isPerfect false', () async {
      final container = _nanikiruContainer(tiles);
      final notifier = container.read(nanikiruProvider.notifier);
      await notifier.initPuzzle();

      notifier.confirmDiscard('m1'); // wrong answer

      final state = container.read(nanikiruProvider);
      expect(state.isPerfect, false);
      expect(state.ukeireCount, 4);
    });
  });
}
