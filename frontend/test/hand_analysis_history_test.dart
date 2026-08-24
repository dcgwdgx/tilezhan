import 'package:flutter_test/flutter_test.dart';
import 'package:tilezhan/features/hand_analyzer/data/hand_analysis_history_store.dart';
import 'package:tilezhan/features/hand_analyzer/domain/hand_analysis_history.dart';

void main() {
  group('HandAnalysisRecord', () {
    test('persists only versionable user input and metadata', () {
      final record = HandAnalysisRecord(
        id: 'hand-1',
        tileIds: _hand13,
        createdAt: 123,
        title: '  Opening hand  ',
        isFavorite: true,
      );

      expect(record.title, 'Opening hand');
      expect(record.tileIds, _hand13);
      expect(() => record.tileIds.add('z1'), throwsUnsupportedError);
      expect(record.toJson(), {
        'id': 'hand-1',
        'tileIds': _hand13,
        'createdAt': 123,
        'title': 'Opening hand',
        'isFavorite': true,
      });
      expect(record.toJson(), isNot(contains('minimumShanten')));
      expect(record.toJson(), isNot(contains('candidates')));
      expect(record.toJson(), isNot(contains('effectiveTileIds')));
    });

    test('rejects impossible or unsupported saved hands', () {
      expect(
        () => HandAnalysisRecord(
          id: 'short',
          tileIds: _hand13.take(12).toList(),
          createdAt: 1,
        ),
        throwsArgumentError,
      );
      expect(
        () => HandAnalysisRecord(
          id: 'bad-id',
          tileIds: [..._hand13.take(12), 'x1'],
          createdAt: 1,
        ),
        throwsArgumentError,
      );
      expect(
        () => HandAnalysisHistory.empty().recordAnalysis(
          tileIds: [..._hand13.take(12), ''],
          createdAt: 1,
        ),
        throwsArgumentError,
      );
      expect(
        () => HandAnalysisRecord(
          id: 'five-copies',
          tileIds: const [
            'm1',
            'm1',
            'm1',
            'm1',
            'm1',
            'm2',
            'm3',
            'm4',
            'p2',
            'p3',
            'p4',
            's2',
            's3',
          ],
          createdAt: 1,
        ),
        throwsArgumentError,
      );
    });

    test('optional-field damage is sanitized without losing the hand', () {
      final record = HandAnalysisRecord.tryFromJson({
        'id': 'valid',
        'tileIds': _hand13,
        'createdAt': 10,
        'title': 42,
        'isFavorite': 'yes',
      });

      expect(record, isNotNull);
      expect(record!.title, isNull);
      expect(record.isFavorite, isFalse);
    });
  });

  group('HandAnalysisHistory schema', () {
    test('round-trips schema version 1', () {
      final original = HandAnalysisHistory.empty()
          .recordAnalysis(tileIds: _hand13, createdAt: 1, id: 'one')
          .setFavorite('one', true)
          .rename('one', 'Favorite hand');

      final json = original.toJson();
      final restored = HandAnalysisHistory.fromJson(json);

      expect(json['schemaVersion'], 1);
      expect(restored.records, hasLength(1));
      expect(
          restored.records.single.toJson(), original.records.single.toJson());
    });

    test('keeps valid siblings when individual records are damaged', () {
      final history = HandAnalysisHistory.fromJson({
        'schemaVersion': 1,
        'records': [
          {
            'id': 'valid-1',
            'tileIds': _hand13,
            'createdAt': 30,
            'isFavorite': true,
          },
          'not-a-map',
          {
            'id': 'invalid-hand',
            'tileIds': [..._hand13.take(12), 'z8'],
            'createdAt': 20,
          },
          {
            'id': 'valid-2',
            'tileIds': _hand14,
            'createdAt': 10,
          },
        ],
      });

      expect(
          history.records.map((record) => record.id), ['valid-1', 'valid-2']);
    });

    test('corrupt root or unknown schema safely falls back to empty', () {
      expect(HandAnalysisHistory.fromJson(const {}).records, isEmpty);
      expect(
        HandAnalysisHistory.fromJson(const {
          'schemaVersion': 2,
          'records': [],
        }).records,
        isEmpty,
      );
      expect(
        HandAnalysisHistory.fromJson(const {
          'schemaVersion': 1,
          'records': 'broken',
        }).records,
        isEmpty,
      );
    });
  });

  group('HandAnalysisHistory behavior', () {
    test('deduplicates the same hand regardless of tile order', () {
      var history = HandAnalysisHistory.empty().recordAnalysis(
        tileIds: _hand13,
        createdAt: 10,
        title: 'First title',
        id: 'stable-id',
      );
      history = history.setFavorite('stable-id', true);
      history = history.recordAnalysis(
        tileIds: _hand13.reversed.toList(),
        createdAt: 20,
        id: 'unused-new-id',
      );

      expect(history.records, hasLength(1));
      expect(history.records.single.id, 'stable-id');
      expect(history.records.single.createdAt, 20);
      expect(history.records.single.title, 'First title');
      expect(history.records.single.isFavorite, isTrue);
    });

    test('keeps recents newest-first and bounded to 20', () {
      var history = HandAnalysisHistory.empty();
      for (var i = 0; i < 25; i++) {
        history = history.recordAnalysis(
          tileIds: _distinctHand(i),
          createdAt: i,
          id: 'hand-$i',
        );
      }

      expect(history.recent, hasLength(20));
      expect(history.recent.first.id, 'hand-24');
      expect(history.recent.last.id, 'hand-5');
      expect(history.recordById('hand-4'), isNull);
    });

    test('protects favorites from recent churn and bounds favorites to 20', () {
      var history = HandAnalysisHistory.empty();
      for (var i = 0; i < 24; i++) {
        history = history.recordAnalysis(
          tileIds: _distinctHand(i),
          createdAt: i,
          id: 'favorite-$i',
        );
        history = history.setFavorite('favorite-$i', true);
      }
      for (var i = 24; i < 48; i++) {
        history = history.recordAnalysis(
          tileIds: _distinctHand(i),
          createdAt: i,
          id: 'recent-$i',
        );
      }

      expect(history.recent, hasLength(20));
      expect(history.favorites, hasLength(20));
      expect(history.recordById('favorite-4'), isNotNull);
      expect(history.recordById('favorite-3'), isNull);
      expect(history.records.length, lessThanOrEqualTo(40));
    });

    test('supports rename, removal, and clearing without losing favorites', () {
      var history = HandAnalysisHistory.empty()
          .recordAnalysis(tileIds: _hand13, createdAt: 2, id: 'favorite')
          .recordAnalysis(tileIds: _hand14, createdAt: 1, id: 'ordinary')
          .setFavorite('favorite', true)
          .rename('favorite', '  Saved  ');

      expect(history.recordById('favorite')!.title, 'Saved');
      history = history.clearRecent();
      expect(history.records.map((record) => record.id), ['favorite']);

      history = history.clearFavorites();
      expect(history.favorites, isEmpty);
      history = history.remove('favorite');
      expect(history.records, isEmpty);
    });
  });

  test('in-memory adapter obeys the injectable store contract', () async {
    final store = InMemoryHandAnalysisHistoryStore();
    final updated = store.read().recordAnalysis(
          tileIds: _hand13,
          createdAt: 1,
          id: 'saved',
        );

    await store.write(updated);

    expect(store.read().recordById('saved'), isNotNull);
    expect(StorageServiceHandAnalysisHistoryStore.storageKey,
        'hand_analysis_history_v1');
  });
}

const _hand13 = [
  'm1',
  'm2',
  'm3',
  'm4',
  'm5',
  'm6',
  'p2',
  'p3',
  'p4',
  's2',
  's3',
  's4',
  'z1',
];

const _hand14 = [
  ..._hand13,
  'z2',
];

List<String> _distinctHand(int seed) {
  const base = [
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
    'p6',
    'p7',
    'p8',
    'p9',
    's1',
    's2',
    's3',
    's4',
    's5',
    's6',
    's7',
    's8',
    's9',
    'z1',
    'z2',
    'z3',
    'z4',
    'z5',
    'z6',
    'z7',
  ];
  final hand = List<String>.generate(
    13,
    (index) => base[(index + seed) % base.length],
  );
  hand[12] = base[(seed * 7 + 13) % base.length];
  return hand;
}
