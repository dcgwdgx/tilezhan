/// FlashcardQuizNotifier 的 Riverpod 状态管理测试
/// 测试覆盖：初始化测验、花色过滤、答题记录、幂等性、下一张、助记符显示、重新开始
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilezhan/features/flashcard/domain/flashcard_provider.dart';
import 'package:tilezhan/core/providers/tile_data_provider.dart';
import 'package:tilezhan/shared/data/tile_repository.dart';
import 'package:tilezhan/shared/models/tile_model.dart';
import 'test_utils.dart';

/// 桩 TileRepository，返回预构建的牌列表，不依赖 rootBundle
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

/// 创建注入了 StubTileRepo 的 ProviderContainer
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
    // initQuiz 填充队列并重置所有状态
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

    // 按花色过滤：指定 'man' 后队列中只包含万子牌
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

    // 答对时 correctCount +1，记录最后正确的牌 ID
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

    // 答错时 wrongCount +1，记录最后错误的牌 ID
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

    // 在答题状态中重复调用 submitAnswer 应被忽略（幂等性）
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

    // nextCard 推进索引并重置答题状态
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

    // showMnemonic 仅在已答题状态下才设置标志位
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

    // restart 重新洗牌并重置所有答题进度
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

    // 所有牌答完后 isFinished 为 true
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
