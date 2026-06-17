/// TileZhan 麻雀牌数据模型。
///
/// 本文件定义了游戏中所有牌的数据结构层，是整个 TileZhan 前端的数据基石。
///
/// 核心职责：
/// - [TileSuit]：花色枚举，定义牌的五大分类体系（万/筒/索/风/箭），
///   驱动牌面渲染的颜色方案、排序规则与游戏逻辑判断。
/// - [MnemonicData]：助记数据实体，为每张牌提供图形化 emoji 图标、
///   多语言名称（中/英）、朗朗上口的助记口诀 slogan、详细释义描述、
///   以及锚点分类 anchor，帮助玩家快速识别与记忆每张牌的对应关系。
/// - [TileModel]：牌的完整数据模型，聚合唯一标识 id、花色 suit、
///   牌面字符 character、篆文艺术字 seal、排序数值 value、显示标签 label、
///   关联的助记数据 mnemonic、以及容易混淆的同类牌列表 confusedWith。
///   通过 [suitColor] getter 提供花色对应的 Material 主题颜色，供 UI 层
///   渲染牌面背景、边框及高亮标记。
///
/// 数据流方向：
///   JSON（assets/data/tiles.json）→ fromJson 工厂构造 → TileModel 实例
///   → UI Widget（TileCard / TileGrid 等）→ 玩家交互
///
/// 使用注意：
/// - [value] 字段类型为 `dynamic`，以适配某些牌值为整型、某些为字符串的
///   混合数据（如风牌 "east"、箭牌 "red"），排序时需先做类型判断。
/// - [confusedWith] 存储的是牌 id 列表而非 TileModel 引用，避免循环依赖，
///   实际混淆牌对象需通过外部 Map<String, TileModel> 查找获取。
import 'package:flutter/material.dart';

/// 麻将牌的五种花色枚举。
///
/// 对应传统麻将牌的五种基本分类：万、筒、索、风、箭。每种花色的
/// 枚举名与其在 JSON 数据中 `suit` 字段的值（全小写英文）保持一致，
/// 通过 `TileSuit.values.firstWhere((s) => s.name == json['suit'])`
/// 实现字符串到枚举的反序列化映射。
///
/// 花色决定了牌的视觉呈现（背景色、边框色）、游戏逻辑中的分组归类、
/// 以及牌序编排中的优先层级。新增花色只需在此枚举添加条目并同步
/// 在 [TileModel.suitColor] getter 中添加对应的颜色分支即可。
enum TileSuit {
  /// 万字牌（Characters / 万子）。
  /// 牌面以汉字数字一~九标识，对应 JSON 中 `"suit": "man"`。
  man,
  /// 筒子牌（Dots / 饼子）。
  /// 牌面以圆形图案（1~9 个圆点）标识，对应 JSON 中 `"suit": "pin"`。
  pin,
  /// 索子牌（Bamboos / 条子）。
  /// 牌面以竹节/条形图案（1~9 条）标识，对应 JSON 中 `"suit": "sou"`。
  sou,
  /// 风牌（Winds）。
  /// 包含东、南、西、北四种方位牌，对应 JSON 中 `"suit": "wind"`。
  wind,
  /// 箭牌（Dragons / 三元牌）。
  /// 包含中（红中）、发（发财）、白（白板）三张，对应 JSON 中 `"suit": "dragon"`。
  dragon,
}

/// 牌的助记数据实体，帮助玩家识别、记忆每张牌的视觉特征与文化内涵。
///
/// 每张麻雀牌（[TileModel]）通过 `mnemonic` 字段关联一个本类实例。
/// 本类是纯数据容器（const 构造，完全不可变），所有字段均为 `final`，
/// 确保牌数据在运行时不会被意外修改，符合 Redux/不可变状态管理范式。
///
/// 设计意图（TileZhan v0.4+）：
/// 麻将牌对初学者而言存在"牌面相似、难以区分"的认知障碍（如"四万"
/// 与"五万"仅差一笔画）。本类通过 emoji 图形化映射 + 口诀化 slogan
/// + 中文释义的多维编码，将每张牌转化为一个可快速检索的"记忆卡片"，
/// 降低学习曲线、提升游戏体验。
///
/// 字段说明见各字段文档注释；JSON 反序列化见 [MnemonicData.fromJson]。
class MnemonicData {
  /// 助记用 emoji 图标。
  ///
  /// 每张牌关联一个具象化的 emoji 符号作为视觉锚点。例如：
  /// - 一条（幺鸡）→ 🐓
  /// - 红中 → 🀄
  /// - 东风 → 🌬️
  ///
  /// 选型原则：优先选择与牌面含义强关联的 emoji（语义映射），
  /// 其次选择形状相似的 emoji（形状映射），确保跨文化可理解。
  final String emoji;

  /// 助记名称（英文）。
  ///
  /// 牌的英文简短名称，用于列表检索与跨语言展示。命名规范：
  /// - 万子：数字 + "Man"（如 "One Man"）
  /// - 筒子：数字 + "Dot"（如 "Three Dot"）
  /// - 索子：数字 + "Bamboo"（如 "Seven Bamboo"）
  /// - 风牌：方位 + "Wind"（如 "East Wind"）
  /// - 箭牌：颜色 + "Dragon"（如 "Red Dragon"）
  final String name;

  /// 助记口诀（简短好记的英文 slogan）。
  ///
  /// 4~8 单词的押韵或节奏型短句，帮助玩家通过声音记忆关联牌面。
  /// 设计目标：每张牌的口诀独一无二且朗朗上口，朗读一遍即可建立
  /// 音-形-义的三角联结。例如 "Little bird, number one"（一条）。
  final String slogan;

  /// 助记详细描述（英文）。
  ///
  /// 1~3 句的扩展说明，解释 emoji 与牌的关联逻辑、文化背景或
  /// 视觉识别要点。在游戏中以 tooltip / info panel 形式展示，
  /// 供希望深入了解的玩家阅读。
  final String desc;

  /// 中文标牌文字。
  ///
  /// 牌面标准中文名称，用于 UI 中文展示场景。示例：
  /// - 一万 → "一万"
  /// - 东风 → "东"
  /// - 红中 → "中"
  ///
  /// 此字段直接采用传统麻将术语，保持对中文玩家的亲和力。
  final String chinese;

  /// 助记锚点分类。
  ///
  /// 将牌按助记策略归类，用于教学中分组展示。典型值包括：
  /// - "number"：数字映射锚点（1~9 对应特定形象）
  /// - "shape"：形状映射锚点（牌面图形与外物相似）
  /// - "culture"：文化映射锚点（风/箭牌的历史典故）
  ///
  /// 此分类独立于 [TileSuit] 花色，侧重"记忆策略"而非牌面归属。
  final String anchor;

  /// 创建不可变的助记数据实例。
  ///
  /// 所有字段均为 [required]，调用方必须提供完整的 6 项数据，
  /// 确保每张牌都有完备的助记体系，避免运行时空指针或空字符串兜底。
  const MnemonicData({
    required this.emoji,
    required this.name,
    required this.slogan,
    required this.desc,
    required this.chinese,
    required this.anchor,
  });

  /// 从 JSON 字典构造 [MnemonicData]。
  ///
  /// 这是标准的 JSON 反序列化工厂方法，用于解析
  /// `assets/data/tiles.json` 中每张牌的 `mnemonic` 子对象。
  ///
  /// 容错策略：所有 6 个字段均采用 `?? ''` 兜底，即 JSON 中缺失
  /// 任何字段都不会导致构造失败，而是以空字符串替代。这是有意为之
  /// 的宽松策略 —— 因为助记数据属于"体验增强"层而非"核心逻辑"层，
  /// 部分缺失不应阻断游戏加载；实际运营中 JSON 数据应通过 CI 校验
  /// 确保完整性。
  factory MnemonicData.fromJson(Map<String, dynamic> json) => MnemonicData(
    emoji: json['emoji'] ?? '',
    name: json['name'] ?? '',
    slogan: json['slogan'] ?? '',
    desc: json['desc'] ?? '',
    chinese: json['chinese'] ?? '',
    anchor: json['anchor'] ?? '',
  );
}

/// 麻雀牌核心数据模型。
///
/// 每张牌拥有唯一的 [id]、一个 [TileSuit] 花色、牌面 [character] 字符、
/// 艺术化的篆文 [seal]、用于排序/判定的 [value] 数值、UI 显示用的
/// [label] 标签、关联的 [MnemonicData] 助记数据、以及容易与本牌混淆的
/// 同类牌 id 列表 [confusedWith]。
///
/// 本类是纯数据模型（const 构造，完全不可变），不包含任何业务逻辑，
/// 仅通过 [suitColor] getter 提供花色→颜色的声明式映射。
///
/// 生命周期：
/// 1. 应用启动时，从 `assets/data/tiles.json` 批量反序列化全部 34 张牌
/// 2. 存入全局 `Map<String, TileModel>`（key = id），作为牌的"字典"
/// 3. 游戏各模块通过 id 查找牌对象，获取花色/颜色/助记等数据
/// 4. 牌的 id 在不同 game round 间保持稳定，是跨场景引用的唯一键
///
/// 不可变性保证：所有字段均为 `final`，构造后不可修改。游戏状态变更
/// 通过创建新的游戏状态对象（而非修改牌数据）来实现，符合函数式
/// 状态管理范式。
class TileModel {
  /// 牌的唯一标识符。
  ///
  /// 格式：`"{花色缩写}{数字或关键词}"`，例如：
  /// - `"man1"` ~ `"man9"`（一万~九万）
  /// - `"pin1"` ~ `"pin9"`（一筒~九筒）
  /// - `"sou1"` ~ `"sou9"`（一索~九索）
  /// - `"wind_east"`, `"wind_south"`, `"wind_west"`, `"wind_north"`
  /// - `"dragon_red"`, `"dragon_green"`, `"dragon_white"`
  ///
  /// id 是跨游戏回合、跨牌局的稳定引用键，不可重复。
  /// [confusedWith] 列表中存储的即为其他牌的 id。
  final String id;

  /// 花色分类，决定牌的视觉呈现与游戏逻辑分组。
  ///
  /// 取值见 [TileSuit] 枚举：万（man）、筒（pin）、索（sou）、
  /// 风（wind）、箭（dragon）。同一花色的牌共享相同的背景色、
  /// 排序优先级和部分游戏规则判定逻辑。
  final TileSuit suit;

  /// 牌面显示字符。
  ///
  /// 牌正面中央的主文字。对于数字牌（万/筒/索），为对应的汉字数字
  /// 或阿拉伯数字；对于风牌和箭牌，为单字方位或名称（如 "东"、"中"）。
  /// 此字段直接用于牌面 Widget 的文字渲染。
  final String character;

  /// 篆文（艺术化牌面文字）。
  ///
  /// 采用篆书或变体字形的艺术化版本，用于牌面装饰或放大展示场景
  /// （如牌详情弹窗、教学面板）。与 [character] 的区别：
  /// character 用于常规阅读，seal 用于视觉效果增强和文化氛围营造。
  /// 在赛博国风设计风格（TileZhan v0.6+）中作为核心视觉元素使用。
  final String seal;

  /// 牌的数值，用于排序比较与游戏判定。
  ///
  /// 类型为 `dynamic`，因为不同花色的 value 类型可能不同：
  /// - 万/筒/索（数字牌）：整型 int（1~9），直接数值比较
  /// - 风牌：字符串（如 "east", "south", "west", "north"），按方位顺序比较
  /// - 箭牌：字符串（如 "red", "green", "white"），按约定顺序比较
  ///
  /// 排序/比较时，调用方必须先通过 `value is int` 做类型分派，
  /// 对整型直接比较，对字符串查预定义的排序映射表。
  ///
  /// 设计决策说明：选择 `dynamic` 而非 `int` 以兼容 34 张牌的
  /// 混合数据类型，避免为风/箭牌硬编码虚拟数值。代价是类型安全
  /// 检查下移到调用方，需在排序工具函数中统一处理。
  final dynamic value;

  /// UI 显示标签。
  ///
  /// 简化展示场景（如列表摘要、紧凑网格）中使用的短标签。
  /// 通常为牌面字符的缩写或格式化版本，与 [character] 可能相同
  /// 也可能更简短。具体格式由数据源（tiles.json）定义。
  final String label;

  /// 关联的助记数据实体。
  ///
  /// 每张牌绑定一个 [MnemonicData] 实例，提供 emoji 图标、中英文名称、
  /// 助记口诀、详细描述和锚点分类。游戏中的"学习模式"和"牌面详情"
  /// 功能主要消费此字段。
  ///
  /// 通过 `const` 构造在反序列化时一并创建，与牌实例生命周期绑定。
  final MnemonicData mnemonic;

  /// 容易与本牌混淆的其他牌 id 列表。
  ///
  /// 存储的是牌 id 字符串（而非 [TileModel] 直接引用），以 `List<String>`
  /// 形式保存。设计理由：
  /// 1. 避免 JSON 反序列化时的循环引用问题
  /// 2. 保持 TileModel 为纯数据模型，不持有对其他 TileModel 的硬引用
  /// 3. 实际混淆牌对象通过外部 `Map<String, TileModel>` 按需查找获取
  ///
  /// 典型混淆场景：
  /// - 四万与五万（笔画相近）
  /// - 二筒与八筒（圆形图案数量快速辨别困难）
  /// - 红中与发财（初学者易混淆的箭牌）
  ///
  /// 此列表用于"混淆训练"游戏模式，系统从列表中选择混淆牌作为
  /// 干扰项展示，训练玩家快速区分相似牌面。
  final List<String> confusedWith;

  /// 创建不可变的牌数据实例。
  ///
  /// 所有字段均为 [required]，调用方必须提供完备的牌数据。
  /// 使用 `const` 构造以支持编译时常量优化 —— 虽然反序列化路径
  /// 使用 `factory` 返回运行时实例，但测试代码中的硬编码牌数据
  /// 可声明为编译时常量以提升性能。
  const TileModel({
    required this.id,
    required this.suit,
    required this.character,
    required this.seal,
    required this.value,
    required this.label,
    required this.mnemonic,
    required this.confusedWith,
  });

  /// 从 JSON 字典构造 [TileModel]。
  ///
  /// 标准 JSON 反序列化工厂，解析 `assets/data/tiles.json` 中
  /// 每个牌对象的顶层字段及嵌套的 `mnemonic` 子对象。
  ///
  /// 解析细节：
  /// - [id]：直接以 `as String` 强转，要求 JSON 必须提供此字段
  ///   （缺失时抛 `TypeError`，视为数据损坏，不应兜底）
  /// - [suit]：通过 `TileSuit.values.firstWhere` 将字符串映射到枚举值；
  ///   若 JSON 中的 suit 值不在枚举定义范围内，抛 `StateError`
  ///   （在应用启动阶段暴露数据错误，避免运行时静默失败）
  /// - [character]、[seal]、[label]：缺失时兜底为空字符串
  /// - [value]：直接透传，保留原始类型（int 或 String），不做类型转换
  /// - [mnemonic]：通过 [MnemonicData.fromJson] 递归构造，字段内自行兜底
  /// - [confusedWith]：通过 `List<String>.from` 将 JSON 数组转为不可变列表，
  ///   缺失时兜底为空列表
  ///
  /// 容错策略说明：id 和 suit 不兜底（数据完整性要求），其余字段兜底
  /// （体验增强层，可降级但不阻断加载）。如果 tiles.json 中的 id 或 suit
  /// 有问题，应用应在启动时立即崩溃，以便开发阶段快速发现和修复。
  factory TileModel.fromJson(Map<String, dynamic> json) => TileModel(
    id: json['id'] as String,
    suit: TileSuit.values.firstWhere((s) => s.name == json['suit']),
    character: json['character'] ?? '',
    seal: json['seal'] ?? '',
    value: json['value'],
    label: json['label'] ?? '',
    mnemonic: MnemonicData.fromJson(json['mnemonic'] ?? {}),
    confusedWith: List<String>.from(json['confused_with'] ?? []),
  );

  /// 获取当前牌花色对应的 UI 颜色，用于渲染牌面背景、边框或标记。
  ///
  /// 颜色映射关系：
  /// - 万（man）：红色 `#E74C3C` —— 传统麻将万字牌常用红色，视觉醒目
  /// - 筒（pin）：蓝色 `#3498DB` —— 与圆形图案（筒）搭配冷静对比
  /// - 索（sou）：绿色 `#2ECC71` —— 竹子/竹节的自然联想色
  /// - 风（wind）：橙色 `#F39C12` —— 方位牌的暖色标识
  /// - 箭（dragon）：紫色 `#9B59B6` —— 三元牌的尊贵/神秘感
  ///
  /// 使用 Dart 3 的 `switch` 表达式（非语句），编译器会校验枚举
  /// 分支完整性：若 [TileSuit] 新增花色但此处未添加对应分支，
  /// 编译报错，防止遗漏。
  ///
  /// 所有颜色均为 `const` 编译时常量，无运行时分配开销。
  Color get suitColor => switch (suit) {
    TileSuit.man => const Color(0xFFE74C3C),
    TileSuit.pin => const Color(0xFF3498DB),
    TileSuit.sou => const Color(0xFF2ECC71),
    TileSuit.wind => const Color(0xFFF39C12),
    TileSuit.dragon => const Color(0xFF9B59B6),
  };
}
