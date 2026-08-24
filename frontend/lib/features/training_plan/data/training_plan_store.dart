import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/storage_provider.dart';
import '../../../core/srs/srs_provider.dart';
import '../../../core/storage/storage_service.dart';
import '../../defense_trainer/data/defense_progress_store.dart';
import '../../nanikiru/domain/nanikiru_skill_mastery_provider.dart';
import '../domain/training_plan.dart';
import '../domain/training_plan_generator.dart';

/// Injectable persistence boundary for one versioned daily plan.
abstract interface class TrainingPlanStore {
  DailyTrainingPlan? read();

  Future<void> write(DailyTrainingPlan plan);
}

class StorageServiceTrainingPlanStore implements TrainingPlanStore {
  const StorageServiceTrainingPlanStore(this._storage);

  final StorageService _storage;

  @override
  DailyTrainingPlan? read() => DailyTrainingPlan.tryFromJson(
        _storage.getJson(StorageService.kDailyTrainingPlanV1),
      );

  @override
  Future<void> write(DailyTrainingPlan plan) async {
    if (plan.isReadOnly) return;
    final value = plan.toJson();
    final expected = jsonEncode(value);
    await _storage.setJson(StorageService.kDailyTrainingPlanV1, value);
    if (jsonEncode(_storage.getJson(StorageService.kDailyTrainingPlanV1)) !=
        expected) {
      throw StateError('Daily training plan storage verification failed');
    }
  }
}

class InMemoryTrainingPlanStore implements TrainingPlanStore {
  InMemoryTrainingPlanStore([this.value]);

  DailyTrainingPlan? value;

  @override
  DailyTrainingPlan? read() => value;

  @override
  Future<void> write(DailyTrainingPlan plan) async {
    if (!plan.isReadOnly) value = plan;
  }
}

final trainingPlanClockProvider = Provider<DateTime Function()>((ref) {
  return DateTime.now;
});

final trainingPlanGeneratorProvider = Provider<TrainingPlanGenerator>((ref) {
  return const TrainingPlanGenerator();
});

final trainingPlanStoreProvider =
    FutureProvider<TrainingPlanStore>((ref) async {
  final storage = await ref.watch(storageServiceProvider.future);
  return StorageServiceTrainingPlanStore(storage);
});

/// Waits for all three existing learning stores before generating a new day.
///
/// Without this barrier, their notifiers initially expose empty memory state
/// and a returning learner could incorrectly receive the first-user plan.
final trainingPlanInputsProvider =
    FutureProvider<TrainingPlanInputs>((ref) async {
  ref.read(srsNotifierProvider);
  ref.read(nanikiruSkillMasteryProvider);
  ref.read(defenseProgressProvider);

  await ref.watch(srsStoreProvider.future);
  await ref.watch(nanikiruSkillMasteryStoreProvider.future);
  await ref.watch(defenseProgressStoreProvider.future);
  // Each learning notifier deliberately attaches its ready store in a
  // microtask. Yield twice so those merge steps have completed.
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);

  return TrainingPlanInputs(
    srsItems: ref.read(srsItemsProvider),
    nanikiruMastery: ref.read(nanikiruSkillMasteryProvider),
    defenseProgress: ref.read(defenseProgressProvider),
  );
});

class TrainingPlanBootstrap {
  const TrainingPlanBootstrap({required this.store, required this.inputs});

  final TrainingPlanStore store;
  final TrainingPlanInputs inputs;
}

final trainingPlanBootstrapProvider = FutureProvider<TrainingPlanBootstrap>(
  (ref) async {
    final store = await ref.watch(trainingPlanStoreProvider.future);
    final inputs = await ref.watch(trainingPlanInputsProvider.future);
    return TrainingPlanBootstrap(store: store, inputs: inputs);
  },
);

/// Null is a short initialization state; a real plan is then loaded or made.
final dailyTrainingPlanProvider =
    NotifierProvider<DailyTrainingPlanNotifier, DailyTrainingPlan?>(
  DailyTrainingPlanNotifier.new,
);

class DailyTrainingPlanNotifier extends Notifier<DailyTrainingPlan?> {
  TrainingPlanStore? _store;
  TrainingPlanInputs? _inputs;
  final List<_PendingTrainingEvent> _pendingEvents = [];
  int _eventSequence = 0;

  Future<void> _writeQueue = Future<void>.value();
  DailyTrainingPlan? _pendingSnapshot;
  Object? _terminalWriteError;
  StackTrace? _terminalWriteStackTrace;
  bool _writePumpRunning = false;
  bool _persistenceEnabled = false;
  bool _disposed = false;

  @override
  DailyTrainingPlan? build() {
    _persistenceEnabled = true;
    ref.onDispose(() => _disposed = true);
    ref.listen<AsyncValue<TrainingPlanBootstrap>>(
      trainingPlanBootstrapProvider,
      (_, next) {
        next.whenData((bootstrap) {
          Future<void>.microtask(() {
            if (!_disposed) _attach(bootstrap);
          });
        });
      },
      fireImmediately: true,
    );
    return null;
  }

  /// Records one accepted answer. Accuracy is intentionally irrelevant to a
  /// learning-day streak: showing up and completing the plan is what counts.
  bool recordAcceptedAttempt(TrainingAttemptEvent event) {
    if (_store == null || state == null) {
      _pendingEvents.add(
        _PendingTrainingEvent(event: event, sequence: _eventSequence++),
      );
      return true;
    }

    var current = state!;
    final eventDate = trainingDateKey(event.localDate);
    if (eventDate.compareTo(current.localDateKey) < 0) return false;
    if (eventDate != current.localDateKey) {
      current = _newPlan(
        now: event.localDate,
        previous: current,
        inputs: _currentInputs(),
      );
    }

    final next = current.recordAcceptedAttempt(event);
    if (identical(next, current)) {
      if (!identical(current, state)) {
        state = current;
        if (!current.isReadOnly) _queueWrite();
      }
      return false;
    }
    state = next;
    if (!next.isReadOnly) _queueWrite();
    return true;
  }

  /// Refreshes a loaded plan when the app returns to Home on a new local day.
  /// Answer events also roll the day forward, but this proactive path prevents
  /// yesterday's task labels and remaining counts from being shown first.
  bool refreshForToday() {
    final current = state;
    if (_store == null || current == null) return false;
    final now = ref.read(trainingPlanClockProvider)();
    if (current.localDateKey == trainingDateKey(now)) return false;

    final next = _newPlan(
      now: now,
      previous: current,
      inputs: _currentInputs(),
    );
    state = next;
    if (!next.isReadOnly) _queueWrite();
    return true;
  }

  /// Waits until initialization and every write accepted so far are complete.
  /// A terminal dirty snapshot is retried once and persistent failure is
  /// explicit, matching the SRS and defense progress durability contract.
  Future<void> flush() async {
    if (!_persistenceEnabled || _disposed) return;
    if (_store == null) {
      final bootstrap = await ref.read(trainingPlanBootstrapProvider.future);
      if (_disposed) return;
      _attach(bootstrap);
    }

    var retriedTerminalSnapshot = false;
    while (!_disposed) {
      if (!_writePumpRunning && _pendingSnapshot != null) {
        if (_terminalWriteError != null) {
          if (retriedTerminalSnapshot) _throwTerminalWriteError();
          retriedTerminalSnapshot = true;
        }
        _startWritePump(retryTerminal: true);
      }

      final tail = _writeQueue;
      await tail;
      if (!identical(tail, _writeQueue) || _writePumpRunning) continue;
      if (_pendingSnapshot == null) return;
      if (_terminalWriteError != null && retriedTerminalSnapshot) {
        _throwTerminalWriteError();
      }
    }
  }

  void _attach(TrainingPlanBootstrap bootstrap) {
    if (_disposed || _store != null) return;
    _store = bootstrap.store;
    _inputs = bootstrap.inputs;

    final now = ref.read(trainingPlanClockProvider)();
    final stored = bootstrap.store.read();
    final today = trainingDateKey(now);
    final needsGeneration =
        stored == null || stored.localDateKey != today || stored.tasks.isEmpty;
    var loaded = needsGeneration
        ? _newPlan(now: now, previous: stored, inputs: bootstrap.inputs)
        : stored;

    final pending = List<_PendingTrainingEvent>.of(_pendingEvents)
      ..sort((left, right) {
        final byTime = left.event.occurredAt.compareTo(right.event.occurredAt);
        return byTime != 0 ? byTime : left.sequence.compareTo(right.sequence);
      });
    _pendingEvents.clear();
    var changed = needsGeneration;
    for (final pendingEvent in pending) {
      final event = pendingEvent.event;
      final eventDate = trainingDateKey(event.localDate);
      if (eventDate.compareTo(loaded.localDateKey) < 0) continue;
      if (eventDate != loaded.localDateKey) {
        loaded = _newPlan(
          now: event.localDate,
          previous: loaded,
          inputs: bootstrap.inputs,
        );
        changed = true;
      }
      final next = loaded.recordAcceptedAttempt(event);
      if (!identical(next, loaded)) {
        loaded = next;
        changed = true;
      }
    }
    state = loaded;
    if (changed && !loaded.isReadOnly) _queueWrite();
  }

  DailyTrainingPlan _newPlan({
    required DateTime now,
    required DailyTrainingPlan? previous,
    required TrainingPlanInputs inputs,
  }) {
    return ref.read(trainingPlanGeneratorProvider).generate(
          now: now,
          inputs: inputs,
          previous: previous,
        );
  }

  TrainingPlanInputs _currentInputs() {
    final fallback = _inputs!;
    try {
      return TrainingPlanInputs(
        srsItems: ref.read(srsItemsProvider),
        nanikiruMastery: ref.read(nanikiruSkillMasteryProvider),
        defenseProgress: ref.read(defenseProgressProvider),
      );
    } on Object {
      return fallback;
    }
  }

  void _queueWrite() {
    final current = state;
    if (_store == null || current == null || current.isReadOnly || _disposed) {
      return;
    }
    _pendingSnapshot = current;
    _terminalWriteError = null;
    _terminalWriteStackTrace = null;
    _startWritePump();
  }

  void _startWritePump({bool retryTerminal = false}) {
    if (_disposed ||
        _store == null ||
        _writePumpRunning ||
        _pendingSnapshot == null ||
        (_terminalWriteError != null && !retryTerminal)) {
      return;
    }
    _writePumpRunning = true;
    _writeQueue = _drainWriteQueue();
  }

  Future<void> _drainWriteQueue() async {
    final store = _store!;
    try {
      while (!_disposed && _pendingSnapshot != null) {
        final snapshot = _pendingSnapshot!;
        _pendingSnapshot = null;
        try {
          await store.write(snapshot);
          _terminalWriteError = null;
          _terminalWriteStackTrace = null;
        } on Object catch (error, stackTrace) {
          _terminalWriteError = error;
          _terminalWriteStackTrace = stackTrace;
          if (_pendingSnapshot == null) {
            _pendingSnapshot = snapshot;
            break;
          }
        }
      }
    } finally {
      _writePumpRunning = false;
    }
  }

  Never _throwTerminalWriteError() {
    Error.throwWithStackTrace(
      _terminalWriteError!,
      _terminalWriteStackTrace ?? StackTrace.current,
    );
  }
}

class _PendingTrainingEvent {
  const _PendingTrainingEvent({required this.event, required this.sequence});

  final TrainingAttemptEvent event;
  final int sequence;
}
