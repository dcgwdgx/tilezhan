import 'package:flutter_test/flutter_test.dart';
import 'package:tilezhan/features/hand_analyzer/presentation/hand_analyzer_tile_adapter.dart';

void main() {
  group('HandAnalyzerTileCatalog', () {
    test('contains each canonical engine and SVG tile ID exactly once', () {
      expect(HandAnalyzerTileCatalog.allTileIds, hasLength(34));
      expect(HandAnalyzerTileCatalog.allTileIds.toSet(), hasLength(34));
      expect(HandAnalyzerTileCatalog.allTileIds.first, 'm1');
      expect(HandAnalyzerTileCatalog.allTileIds.last, 'z7');
    });
  });

  group('HandAnalyzerSelection', () {
    test('sorts entered tiles into canonical hand order', () {
      final selection = HandAnalyzerSelection.fromTileIds(
        const ['z7', 's2', 'm9', 'p1', 'm1'],
      );

      expect(selection.tileIds, const ['m1', 'm9', 'p1', 's2', 'z7']);
      expect(() => selection.tileIds.add('m2'), throwsUnsupportedError);
    });

    test('accepts both 13- and 14-tile analysis states', () {
      var selection = HandAnalyzerSelection.empty();
      for (final tileId in const [
        'm1',
        'm2',
        'm3',
        'm4',
        'm5',
        'm6',
        'm7',
        'm8',
        'm9',
        'p1',
        'p2',
        'p3',
        'p4',
      ]) {
        selection = selection.add(tileId).selection;
      }

      expect(selection.count, 13);
      expect(selection.canAnalyze, isTrue);
      expect(selection.targetCount, 13);

      selection = selection.add('p5').selection;
      expect(selection.count, 14);
      expect(selection.canAnalyze, isTrue);
      expect(selection.targetCount, 14);
      expect(selection.isFull, isTrue);
    });

    test('rejects a fifth physical copy without changing the hand', () {
      final fourCopies = HandAnalyzerSelection.fromTileIds(
        const ['m1', 'm1', 'm1', 'm1'],
      );

      final update = fourCopies.add('m1');

      expect(update.added, isFalse);
      expect(update.issue, HandAnalyzerSelectionIssue.fourCopyLimit);
      expect(update.selection.tileIds, fourCopies.tileIds);
    });

    test('rejects a fifteenth tile without changing the hand', () {
      final full = HandAnalyzerSelection.fromTileIds(const [
        'm1',
        'm2',
        'm3',
        'm4',
        'm5',
        'm6',
        'm7',
        'm8',
        'm9',
        'p1',
        'p2',
        'p3',
        'p4',
        'p5',
      ]);

      final update = full.add('p6');

      expect(update.added, isFalse);
      expect(update.issue, HandAnalyzerSelectionIssue.handFull);
      expect(update.selection.tileIds, full.tileIds);
    });

    test('removes one occurrence and clears without mutating prior state', () {
      final original = HandAnalyzerSelection.fromTileIds(
        const ['p2', 'm1', 'p2'],
      );
      final removed = original.removeAt(1);
      final cleared = removed.clear();

      expect(original.tileIds, const ['m1', 'p2', 'p2']);
      expect(removed.tileIds, const ['m1', 'p2']);
      expect(cleared.tileIds, isEmpty);
    });
  });
}
