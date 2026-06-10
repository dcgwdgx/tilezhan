import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilezhan/features/flashcard/domain/flashcard_provider.dart';
import 'package:tilezhan/features/flashcard/domain/flashcard_state.dart';
import 'package:tilezhan/core/providers/tile_data_provider.dart';
import 'package:tilezhan/shared/data/tile_repository.dart';
import 'package:tilezhan/shared/models/tile_model.dart';
import 'test_utils.dart';

/// Stub TileRepository that returns pre-built tiles without rootBundle.
/// Public so other test files can reuse it.
class StubTileRepo extends TileRepository {
  final List<TileModel> tiles;

  StubTileRepo(this.tiles);

  @override
  Future<List<TileModel>> loadAllTiles() async => tiles;

  @override
  TileModel? getById(String id, List<TileModel> tiles) {
    try {
      return tiles.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  List<TileModel> getDistractors(
      TileModel correct, List<TileModel> allTiles, int count) {
    final others =
        allTiles.where((t) => t.id != correct.id).toList()..shuffle();
    return others.take(count).toList();
  }
}

ProviderContainer _container(List<TileModel> tiles) {
  final container = ProviderContainer(overrides: [
    tileRepositoryProvider.overrideWithValue(StubTileRepo(tiles)),
  ]);
  addTearDown(container.dispose);
  return container;
}

void main() {
  late List<TileModel> tiles;

  setUp(() {
    tiles = List.generate(10, (i) => makeTile('m$i', TileSuit.man, '${i + 1}'));
  });

  group('FlashcardQuizNotifier', () {
    test('initQuiz populates queue and resets state', () async {
      final container = _container(tiles);
      final notifier = container.read(flashcardQuizProvider.notifier);

      await notifier.initQuiz(suite: 'man', count: 5);

      final state = container.read(flashcardQuizProvider);
      expect(state.totalCount, 5);
      expect(state.currentIndex, 0);
      expect(state.suite, 'man');
      expect(state.isFinished, false);
      expect(state.currentTile, isNotNull);
    });

    test('initQuiz filters by suite', () async {
      final mixed = [
        ...tiles,
        makeTile('p0', TileSuit.pin, '0'),
        makeTile('s0', TileSuit.sou, '0'),
      ];
      final container = _container(mixed);
      final notifier = container.read(flashcardQuizProvider.notifier);

      await notifier.initQuiz(suite: 'man', count: 20);

      final state = container.read(flashcardQuizProvider);
      // Only man tiles should be in queue
      for (final t in state.queue) {
        expect(t.suit, TileSuit.man);
      }
    });

    test('submitAnswer records correct answer', () async {
      final container = _container(tiles);
      final notifier = container.read(flashcardQuizProvider.notifier);
      await notifier.initQuiz(count: 5);

      notifier.submitAnswer(true);

      final state = container.read(flashcardQuizProvider);
      expect(state.correctCount, 1);
      expect(state.wrongCount, 0);
      expect(state.isAnswering, true);
      expect(state.lastCorrectId, isNotNull);
      expect(state.lastWrongId, isNull);
    });

    test('submitAnswer records wrong answer', () async {
      final container = _container(tiles);
      final notifier = container.read(flashcardQuizProvider.notifier);
      await notifier.initQuiz(count: 5);

      notifier.submitAnswer(false);

      final state = container.read(flashcardQuizProvider);
      expect(state.correctCount, 0);
      expect(state.wrongCount, 1);
      expect(state.lastCorrectId, isNull);
      expect(state.lastWrongId, isNotNull);
    });

    test('submitAnswer is idempotent while answering', () async {
      final container = _container(tiles);
      final notifier = container.read(flashcardQuizProvider.notifier);
      await notifier.initQuiz(count: 5);

      notifier.submitAnswer(true);
      notifier.submitAnswer(true); // second call should be ignored
      notifier.submitAnswer(false); // should also be ignored

      final state = container.read(flashcardQuizProvider);
      expect(state.correctCount, 1);
      expect(state.wrongCount, 0);
    });

    test('nextCard advances and resets answer state', () async {
      final container = _container(tiles);
      final notifier = container.read(flashcardQuizProvider.notifier);
      await notifier.initQuiz(count: 5);

      notifier.submitAnswer(true);
      notifier.nextCard();

      final state = container.read(flashcardQuizProvider);
      expect(state.currentIndex, 1);
      expect(state.isAnswering, false);
      expect(state.isShowingMnemonic, false);
    });

    test('showMnemonic sets flag only when answering', () async {
      final container = _container(tiles);
      final notifier = container.read(flashcardQuizProvider.notifier);
      await notifier.initQuiz(count: 5);

      // Should not show before answering
      notifier.showMnemonic();
      expect(container.read(flashcardQuizProvider).isShowingMnemonic, false);

      // Should show after answering
      notifier.submitAnswer(true);
      notifier.showMnemonic();
      expect(container.read(flashcardQuizProvider).isShowingMnemonic, true);
    });

    test('restart re-shuffles queue', () async {
      final container = _container(tiles);
      final notifier = container.read(flashcardQuizProvider.notifier);
      await notifier.initQuiz(count: 10);

      // Answer 3 questions to advance state
      for (int i = 0; i < 3; i++) {
        notifier.submitAnswer(true);
        notifier.nextCard();
      }

      notifier.restart();

      final state = container.read(flashcardQuizProvider);
      expect(state.currentIndex, 0);
      expect(state.correctCount, 0);
      expect(state.wrongCount, 0);
      expect(state.isAnswering, false);
      expect(state.totalCount, 10);
    });

    test('isFinished true when all cards done', () async {
      final container = _container(tiles);
      final notifier = container.read(flashcardQuizProvider.notifier);
      await notifier.initQuiz(count: 2);

      // Answer both
      notifier.submitAnswer(true);
      notifier.nextCard();
      notifier.submitAnswer(false);
      notifier.nextCard();

      final state = container.read(flashcardQuizProvider);
      expect(state.isFinished, true);
    });
  });
}
