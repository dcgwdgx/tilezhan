import 'package:flutter_test/flutter_test.dart';
import 'package:tilezhan/shared/models/tile_model.dart';

void main() {
  group('Nani-Kiru hand sort', () {
    TileModel t(String id, TileSuit suit, int value) => TileModel(
      id: id, suit: suit, character: id, seal: '',
      value: value, label: id,
      mnemonic: const MnemonicData(emoji: '', name: '', slogan: '', desc: '', chinese: '', anchor: ''),
      confusedWith: const [],
    );

    test('sorts by suit then value', () {
      final hand = [
        t('s7', TileSuit.sou, 7),
        t('m1', TileSuit.man, 1),
        t('p5', TileSuit.pin, 5),
        t('m9', TileSuit.man, 9),
        t('z1', TileSuit.wind, 1),
        t('p1', TileSuit.pin, 1),
      ];
      hand.sort((a, b) {
        final suitOrder = a.suit.index.compareTo(b.suit.index);
        if (suitOrder != 0) return suitOrder;
        return (a.value as int).compareTo(b.value as int);
      });
      // Expected order: man, pin, sou, wind
      expect(hand[0].id, 'm1');
      expect(hand[1].id, 'm9');
      expect(hand[2].id, 'p1');
      expect(hand[3].id, 'p5');
      expect(hand[4].id, 's7');
      expect(hand[5].id, 'z1');
    });

    test('same suit sorted by value', () {
      final hand = [
        t('m9', TileSuit.man, 9),
        t('m3', TileSuit.man, 3),
        t('m1', TileSuit.man, 1),
        t('m5', TileSuit.man, 5),
      ];
      hand.sort((a, b) => (a.value as int).compareTo(b.value as int));
      expect(hand[0].id, 'm1');
      expect(hand[3].id, 'm9');
    });
  });
}
