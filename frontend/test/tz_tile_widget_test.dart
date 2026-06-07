import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilezhan/shared/models/tile_model.dart';
import 'package:tilezhan/shared/widgets/tz_tile.dart';

TileModel _makeTile(String id, TileSuit suit, String char, String seal, String label) {
  return TileModel(
    id: id, suit: suit, character: char, seal: seal,
    value: 1, label: label,
    mnemonic: const MnemonicData(emoji: '', name: '', slogan: '', desc: '', chinese: '', anchor: ''),
    confusedWith: const [],
  );
}

void main() {
  group('TzTile widget', () {
    testWidgets('renders character text', (tester) async {
      final tile = _makeTile('m5', TileSuit.man, '五', '萬', '5m');
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: Center(child: TzTile(tile: tile)))),
      );
      expect(find.text('五'), findsOneWidget);
      expect(find.text('萬'), findsOneWidget);
    });

    testWidgets('renders corner label', (tester) async {
      final tile = _makeTile('m5', TileSuit.man, '五', '萬', '5m');
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: Center(child: TzTile(tile: tile)))),
      );
      expect(find.text('5m'), findsOneWidget);
    });

    testWidgets('md lg sizes render without error', (tester) async {
      final tile = _makeTile('m5', TileSuit.man, '五', '萬', '5m');
      for (final size in [TileSize.md, TileSize.lg]) {
        await tester.pumpWidget(
          MaterialApp(home: Scaffold(body: Center(child: TzTile(tile: tile, size: size)))),
        );
        expect(find.text('五'), findsOneWidget);
      }
    });

    testWidgets('selected state applies transform', (tester) async {
      final tile = _makeTile('m5', TileSuit.man, '五', '萬', '5m');
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: Center(
          child: TzTile(tile: tile, state: TileState.selected),
        ))),
      );
      expect(find.text('五'), findsOneWidget);
    });

    testWidgets('dimmed state renders without error', (tester) async {
      final tile = _makeTile('m5', TileSuit.man, '五', '萬', '5m');
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: Center(
          child: TzTile(tile: tile, state: TileState.dimmed),
        ))),
      );
      expect(find.text('五'), findsOneWidget);
    });

    testWidgets('onTap callback fires', (tester) async {
      final tile = _makeTile('m5', TileSuit.man, '五', '萬', '5m');
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: Center(
          child: TzTile(tile: tile, onTap: () => tapped = true),
        ))),
      );
      await tester.tap(find.text('五'));
      expect(tapped, true);
    });

    testWidgets('each suit has different border color', (tester) async {
      final suits = [
        _makeTile('m5', TileSuit.man, '五', '萬', '5m'),
        _makeTile('p5', TileSuit.pin, '五', '筒', '5p'),
        _makeTile('s5', TileSuit.sou, '五', '条', '5s'),
        _makeTile('z1', TileSuit.wind, '東', '風', 'East'),
        _makeTile('z5', TileSuit.dragon, '中', '龍', 'Red'),
      ];
      for (final tile in suits) {
        await tester.pumpWidget(
          MaterialApp(home: Scaffold(body: Center(child: TzTile(tile: tile)))),
        );
        expect(tester.takeException(), isNull);
      }
    });
  });
}
