/// 日麻常见役种数据 — 12 个入门级役种。
/// 结构对齐 tilezhan-design-spec.md §4.8: 番型详情。
class YakuData {
  final String id;
  final String nameEn;
  final String nameJp;
  final int han;
  final int hanClosed; // 门前清时
  final String difficulty; // Beginner / Intermediate / Advanced
  final String description;
  final List<String> conditions;
  final List<String> examples;
  final List<YakuCombo> combos;
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
  final String name;
  final int totalHan;
  const YakuCombo(this.name, this.totalHan);
}

/// All available yaku for the detail page.
const List<YakuData> allYaku = [
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

YakuData? getYakuById(String id) {
  try {
    return allYaku.firstWhere((y) => y.id == id);
  } catch (_) {
    return null;
  }
}
