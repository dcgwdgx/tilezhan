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
    test('initial state defaults', () {
      const state = FlashcardQuizState();
      expect(state.queue, isEmpty);
      expect(state.currentIndex, 0);
      expect(state.isAnswering, false);
      expect(state.isShowingMnemonic, false);
      expect(state.isFinished, true);  // empty queue = finished
    });

    test('isFinished true when index >= total', () {
      final tiles = [_t('m1', TileSuit.man), _t('m2', TileSuit.man)];
      final state = FlashcardQuizState(queue: tiles, currentIndex: 2);
      expect(state.isFinished, true);
    });

    test('isFinished false when index < total', () {
      final tiles = [_t('m1', TileSuit.man), _t('m2', TileSuit.man)];
      final state = FlashcardQuizState(queue: tiles, currentIndex: 1);
      expect(state.isFinished, false);
    });

    test('currentTile returns null for empty queue', () {
      const state = FlashcardQuizState();
      expect(state.currentTile, null);
    });

    test('currentTile returns correct tile', () {
      final tiles = [_t('m1', TileSuit.man), _t('m2', TileSuit.man)];
      final state = FlashcardQuizState(queue: tiles, currentIndex: 1);
      expect(state.currentTile?.id, 'm2');
    });

    test('progress returns fraction', () {
      final tiles = [_t('m1', TileSuit.man), _t('m2', TileSuit.man)];
      final state = FlashcardQuizState(queue: tiles, currentIndex: 1);
      expect(state.progress, 0.5);
    });

    test('progress returns 0 for empty', () {
      const state = FlashcardQuizState();
      expect(state.progress, 0);
    });

    test('copyWith creates correct partial update', () {
      final state = FlashcardQuizState(suite: 'man');
      final next = state.copyWith(currentIndex: 3, correctCount: 2);
      expect(next.suite, 'man');
      expect(next.currentIndex, 3);
      expect(next.correctCount, 2);
    });

    test('correctCount and wrongCount track independently', () {
      final state = FlashcardQuizState(correctCount: 7, wrongCount: 3);
      expect(state.correctCount, 7);
      expect(state.wrongCount, 3);
    });
  });
}
