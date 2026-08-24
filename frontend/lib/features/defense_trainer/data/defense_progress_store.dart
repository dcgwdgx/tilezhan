import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/storage_provider.dart';
import '../../../core/storage/storage_service.dart';
import '../domain/defense_progress.dart';

/// Injectable persistence boundary for aggregate defense progress.
abstract interface class DefenseProgressStore {
  DefenseProgressProfile read();

  Future<void> write(DefenseProgressProfile profile);
}

/// Production adapter backed by one independent versioned JSON file.
class StorageServiceDefenseProgressStore implements DefenseProgressStore {
  const StorageServiceDefenseProgressStore(this._storage);

  static const storageKey = 'defense_progress_v1';

  final StorageService _storage;

  @override
  DefenseProgressProfile read() => DefenseProgressProfile.fromJson(
        _storage.getJson(storageKey),
      );

  @override
  Future<void> write(DefenseProgressProfile profile) async {
    if (profile.isReadOnly) return;
    final value = profile.toJson();
    final expected = jsonEncode(value);
    await _storage.setJson(storageKey, value);
    if (jsonEncode(_storage.getJson(storageKey)) != expected) {
      throw StateError('Defense progress storage verification failed');
    }
  }
}

/// Lightweight store for deterministic tests and storage-free previews.
class InMemoryDefenseProgressStore implements DefenseProgressStore {
  InMemoryDefenseProgressStore([
    DefenseProgressProfile? initialValue,
  ]) : _value = initialValue ?? DefenseProgressProfile.empty();

  DefenseProgressProfile _value;

  @override
  DefenseProgressProfile read() => _value;

  @override
  Future<void> write(DefenseProgressProfile profile) async {
    if (profile.isReadOnly) return;
    _value = profile;
  }
}

final defenseProgressStoreProvider = FutureProvider<DefenseProgressStore>(
  (ref) async {
    final storage = await ref.watch(storageServiceProvider.future);
    return StorageServiceDefenseProgressStore(storage);
  },
);

final defenseProgressProvider =
    NotifierProvider<DefenseProgressNotifier, DefenseProgressProfile>(
  DefenseProgressNotifier.new,
);

final defenseSkillStatsProvider =
    Provider.family<DefenseSkillStats?, String>((ref, skillId) {
  return ref.watch(defenseProgressProvider).skill(skillId);
});

/// Offline-first reducer with pending-event replay and serialized writes.
class DefenseProgressNotifier extends Notifier<DefenseProgressProfile> {
  DefenseProgressStore? _store;
  final List<_PendingDefenseAttempt> _pendingAttempts = [];
  Future<void> _writeQueue = Future<void>.value();
  DefenseProgressProfile? _pendingSnapshot;
  Object? _terminalWriteError;
  StackTrace? _terminalWriteStackTrace;
  bool _writePumpRunning = false;
  bool _persistenceEnabled = false;
  bool _disposed = false;

  @override
  DefenseProgressProfile build() {
    _persistenceEnabled = true;
    ref.onDispose(() => _disposed = true);
    ref.listen<AsyncValue<DefenseProgressStore>>(
      defenseProgressStoreProvider,
      (_, next) {
        next.whenData((store) {
          Future<void>.microtask(() {
            if (!_disposed) _attachStore(store);
          });
        });
      },
      fireImmediately: true,
    );
    return DefenseProgressProfile.empty();
  }

  /// Records one supported attempt and updates memory synchronously.
  bool recordAttempt({
    required String skillId,
    required String questionId,
    required DefenseAttemptOutcome outcome,
    int? occurredAt,
  }) {
    if (!DefenseSkillIds.all.contains(skillId)) return false;
    final attempt = _PendingDefenseAttempt(
      skillId: skillId,
      questionId: questionId,
      outcome: outcome,
      occurredAt: occurredAt ?? DateTime.now().millisecondsSinceEpoch,
    );
    if (_persistenceEnabled && _store == null) _pendingAttempts.add(attempt);
    state = attempt.applyTo(state);
    if (_persistenceEnabled && _store != null && !state.isReadOnly) {
      _queueWrite();
    }
    return true;
  }

  /// Waits until storage is initialized and the write queue is stably empty.
  ///
  /// Attempts added while this method waits are included. A terminal dirty
  /// snapshot is retried once; persistent failure is surfaced to the caller.
  Future<void> flush() async {
    if (!_persistenceEnabled || _disposed) return;
    if (_store == null) {
      final store = await ref.read(defenseProgressStoreProvider.future);
      if (_disposed) return;
      _attachStore(store);
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

  void _attachStore(DefenseProgressStore store) {
    if (_disposed || _store != null) return;
    _store = store;

    var loaded = store.read();
    final pending = List<_PendingDefenseAttempt>.of(_pendingAttempts);
    _pendingAttempts.clear();
    for (final attempt in pending) {
      loaded = attempt.applyTo(loaded);
    }
    state = loaded;
    if (pending.isNotEmpty && !state.isReadOnly) _queueWrite();
  }

  void _queueWrite() {
    final store = _store;
    if (store == null || state.isReadOnly || _disposed) return;
    _pendingSnapshot = state;
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
          // A newer complete profile supersedes the failed snapshot and
          // contains every accepted attempt, so continue directly to it.
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

class _PendingDefenseAttempt {
  const _PendingDefenseAttempt({
    required this.skillId,
    required this.questionId,
    required this.outcome,
    required this.occurredAt,
  });

  final String skillId;
  final String questionId;
  final DefenseAttemptOutcome outcome;
  final int occurredAt;

  DefenseProgressProfile applyTo(DefenseProgressProfile profile) {
    return profile.recordAttempt(
      skillId: skillId,
      questionId: questionId,
      outcome: outcome,
      occurredAt: occurredAt,
    );
  }
}
