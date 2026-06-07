import 'package:flutter_test/flutter_test.dart';
import 'package:tilezhan/features/nanikiru/domain/nanikiru_state.dart';
import 'package:tilezhan/shared/models/tile_model.dart';

TileModel _t(String id, TileSuit suit) => TileModel(
  id: id, suit: suit, character: id, seal: '', value: 1, label: id,
  mnemonic: const MnemonicData(emoji: '', name: '', slogan: '', desc: '', chinese: '', anchor: ''),
  confusedWith: const [],
);

void main() {
  group('NaniKiruState', () {
    test('initial state defaults', () {
      const state = NaniKiruState();
      expect(state.handTiles, isEmpty);
      expect(state.phase, NaniKiruPhase.ready);
      expect(state.countdownValue, 10.0);
      expect(state.isFinished, false);
    });

    test('copyWith updates only specified fields', () {
      final tiles = [_t('m1', TileSuit.man)];
      final state = NaniKiruState(handTiles: tiles);
      final next = state.copyWith(phase: NaniKiruPhase.feedback, isPerfect: true, ukeireCount: 11);
      expect(next.handTiles, tiles);
      expect(next.phase, NaniKiruPhase.feedback);
      expect(next.isPerfect, true);
      expect(next.ukeireCount, 11);
    });

    test('copyWith phase=feedback marks isFinished', () {
      final state = NaniKiruState(handTiles: [_t('m1', TileSuit.man)]);
      final next = state.copyWith(phase: NaniKiruPhase.feedback, isPerfect: true);
      expect(next.isFinished, true);
      expect(next.isPerfect, true);
    });

    test('countdownValue copied correctly', () {
      final state = NaniKiruState(countdownValue: 5.0);
      final next = state.copyWith(countdownValue: 3.0);
      expect(next.countdownValue, 3.0);
    });

    test('ukeire fields preserved in copy', () {
      final state = NaniKiruState(
        ukeireCount: 11, ukeireTypes: 3, ukeireTiles: ['2p', '5p'],
      );
      expect(state.ukeireCount, 11);
      expect(state.ukeireTypes, 3);
    });
  });
}
