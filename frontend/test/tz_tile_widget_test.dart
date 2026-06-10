import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/svg.dart';
import 'package:tilezhan/shared/models/tile_model.dart';
import 'package:tilezhan/shared/widgets/tz_tile.dart';

TileModel _makeTile(String id, TileSuit suit, String label) {
  return TileModel(
    id: id, suit: suit, character: 'x', seal: 'y',
    value: 1, label: label,
    mnemonic: const MnemonicData(emoji: '', name: '', slogan: '', desc: '', chinese: '', anchor: ''),
    confusedWith: const [],
  );
}

void main() {
  group('TzTile widget', () {
    testWidgets('renders SvgPicture for tile asset', (tester) async {
      final tile = _makeTile('m5', TileSuit.man, '5m');
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: Center(child: TzTile(tile: tile)))),
      );
      // Should contain an SVG widget (renders placeholder in test env)
      expect(find.byType(SvgPicture), findsOneWidget);
    });

    testWidgets('md and lg sizes render without error', (tester) async {
      final tile = _makeTile('m5', TileSuit.man, '5m');
      for (final size in [TileSize.md, TileSize.lg]) {
        await tester.pumpWidget(
          MaterialApp(home: Scaffold(body: Center(child: TzTile(tile: tile, size: size)))),
        );
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('selected state renders without error', (tester) async {
      final tile = _makeTile('m5', TileSuit.man, '5m');
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: Center(
          child: TzTile(tile: tile, state: TileState.selected),
        ))),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('dimmed state renders without error', (tester) async {
      final tile = _makeTile('m5', TileSuit.man, '5m');
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: Center(
          child: TzTile(tile: tile, state: TileState.dimmed),
        ))),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('onTap callback fires', (tester) async {
      final tile = _makeTile('m5', TileSuit.man, '5m');
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: Center(
          child: TzTile(tile: tile, onTap: () => tapped = true),
        ))),
      );
      await tester.tap(find.byType(TzTile));
      expect(tapped, true);
    });

    testWidgets('each suit renders without error', (tester) async {
      final suits = [
        _makeTile('m5', TileSuit.man, '5m'),
        _makeTile('p5', TileSuit.pin, '5p'),
        _makeTile('s5', TileSuit.sou, '5s'),
        _makeTile('z1', TileSuit.wind, 'East'),
        _makeTile('z5', TileSuit.dragon, 'Red'),
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
