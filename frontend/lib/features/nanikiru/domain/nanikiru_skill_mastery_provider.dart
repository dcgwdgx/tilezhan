import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/storage_provider.dart';
import '../../../core/storage/storage_service.dart';
import 'nanikiru_skill_mastery.dart';
import 'nanikiru_state.dart';

/// Persistence boundary for Nanikiru mastery data.
///
/// The production implementation uses [StorageService]. Keeping the boundary
/// small makes loading and serialized writes deterministic in unit tests.
abstract interface class NanikiruSkillMasteryStore {
  NanikiruSkillMasteryProfile read();

  Future<void> write(NanikiruSkillMasteryProfile profile);
}

class StorageServiceNanikiruSkillMasteryStore
    implements NanikiruSkillMasteryStore {
  const StorageServiceNanikiruSkillMasteryStore(this._storage);

  final StorageService _storage;

  @override
  NanikiruSkillMasteryProfile read() {
    return NanikiruSkillMasteryProfile.fromJson(
      _storage.getJson(StorageService.kNanikiruSkillMasteryV1),
    );
  }

  @override
  Future<void> write(NanikiruSkillMasteryProfile profile) async {
    final value = profile.toJson();
    final expected = jsonEncode(value);
    await _storage.setJson(
      StorageService.kNanikiruSkillMasteryV1,
      value,
    );
    if (jsonEncode(
          _storage.getJson(StorageService.kNanikiruSkillMasteryV1),
        ) !=
        expected) {
      throw StateError('Nanikiru skill mastery storage verification failed');
    }
  }
}

final nanikiruSkillMasteryStoreProvider =
    FutureProvider<NanikiruSkillMasteryStore>((ref) async {
  final storage = await ref.watch(storageServiceProvider.future);
  return StorageServiceNanikiruSkillMasteryStore(storage);
});

final nanikiruSkillMasteryProvider =
    NotifierProvider<NanikiruSkillMasteryNotifier, NanikiruSkillMasteryProfile>(
  NanikiruSkillMasteryNotifier.new,
);

final nanikiruSkillMasteryForProvider =
    Provider.family<NanikiruSkillMastery?, String>((ref, skillId) {
  return ref.watch(nanikiruSkillMasteryProvider).skill(skillId);
});

class NanikiruSkillMasteryNotifier
    extends Notifier<NanikiruSkillMasteryProfile> {
  NanikiruSkillMasteryStore? _store;
  final List<_PendingAttempt> _pendingAttempts = [];
  Future<void> _writeQueue = Future<void>.value();
  NanikiruSkillMasteryProfile? _pendingSnapshot;
  Object? _terminalWriteError;
  StackTrace? _terminalWriteStackTrace;
  bool _writePumpRunning = false;
  bool _persistenceEnabled = false;
  bool _disposed = false;

  @override
  NanikiruSkillMasteryProfile build() {
    _persistenceEnabled = true;
    ref.onDispose(() => _disposed = true);
    ref.listen<AsyncValue<NanikiruSkillMasteryStore>>(
      nanikiruSkillMasteryStoreProvider,
      (_, next) {
        next.whenData((store) {
          // A provider override may already contain data while this notifier is
          // building. Defer attachment until its initial state exists.
          Future<void>.microtask(() {
            if (!_disposed) _attachStore(store);
          });
        });
      },
      fireImmediately: true,
    );
    return NanikiruSkillMasteryProfile.empty();
  }

  /// Records one completed attempt and immediately updates in-memory state.
  ///
  /// Returns `false` when the attempt contains no evidence: unanswered, or no
  /// supported skill identifier. Such attempts are neither counted nor saved.
  bool recordAttempt({
    required Iterable<String> skillIds,
    required NaniKiruOutcome outcome,
    required int puzzleDifficulty,
    int? occurredAt,
  }) {
    final normalizedSkillIds =
        skillIds.where(NanikiruSkillIds.all.contains).toSet();
    if (outcome == NaniKiruOutcome.unanswered || normalizedSkillIds.isEmpty) {
      return false;
    }

    final attempt = _PendingAttempt(
      skillIds: normalizedSkillIds,
      outcome: outcome,
      puzzleDifficulty: puzzleDifficulty,
      occurredAt: occurredAt ?? DateTime.now().millisecondsSinceEpoch,
    );
    if (_persistenceEnabled && _store == null) _pendingAttempts.add(attempt);
    state = attempt.applyTo(state);
    if (_persistenceEnabled && _store != null) _queueWrite();
    return true;
  }

  /// Waits until storage is initialized and the write queue is stably empty.
  ///
  /// Attempts added while this method waits are included. A terminal dirty
  /// snapshot is retried once; persistent failure is surfaced to the caller.
  Future<void> flush() async {
    if (!_persistenceEnabled || _disposed) return;
    if (_store == null) {
      final store = await ref.read(nanikiruSkillMasteryStoreProvider.future);
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

  void _attachStore(NanikiruSkillMasteryStore store) {
    if (_disposed || _store != null) return;

    _store = store;
    var loaded = store.read();
    final pending = List<_PendingAttempt>.of(_pendingAttempts);
    _pendingAttempts.clear();
    for (final attempt in pending) {
      loaded = attempt.applyTo(loaded);
    }
    state = loaded;
    if (pending.isNotEmpty) _queueWrite();
  }

  void _queueWrite() {
    final store = _store;
    if (store == null || _disposed) return;
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
          // already contains every accepted attempt.
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

class _PendingAttempt {
  const _PendingAttempt({
    required this.skillIds,
    required this.outcome,
    required this.puzzleDifficulty,
    required this.occurredAt,
  });

  final Set<String> skillIds;
  final NaniKiruOutcome outcome;
  final int puzzleDifficulty;
  final int occurredAt;

  NanikiruSkillMasteryProfile applyTo(
    NanikiruSkillMasteryProfile profile,
  ) {
    return profile.recordAttempt(
      skillIds: skillIds,
      outcome: outcome,
      puzzleDifficulty: puzzleDifficulty,
      occurredAt: occurredAt,
    );
  }
}
