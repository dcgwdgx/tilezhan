/// 日麻常见役种数据模型 — 涵盖 12 个入门到高级役种。
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
  /// 基础番数（副露手牌时的番值）。
  final int han;
  /// 门清（完全立直）状态下的番数。
  final int hanClosed;
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
    required this.id, required this.nameEn, required this.nameJp,
    required this.han, required this.hanClosed,
    required this.difficulty, required this.description,
    required this.conditions, required this.examples,
    required this.combos, required this.tip,
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
/// 涵盖从入门到高级的 12 个核心役种，按难度递进排列。
const List<YakuData> allYaku = [
  /// 立直（Riichi）：门清宣言役。听牌时支付 1,000 点供託棒并宣言立直，
  /// 解锁一发与里宝牌额外番数加成，是日麻中最具代表性的役种。
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
  /// 断幺九（Tanyao / All Simples）：仅使用数牌 2-8，不含任何幺九牌（1/9）
  /// 与字牌（风牌/三元牌）。现代麻将中使用频率最高的役种，快速可靠。
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
  /// 平和（Pinfu / Peaceful Hand）：全顺子门清手牌，两面听且雀头非役牌。
  /// 除底符 20 之外不附加任何符数——"零成本"役种，可在追求其他役种时自然成型。
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
  /// 役牌（Yakuhai / Value Honor）：三元牌（白/发/中）、场风或自风的刻子。
  /// 获取 1 番并满足起和最低番数要求的最快途径——早期摸到役牌对子务必保留。
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
  /// 一盃口（Iipeiko / Double Sequence）：同花色内两组完全相同的顺子，
  /// 必须门清。手中同一花色的相同数字对子是此役的种子牌。
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
  /// 混全帯么九（Chanta / Mixed Outside）：每组面子（含雀头）必须至少包含
  /// 一张幺九牌（1 或 9）或字牌。常与混一色自然复合，门清 2 番副露 1 番。
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
  /// 混一色（Honitsu / Half Flush）：单一数牌花色 + 任意字牌。
  /// 半清一色——门清 3 番、副露 2 番。手中同花色牌达 7 张以上时，
  /// 果断转向混一色，弃掉其他花色保留字牌以最大化番值。
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
  /// 七対子（Chitoitsu / Seven Pairs）：七组各不相同的对子，共 14 张。
  /// 必须完全门清的特殊牌形——手中连续摸到对子时的经典"B 计划"，
  /// 放弃顺子构建，专注凑齐七个不同对子。
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
  /// 対々和（Toitoi / All Triplets）：四组面子全部由刻子（暗刻或明刻）组成，
  /// 不含任何顺子。起手多对子时此为最佳路线——积极碰牌加速手牌成型。
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
  /// 三色同顺（Sanshoku / Mixed Triple）：同一数字的顺子在三色（万/筒/索）中
  /// 各有一组（如 2-3-4 同时出现在万、筒、索）。门清 2 番，副露降为 1 番。
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
  /// 一気通貫（Ikkitsukan / Pure Straight）：同一花色内三组连续顺子——
  /// 1-2-3、4-5-6、7-8-9，共九张牌组成一条纯正龙。难以刻意规划，
  /// 但一旦成型威力巨大。门清 2 番，副露 1 番。
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
  /// 清一色（Chinitsu / Full Flush）：全部牌张来自唯一数牌花色，不含任何字牌。
  /// 纯清一色——门清 6 番、副露 5 番，常见役种中番值最高的顶级役，
  /// 起手同花色牌达 9 张以上即可全力冲刺。
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
