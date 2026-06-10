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

  Map<String, dynamic> toJson() => {
    'itemId':itemId,'type':type,'ef':ef,'reps':reps,'interval':interval,
    'nextReviewAt':nextReviewAt,'errors':errors,
    'createdAt':createdAt,'lastReviewedAt':lastReviewedAt,
  };
  factory SrsItem.fromJson(Map<String, dynamic> j) => SrsItem(
    itemId: j['itemId'], type: j['type']??'flashcard',
    ef: (j['ef'] as num?)?.toDouble()??2.5, reps: j['reps']??0,
    interval: j['interval']??1, nextReviewAt: j['nextReviewAt']??0,
    errors: j['errors']??0, createdAt: j['createdAt']??0,
    lastReviewedAt: j['lastReviewedAt']??0,
  );
}
