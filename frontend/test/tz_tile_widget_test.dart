/// TzTile 牌的 Widget 渲染和交互测试
/// 测试覆盖：SVG 渲染、尺寸变体（md/lg）、状态变体（选中/变暗）、点击回调、各花色渲染
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/svg.dart';
import 'package:tilezhan/shared/models/tile_model.dart';
import 'package:tilezhan/shared/widgets/tz_tile.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:tilezhan/l10n/generated/app_localizations.dart';

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
    // 验证牌组件渲染了 SVG 图片资源
    testWidgets('renders SvgPicture for tile asset', (tester) async {
      final tile = _makeTile('m5', TileSuit.man, '5m');
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en')],
          home: Scaffold(body: Center(child: TzTile(tile: tile))),
        ),
      );
      // Should contain an SVG widget (renders placeholder in test env)
      expect(find.byType(SvgPicture), findsOneWidget);
    });

    // 两种尺寸（md 和 lg）都能无异常渲染
    testWidgets('md and lg sizes render without error', (tester) async {
      final tile = _makeTile('m5', TileSuit.man, '5m');
      for (final size in [TileSize.md, TileSize.lg]) {
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: const [Locale('en')],
            home: Scaffold(body: Center(child: TzTile(tile: tile, size: size))),
          ),
        );
        expect(tester.takeException(), isNull);
      }
    });

    // 选中状态能无异常渲染
    testWidgets('selected state renders without error', (tester) async {
      final tile = _makeTile('m5', TileSuit.man, '5m');
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en')],
          home: Scaffold(body: Center(
            child: TzTile(tile: tile, state: TileState.selected),
          )),
        ),
      );
      expect(tester.takeException(), isNull);
    });

    // 变暗状态能无异常渲染（用于表示不能打的牌）
    testWidgets('dimmed state renders without error', (tester) async {
      final tile = _makeTile('m5', TileSuit.man, '5m');
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en')],
          home: Scaffold(body: Center(
            child: TzTile(tile: tile, state: TileState.dimmed),
          )),
        ),
      );
      expect(tester.takeException(), isNull);
    });

    // 点击牌时触发 onTap 回调
    testWidgets('onTap callback fires', (tester) async {
      final tile = _makeTile('m5', TileSuit.man, '5m');
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en')],
          home: Scaffold(body: Center(
            child: TzTile(tile: tile, onTap: () => tapped = true),
          )),
        ),
      );
      await tester.tap(find.byType(TzTile));
      expect(tapped, true);
    });

    // 五种花色（万/筒/索/风/箭）都能无异常渲染
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
          MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: const [Locale('en')],
            home: Scaffold(body: Center(child: TzTile(tile: tile))),
          ),
        );
        expect(tester.takeException(), isNull);
      }
    });
  });
}
