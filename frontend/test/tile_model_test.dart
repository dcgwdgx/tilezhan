import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilezhan/shared/models/tile_model.dart';

void main() {
  group('TileModel', () {
    test('fromJson parses m5 correctly', () {
      final json = {
        'id': 'm5', 'suit': 'man', 'character': '五', 'seal': '萬',
        'value': 5, 'label': '5-Man',
        'mnemonic': {
          'emoji': '🏖️', 'name': 'The Lawn Chair', 'slogan': 'Max relaxation!',
          'desc': 'Lounging on a 5-shaped folding beach chair...',
          'chinese': '外卖小哥在车座上焊接了...', 'anchor': '🧹 Wand-Scooter',
        },
        'confused_with': ['m4', 'm6', 'p5'],
      };
      final tile = TileModel.fromJson(json);
      expect(tile.id, 'm5');
      expect(tile.suit, TileSuit.man);
      expect(tile.character, '五');
      expect(tile.mnemonic.emoji, '🏖️');
      expect(tile.confusedWith, ['m4', 'm6', 'p5']);
    });

    test('suitColor returns correct colors', () {
      final man = TileModel.fromJson({
        'id':'m1','suit':'man','character':'一','seal':'萬','value':1,'label':'1-Man',
        'mnemonic':{},'confused_with':[],
      });
      expect(man.suitColor.value, 0xFFE74C3C);

      final pin = TileModel.fromJson({
        'id':'p1','suit':'pin','character':'一','seal':'筒','value':1,'label':'1-Pin',
        'mnemonic':{},'confused_with':[],
      });
      expect(pin.suitColor.value, 0xFF3498DB);
    });
  });
}
