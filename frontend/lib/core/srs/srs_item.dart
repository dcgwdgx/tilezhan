/// SM-2 spaced-repetition data model.
///
/// Contains the immutable [SrsItem] value-object together with its JSON
/// serialisation helpers.  Used by the review scheduler to decide which
/// item to serve next and how to update its interval/easiness after a grade.
///
/// See [SrsItem.errorWeight] for the prioritisation heuristic.

/// Immutable model for a single SM-2 spaced-repetition item.
///
/// Tracks review history (repetitions, interval, easiness factor) and
/// computes an [errorWeight] used to prioritise urgent items.
class SrsItem {
  final String itemId;
  final String type;       // 'flashcard' | 'nanikiru'
  final double ef;         // easiness factor (start 2.5)
  final int reps;          // consecutive correct
  final int interval;      // days until next review
  final int nextReviewAt;  // epoch ms
  final int errors;
  final int createdAt;     // epoch ms — first error
  final int lastReviewedAt;// epoch ms — most recent review

  /// Creates a new SM-2 item.
  ///
  /// [type] must be `'flashcard'` or `'nanikiru'`.
  /// [ef] defaults to the SM-2 starting easiness of 2.5.
  /// [interval] is in days; [nextReviewAt] / [createdAt] / [lastReviewedAt]
  /// are epoch milliseconds.
  const SrsItem({
    required this.itemId,
    required this.type,
    this.ef = 2.5,
    this.reps = 0,
    this.interval = 1,
    this.nextReviewAt = 0,
    this.errors = 0,
    this.createdAt = 0,
    this.lastReviewedAt = 0,
  });

  /// Higher = more urgent to review.
  double get errorWeight => reps == 0 ? errors.toDouble() : errors / (reps + 1);

  /// Returns a copy with the given fields replaced.
  SrsItem copyWith({
    double? ef, int? reps, int? interval, int? nextReviewAt,
    int? errors, int? createdAt, int? lastReviewedAt,
  }) => SrsItem(
    itemId: itemId, type: type,
    ef: ef ?? this.ef, reps: reps ?? this.reps,
    interval: interval ?? this.interval,
    nextReviewAt: nextReviewAt ?? this.nextReviewAt,
    errors: errors ?? this.errors,
    createdAt: createdAt ?? this.createdAt,
    lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
  );

  /// Serialises this item to a JSON-compatible map.
  Map<String, dynamic> toJson() => {
    'itemId':itemId,'type':type,'ef':ef,'reps':reps,'interval':interval,
    'nextReviewAt':nextReviewAt,'errors':errors,
    'createdAt':createdAt,'lastReviewedAt':lastReviewedAt,
  };
  /// Deserialises an [SrsItem] from a JSON-compatible map.
  factory SrsItem.fromJson(Map<String, dynamic> j) => SrsItem(
    itemId: j['itemId'], type: j['type']??'flashcard',
    ef: (j['ef'] as num?)?.toDouble()??2.5, reps: j['reps']??0,
    interval: j['interval']??1, nextReviewAt: j['nextReviewAt']??0,
    errors: j['errors']??0, createdAt: j['createdAt']??0,
    lastReviewedAt: j['lastReviewedAt']??0,
  );
}
