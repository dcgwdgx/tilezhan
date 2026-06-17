/// FlashcardQuizState 不可变状态类的单元测试
/// 测试覆盖：初始默认值、进度计算、当前牌获取、copyWith 部分更新
import 'package:flutter_test/flutter_test.dart';
import 'package:tilezhan/features/flashcard/domain/flashcard_state.dart';
import 'package:tilezhan/shared/models/tile_model.dart';

TileModel _t(String id, TileSuit suit) => TileModel(
  id: id, suit: suit, character: id, seal: '', value: 1, label: id,
  mnemonic: const MnemonicData(emoji: '', name: '', slogan: '', desc: '', chinese: '', anchor: ''),
  confusedWith: const [],
);

void main() {
  group('FlashcardQuizState', () {
    // 验证初始状态默认值：队列为空、未在答题、未显示助记符
    test('initial state defaults', () {
      const state = FlashcardQuizState();
      expect(state.queue, isEmpty);
      expect(state.currentIndex, 0);
      expect(state.isAnswering, false);
      expect(state.isShowingMnemonic, false);
      expect(state.isFinished, true);  // empty queue = finished
    });

    // 当前索引 >= 总牌数时，测验结束
    test('isFinished true when index >= total', () {
      final tiles = [_t('m1', TileSuit.man), _t('m2', TileSuit.man)];
      final state = FlashcardQuizState(queue: tiles, currentIndex: 2);
      expect(state.isFinished, true);
    });

    // 当前索引 < 总牌数时，测验进行中
    test('isFinished false when index < total', () {
      final tiles = [_t('m1', TileSuit.man), _t('m2', TileSuit.man)];
      final state = FlashcardQuizState(queue: tiles, currentIndex: 1);
      expect(state.isFinished, false);
    });

    // 空队列时 currentTile 返回 null
    test('currentTile returns null for empty queue', () {
      const state = FlashcardQuizState();
      expect(state.currentTile, null);
    });

    // 根据当前索引返回正确的牌
    test('currentTile returns correct tile', () {
      final tiles = [_t('m1', TileSuit.man), _t('m2', TileSuit.man)];
      final state = FlashcardQuizState(queue: tiles, currentIndex: 1);
      expect(state.currentTile?.id, 'm2');
    });

    // 进度计算：当前索引 / 总牌数
    test('progress returns fraction', () {
      final tiles = [_t('m1', TileSuit.man), _t('m2', TileSuit.man)];
      final state = FlashcardQuizState(queue: tiles, currentIndex: 1);
      expect(state.progress, 0.5);
    });

    // 空队列时进度为 0
    test('progress returns 0 for empty', () {
      const state = FlashcardQuizState();
      expect(state.progress, 0);
    });

    // copyWith 只更新指定字段，其他字段保持原值
    test('copyWith creates correct partial update', () {
      final state = FlashcardQuizState(suite: 'man');
      final next = state.copyWith(currentIndex: 3, correctCount: 2);
      expect(next.suite, 'man');
      expect(next.currentIndex, 3);
      expect(next.correctCount, 2);
    });

    // 正确计数和错误计数独立追踪
    test('correctCount and wrongCount track independently', () {
      final state = FlashcardQuizState(correctCount: 7, wrongCount: 3);
      expect(state.correctCount, 7);
      expect(state.wrongCount, 3);
    });
  });
}
