/// NanikiruNotifier 的 Riverpod 状态管理测试
/// 测试覆盖：初始化题目、倒计时、选牌交互（单击选择/双击确认）、正确/错误答案判定
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilezhan/core/providers/tile_data_provider.dart';
import 'package:tilezhan/features/nanikiru/domain/nanikiru_provider.dart';
import 'package:tilezhan/features/nanikiru/domain/nanikiru_state.dart';
import 'package:tilezhan/shared/models/tile_model.dart';
import 'test_utils.dart';
import 'flashcard_provider_test.dart' show StubTileRepo;

/// 创建注入了 StubTileRepo 的 ProviderContainer（含全部 34 种牌）
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
    // 构建全部 34 种牌，确保 PuzzleGenerator 有完整的牌池
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

  /// NanikiruNotifier 核心逻辑测试组：覆盖题目生成、倒计时、选牌交互、正确/错误判定
  group('NanikiruNotifier', () {
    // initPuzzle 生成 14 张手牌并重置所有状态
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

    // tickCountdown 按传入的增量减少倒计时
    test('tickCountdown decreases value', () async {
      final container = _nanikiruContainer(tiles);
      final notifier = container.read(nanikiruProvider.notifier);
      await notifier.initPuzzle();

      notifier.tickCountdown(1.0);
      expect(container.read(nanikiruProvider).countdownValue, closeTo(9.0, 0.01));
    });

    // 倒计时归零时自动确认打出（超时判错）
    test('tickCountdown to 0 auto-confirms', () async {
      final container = _nanikiruContainer(tiles);
      final notifier = container.read(nanikiruProvider.notifier);
      await notifier.initPuzzle();

      notifier.tickCountdown(10.0);
      expect(container.read(nanikiruProvider).isFinished, true);
    });

    // 第一次点击牌：选中该牌，进入选择阶段
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

    // 第二次点击同一张牌：确认打出该牌
    test('onTileTapped same tile twice confirms discard', () async {
      final container = _nanikiruContainer(tiles);
      final notifier = container.read(nanikiruProvider.notifier);
      await notifier.initPuzzle();

      final firstTileId = container.read(nanikiruProvider).handTiles[0].id;
      notifier.onTileTapped(firstTileId);
      notifier.onTileTapped(firstTileId);

      expect(container.read(nanikiruProvider).isFinished, true);
    });

    // 在 feedback 阶段点击牌应被忽略
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

    // 打出正确答案时 isPerfect 为 true
    test('confirmDiscard with correct answer sets isPerfect true', () async {
      final container = _nanikiruContainer(tiles);
      final notifier = container.read(nanikiruProvider.notifier);
      await notifier.initPuzzle();

      final correctId = container.read(nanikiruProvider).correctDiscardId;
      notifier.confirmDiscard(correctId);

      final state = container.read(nanikiruProvider);
      expect(state.isPerfect, true);
    });

    // 打出错误答案时 isPerfect 为 false
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
