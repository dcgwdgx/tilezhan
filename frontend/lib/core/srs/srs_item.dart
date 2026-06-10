class SrsItem {
  final String itemId;   // tile id or puzzle id
  final String type;     // 'flashcard' | 'nanikiru'
  final double ef;       // easiness factor (start 2.5)
  final int reps;        // consecutive correct recalls
  final int interval;    // days until next review
  final int nextReviewAt; // epoch ms
  final int errors;

  const SrsItem({
    required this.itemId,
    required this.type,
    this.ef = 2.5,
    this.reps = 0,
    this.interval = 1,
    this.nextReviewAt = 0,
    this.errors = 0,
  });

  SrsItem copyWith({double? ef, int? reps, int? interval, int? nextReviewAt, int? errors}) =>
      SrsItem(itemId: itemId, type: type,
        ef: ef ?? this.ef, reps: reps ?? this.reps,
        interval: interval ?? this.interval,
        nextReviewAt: nextReviewAt ?? this.nextReviewAt,
        errors: errors ?? this.errors);

  Map<String, dynamic> toJson() => {'itemId':itemId,'type':type,'ef':ef,'reps':reps,'interval':interval,'nextReviewAt':nextReviewAt,'errors':errors};
  factory SrsItem.fromJson(Map<String, dynamic> j) => SrsItem(
    itemId: j['itemId'], type: j['type']??'flashcard',
    ef: (j['ef'] as num?)?.toDouble()??2.5, reps: j['reps']??0,
    interval: j['interval']??1, nextReviewAt: j['nextReviewAt']??0, errors: j['errors']??0);
}
