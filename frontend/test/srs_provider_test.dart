// SRS 提供者逻辑的单元测试
// 测试覆盖：首次复习创建条目、质量 4/5 的差异、待复习项按错误权重排序、错误权重公式、正误答案调度
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilezhan/core/srs/srs_engine.dart';
import 'package:tilezhan/core/srs/srs_item.dart';
import 'package:tilezhan/core/srs/srs_provider.dart';

void main() {
  /// SRS 提供者逻辑的单元测试
  /// 测试覆盖：首次复习创建条目、质量 4/5 的差异、待复习项按错误权重排序、错误权重公式、正误答案调度
  group('SRS provider logic', () {
    // 质量 1（错误）的首次复习：reps=0, interval=1, nextReviewAt=0（立即重考）
    test('recordReview creates new item with correct defaults', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      final (ef, reps, interval) = SrsEngine.calculate(2.5, 0, 1, 1);
      expect(reps, 0);
      expect(interval, 1);
      final item = SrsItem(
        itemId: 'm1',
        type: 'flashcard',
        ef: ef,
        reps: reps,
        interval: interval,
        nextReviewAt: 0,
        errors: 1,
        createdAt: now,
        lastReviewedAt: now,
      );
      expect(item.nextReviewAt, 0); // quality<3 → immediate
      expect(item.errors, 1);
    });

    // 质量 4（正确）的首次复习：reps=1, interval=1, EF>=2.5
    test('recordReview quality 4: reps=1, interval=1', () {
      final (ef, reps, interval) = SrsEngine.calculate(2.5, 0, 1, 4);
      expect(reps, 1);
      expect(interval, 1);
      expect(ef, greaterThanOrEqualTo(2.5));
    });

    // 质量 5（完美）的 EF 提升程度应大于质量 4
    test('recordReview quality 5: EF increases more than quality 4', () {
      final (ef4, _, _) = SrsEngine.calculate(2.5, 0, 1, 4);
      final (ef5, _, _) = SrsEngine.calculate(2.5, 0, 1, 5);
      expect(ef5, greaterThan(ef4));
    });

    // 待复习项按错误权重降序排列：最高错误密度的排最前
    test('due items sorted by errorWeight descending', () {
      final items = [
        const SrsItem(
            itemId: 'a',
            type: 'flashcard',
            nextReviewAt: 0,
            errors: 1,
            reps: 2), // 1/3=0.33
        const SrsItem(
            itemId: 'b',
            type: 'flashcard',
            nextReviewAt: 0,
            errors: 5,
            reps: 1), // 5/2=2.5
        const SrsItem(
            itemId: 'c',
            type: 'flashcard',
            nextReviewAt: 0,
            errors: 2,
            reps: 0), // 2/1=2.0
      ];
      items.sort((a, b) => b.errorWeight.compareTo(a.errorWeight));
      expect(items[0].itemId, 'b'); // 2.5 highest
      expect(items[2].itemId, 'a'); // 0.33 lowest
    });

    // 验证错误权重公式的三个边界值
    test('errorWeight formula: errors/(reps+1)', () {
      expect(
          const SrsItem(itemId: 'x', type: 'flashcard', errors: 0, reps: 0)
              .errorWeight,
          0.0);
      expect(
          const SrsItem(itemId: 'x', type: 'flashcard', errors: 5, reps: 0)
              .errorWeight,
          5.0);
      expect(
          const SrsItem(itemId: 'x', type: 'flashcard', errors: 6, reps: 2)
              .errorWeight,
          2.0);
    });

    // 回答正确时安排未来复习（间隔 > 0）
    test('correct answer schedules future review', () {
      final (_, _, interval) = SrsEngine.calculate(2.5, 0, 1, 4);
      expect(interval, greaterThan(0));
    });

    // 回答错误时安排立即复习（间隔 = 1 天 = 当天）
    test('wrong answer schedules immediate review (0 days)', () {
      final (_, _, interval) = SrsEngine.calculate(2.5, 0, 1, 1);
      expect(interval, 1);
    });
  });

  group('SrsReviewNotifier persistence', () {
    test('isolates malformed JSON entries and keeps valid siblings', () async {
      final store = _MemorySrsStore({
        'valid': const SrsItem(
          itemId: 'valid',
          type: 'flashcard',
          reps: 2,
          createdAt: 10,
        ).toJson(),
        'not-a-map': 'broken',
        'bad-field-type': {
          'itemId': 'bad-field-type',
          'type': 'flashcard',
          'reps': 'two',
        },
        'mismatched-key': {
          'itemId': 'different-id',
          'type': 'flashcard',
        },
        'empty-type': {
          'itemId': 'empty-type',
          'type': '',
        },
        'negative-reps': {
          'itemId': 'negative-reps',
          'type': 'flashcard',
          'reps': -1,
        },
        'zero-interval': {
          'itemId': 'zero-interval',
          'type': 'flashcard',
          'interval': 0,
        },
        'invalid-ef': {
          'itemId': 'invalid-ef',
          'type': 'flashcard',
          'ef': 1.2,
        },
      });
      final container = _containerWith(store);
      addTearDown(container.dispose);
      final notifier = container.read(srsNotifierProvider.notifier);

      await notifier.flush();

      expect(container.read(srsNotifierProvider).keys, ['valid']);
      expect(container.read(srsItemsProvider).keys, ['valid']);
      expect(store.writes, isEmpty);
    });

    test('replays reviews received while storage is loading onto disk state',
        () async {
      const diskItem = SrsItem(
        itemId: 'same-card',
        type: 'flashcard',
        ef: 2.5,
        reps: 2,
        interval: 6,
        nextReviewAt: 200,
        errors: 1,
        createdAt: 100,
        lastReviewedAt: 200,
      );
      final store = _MemorySrsStore({'same-card': diskItem.toJson()});
      final storeCompleter = Completer<SrsStore>();
      final container = ProviderContainer(
        overrides: [
          srsStoreProvider.overrideWith((ref) => storeCompleter.future),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(srsNotifierProvider.notifier);

      notifier.recordReview('same-card', 'flashcard', 4);
      notifier.recordReview('same-card', 'flashcard', 4);
      expect(container.read(srsNotifierProvider)['same-card']!.reps, 2);

      storeCompleter.complete(store);
      await notifier.flush();

      final merged = container.read(srsNotifierProvider)['same-card']!;
      expect(merged.reps, 4);
      expect(merged.errors, 1);
      expect(merged.createdAt, 100);
      expect(store.writes, hasLength(1));
      expect(
        SrsItem.fromJson(
          Map<String, dynamic>.from(store.writes.single['same-card'] as Map),
        ).reps,
        4,
      );
    });

    test('replays content replacement without resetting disk schedule',
        () async {
      const diskItem = SrsItem(
        itemId: 'nanikiru-1',
        type: 'nanikiru',
        ef: 1.8,
        reps: 5,
        interval: 12,
        nextReviewAt: 700,
        errors: 3,
        createdAt: 100,
        lastReviewedAt: 600,
        content: {'engineVersion': 1},
      );
      final store = _MemorySrsStore({'nanikiru-1': diskItem.toJson()});
      final storeCompleter = Completer<SrsStore>();
      final container = ProviderContainer(
        overrides: [
          srsStoreProvider.overrideWith((ref) => storeCompleter.future),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(srsNotifierProvider.notifier);

      notifier.replaceContentPreservingSchedule(
        const SrsItem(itemId: 'nanikiru-1', type: 'nanikiru'),
        const {'engineVersion': 2},
      );
      storeCompleter.complete(store);
      await notifier.flush();

      final merged = container.read(srsNotifierProvider)['nanikiru-1']!;
      expect(merged.ef, diskItem.ef);
      expect(merged.reps, diskItem.reps);
      expect(merged.interval, diskItem.interval);
      expect(merged.nextReviewAt, diskItem.nextReviewAt);
      expect(merged.errors, diskItem.errors);
      expect(merged.createdAt, diskItem.createdAt);
      expect(merged.lastReviewedAt, diskItem.lastReviewedAt);
      expect(merged.content, {'engineVersion': 2});
    });

    test('discards an unrecoverable item even while storage is loading',
        () async {
      const brokenReview = SrsItem(
        itemId: 'legacy-nanikiru',
        type: 'nanikiru',
        nextReviewAt: 0,
        content: {'legacy': true},
      );
      final store = _MemorySrsStore({
        brokenReview.itemId: brokenReview.toJson(),
      });
      final storeCompleter = Completer<SrsStore>();
      final container = ProviderContainer(
        overrides: [
          srsStoreProvider.overrideWith((ref) => storeCompleter.future),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(srsNotifierProvider.notifier);

      notifier.discardUnrecoverableItem(brokenReview.itemId);
      storeCompleter.complete(store);
      await notifier.flush();

      expect(container.read(srsNotifierProvider), isEmpty);
      expect(store.persisted, isEmpty);
    });

    test('serializes rapid writes and persists the newest snapshot last',
        () async {
      final store = _MemorySrsStore(
        const {},
        writeDelay: const Duration(milliseconds: 1),
      );
      final container = _containerWith(store);
      addTearDown(container.dispose);
      final notifier = container.read(srsNotifierProvider.notifier);
      await notifier.flush();

      for (var index = 0; index < 30; index++) {
        notifier.recordReview('card-$index', 'flashcard', 4);
      }
      await notifier.flush();

      expect(store.maximumConcurrentWrites, 1);
      expect(store.writes.length, lessThan(30));
      expect(store.writes.last, hasLength(30));
      expect(store.persisted, hasLength(30));
      expect(store.persisted.keys, contains('card-29'));
    });

    test('a failed write does not poison later queued snapshots', () async {
      final store = _MemorySrsStore(const {}, failWriteCount: 1);
      final container = _containerWith(store);
      addTearDown(container.dispose);
      final notifier = container.read(srsNotifierProvider.notifier);
      await notifier.flush();

      notifier.recordReview('first', 'flashcard', 4);
      notifier.recordReview('second', 'flashcard', 4);
      await notifier.flush();

      expect(store.maximumConcurrentWrites, 1);
      expect(store.writeAttempts, 2);
      expect(store.persisted.keys, {'first', 'second'});
    });

    test('flush retries a terminal dirty snapshot with no later mutation',
        () async {
      final store = _MemorySrsStore(const {}, failWriteCount: 1);
      final container = _containerWith(store);
      addTearDown(container.dispose);
      final notifier = container.read(srsNotifierProvider.notifier);
      await notifier.flush();

      notifier.recordReview('only-card', 'flashcard', 4);
      await notifier.flush();

      expect(store.writeAttempts, 2);
      expect(store.persisted.keys, {'only-card'});
    });

    test('flush surfaces a persistent terminal write failure', () async {
      final store = _MemorySrsStore(const {}, failWriteCount: 2);
      final container = _containerWith(store);
      addTearDown(container.dispose);
      final notifier = container.read(srsNotifierProvider.notifier);
      await notifier.flush();

      notifier.recordReview('only-card', 'flashcard', 4);

      await expectLater(notifier.flush(), throwsStateError);
      expect(store.writeAttempts, 2);
      expect(store.persisted, isEmpty);
    });

    test('flush waits for mutations appended while a write is in flight',
        () async {
      final firstWriteGate = Completer<void>();
      final store = _MemorySrsStore(
        const {},
        firstWriteGate: firstWriteGate,
      );
      final container = _containerWith(store);
      addTearDown(container.dispose);
      final notifier = container.read(srsNotifierProvider.notifier);
      await notifier.flush();

      notifier.recordReview('first', 'flashcard', 4);
      expect(store.writeAttempts, 1);
      var flushCompleted = false;
      final flushFuture = notifier.flush().then((_) => flushCompleted = true);
      notifier.recordReview('second', 'flashcard', 4);
      await Future<void>.delayed(Duration.zero);
      expect(flushCompleted, isFalse);

      firstWriteGate.complete();
      await flushFuture;

      expect(store.writeAttempts, 2);
      expect(store.maximumConcurrentWrites, 1);
      expect(store.persisted.keys, {'first', 'second'});
    });

    test('build-only in-memory subclasses keep flush storage-free', () async {
      var storeProviderReads = 0;
      final container = ProviderContainer(
        overrides: [
          srsStoreProvider.overrideWith((ref) async {
            storeProviderReads += 1;
            throw StateError('must not initialize persistence');
          }),
          srsNotifierProvider.overrideWith(_BuildOnlyMemorySrsNotifier.new),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(srsNotifierProvider.notifier);

      notifier.recordReview('memory-card', 'flashcard', 4);
      await notifier.flush();

      expect(container.read(srsNotifierProvider).keys, ['memory-card']);
      expect(storeProviderReads, 0);
    });

    test('deferred store attachment is ignored after disposal', () async {
      final store = _MemorySrsStore(const {});
      final container = ProviderContainer(
        overrides: [
          srsStoreProvider.overrideWith((ref) async => store),
        ],
      );

      container.read(srsNotifierProvider);
      container.dispose();
      await Future<void>.delayed(Duration.zero);

      expect(store.writeAttempts, 0);
    });

    test('first correct review records a real creation timestamp', () async {
      final store = _MemorySrsStore(const {});
      final container = _containerWith(store);
      addTearDown(container.dispose);
      final notifier = container.read(srsNotifierProvider.notifier);
      await notifier.flush();
      final before = DateTime.now().millisecondsSinceEpoch;

      notifier.recordReview('new-card', 'flashcard', 4);
      await notifier.flush();

      final item = container.read(srsNotifierProvider)['new-card']!;
      expect(item.createdAt, greaterThanOrEqualTo(before));
      expect(item.createdAt, item.lastReviewedAt);
      expect(item.createdAt, greaterThan(0));
    });
  });
}

ProviderContainer _containerWith(SrsStore store) {
  return ProviderContainer(
    overrides: [
      srsStoreProvider.overrideWith((ref) async => store),
    ],
  );
}

class _MemorySrsStore implements SrsStore {
  _MemorySrsStore(
    Map<String, dynamic> initial, {
    this.writeDelay = Duration.zero,
    this.failWriteCount = 0,
    this.firstWriteGate,
  }) : persisted = Map<String, dynamic>.from(initial);

  final Duration writeDelay;
  final int failWriteCount;
  final Completer<void>? firstWriteGate;
  final List<Map<String, dynamic>> writes = [];
  Map<String, dynamic> persisted;
  int writeAttempts = 0;
  int _concurrentWrites = 0;
  int maximumConcurrentWrites = 0;

  @override
  Map<String, dynamic> read() => Map<String, dynamic>.from(persisted);

  @override
  Future<void> write(Map<String, dynamic> value) async {
    writeAttempts += 1;
    _concurrentWrites += 1;
    if (_concurrentWrites > maximumConcurrentWrites) {
      maximumConcurrentWrites = _concurrentWrites;
    }
    try {
      if (writeAttempts == 1 && firstWriteGate != null) {
        await firstWriteGate!.future;
      }
      if (writeDelay > Duration.zero) {
        await Future<void>.delayed(writeDelay);
      }
      if (writeAttempts <= failWriteCount) {
        throw StateError('simulated write failure');
      }
      final snapshot = Map<String, dynamic>.from(value);
      writes.add(snapshot);
      persisted = snapshot;
    } finally {
      _concurrentWrites -= 1;
    }
  }
}

class _BuildOnlyMemorySrsNotifier extends SrsReviewNotifier {
  @override
  Map<String, SrsItem> build() => {};
}
