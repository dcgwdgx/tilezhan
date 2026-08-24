import 'dart:math' as math;

/// Stable module identifiers used by the persisted daily training plan.
enum TrainingModule { review, flashcard, nanikiru, defense, yaku }

/// Stable task kinds used by the daily plan.
enum TrainingTaskKind {
  starterLesson,
  dueReview,
  weakSkill,
  dailyChallenge,
  exploration,
}

extension TrainingModuleStorageId on TrainingModule {
  String get storageId => switch (this) {
        TrainingModule.review => 'review',
        TrainingModule.flashcard => 'flashcard',
        TrainingModule.nanikiru => 'nanikiru',
        TrainingModule.defense => 'defense',
        TrainingModule.yaku => 'yaku',
      };

  static TrainingModule? tryParse(Object? value) {
    if (value is! String) return null;
    for (final module in TrainingModule.values) {
      if (module.storageId == value) return module;
    }
    return null;
  }
}

extension TrainingTaskKindStorageId on TrainingTaskKind {
  String get storageId => switch (this) {
        TrainingTaskKind.starterLesson => 'starter_lesson',
        TrainingTaskKind.dueReview => 'due_review',
        TrainingTaskKind.weakSkill => 'weak_skill',
        TrainingTaskKind.dailyChallenge => 'daily_challenge',
        TrainingTaskKind.exploration => 'exploration',
      };

  static TrainingTaskKind? tryParse(Object? value) {
    if (value is! String) return null;
    for (final kind in TrainingTaskKind.values) {
      if (kind.storageId == value) return kind;
    }
    return null;
  }
}

/// One immutable item in a plan that is fixed for the whole local day.
class TrainingPlanTask {
  TrainingPlanTask({
    required String id,
    required this.kind,
    required this.module,
    required int targetAttempts,
    int completedAttempts = 0,
    String? focusSkillId,
  })  : id = _validatedId(id),
        targetAttempts = _validatedTarget(targetAttempts),
        completedAttempts = completedAttempts.clamp(0, targetAttempts).toInt(),
        focusSkillId = _normalizedOptionalId(focusSkillId);

  final String id;
  final TrainingTaskKind kind;
  final TrainingModule module;
  final int targetAttempts;
  final int completedAttempts;
  final String? focusSkillId;

  int get remainingAttempts => targetAttempts - completedAttempts;
  bool get isComplete => completedAttempts >= targetAttempts;
  double get progress => completedAttempts / targetAttempts;

  TrainingPlanTask recordOne() {
    if (isComplete) return this;
    return TrainingPlanTask(
      id: id,
      kind: kind,
      module: module,
      targetAttempts: targetAttempts,
      completedAttempts: completedAttempts + 1,
      focusSkillId: focusSkillId,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind.storageId,
        'module': module.storageId,
        'targetAttempts': targetAttempts,
        'completedAttempts': completedAttempts,
        if (focusSkillId != null) 'focusSkillId': focusSkillId,
      };

  static TrainingPlanTask? tryFromJson(Object? value) {
    if (value is! Map) return null;
    try {
      final json = Map<String, dynamic>.from(value);
      final id = json['id'];
      final kind = TrainingTaskKindStorageId.tryParse(json['kind']);
      final module = TrainingModuleStorageId.tryParse(json['module']);
      final targetAttempts = _exactInt(json['targetAttempts']);
      if (id is! String ||
          kind == null ||
          module == null ||
          targetAttempts == null ||
          targetAttempts < 1 ||
          targetAttempts > maximumTargetAttempts) {
        return null;
      }
      return TrainingPlanTask(
        id: id,
        kind: kind,
        module: module,
        targetAttempts: targetAttempts,
        completedAttempts: _nonNegativeInt(json['completedAttempts']),
        focusSkillId:
            json['focusSkillId'] is String ? json['focusSkillId'] : null,
      );
    } on Object {
      return null;
    }
  }

  static const maximumTargetAttempts = 20;

  static String _validatedId(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty || normalized.length > 160) {
      throw ArgumentError.value(value, 'id', 'Expected 1 to 160 characters');
    }
    return normalized;
  }

  static int _validatedTarget(int value) {
    if (value < 1 || value > maximumTargetAttempts) {
      throw RangeError.range(value, 1, maximumTargetAttempts, 'targetAttempts');
    }
    return value;
  }

  static String? _normalizedOptionalId(String? value) {
    if (value == null) return null;
    final normalized = value.trim();
    if (normalized.isEmpty || normalized.length > 160) return null;
    return normalized;
  }
}

/// One answer event accepted by a learning screen.
///
/// The caller owns [eventId]. It must stay the same if an already accepted
/// answer is accidentally delivered twice. The plan stores accepted IDs for
/// the current day so widget rebuilds cannot advance progress twice.
class TrainingAttemptEvent {
  TrainingAttemptEvent({
    required String eventId,
    required this.module,
    required this.occurredAt,
    this.isReview = false,
    this.isDailyChallenge = false,
    Iterable<String> skillIds = const [],
  })  : eventId = _validateEventId(eventId),
        skillIds = Set<String>.unmodifiable(
          skillIds
              .map((value) => value.trim())
              .where((value) => value.isNotEmpty && value.length <= 160),
        ) {
    if (occurredAt < 0) {
      throw ArgumentError.value(occurredAt, 'occurredAt');
    }
    if (isReview && isDailyChallenge) {
      throw ArgumentError(
        'An attempt cannot be both a review and a daily challenge',
      );
    }
  }

  final String eventId;
  final TrainingModule module;
  final int occurredAt;
  final bool isReview;
  final bool isDailyChallenge;
  final Set<String> skillIds;

  DateTime get localDate =>
      DateTime.fromMillisecondsSinceEpoch(occurredAt).toLocal();

  static String _validateEventId(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty || normalized.length > 200) {
      throw ArgumentError.value(
        value,
        'eventId',
        'Expected 1 to 200 characters',
      );
    }
    return normalized;
  }
}

/// Versioned, offline-first plan and completion history for one local day.
class DailyTrainingPlan {
  DailyTrainingPlan({
    required DateTime localDate,
    required List<TrainingPlanTask> tasks,
    int currentStreak = 0,
    int bestStreak = 0,
    String lastCompletedDate = '',
    int completedAt = 0,
    int updatedAt = 0,
    List<String> acceptedEventIds = const [],
  }) : this._(
          localDateKey: trainingDateKey(localDate),
          tasks: tasks,
          currentStreak: math.max(0, currentStreak),
          bestStreak: math.max(math.max(0, currentStreak), bestStreak),
          lastCompletedDate: _validDateKey(lastCompletedDate) ?? '',
          completedAt: math.max(0, completedAt),
          updatedAt: math.max(0, updatedAt),
          acceptedEventIds: acceptedEventIds,
          sourceSchemaVersion: schemaVersion,
          sourcePlanVersion: planVersion,
          isReadOnly: false,
        );

  DailyTrainingPlan._({
    required this.localDateKey,
    required List<TrainingPlanTask> tasks,
    required this.currentStreak,
    required this.bestStreak,
    required this.lastCompletedDate,
    required this.completedAt,
    required this.updatedAt,
    required List<String> acceptedEventIds,
    required this.sourceSchemaVersion,
    required this.sourcePlanVersion,
    required this.isReadOnly,
  })  : tasks = List<TrainingPlanTask>.unmodifiable(_uniqueTasks(tasks)),
        acceptedEventIds = List<String>.unmodifiable(
          _uniqueEventIds(acceptedEventIds),
        );

  static const schemaVersion = 1;
  static const planVersion = 1;
  static const maximumAcceptedEventIds = 256;

  final String localDateKey;
  final List<TrainingPlanTask> tasks;
  final int currentStreak;
  final int bestStreak;
  final String lastCompletedDate;
  final int completedAt;
  final int updatedAt;
  final List<String> acceptedEventIds;
  final int sourceSchemaVersion;
  final int sourcePlanVersion;
  final bool isReadOnly;

  int get completedAttempts =>
      tasks.fold(0, (total, task) => total + task.completedAttempts);
  int get targetAttempts =>
      tasks.fold(0, (total, task) => total + task.targetAttempts);
  bool get isComplete =>
      tasks.isNotEmpty && tasks.every((task) => task.isComplete);
  double get progress =>
      targetAttempts == 0 ? 0 : completedAttempts / targetAttempts;
  TrainingPlanTask? get nextTask {
    for (final task in tasks) {
      if (!task.isComplete) return task;
    }
    return null;
  }

  /// Creates the next local day's fixed plan while retaining streak history.
  factory DailyTrainingPlan.forNewDay({
    required DateTime localDate,
    required List<TrainingPlanTask> tasks,
    DailyTrainingPlan? previous,
    bool readOnly = false,
    int? sourceSchemaVersion,
    int? sourcePlanVersion,
  }) {
    final dateKey = trainingDateKey(localDate);
    final yesterday = previousDateKey(localDate);
    final previousCompletion = previous?.lastCompletedDate ?? '';
    final carriedStreak =
        previousCompletion == yesterday || previousCompletion == dateKey
            ? previous?.currentStreak ?? 0
            : 0;
    return DailyTrainingPlan._(
      localDateKey: dateKey,
      tasks: tasks,
      currentStreak: carriedStreak,
      bestStreak: math.max(previous?.bestStreak ?? 0, carriedStreak),
      lastCompletedDate: previousCompletion,
      completedAt: 0,
      updatedAt: previous?.updatedAt ?? 0,
      acceptedEventIds: const [],
      sourceSchemaVersion:
          sourceSchemaVersion ?? previous?.sourceSchemaVersion ?? schemaVersion,
      sourcePlanVersion:
          sourcePlanVersion ?? previous?.sourcePlanVersion ?? planVersion,
      isReadOnly: readOnly || (previous?.isReadOnly ?? false),
    );
  }

  /// Applies one accepted answer to at most one incomplete task.
  ///
  /// Returns this identical instance if the event is duplicated, belongs to a
  /// different local day, or cannot advance any task.
  DailyTrainingPlan recordAcceptedAttempt(TrainingAttemptEvent event) {
    if (trainingDateKey(event.localDate) != localDateKey ||
        acceptedEventIds.contains(event.eventId)) {
      return this;
    }

    var matchedIndex = -1;
    for (var index = 0; index < tasks.length; index++) {
      final task = tasks[index];
      if (!task.isComplete && _matches(task, event)) {
        matchedIndex = index;
        break;
      }
    }
    if (matchedIndex < 0) return this;

    final wasComplete = isComplete;
    final nextTasks = List<TrainingPlanTask>.of(tasks);
    nextTasks[matchedIndex] = nextTasks[matchedIndex].recordOne();
    final nextIsComplete = nextTasks.every((task) => task.isComplete);

    var nextCurrentStreak = currentStreak;
    var nextBestStreak = bestStreak;
    var nextLastCompletedDate = lastCompletedDate;
    var nextCompletedAt = completedAt;
    if (!wasComplete && nextIsComplete) {
      if (lastCompletedDate != localDateKey) {
        nextCurrentStreak =
            lastCompletedDate == previousDateKey(event.localDate)
                ? currentStreak + 1
                : 1;
      }
      nextBestStreak = math.max(bestStreak, nextCurrentStreak);
      nextLastCompletedDate = localDateKey;
      nextCompletedAt = event.occurredAt;
    }

    final nextEventIds = <String>[...acceptedEventIds, event.eventId];
    if (nextEventIds.length > maximumAcceptedEventIds) {
      nextEventIds.removeRange(
        0,
        nextEventIds.length - maximumAcceptedEventIds,
      );
    }
    return DailyTrainingPlan._(
      localDateKey: localDateKey,
      tasks: nextTasks,
      currentStreak: nextCurrentStreak,
      bestStreak: nextBestStreak,
      lastCompletedDate: nextLastCompletedDate,
      completedAt: nextCompletedAt,
      updatedAt: math.max(updatedAt, event.occurredAt),
      acceptedEventIds: nextEventIds,
      sourceSchemaVersion: sourceSchemaVersion,
      sourcePlanVersion: sourcePlanVersion,
      isReadOnly: isReadOnly,
    );
  }

  Map<String, dynamic> toJson() {
    if (isReadOnly) {
      throw StateError('A future daily training plan must not be overwritten');
    }
    return {
      'schemaVersion': schemaVersion,
      'planVersion': planVersion,
      'localDate': localDateKey,
      'tasks': tasks.map((task) => task.toJson()).toList(growable: false),
      'currentStreak': currentStreak,
      'bestStreak': bestStreak,
      'lastCompletedDate': lastCompletedDate,
      'completedAt': completedAt,
      'updatedAt': updatedAt,
      'acceptedEventIds': acceptedEventIds,
    };
  }

  /// Safely decodes a persisted plan. Missing or malformed current schemas
  /// return null so the generator can create a clean plan. Future versions are
  /// represented as read-only to prevent older builds overwriting newer data.
  static DailyTrainingPlan? tryFromJson(Map<String, dynamic> json) {
    if (json.isEmpty) return null;
    final rawSchema = _exactInt(json['schemaVersion']);
    final rawPlan = _exactInt(json['planVersion']);
    final rawDate = _validDateKey(json['localDate']);

    if ((rawSchema ?? 0) > schemaVersion || (rawPlan ?? 0) > planVersion) {
      final fallbackDate = rawDate ?? trainingDateKey(DateTime.now());
      final current = _nonNegativeInt(json['currentStreak']);
      return DailyTrainingPlan._(
        localDateKey: fallbackDate,
        tasks: const [],
        currentStreak: current,
        bestStreak: math.max(current, _nonNegativeInt(json['bestStreak'])),
        lastCompletedDate: _validDateKey(json['lastCompletedDate']) ?? '',
        completedAt: 0,
        updatedAt: _nonNegativeInt(json['updatedAt']),
        acceptedEventIds: const [],
        sourceSchemaVersion: rawSchema ?? schemaVersion,
        sourcePlanVersion: rawPlan ?? planVersion,
        isReadOnly: true,
      );
    }

    if (rawSchema != schemaVersion ||
        rawPlan != planVersion ||
        rawDate == null ||
        json['tasks'] is! List) {
      return null;
    }

    final tasks = <TrainingPlanTask>[];
    for (final value in json['tasks'] as List) {
      final task = TrainingPlanTask.tryFromJson(value);
      if (task != null) tasks.add(task);
    }
    final uniqueTasks = _uniqueTasks(tasks);
    if (uniqueTasks.isEmpty) return null;

    final acceptedEventIds = json['acceptedEventIds'] is List
        ? (json['acceptedEventIds'] as List).whereType<String>().toList()
        : const <String>[];
    final current = _nonNegativeInt(json['currentStreak']);
    final complete = uniqueTasks.every((task) => task.isComplete);
    return DailyTrainingPlan._(
      localDateKey: rawDate,
      tasks: uniqueTasks,
      currentStreak: current,
      bestStreak: math.max(current, _nonNegativeInt(json['bestStreak'])),
      lastCompletedDate: _validDateKey(json['lastCompletedDate']) ?? '',
      completedAt: complete ? _nonNegativeInt(json['completedAt']) : 0,
      updatedAt: _nonNegativeInt(json['updatedAt']),
      acceptedEventIds: acceptedEventIds,
      sourceSchemaVersion: schemaVersion,
      sourcePlanVersion: planVersion,
      isReadOnly: false,
    );
  }

  static bool _matches(TrainingPlanTask task, TrainingAttemptEvent event) {
    return switch (task.kind) {
      TrainingTaskKind.dueReview => event.isReview,
      TrainingTaskKind.dailyChallenge =>
        event.isDailyChallenge && event.module == TrainingModule.nanikiru,
      TrainingTaskKind.starterLesson ||
      TrainingTaskKind.exploration =>
        !event.isReview &&
            !event.isDailyChallenge &&
            event.module == task.module,
      TrainingTaskKind.weakSkill => !event.isReview &&
          !event.isDailyChallenge &&
          event.module == task.module &&
          (task.focusSkillId == null ||
              event.skillIds.contains(task.focusSkillId)),
    };
  }

  static List<TrainingPlanTask> _uniqueTasks(
    Iterable<TrainingPlanTask> source,
  ) {
    final seen = <String>{};
    return [
      for (final task in source)
        if (seen.add(task.id)) task
    ];
  }

  static List<String> _uniqueEventIds(Iterable<String> source) {
    final seen = <String>{};
    final normalized = <String>[];
    for (final raw in source) {
      final value = raw.trim();
      if (value.isEmpty || value.length > 200 || !seen.add(value)) continue;
      normalized.add(value);
    }
    if (normalized.length <= maximumAcceptedEventIds) return normalized;
    return normalized.sublist(normalized.length - maximumAcceptedEventIds);
  }
}

String trainingDateKey(DateTime value) {
  final local = value.toLocal();
  return '${local.year.toString().padLeft(4, '0')}-'
      '${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')}';
}

String previousDateKey(DateTime value) {
  final local = value.toLocal();
  return trainingDateKey(
    DateTime(local.year, local.month, local.day)
        .subtract(const Duration(days: 1)),
  );
}

String? _validDateKey(Object? value) {
  if (value is! String || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
    return null;
  }
  final parts = value.split('-').map(int.parse).toList(growable: false);
  final parsed = DateTime(parts[0], parts[1], parts[2]);
  return trainingDateKey(parsed) == value ? value : null;
}

int _nonNegativeInt(Object? value) {
  final parsed = _exactInt(value);
  return parsed == null ? 0 : math.max(0, parsed);
}

int? _exactInt(Object? value) {
  if (value is int) return value;
  if (value is num && value.isFinite && value == value.toInt()) {
    return value.toInt();
  }
  return null;
}
