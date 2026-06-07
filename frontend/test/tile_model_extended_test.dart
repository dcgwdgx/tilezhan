import 'package:flutter_test/flutter_test.dart';
import 'package:tilezhan/shared/models/tile_model.dart';

void main() {
  group('TileModel extended', () {
    test('all suits have correct color values', () {
      final colors = {
        TileSuit.man: 0xFFE74C3C,
        TileSuit.pin: 0xFF3498DB,
        TileSuit.sou: 0xFF2ECC71,
        TileSuit.wind: 0xFFF39C12,
        TileSuit.dragon: 0xFF9B59B6,
      };
      for (final entry in colors.entries) {
        expect(
          TileModel.fromJson({
            'id': 'x', 'suit': entry.key.name, 'character': '', 'seal': '',
            'value': 0, 'label': '',
            'mnemonic': <String, dynamic>{}, 'confused_with': <String>[],
          }).suitColor.value,
          entry.value,
        );
      }
    });

    test('value can be int or string', () {
      final withInt = TileModel.fromJson({
        'id': 'm5', 'suit': 'man', 'character': '五', 'seal': '萬',
        'value': 5, 'label': '5-Man',
        'mnemonic': <String, dynamic>{}, 'confused_with': <String>[],
      });
      expect(withInt.value, 5);

      final withStr = TileModel.fromJson({
        'id': 'z1', 'suit': 'wind', 'character': '東', 'seal': '風',
        'value': 'E', 'label': 'East',
        'mnemonic': <String, dynamic>{}, 'confused_with': <String>[],
      });
      expect(withStr.value, 'E');
    });

    test('confusedWith defaults to empty list', () {
      final tile = TileModel.fromJson({
        'id': 'm1', 'suit': 'man', 'character': '一', 'seal': '萬',
        'value': 1, 'label': '1-Man',
        'mnemonic': <String, dynamic>{},
      });
      expect(tile.confusedWith, isEmpty);
    });
  });

  group('MnemonicData', () {
    test('fromJson with empty map has empty strings', () {
      final m = MnemonicData.fromJson({});
      expect(m.emoji, '');
      expect(m.name, '');
      expect(m.slogan, '');
    });

    test('fromJson preserves all fields', () {
      final json = <String, dynamic>{
        'emoji': '🏖️', 'name': 'Lawn Chair', 'slogan': 'Max relaxation!',
        'desc': 'A story', 'chinese': '中文', 'anchor': 'Anchor',
      };
      final m = MnemonicData.fromJson(json);
      expect(m.emoji, '🏖️');
      expect(m.name, 'Lawn Chair');
      expect(m.slogan, 'Max relaxation!');
      expect(m.desc, 'A story');
      expect(m.chinese, '中文');
      expect(m.anchor, 'Anchor');
    });
  });
}
