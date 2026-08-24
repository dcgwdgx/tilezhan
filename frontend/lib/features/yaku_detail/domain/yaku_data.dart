/// 日麻常见役种数据模型 — 涵盖 39 个入门到役满役种。
///
/// 每个役种包含：唯一标识、名称（英文/日文）、番数（门清/副露）、难度级别、
/// 成立条件、示例牌型、常见复合组合与实战口诀。
/// 供 [YakuDetailScreen] 渲染役种详情页使用。
/// 数据结构对齐 tilezhan-design-spec.md §4.8 番型详情规范。
class YakuData {
  /// 役种唯一标识，对应 Scanner 列表中的路由参数 /yaku/:id，
  /// 用于详情页导航与数据查找。
  final String id;

  /// 役种英文名称，用于 UI 主标题展示。
  final String nameEn;

  /// 役种日文名称（汉字表示），用于副标题与文化准确性。
  final String nameJp;

  /// 门清状态下的番数。
  final int closedHan;

  /// 副露状态下的番数；门清限定役为 `null`。
  final int? openHan;

  /// 难度分级标签：Beginner（入门）/ Intermediate（中级）/ Advanced（高级）。
  final String difficulty;

  /// 役种成立条件与计分方式的详细文字说明。
  final String description;

  /// 役种成立所必须满足的条件列表，逐条列出。
  final List<String> conditions;

  /// 示例牌型字符串集合，使用麻将牌 emoji 展示典型牌姿。
  final List<String> examples;

  /// 常见复合役种组合列表，每个条目包含组合名称与合计番数。
  final List<YakuCombo> combos;

  /// 实战中构建该役种的实用技巧与策略建议。
  final String tip;

  /// 构造一个 [YakuData] 实例，所有字段均为必填参数。
  /// 此构造为 const，确保役种数据在编译期即可确定，零运行时开销。
  const YakuData({
    required this.id,
    required this.nameEn,
    required this.nameJp,
    required this.closedHan,
    required this.openHan,
    required this.difficulty,
    required this.description,
    required this.conditions,
    required this.examples,
    required this.combos,
    required this.tip,
  });
}

/// 役种复合组合数据模型。
///
/// 描述两个及以上役种复合出现时的组合名称与合计番数，
/// 用于役种详情页展示常见搭配及其得分参考。
class YakuCombo {
  /// 复合组合的可读名称，例如 "Riichi + Ippatsu" 或 "Chinitsu + Pinfu"。
  final String name;

  /// 该复合组合的合计番数，为各组成役种番数之和。
  final int totalHan;

  /// 构造一个 [YakuCombo] 实例。
  /// [name] 为组合可读名称，[totalHan] 为合计番数。
  const YakuCombo(this.name, this.totalHan);
}

/// 全部可用役种列表，供役种详情页展示与查找。
/// 涵盖从入门到役满的 39 个役种，按难度递进排列。
const List<YakuData> allYaku = [
  /// 立直（Riichi）：门清宣言役。听牌时支付 1,000 点供託棒并宣言立直，
  /// 解锁一发与里宝牌额外番数加成，是日麻中最具代表性的役种。
  YakuData(
    id: 'riichi',
    nameEn: 'Riichi',
    nameJp: '立直',
    closedHan: 1,
    openHan: null,
    difficulty: 'Beginner',
    description:
        'Declare "Riichi" when you are one tile away from a complete hand. '
        'Place a 1,000-point stick on the table and draw your winning tile.',
    conditions: [
      'Hand must be fully closed (no open melds)',
      'Must be in tenpai (one tile from winning)',
      'Must have at least 1,000 points to declare'
    ],
    examples: ['🀇🀈🀉 🀐🀑🀒 🀛🀜🀝 🀅🀅 → Riichi ready on any valid tile'],
    combos: [
      YakuCombo('Riichi + Ippatsu', 2),
      YakuCombo('Riichi + Tsumo', 2),
      YakuCombo('Riichi + Pinfu', 2),
      YakuCombo('Riichi + Menzen Tsumo', 2)
    ],
    tip:
        'Always declare Riichi when you can. The extra han plus the chance of Ippatsu or Ura Dora makes it one of the most powerful yaku.',
  ),

  /// 断幺九（Tanyao / All Simples）：仅使用数牌 2-8，不含任何幺九牌（1/9）
  /// 与字牌（风牌/三元牌）。现代麻将中使用频率最高的役种，快速可靠。
  YakuData(
    id: 'tanyao',
    nameEn: 'Tanyao (All Simples)',
    nameJp: '断幺九',
    closedHan: 1,
    openHan: 1,
    difficulty: 'Beginner',
    description: 'A hand consisting entirely of numbered tiles 2-8. '
        'No terminals (1 or 9) and no honor tiles (winds/dragons).',
    conditions: [
      'All tiles must be numbers 2-8 of any suit',
      'No 1s, 9s, winds, or dragons anywhere in the hand',
      'Can be open or closed (open = 1 han)'
    ],
    examples: ['🀈🀉🀊 🀒🀓🀔 🀖🀗🀘 🀝🀝 → Pure 2-8 tiles across all suits'],
    combos: [
      YakuCombo('Tanyao + Pinfu', 2),
      YakuCombo('Tanyao + Menzen Tsumo', 2)
    ],
    tip:
        'Tanyao is the most common yaku in modern mahjong. When your hand has no terminals or honors, go for it — it\'s fast and reliable.',
  ),

  /// 平和（Pinfu / Peaceful Hand）：全顺子门清手牌，两面听且雀头非役牌。
  /// 除底符 20 之外不附加任何符数——"零成本"役种，可在追求其他役种时自然成型。
  YakuData(
    id: 'pinfu',
    nameEn: 'Pinfu (Peaceful Hand)',
    nameJp: '平和',
    closedHan: 1,
    openHan: null,
    difficulty: 'Beginner',
    description:
        'A completely closed hand with no fu (minipoints) beyond the base 20. '
        'All sets are sequences, the pair is not a value pair, and the wait is two-sided.',
    conditions: [
      'All four sets must be sequences (no triplets)',
      'The pair must not be a value pair (winds, dragons)',
      'Must have a two-sided wait (ryanmen)',
      'Must be fully closed (menzen)'
    ],
    examples: ['🀈🀉🀊 🀒🀓🀔 🀖🀗🀘 🀛🀜🀝 🀅🀅 → Two-sided wait on 5m or 8m'],
    combos: [
      YakuCombo('Pinfu + Tanyao', 2),
      YakuCombo('Pinfu + Menzen Tsumo', 2)
    ],
    tip:
        'Pinfu is a "zero-cost" yaku — you can build it naturally while going for other yaku. Focus on making sequences and a safe pair.',
  ),

  /// 役牌（Yakuhai / Value Honor）：三元牌（白/发/中）、场风或自风的刻子。
  /// 获取 1 番并满足起和最低番数要求的最快途径——早期摸到役牌对子务必保留。
  YakuData(
    id: 'yakuhai',
    nameEn: 'Yakuhai (Value Honor)',
    nameJp: '役牌',
    closedHan: 1,
    openHan: 1,
    difficulty: 'Beginner',
    description:
        'A hand containing a triplet of any dragon tile or a triplet of '
        'the round wind or your seat wind.',
    conditions: [
      'Triplet of any dragon (🀄🀫🀅): Haku, Hatsu, Chun',
      'Triplet of the round wind (East = 🀀)',
      'Triplet of your seat wind'
    ],
    examples: ['🀄🀄🀄 + any other sets → 1 han for White Dragon triplet'],
    combos: [
      YakuCombo('Yakuhai + Toitoi', 3),
      YakuCombo('Yakuhai + Honitsu', 4)
    ],
    tip:
        'If you draw a pair of dragons or seat winds early, keep them. A quick yakuhai triplet is the fastest way to get 1 han.',
  ),

  /// 一盃口（Iipeiko / Double Sequence）：同花色内两组完全相同的顺子，
  /// 必须门清。手中同一花色的相同数字对子是此役的种子牌。
  YakuData(
    id: 'iipeiko',
    nameEn: 'Iipeiko (Double Sequence)',
    nameJp: '一盃口',
    closedHan: 1,
    openHan: null,
    difficulty: 'Beginner',
    description: 'Two identical sequences in the same suit. Must be closed.',
    conditions: [
      'Two identical sequences (e.g. 2-3-4 and 2-3-4 of same suit)',
      'Must be fully closed hand'
    ],
    examples: ['🀈🀉🀊 🀈🀉🀊 + other sets → Double 2-3-4 Bamboo sequences'],
    combos: [
      YakuCombo('Iipeiko + Pinfu', 2),
      YakuCombo('Iipeiko + Menzen Tsumo', 2)
    ],
    tip:
        'When you have two pairs of the same numbers in one suit, keep both — they can become an Iipeiko if you draw the third tile for each pair.',
  ),

  /// 混全帯么九（Chanta / Mixed Outside）：每组面子（含雀头）必须至少包含
  /// 一张幺九牌（1 或 9）或字牌。常与混一色自然复合，门清 2 番副露 1 番。
  YakuData(
    id: 'chanta',
    nameEn: 'Chanta (Mixed Outside)',
    nameJp: '混全帯么九',
    closedHan: 2,
    openHan: 1,
    difficulty: 'Intermediate',
    description:
        'Every set must contain at least one terminal (1 or 9) or honor tile.',
    conditions: [
      'Every set must have a terminal or honor',
      'The pair must also be a terminal or honor',
      'Can be open (-1 han)'
    ],
    examples: [
      '🀇🀈🀉 🀐🀑🀒 🀅🀅🀅 🀆🀆 → Every set touches a terminal or honor'
    ],
    combos: [
      YakuCombo('Chanta + Honitsu', 5),
      YakuCombo('Chanta + Sanshoku', 4)
    ],
    tip:
        'Chanta often pairs with Honitsu. If your hand has mostly terminals and honors in one suit, go for both.',
  ),

  /// 混一色（Honitsu / Half Flush）：单一数牌花色 + 任意字牌。
  /// 半清一色——门清 3 番、副露 2 番。手中同花色牌达 7 张以上时，
  /// 果断转向混一色，弃掉其他花色保留字牌以最大化番值。
  YakuData(
    id: 'honitsu',
    nameEn: 'Honitsu (Half Flush)',
    nameJp: '混一色',
    closedHan: 3,
    openHan: 2,
    difficulty: 'Intermediate',
    description: 'All tiles are from ONE suit plus any number of honor tiles.',
    conditions: [
      'Only one number suit throughout the hand',
      'Honor tiles (winds + dragons) are allowed',
      'Cannot contain tiles from a second number suit',
      'Open hand = 2 han, closed = 3 han'
    ],
    examples: ['🀇🀈🀉 🀑🀒🀓 🀅🀅🀅 🀆🀆 → All Bamboo + honors'],
    combos: [
      YakuCombo('Honitsu + Toitoi', 5),
      YakuCombo('Honitsu + Yakuhai', 4)
    ],
    tip:
        'When you have 7+ tiles of the same suit, consider Honitsu. Discard tiles from other suits and keep honors for extra value.',
  ),

  /// 七対子（Chitoitsu / Seven Pairs）：七组各不相同的对子，共 14 张。
  /// 必须完全门清的特殊牌形——手中连续摸到对子时的经典"B 计划"，
  /// 放弃顺子构建，专注凑齐七个不同对子。
  YakuData(
    id: 'chitoitsu',
    nameEn: 'Chitoitsu (Seven Pairs)',
    nameJp: '七対子',
    closedHan: 2,
    openHan: null,
    difficulty: 'Intermediate',
    description: 'Seven distinct pairs. Must be fully closed.',
    conditions: [
      'Exactly seven pairs (14 tiles total)',
      'All pairs must be different — no duplicate pairs',
      'Must be fully closed — you cannot call tiles'
    ],
    examples: ['🀇🀇 🀊🀊 🀎🀎 🀒🀒 🀕🀕 🀟🀟 🀅🀅 → Seven unique pairs'],
    combos: [YakuCombo('Chitoitsu + Tanyao', 3)],
    tip:
        'Chitoitsu is a "plan B" hand. If you keep drawing pairs instead of sequences, switch to 7 pairs instead of fighting it.',
  ),

  /// 対々和（Toitoi / All Triplets）：四组面子全部由刻子（暗刻或明刻）组成，
  /// 不含任何顺子。起手多对子时此为最佳路线——积极碰牌加速手牌成型。
  YakuData(
    id: 'toitoi',
    nameEn: 'Toitoi (All Triplets)',
    nameJp: '対々和',
    closedHan: 2,
    openHan: 2,
    difficulty: 'Intermediate',
    description: 'All four sets are triplets. No sequences allowed.',
    conditions: [
      'All four sets must be triplets (koutsu)',
      'The pair completes the 14-tile hand',
      'Can be open or closed'
    ],
    examples: ['🀇🀇🀇 🀍🀍🀍 🀏🀏🀏 🀕🀕🀕 🀆🀆 → All triplets'],
    combos: [
      YakuCombo('Toitoi + Honitsu', 5),
      YakuCombo('Toitoi + Yakuhai', 3)
    ],
    tip:
        'Toitoi works best when you already have two or more pairs. Call pon on any tile you can to speed up the hand.',
  ),

  /// 三色同顺（Sanshoku / Mixed Triple）：同一数字的顺子在三色（万/筒/索）中
  /// 各有一组（如 2-3-4 同时出现在万、筒、索）。门清 2 番，副露降为 1 番。
  YakuData(
    id: 'sanshoku',
    nameEn: 'Sanshoku (Mixed Triple)',
    nameJp: '三色同順',
    closedHan: 2,
    openHan: 1,
    difficulty: 'Intermediate',
    description: 'The same sequence in all three suits.',
    conditions: [
      'Same number sequence in Bamboo, Characters, and Dots',
      'e.g. 2-3-4 in all three suits',
      'Can be open (-1 han)'
    ],
    examples: ['🀇🀈🀉 + 🀐🀑🀒 + 🀙🀚🀛 → 1-2-3 in all three suits'],
    combos: [
      YakuCombo('Sanshoku + Pinfu', 3),
      YakuCombo('Sanshoku + Tanyao', 3)
    ],
    tip:
        'If you get the same sequence in two suits, keep tiles of that number in the third suit — you\'re one sequence away.',
  ),

  /// 一気通貫（Ikkitsukan / Pure Straight）：同一花色内三组连续顺子——
  /// 1-2-3、4-5-6、7-8-9，共九张牌组成一条纯正龙。难以刻意规划，
  /// 但一旦成型威力巨大。门清 2 番，副露 1 番。
  YakuData(
    id: 'ikkitsukan',
    nameEn: 'Ikkitsukan (Pure Straight)',
    nameJp: '一気通貫',
    closedHan: 2,
    openHan: 1,
    difficulty: 'Advanced',
    description:
        'Three consecutive sequences of the same suit: 1-2-3, 4-5-6, 7-8-9.',
    conditions: [
      '1-2-3, 4-5-6, 7-8-9 of the SAME suit',
      'All three sequences must be present',
      'Can be open (-1 han)'
    ],
    examples: ['🀇🀈🀉 🀊🀋🀌 🀍🀎🀏 → 1-9 in Bamboo (3 sequences)'],
    combos: [
      YakuCombo('Ikkitsukan + Pinfu', 3),
      YakuCombo('Ikkitsukan + Honitsu', 6)
    ],
    tip:
        'Ikkitsukan is hard to plan. If you naturally get 1-2-3 and 4-5-6 in one suit, pivot your hand to chase 7-8-9.',
  ),

  /// 清一色（Chinitsu / Full Flush）：全部牌张来自唯一数牌花色，不含任何字牌。
  /// 纯清一色——门清 6 番、副露 5 番，常见役种中番值最高的顶级役，
  /// 起手同花色牌达 9 张以上即可全力冲刺。
  YakuData(
    id: 'chinitsu',
    nameEn: 'Chinitsu (Full Flush)',
    nameJp: '清一色',
    closedHan: 6,
    openHan: 5,
    difficulty: 'Advanced',
    description: 'All tiles are from a SINGLE suit. No honors allowed.',
    conditions: [
      'Every single tile must be from one number suit',
      'No honor tiles permitted',
      'Open hand = 5 han, closed = 6 han'
    ],
    examples: ['🀇🀈🀉 🀋🀌🀍 🀎🀏🀐 🀑🀑 → Pure Bamboo hand'],
    combos: [
      YakuCombo('Chinitsu + Pinfu', 7),
      YakuCombo('Chinitsu + Tanyao', 7)
    ],
    tip:
        'If you start with 9+ tiles of one suit, go Chinitsu. Discard EVERYTHING from other suits — the 6 han payout is worth it.',
  ),

  // ═══ 1-Han Yaku (Continued) ═══

  /// 門前清自摸和（Menzen Tsumo）：完全门清状态下自摸和牌，奖励 1 番。
  /// 日麻中最常见的额外番来源之一，几乎每局都会出现。
  YakuData(
    id: 'menzen_tsumo',
    nameEn: 'Menzen Tsumo (Self-Draw)',
    nameJp: '門前清自摸和',
    closedHan: 1,
    openHan: null,
    difficulty: 'Beginner',
    description:
        'Win by drawing the winning tile yourself with a fully closed hand. Awards 1 extra han on top of any other yaku.',
    conditions: [
      'Hand must be fully closed (no open melds)',
      'Must draw the winning tile yourself (tsumo)',
      'Cannot be combined with a ron (discard) win'
    ],
    examples: [
      '🀇🀈🀉 🀐🀑🀒 🀛🀜🀝 🀅🀅 + 🀆 → Self-draw win with closed hand'
    ],
    combos: [
      YakuCombo('Menzen Tsumo + Riichi', 2),
      YakuCombo('Menzen Tsumo + Pinfu', 2)
    ],
    tip:
        'Menzen Tsumo is a "free" han when you keep your hand closed. Combined with Riichi, it\'s a reliable 2-han minimum.',
  ),

  /// 一発（Ippatsu）：立直宣言后一巡内和牌。稀有但高回报的奖励番。
  YakuData(
    id: 'ippatsu',
    nameEn: 'Ippatsu (One-Shot)',
    nameJp: '一発',
    closedHan: 1,
    openHan: null,
    difficulty: 'Intermediate',
    description:
        'Win within one full turn (4 discards) after declaring riichi, before anyone else calls a tile.',
    conditions: [
      'Must have declared riichi',
      'Win must occur within one turn after riichi declaration',
      'If anyone calls pon/chi/kan before your win, ippatsu is lost'
    ],
    examples: [
      'Riichi + immediate tsumo next turn → 2 han total (Riichi 1 + Ippatsu 1)'
    ],
    combos: [
      YakuCombo('Riichi + Ippatsu', 2),
      YakuCombo('Riichi + Ippatsu + Tsumo', 3)
    ],
    tip:
        'Ippatsu is pure luck — you can\'t plan for it. But when you get it, the psychological damage to opponents is real.',
  ),

  /// 海底摸月（Haitei Raoyue）：牌山最后一巡自摸和牌。
  YakuData(
    id: 'haitei',
    nameEn: 'Haitei Raoyue (Last Draw)',
    nameJp: '海底摸月',
    closedHan: 1,
    openHan: 1,
    difficulty: 'Intermediate',
    description:
        'Win on the very last tile drawn from the wall (the haitei tile). A rare, dramatic finish.',
    conditions: [
      'Must win on the absolute last draw from the wall',
      'The haitei tile is the final tile before the dead wall',
      'Cannot be combined with houtei (last discard) in the same hand'
    ],
    examples: ['Wall exhausts → draw last tile → Tsumo! → 1 extra han'],
    combos: [
      YakuCombo('Haitei + Menzen Tsumo', 2),
      YakuCombo('Haitei + any closed yaku', 2)
    ],
    tip:
        'If you\'re tenpai when the wall is almost exhausted, don\'t give up. The last draw can save your hand with an extra han.',
  ),

  /// 河底撈魚（Houtei Raoyui）：牌山最后一巡以他人舍牌和牌。
  YakuData(
    id: 'houtei',
    nameEn: 'Houtei Raoyui (Last Discard)',
    nameJp: '河底撈魚',
    closedHan: 1,
    openHan: 1,
    difficulty: 'Intermediate',
    description:
        'Win on the very last discard of the hand (the houtei tile). The last defensive chance for the dealer.',
    conditions: [
      'Must win on the final discard before the exhaustive draw',
      'The tile that completes your hand must be the last one discarded',
      'Cannot be combined with haitei'
    ],
    examples: [
      'Last turn → opponent discards your winning tile → Ron! → 1 extra han'
    ],
    combos: [YakuCombo('Houtei + any open yaku', 2)],
    tip:
        'When the wall is almost empty and you need just one tile, watch the final discards carefully. Someone may deal into your hand.',
  ),

  /// 嶺上開花（Rinshan Kaihou）：开杠后从岭上牌自摸和牌。
  YakuData(
    id: 'rinshan_kaihou',
    nameEn: 'Rinshan Kaihou (After Kan)',
    nameJp: '嶺上開花',
    closedHan: 1,
    openHan: 1,
    difficulty: 'Intermediate',
    description:
        'Win by drawing the replacement tile from the dead wall after declaring a kan. Turns a defensive move into a surprise attack.',
    conditions: [
      'Must declare a kan (open or closed)',
      'Draw the replacement tile from the dead wall',
      'The drawn tile must complete your hand'
    ],
    examples: ['Declare kan → draw from dead wall → Tsumo! → 1 extra han'],
    combos: [
      YakuCombo('Rinshan Kaihou + Menzen Tsumo', 2),
      YakuCombo('Rinshan + Toitoi', 3)
    ],
    tip:
        'Kanning when you\'re tenpai is a high-risk, high-reward play. If you draw the winning tile from the dead wall, it\'s a legendary Rinshan Kaihou.',
  ),

  /// 搶槓（Chankan / Robbing a Kan）：当对手将手中刻子加杠为杠子时，以该牌和牌。
  YakuData(
    id: 'chankan',
    nameEn: 'Chankan (Robbing a Kan)',
    nameJp: '搶槓',
    closedHan: 1,
    openHan: 1,
    difficulty: 'Intermediate',
    description:
        'Win by calling ron on a tile that an opponent adds to an open triplet to make a kan. The rarest of the 1-han yaku.',
    conditions: [
      'Opponent must add a tile to an open triplet (daiminkan)',
      'The tile they add must be your winning tile',
      'Only applies to open kan upgrades — not closed or concealed kan'
    ],
    examples: [
      'Opponent ponned 5m → later adds 4th 5m to kan → you call Ron on that 5m!'
    ],
    combos: [],
    tip:
        'Chankan is extremely rare — you may play hundreds of games without seeing one. But when it happens, it\'s a moment to remember.',
  ),

  // ═══ 2-Han Yaku ═══

  /// 両立直（Double Riichi）：第一巡即宣告立直，奖励 2 番。
  YakuData(
    id: 'double_riichi',
    nameEn: 'Double Riichi',
    nameJp: '両立直',
    closedHan: 2,
    openHan: null,
    difficulty: 'Advanced',
    description:
        'Declare riichi on your very first turn, before anyone has discarded. Worth 2 han instead of 1 — a rare and powerful opening move.',
    conditions: [
      'Must declare riichi on your first discard turn',
      'No player may have called pon/chi/kan before your declaration',
      'Hand must be fully closed and in tenpai from the initial deal'
    ],
    examples: [
      'Initial 13 tiles form tenpai → declare Double Riichi → 2 han immediately'
    ],
    combos: [
      YakuCombo('Double Riichi + Ippatsu', 3),
      YakuCombo('Double Riichi + Tsumo', 3)
    ],
    tip:
        'Double Riichi is a gift from the tile gods. If you get tenpai on the first turn, declare immediately — the 2 han + psychological pressure is devastating.',
  ),

  /// 三色同刻（Sanshoku Doukou）：万、筒、索三色中各有同一数字的刻子。
  YakuData(
    id: 'sanshoku_doukou',
    nameEn: 'Sanshoku Doukou (Triple Triplets)',
    nameJp: '三色同刻',
    closedHan: 2,
    openHan: 2,
    difficulty: 'Intermediate',
    description:
        'Three triplets of the same number across all three suits. Less common than Sanshoku (sequences version) but worth more han.',
    conditions: [
      'Same-number triplet in all three suits (e.g. 3m triplet + 3p triplet + 3s triplet)',
      'The fourth set and pair can be anything',
      'Can be open or closed'
    ],
    examples: ['🀊🀊🀊 + 🀒🀒🀒 + 🀚🀚🀚 → 3 of the same number in m, p, s'],
    combos: [YakuCombo('Sanshoku Doukou + Toitoi', 4)],
    tip:
        'If you have the same number pair in two suits, call pon on the third suit to complete Sanshoku Doukou. It pairs naturally with Toitoi.',
  ),

  /// 三槓子（San Kantsu）：手中持有三个杠子。
  YakuData(
    id: 'san_kantsu',
    nameEn: 'San Kantsu (Three Quads)',
    nameJp: '三槓子',
    closedHan: 2,
    openHan: 2,
    difficulty: 'Advanced',
    description:
        'Declare three kans during the hand. Extremely rare — declaring even one kan is risky, let alone three.',
    conditions: [
      'Must have declared three kans',
      'Kans can be open or closed',
      'Each kan reveals a new dora indicator'
    ],
    examples: [
      'Kan ×3 + remaining set + pair → 2 han + 3 extra dora indicators revealed'
    ],
    combos: [YakuCombo('San Kantsu + Toitoi', 4)],
    tip:
        'Three kans is a double-edged sword — you get 2 han but reveal 3 extra dora indicators that benefit everyone. Only pursue this if you\'re already far ahead.',
  ),

  /// 三暗刻（San Ankou）：手中持有三个暗刻（未碰出的刻子）。
  YakuData(
    id: 'san_ankou',
    nameEn: 'San Ankou (Three Concealed Triplets)',
    nameJp: '三暗刻',
    closedHan: 2,
    openHan: 2,
    difficulty: 'Intermediate',
    description:
        'Three concealed triplets (formed without calling pon). Must be fully closed to qualify all three as ankou.',
    conditions: [
      'Three triplets formed without calling pon',
      'Must be fully closed if all three are to count as concealed',
      'The fourth set can be a sequence or open triplet'
    ],
    examples: [
      '🀇🀇🀇 🀍🀍🀍 🀕🀕🀕 + sequence + pair → all triplets self-drawn'
    ],
    combos: [
      YakuCombo('San Ankou + Toitoi', 4),
      YakuCombo('San Ankou + Honitsu', 5)
    ],
    tip:
        'San Ankou is a strong signal to go for Suu Ankou (yakuman). If you have three concealed triplets and a closed hand, one more triplet and you\'re at yakuman.',
  ),

  /// 小三元（Shousangen）：两组三元牌刻子 + 第三组三元牌对子作雀头。
  YakuData(
    id: 'shousangen',
    nameEn: 'Shousangen (Little Three Dragons)',
    nameJp: '小三元',
    closedHan: 2,
    openHan: 2,
    difficulty: 'Intermediate',
    description:
        'Two dragon triplets plus a dragon pair. Worth 2 han for the two yakuhai, plus whatever the rest of the hand earns.',
    conditions: [
      'Two of the three dragon types as triplets',
      'The third dragon as the pair',
      'Each dragon triplet gives 1 han from Yakuhai'
    ],
    examples: ['🀄🀄🀄 + 🀅🀅🀅 + 🀆🀆 + other sets → 2 yakuhai + other yaku'],
    combos: [
      YakuCombo('Shousangen + Honitsu', 5),
      YakuCombo('Shousangen + Daisangen', 13)
    ],
    tip:
        'If you have two dragon pairs early, call pon on both. Even if someone else gets the third dragon, your Shousangen is still worth 2 from the two yakuhai.',
  ),

  /// 混老頭（Honroutou）：全部牌由幺九牌（1、9）和字牌组成。
  YakuData(
    id: 'honroutou',
    nameEn: 'Honroutou (All Terminals & Honors)',
    nameJp: '混老頭',
    closedHan: 2,
    openHan: 2,
    difficulty: 'Advanced',
    description:
        'Every tile in the hand is either a terminal (1 or 9) or an honor tile. No tiles 2–8 allowed.',
    conditions: [
      'All tiles must be terminals (1 or 9) or honors',
      'No tiles with numbers 2-8 anywhere',
      'Always pairs with Toitoi or Chitoitsu (no sequences possible)'
    ],
    examples: ['🀇🀇🀇 🀏🀏🀏 🀀🀀🀀 🀆🀆 → Only 1s, 9s, and honors'],
    combos: [
      YakuCombo('Honroutou + Toitoi', 4),
      YakuCombo('Honroutou + Honitsu', 5)
    ],
    tip:
        'Honroutou naturally pairs with Toitoi since you can\'t form sequences with only terminals and honors. It\'s a step toward the yakuman Chinroutou.',
  ),

  /// 純全帯么九（Junchan Taiyao）：每组面子（含雀头）必须至少包含一张幺九牌。
  YakuData(
    id: 'junchan',
    nameEn: 'Junchan (Pure Outside Hand)',
    nameJp: '純全帯么九',
    closedHan: 3,
    openHan: 2,
    difficulty: 'Intermediate',
    description:
        'Every set AND the pair must contain at least one terminal (1 or 9). Unlike Chanta, no honors allowed.',
    conditions: [
      'Every set must have a 1 or 9 terminal',
      'The pair must also be a 1 or 9 terminal',
      'No honor tiles in any set or the pair',
      'Open = 2 han, closed = 3 han'
    ],
    examples: [
      '🀇🀈🀉 🀐🀑🀒 🀘🀙🀚 🀏🀏 → Every set touches a 1 or 9, no honors'
    ],
    combos: [
      YakuCombo('Junchan + Sanshoku', 5),
      YakuCombo('Junchan + Honitsu', 6)
    ],
    tip:
        'Junchan is Chanta\'s stricter cousin — no honors allowed, but worth 1 more han. If your terminals are all in one suit, pivot to Chinitsu instead.',
  ),

  /// 二盃口（Ryanpeikou）：同一花色内两组完全相同的顺子 —— 两盃口。
  YakuData(
    id: 'ryanpeikou',
    nameEn: 'Ryanpeikou (Twice Pure Double)',
    nameJp: '二盃口',
    closedHan: 3,
    openHan: null,
    difficulty: 'Advanced',
    description:
        'Two pairs of identical sequences (i.e., two Iipeikou). Must be fully closed. An elegant, rare hand.',
    conditions: [
      'Two pairs of identical sequences (e.g. 2-3-4 ×2 AND 6-7-8 ×2)',
      'Must be fully closed',
      'Essentially Iipeikou ×2'
    ],
    examples: [
      '🀈🀉🀊 🀈🀉🀊 🀖🀗🀘 🀖🀗🀘 🀆🀆 → Two pairs of identical sequences'
    ],
    combos: [
      YakuCombo('Ryanpeikou + Pinfu', 4),
      YakuCombo('Ryanpeikou + Tanyao', 4)
    ],
    tip:
        'Ryanpeikou requires incredible luck or patience. If you have one Iipeikou and draw toward a second, keep your hand closed at all costs.',
  ),

  // ═══ Yakuman (役満) ═══

  /// 国士無双（Kokushi Musou / Thirteen Orphans）：十三种幺九牌各一张 + 任意一张对子。
  YakuData(
    id: 'kokushi_musou',
    nameEn: 'Kokushi Musou (Thirteen Orphans)',
    nameJp: '国士無双',
    closedHan: 13,
    openHan: null,
    difficulty: 'Advanced',
    description:
        'One of every terminal and honor tile (13 unique tiles), plus a duplicate of any one of them for the pair. The most iconic yakuman.',
    conditions: [
      'Must collect 1 of each: 1m, 9m, 1p, 9p, 1s, 9s, and all 7 honors',
      'Plus one duplicate for the 14th tile (pair)',
      'Must be fully closed',
      '13-sided tenpai if you have all 13 unique tiles (waiting for any duplicate)'
    ],
    examples: [
      '🀇 🀏 🀐 🀘 🀙 🀡 🀀🀁🀂🀃 🀄🀅🀆 + 🀇(pair) → All 13 orphans + pair'
    ],
    combos: [],
    tip:
        'Kokushi is the most common yakuman at beginner tables. If your starting hand has 8+ distinct terminals/honors, seriously consider this path.',
  ),

  /// 大三元（Daisangen / Big Three Dragons）：白、发、中三组三元牌全为刻子。
  YakuData(
    id: 'daisangen',
    nameEn: 'Daisangen (Big Three Dragons)',
    nameJp: '大三元',
    closedHan: 13,
    openHan: 13,
    difficulty: 'Advanced',
    description:
        'Triplets of all three dragon types. The most feared yakuman — when someone is calling two dragon pons, everyone defends.',
    conditions: [
      'Triplet of White Dragon (Haku)',
      'Triplet of Green Dragon (Hatsu)',
      'Triplet of Red Dragon (Chun)',
      'Can be open or closed'
    ],
    examples: ['🀄🀄🀄 + 🀅🀅🀅 + 🀆🀆🀆 + remaining set + pair → Yakuman!'],
    combos: [
      YakuCombo('Daisangen + Honitsu', 13),
      YakuCombo('Daisangen + Shousangen → Daisangen', 13)
    ],
    tip:
        'If you have two dragon triplets and a pair of the third dragon, everyone at the table will defend. Call pon aggressively on the third dragon — don\'t let them scare you off a yakuman.',
  ),

  /// 小四喜（Shousuushi / Little Four Winds）：三组风牌刻子 + 第四种风牌对子。
  YakuData(
    id: 'shousuushi',
    nameEn: 'Shousuushi (Little Four Winds)',
    nameJp: '小四喜',
    closedHan: 13,
    openHan: 13,
    difficulty: 'Advanced',
    description:
        'Three wind triplets plus the fourth wind as the pair. One step below Daisuushi (Big Four Winds) but still a yakuman.',
    conditions: [
      'Triplet of any three wind types',
      'Pair of the fourth wind type',
      'Can be open or closed'
    ],
    examples: ['🀀🀀🀀 + 🀁🀁🀁 + 🀂🀂🀂 + 🀃🀃 + other set → Yakuman!'],
    combos: [],
    tip:
        'Shousuushi is the "early warning" for Daisuushi. If you have 3 wind triplets, every player at the table will try to hold the 4th wind to block your yakuman.',
  ),

  /// 大四喜（Daisuushi / Big Four Winds）：四种风牌全部为刻子。
  YakuData(
    id: 'daisuushi',
    nameEn: 'Daisuushi (Big Four Winds)',
    nameJp: '大四喜',
    closedHan: 26,
    openHan: 26,
    difficulty: 'Advanced',
    description:
        'Triplets of ALL four winds. Double yakuman in most rulesets. The rarest and highest-scoring hand in mahjong.',
    conditions: [
      'Triplet of East (Ton)',
      'Triplet of South (Nan)',
      'Triplet of West (Sha)',
      'Triplet of North (Pei)',
      'Can be open or closed'
    ],
    examples: ['🀀🀀🀀 + 🀁🀁🀁 + 🀂🀂🀂 + 🀃🀃🀃 + pair → Double Yakuman!'],
    combos: [],
    tip:
        'Big Four Winds is the holy grail. Most players will never see it in their lifetime. If you somehow have three wind triplets, defend the fourth at all costs.',
  ),

  /// 字一色（Tsuuiisou / All Honors）：全部由字牌组成的牌型。
  YakuData(
    id: 'tsuuiisou',
    nameEn: 'Tsuuiisou (All Honors)',
    nameJp: '字一色',
    closedHan: 13,
    openHan: 13,
    difficulty: 'Advanced',
    description:
        'Every single tile is a wind or dragon. No numbered tiles anywhere in the hand.',
    conditions: [
      'Only wind and dragon tiles',
      'No numbered suits (manzu, pinzu, souzu) at all',
      'Always pairs with Toitoi (no sequences with only honors)'
    ],
    examples: ['🀀🀀🀀 🀂🀂🀂 🀄🀄🀄 🀅🀅🀅 🀆🀆 → Pure honor tiles only'],
    combos: [YakuCombo('Tsuuiisou + Daisangen', 13)],
    tip:
        'Tsuuiisou is built from pure honor tiles. If your opening hand has 7+ honors, especially pairs, consider this path. Pon every honor you can.',
  ),

  /// 緑一色（Ryuuiisou / All Green）：全部牌面只含绿色的牌。
  YakuData(
    id: 'ryuuiisou',
    nameEn: 'Ryuuiisou (All Green)',
    nameJp: '緑一色',
    closedHan: 13,
    openHan: 13,
    difficulty: 'Advanced',
    description:
        'Only tiles that are entirely green: 2, 3, 4, 6, 8 of Souzu (bamboo) and the Green Dragon (Hatsu). One of the most visually striking yakuman.',
    conditions: [
      'Only these specific tiles: 2s, 3s, 4s, 6s, 8s, and Green Dragon (Hatsu)',
      'No other tiles allowed',
      '5s is NOT allowed (has red markings), 7s is NOT allowed (has red)'
    ],
    examples: ['🀛🀛🀛 🀜🀜🀜 🀝🀝🀝 🀟🀟🀟 🀅🀅 → Pure green tiles'],
    combos: [],
    tip:
        'All Green is surprisingly achievable if you draw mostly bamboo tiles. The key is remembering: 2-3-4-6-8s and Hatsu ONLY. No 1s, 5s, 7s, or 9s.',
  ),

  /// 清老頭（Chinroutou / All Terminals）：全部由幺九数牌（1和9）组成，不含字牌。
  YakuData(
    id: 'chinroutou',
    nameEn: 'Chinroutou (All Terminals)',
    nameJp: '清老頭',
    closedHan: 13,
    openHan: 13,
    difficulty: 'Advanced',
    description:
        'Only terminal tiles (1s and 9s of each suit). No honors, no 2-8 tiles. The "pure" version of Honroutou.',
    conditions: [
      'Only 1 and 9 of manzu, pinzu, and souzu',
      'No honor tiles anywhere in the hand',
      'No tiles 2-8 from any suit'
    ],
    examples: ['🀇🀇🀇 🀏🀏🀏 🀐🀐🀐 🀘🀘🀘 🀙🀙 → Only 1s and 9s, no honors'],
    combos: [YakuCombo('Chinroutou + Toitoi', 13)],
    tip:
        'Chinroutou is Honroutou without the honors. If you have 6+ terminals across multiple suits and no honors in sight, this is your yakuman path.',
  ),

  /// 九蓮宝燈（Chuuren Poutou / Nine Gates）：同花色按 1112345678999 + 任意同花色牌组成的和牌形。
  YakuData(
    id: 'chuuren_poutou',
    nameEn: 'Chuuren Poutou (Nine Gates)',
    nameJp: '九蓮宝燈',
    closedHan: 13,
    openHan: null,
    difficulty: 'Advanced',
    description:
        'A hand of 1112345678999 in a single suit, plus any one tile of the same suit. The pure nine-wait hand is the most elegant yakuman.',
    conditions: [
      'All tiles from a single suit',
      'Must contain 111 2345678 999 in the same suit, plus one extra tile of that suit',
      'Must be fully closed (menzen)',
      'The "pure" 9-sided wait (1-9 all valid) is double yakuman in some rules'
    ],
    examples: ['🀇🀇🀇 🀈🀉🀊🀋🀌🀍🀎🀏 🀏🀏 + any tile → Pure nine gates'],
    combos: [YakuCombo('Chuuren + Chinitsu', 13)],
    tip:
        'Nine Gates is the holy grail of single-suit hands. If you have 111 456 999 in one suit plus some middle tiles, you\'re in the zone. Don\'t open your hand.',
  ),

  /// 四槓子（Suu Kantsu / Four Quads）：四个杠子。极其罕见。
  YakuData(
    id: 'suu_kantsu',
    nameEn: 'Suu Kantsu (Four Quads)',
    nameJp: '四槓子',
    closedHan: 13,
    openHan: 13,
    difficulty: 'Advanced',
    description:
        'Declare four kans. The rarest yakuman — many players go their entire lives without seeing this hand.',
    conditions: [
      'Must declare four kans',
      'Can be open or closed',
      'Because four kans remove 16 tiles, there may not be enough tiles left to finish',
      'If all four kans are called, the hand may end in an abortive draw'
    ],
    examples: ['Kan ×4 + pair → Yakuman!'],
    combos: [],
    tip:
        'Four kans is the unicorn of mahjong. You\'ll likely never see it. If you have three kans and a chance at a fourth, go for it — you may never get another shot.',
  ),

  /// 天和（Tenhou）：庄家（东家）配牌即和牌。
  YakuData(
    id: 'tenhou',
    nameEn: 'Tenhou (Blessing of Heaven)',
    nameJp: '天和',
    closedHan: 13,
    openHan: null,
    difficulty: 'Advanced',
    description:
        'The dealer wins on their initial 14-tile hand. No draws, no discards — a perfect starting hand.',
    conditions: [
      'Must be the dealer (East seat)',
      'Win from the initial 14-tile deal',
      'No player has made any move yet'
    ],
    examples: ['Initial deal → 14 tiles form complete hand → Yakuman!'],
    combos: [],
    tip:
        'Tenhou is pure destiny. You can\'t play for it, you can only receive it. If the tile gods bless you with a complete hand on deal, accept it with gratitude.',
  ),

  /// 地和（Chiihou）：子家（非庄家）第一巡自摸和牌。
  YakuData(
    id: 'chiihou',
    nameEn: 'Chiihou (Blessing of Earth)',
    nameJp: '地和',
    closedHan: 13,
    openHan: null,
    difficulty: 'Advanced',
    description:
        'A non-dealer wins on their very first draw. The non-dealer version of Tenhou.',
    conditions: [
      'Must not be the dealer',
      'Win on your first draw from the wall',
      'No calls may have been made before your first draw'
    ],
    examples: ['Non-dealer → first draw from wall → Tsumo! → Yakuman!'],
    combos: [],
    tip:
        'Like Tenhou, Chiihou is a gift. If you\'re the first non-dealer to draw and your 13-tile starting hand is tenpai, hold your breath — you might hit the lottery.',
  ),

  /// 四暗刻（Suu Ankou / Four Concealed Triplets）：四个暗刻，完全靠自摸形成的刻子手。
  YakuData(
    id: 'suu_ankou',
    nameEn: 'Suu Ankou (Four Concealed Triplets)',
    nameJp: '四暗刻',
    closedHan: 13,
    openHan: null,
    difficulty: 'Advanced',
    description:
        'Four concealed triplets (formed entirely by self-draw, no calls). The ultimate test of patience and tile luck.',
    conditions: [
      'Four triplets formed without calling pon',
      'Must be fully closed',
      'The pair completes the hand',
      'Often reached by upgrading from San Ankou (three concealed triplets)'
    ],
    examples: [
      '🀇🀇🀇 🀍🀍🀍 🀒🀒🀒 🀕🀕🀕 🀆🀆 → All four triplets self-drawn, closed'
    ],
    combos: [YakuCombo('Suu Ankou + Tanyao', 13)],
    tip:
        'Suu Ankou is the most achievable yakuman at intermediate play. If you have San Ankou (three concealed triplets), guard your closed hand — one more self-drawn triplet makes yakuman.',
  ),

  /// 流し満貫（Nagashi Mangan）：荒牌流局时，自己的全部舍牌都是幺九牌，且未被鸣牌。
  YakuData(
    id: 'nagashi_mangan',
    nameEn: 'Nagashi Mangan (All Terminals Discard)',
    nameJp: '流し満貫',
    closedHan: 5,
    openHan: 5,
    difficulty: 'Intermediate',
    description:
        'Reach an exhaustive draw while all your discards are terminals and honors, none of which were called by opponents. Worth mangan (5 han equivalent).',
    conditions: [
      'Every tile you discard must be a terminal (1 or 9) or honor',
      'None of your discards may have been called (pon/chi/kan) by anyone',
      'The hand must reach exhaustive draw',
      'You do not need to be tenpai'
    ],
    examples: [
      'Discard only 1s, 9s, winds, dragons → exhaustive draw → Mangan!'
    ],
    combos: [],
    tip:
        'Nagashi Mangan is the "defensive" yakuman-lite. If your hand is garbage by mid-game, pivot to discarding only terminals/honors and pray for the exhaustive draw.',
  ),
];

/// 根据役种 [id] 在 [allYaku] 列表中查找对应的役种数据。
///
/// 使用 [Iterable.firstWhere] 遍历列表进行精确 ID 匹配。
/// 未找到匹配项时返回 `null`，调用方负责 nil 检查。
/// 内部使用 try/catch 捕获 [StateError] 以避免 firstWhere 的异常传播。
YakuData? getYakuById(String id) {
  try {
    // 遍历全量役种列表，找到首个 ID 匹配的役种数据
    return allYaku.firstWhere((y) => y.id == id);
  } catch (_) {
    // firstWhere 未找到匹配时抛出 StateError，捕获后返回 null
    return null;
  }
}
