import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilezhan/l10n/generated/app_localizations.dart';
import 'package:tilezhan/features/yaku_detail/domain/yaku_data.dart';
import 'package:tilezhan/features/yaku_detail/presentation/yaku_detail_screen.dart';

void main() {
  group('YakuData', () {
    test('all yaku have valid data', () {
      expect(allYaku.length, greaterThanOrEqualTo(12));
      for (final y in allYaku) {
        expect(y.id, isNotEmpty);
        expect(y.nameEn, isNotEmpty);
        expect(y.closedHan, greaterThan(0));
        if (y.openHan != null) {
          expect(y.openHan, greaterThan(0));
        }
        expect(y.conditions, isNotEmpty);
        expect(y.examples, isNotEmpty);
        expect(y.tip, isNotEmpty);
      }
    });

    test('all yaku IDs are unique', () {
      final ids = allYaku.map((y) => y.id).toSet();
      expect(ids.length, allYaku.length);
    });

    test('han values are realistic and open hands never gain han', () {
      for (final y in allYaku) {
        expect(y.closedHan, inInclusiveRange(1, 26));
        if (y.openHan != null) {
          expect(y.openHan, inInclusiveRange(1, y.closedHan));
        }
      }
    });

    test('open-hand reductions have exact closed and open values', () {
      const expected = <String, (int, int)>{
        'chanta': (2, 1),
        'honitsu': (3, 2),
        'sanshoku': (2, 1),
        'ikkitsukan': (2, 1),
        'chinitsu': (6, 5),
        'junchan': (3, 2),
      };

      for (final entry in expected.entries) {
        final yaku = getYakuById(entry.key)!;
        expect(yaku.closedHan, entry.value.$1, reason: entry.key);
        expect(yaku.openHan, entry.value.$2, reason: entry.key);
      }
    });

    test('closed-only yaku have no open-hand value', () {
      const closedOnlyIds = {
        'riichi',
        'pinfu',
        'iipeiko',
        'chitoitsu',
        'menzen_tsumo',
        'ippatsu',
        'double_riichi',
        'ryanpeikou',
        'kokushi_musou',
        'chuuren_poutou',
        'tenhou',
        'chiihou',
        'suu_ankou',
      };

      for (final id in closedOnlyIds) {
        expect(getYakuById(id)!.openHan, isNull, reason: id);
      }
    });

    test('getYakuById finds valid IDs', () {
      expect(getYakuById('riichi')!.nameEn, 'Riichi');
      expect(getYakuById('chinitsu')!.closedHan, 6);
      expect(getYakuById('tanyao')!.difficulty, 'Beginner');
    });

    test('getYakuById returns null for invalid ID', () {
      expect(getYakuById('nonexistent'), isNull);
    });

    test('each yaku combos have valid data when present', () {
      for (final y in allYaku) {
        for (final c in y.combos) {
          expect(c.name, isNotEmpty);
          expect(c.totalHan, greaterThan(0));
        }
      }
    });

    test('yakuhai never claims the mutually exclusive tanyao combination', () {
      final comboNames = getYakuById('yakuhai')!.combos.map((c) => c.name);
      expect(comboNames, isNot(contains('Yakuhai + Tanyao')));
      expect(comboNames, contains('Yakuhai + Toitoi'));
    });
  });

  group('YakuDetailScreen', () {
    testWidgets('shows yaku name and key sections for riichi', (tester) async {
      await tester.pumpWidget(ProviderScope(
          child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en')],
        home: YakuDetailScreen(yakuId: 'riichi'),
      )));
      await tester.pumpAndSettle();

      expect(find.text('Riichi'), findsWidgets); // AppBar title + content
      expect(find.text('立直'), findsOneWidget);
      expect(find.text('Conditions'), findsOneWidget);
      expect(find.text('Pro Tip'), findsOneWidget);
    });

    testWidgets('every yaku renders without crash', (tester) async {
      for (final y in allYaku) {
        await tester.pumpWidget(ProviderScope(
            child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en')],
          home: YakuDetailScreen(yakuId: y.id),
        )));
        await tester.pump();
        expect(find.text(y.nameEn), findsWidgets, reason: '${y.id}');
      }
    });

    testWidgets('shows fallback for unknown yaku', (tester) async {
      await tester.pumpWidget(ProviderScope(
          child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en')],
        home: const YakuDetailScreen(yakuId: 'bad_id'),
      )));
      await tester.pumpAndSettle();
      expect(find.text('Not found'), findsOneWidget);
    });
  });
}
