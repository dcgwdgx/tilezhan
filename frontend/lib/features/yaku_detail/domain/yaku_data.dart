/// 日麻常见役种数据 — 12 个入门到高级役种。
///
/// 每个役种包含：名称(英/日)、番数(门清/副露)、难度、成立条件、
/// 示例牌型、常见组合、实战口诀。供 [YakuDetailScreen] 渲染详情页。
/// 结构对齐 tilezhan-design-spec.md §4.8 番型详情。
class YakuData {
  /// 唯一 ID，对应 Scanner 列表中的路由参数 /yaku/:id。
  final String id;
  /// English name of the yaku.
  final String nameEn;
  /// Japanese name in kanji.
  final String nameJp;
  /// Base han value (open or closed).
  final int han;
  /// Han value when the hand is fully closed (menzen).
  final int hanClosed;
  /// Difficulty tier: Beginner / Intermediate / Advanced.
  final String difficulty;
  /// Explanation of how the yaku is formed and scored.
  final String description;
  /// Requirements that must be satisfied for the yaku to count.
  final List<String> conditions;
  /// Example hand strings showing the tile pattern.
  final List<String> examples;
  /// Common compound yaku combinations and their total han.
  final List<YakuCombo> combos;
  /// Practical advice for forming this yaku in real play.
  final String tip;

  const YakuData({
    required this.id, required this.nameEn, required this.nameJp,
    required this.han, required this.hanClosed,
    required this.difficulty, required this.description,
    required this.conditions, required this.examples,
    required this.combos, required this.tip,
  });
}

class YakuCombo {
  /// Human-readable name of the compound (e.g. "Riichi + Ippatsu").
  final String name;
  /// Combined han value of the compound.
  final int totalHan;
  const YakuCombo(this.name, this.totalHan);
}

/// All available yaku for the detail page.
const List<YakuData> allYaku = [
  /// Riichi: closed-hand declaration yaku. Deposit a 1,000-point stick when
  /// in tenpai; unlocks ippatsu and ura-dora bonuses.
  YakuData(
    id: 'riichi', nameEn: 'Riichi', nameJp: '立直',
    han: 1, hanClosed: 1, difficulty: 'Beginner',
    description: 'Declare "Riichi" when you are one tile away from a complete hand. '
        'Place a 1,000-point stick on the table and draw your winning tile.',
    conditions: ['Hand must be fully closed (no open melds)',
      'Must be in tenpai (one tile from winning)',
      'Must have at least 1,000 points to declare'],
    examples: ['🀇🀈🀉 🀐🀑🀒 🀛🀜🀝 🀅🀅 → Riichi ready on any valid tile'],
    combos: [YakuCombo('Riichi + Ippatsu', 2), YakuCombo('Riichi + Tsumo', 2),
      YakuCombo('Riichi + Pinfu', 2), YakuCombo('Riichi + Menzen Tsumo', 2)],
    tip: 'Always declare Riichi when you can. The extra han plus the chance of Ippatsu or Ura Dora makes it one of the most powerful yaku.',
  ),
  /// Tanyao: simple tiles only (numbered 2-8). No terminals, no honors.
  /// The most common yaku in modern mahjong — fast and reliable.
  YakuData(
    id: 'tanyao', nameEn: 'Tanyao (All Simples)', nameJp: '断幺九',
    han: 1, hanClosed: 1, difficulty: 'Beginner',
    description: 'A hand consisting entirely of numbered tiles 2-8. '
        'No terminals (1 or 9) and no honor tiles (winds/dragons).',
    conditions: ['All tiles must be numbers 2-8 of any suit',
      'No 1s, 9s, winds, or dragons anywhere in the hand',
      'Can be open or closed (open = 1 han)'],
    examples: ['🀈🀉🀊 🀒🀓🀔 🀖🀗🀘 🀝🀝 → Pure 2-8 tiles across all suits'],
    combos: [YakuCombo('Tanyao + Pinfu', 2), YakuCombo('Tanyao + Menzen Tsumo', 2)],
    tip: 'Tanyao is the most common yaku in modern mahjong. When your hand has no terminals or honors, go for it — it\'s fast and reliable.',
  ),
  /// Pinfu: all-sequences closed hand with a two-sided wait and a non-value
  /// pair. Adds no fu beyond the base 20 — a "zero-cost" yaku.
  YakuData(
    id: 'pinfu', nameEn: 'Pinfu (Peaceful Hand)', nameJp: '平和',
    han: 1, hanClosed: 1, difficulty: 'Beginner',
    description: 'A completely closed hand with no fu (minipoints) beyond the base 20. '
        'All sets are sequences, the pair is not a value pair, and the wait is two-sided.',
    conditions: ['All four sets must be sequences (no triplets)',
      'The pair must not be a value pair (winds, dragons)',
      'Must have a two-sided wait (ryanmen)',
      'Must be fully closed (menzen)'],
    examples: ['🀈🀉🀊 🀒🀓🀔 🀖🀗🀘 🀛🀜🀝 🀅🀅 → Two-sided wait on 5m or 8m'],
    combos: [YakuCombo('Pinfu + Tanyao', 2), YakuCombo('Pinfu + Menzen Tsumo', 2)],
    tip: 'Pinfu is a "zero-cost" yaku — you can build it naturally while going for other yaku. Focus on making sequences and a safe pair.',
  ),
  /// Yakuhai: triplet of a dragon tile, the round wind, or your seat wind.
  /// The fastest way to secure 1 han and meet the minimum yaku requirement.
  YakuData(
    id: 'yakuhai', nameEn: 'Yakuhai (Value Honor)', nameJp: '役牌',
    han: 1, hanClosed: 1, difficulty: 'Beginner',
    description: 'A hand containing a triplet of any dragon tile or a triplet of '
        'the round wind or your seat wind.',
    conditions: ['Triplet of any dragon (🀄🀫🀅): Haku, Hatsu, Chun',
      'Triplet of the round wind (East = 🀀)',
      'Triplet of your seat wind'],
    examples: ['🀄🀄🀄 + any other sets → 1 han for White Dragon triplet'],
    combos: [YakuCombo('Yakuhai + Tanyao', 2), YakuCombo('Yakuhai + Honitsu', 4)],
    tip: 'If you draw a pair of dragons or seat winds early, keep them. A quick yakuhai triplet is the fastest way to get 1 han.',
  ),
  /// Iipeiko: two identical sequences in the same suit. Must be fully closed.
  /// Pairs of the same numbered tiles in one suit are the seed for this yaku.
  YakuData(
    id: 'iipeiko', nameEn: 'Iipeiko (Double Sequence)', nameJp: '一盃口',
    han: 1, hanClosed: 1, difficulty: 'Beginner',
    description: 'Two identical sequences in the same suit. Must be closed.',
    conditions: ['Two identical sequences (e.g. 2-3-4 and 2-3-4 of same suit)',
      'Must be fully closed hand'],
    examples: ['🀈🀉🀊 🀈🀉🀊 + other sets → Double 2-3-4 Bamboo sequences'],
    combos: [YakuCombo('Iipeiko + Pinfu', 2), YakuCombo('Iipeiko + Menzen Tsumo', 2)],
    tip: 'When you have two pairs of the same numbers in one suit, keep both — they can become an Iipeiko if you draw the third tile for each pair.',
  ),
  /// Chanta: every set (and the pair) must contain at least one terminal (1/9)
  /// or honor tile. Often pairs naturally with Honitsu.
  YakuData(
    id: 'chanta', nameEn: 'Chanta (Mixed Outside)', nameJp: '混全帯么九',
    han: 2, hanClosed: 1, difficulty: 'Intermediate',
    description: 'Every set must contain at least one terminal (1 or 9) or honor tile.',
    conditions: ['Every set must have a terminal or honor',
      'The pair must also be a terminal or honor',
      'Can be open (-1 han)'],
    examples: ['🀇🀈🀉 🀐🀑🀒 🀅🀅🀅 🀆🀆 → Every set touches a terminal or honor'],
    combos: [YakuCombo('Chanta + Honitsu', 5), YakuCombo('Chanta + Sanshoku', 4)],
    tip: 'Chanta often pairs with Honitsu. If your hand has mostly terminals and honors in one suit, go for both.',
  ),
  /// Honitsu: one number suit plus any honor tiles. Half flush — worth 3 han
  /// closed, 2 han open. Pivot when you have 7+ tiles of the same suit.
  YakuData(
    id: 'honitsu', nameEn: 'Honitsu (Half Flush)', nameJp: '混一色',
    han: 3, hanClosed: 2, difficulty: 'Intermediate',
    description: 'All tiles are from ONE suit plus any number of honor tiles.',
    conditions: ['Only one number suit throughout the hand',
      'Honor tiles (winds + dragons) are allowed',
      'Cannot contain tiles from a second number suit',
      'Open hand = 2 han, closed = 3 han'],
    examples: ['🀇🀈🀉 🀑🀒🀓 🀅🀅🀅 🀆🀆 → All Bamboo + honors'],
    combos: [YakuCombo('Honitsu + Toitoi', 5), YakuCombo('Honitsu + Yakuhai', 4)],
    tip: 'When you have 7+ tiles of the same suit, consider Honitsu. Discard tiles from other suits and keep honors for extra value.',
  ),
  /// Chitoitsu: seven unique pairs. Closed-only special hand — a classic
  /// "plan B" when you keep drawing pairs instead of sequences.
  YakuData(
    id: 'chitoitsu', nameEn: 'Chitoitsu (Seven Pairs)', nameJp: '七対子',
    han: 2, hanClosed: 2, difficulty: 'Intermediate',
    description: 'Seven distinct pairs. Must be fully closed.',
    conditions: ['Exactly seven pairs (14 tiles total)',
      'All pairs must be different — no duplicate pairs',
      'Must be fully closed — you cannot call tiles'],
    examples: ['🀇🀇 🀊🀊 🀎🀎 🀒🀒 🀕🀕 🀟🀟 🀅🀅 → Seven unique pairs'],
    combos: [YakuCombo('Chitoitsu + Tanyao', 3)],
    tip: 'Chitoitsu is a "plan B" hand. If you keep drawing pairs instead of sequences, switch to 7 pairs instead of fighting it.',
  ),
  /// Toitoi: all four sets are triplets (koutsu). No sequences. Works well
  /// when you start with multiple pairs — call pon aggressively.
  YakuData(
    id: 'toitoi', nameEn: 'Toitoi (All Triplets)', nameJp: '対々和',
    han: 2, hanClosed: 2, difficulty: 'Intermediate',
    description: 'All four sets are triplets. No sequences allowed.',
    conditions: ['All four sets must be triplets (koutsu)',
      'The pair completes the 14-tile hand',
      'Can be open or closed'],
    examples: ['🀇🀇🀇 🀍🀍🀍 🀏🀏🀏 🀕🀕🀕 🀆🀆 → All triplets'],
    combos: [YakuCombo('Toitoi + Honitsu', 5), YakuCombo('Toitoi + Yakuhai', 3)],
    tip: 'Toitoi works best when you already have two or more pairs. Call pon on any tile you can to speed up the hand.',
  ),
  /// Sanshoku: the same number sequence in all three suits (e.g. 2-3-4 in
  /// Bamboo, Characters, and Dots). Worth 2 han closed, 1 han open.
  YakuData(
    id: 'sanshoku', nameEn: 'Sanshoku (Mixed Triple)', nameJp: '三色同順',
    han: 2, hanClosed: 1, difficulty: 'Intermediate',
    description: 'The same sequence in all three suits.',
    conditions: ['Same number sequence in Bamboo, Characters, and Dots',
      'e.g. 2-3-4 in all three suits',
      'Can be open (-1 han)'],
    examples: ['🀇🀈🀉 + 🀐🀑🀒 + 🀙🀚🀛 → 1-2-3 in all three suits'],
    combos: [YakuCombo('Sanshoku + Pinfu', 3), YakuCombo('Sanshoku + Tanyao', 3)],
    tip: 'If you get the same sequence in two suits, keep tiles of that number in the third suit — you\'re one sequence away.',
  ),
  /// Ikkitsukan: three consecutive sequences in one suit — 1-2-3, 4-5-6,
  /// 7-8-9. A pure straight of nine tiles. Hard to plan, powerful when hit.
  YakuData(
    id: 'ikkitsukan', nameEn: 'Ikkitsukan (Pure Straight)', nameJp: '一気通貫',
    han: 2, hanClosed: 1, difficulty: 'Advanced',
    description: 'Three consecutive sequences of the same suit: 1-2-3, 4-5-6, 7-8-9.',
    conditions: ['1-2-3, 4-5-6, 7-8-9 of the SAME suit',
      'All three sequences must be present',
      'Can be open (-1 han)'],
    examples: ['🀇🀈🀉 🀊🀋🀌 🀍🀎🀏 → 1-9 in Bamboo (3 sequences)'],
    combos: [YakuCombo('Ikkitsukan + Pinfu', 3), YakuCombo('Ikkitsukan + Honitsu', 6)],
    tip: 'Ikkitsukan is hard to plan. If you naturally get 1-2-3 and 4-5-6 in one suit, pivot your hand to chase 7-8-9.',
  ),
  /// Chinitsu: all tiles from a single number suit. No honors permitted.
  /// Full flush — the highest-scoring common yaku at 6 han closed, 5 han open.
  YakuData(
    id: 'chinitsu', nameEn: 'Chinitsu (Full Flush)', nameJp: '清一色',
    han: 6, hanClosed: 5, difficulty: 'Advanced',
    description: 'All tiles are from a SINGLE suit. No honors allowed.',
    conditions: ['Every single tile must be from one number suit',
      'No honor tiles permitted',
      'Open hand = 5 han, closed = 6 han'],
    examples: ['🀇🀈🀉 🀋🀌🀍 🀎🀏🀐 🀑🀑 → Pure Bamboo hand'],
    combos: [YakuCombo('Chinitsu + Pinfu', 7), YakuCombo('Chinitsu + Tanyao', 7)],
    tip: 'If you start with 9+ tiles of one suit, go Chinitsu. Discard EVERYTHING from other suits — the 6 han payout is worth it.',
  ),
];

/// Looks up a yaku by its [id] in [allYaku]. Returns `null` if no match is found.
YakuData? getYakuById(String id) {
  try {
    return allYaku.firstWhere((y) => y.id == id);
  } catch (_) {
    return null;
  }
}
