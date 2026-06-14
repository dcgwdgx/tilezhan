/// TileZhan 麻雀牌数据模型。
///
/// 定义牌的完整数据层：花色枚举、助记数据（emoji/名称/slogan/中文释义）、
/// 混淆牌列表以及 JSON 反序列化。是游戏中所有牌展示与交互的核心载体。
import 'package:flutter/material.dart';

/// 麻将牌的五种花色。
enum TileSuit {
  /// 万
  man,
  /// 筒
  pin,
  /// 索
  sou,
  /// 风
  wind,
  /// 箭
  dragon,
}

/// 牌的助记数据，帮助玩家识别与记忆每张牌。
///
/// 每张麻雀牌关联一个助记实体，包含图形化的 emoji、多语言名称、
/// 朗朗上口的口诀 slogan、详细释义、中文标牌和锚点分类。
class MnemonicData {
  /// 助记用 emoji 图标。
  final String emoji;
  /// 助记名称（英文）。
  final String name;
  /// 助记口诀（简短好记的英文 slogan）。
  final String slogan;
  /// 助记详细描述。
  final String desc;
  /// 中文标牌文字。
  final String chinese;
  /// 助记锚点分类。
  final String anchor;

  const MnemonicData({
    required this.emoji,
    required this.name,
    required this.slogan,
    required this.desc,
    required this.chinese,
    required this.anchor,
  });

  /// 从 JSON 字典构造 [MnemonicData]，缺失字段回退为空字符串。
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
/// 每张牌由唯一 id、花色、牌面字符、篆文 seal、数值 value、
/// 显示标签 label、[MnemonicData] 助记数据以及容易混淆的同类牌列表组成。
/// 从 JSON 构造后，可通过 [suitColor] 获取花色对应的 UI 颜色。
class TileModel {
  /// 牌的唯一标识符。
  final String id;
  /// 花色（万/筒/索/风/箭）。
  final TileSuit suit;
  /// 牌面字符（如数字或风箭单字）。
  final String character;
  /// 篆文（艺术化牌面文字）。
  final String seal;
  /// 牌的数值（用于排序与判定）。
  final dynamic value;
  /// UI 显示标签。
  final String label;
  /// 关联的助记数据。
  final MnemonicData mnemonic;
  /// 容易与此牌混淆的其他牌 id 列表。
  final List<String> confusedWith;

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
  /// [suit] 字段与 [TileSuit] 枚举名一一对应；
  /// [confused_with] 字段解为 `List<String>`；
  /// 其余字段缺失时回退为空字符串或空对象。
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

  /// 花色对应的 UI 颜色，用于渲染牌面背景或标记。
  Color get suitColor => switch (suit) {
    TileSuit.man => const Color(0xFFE74C3C),
    TileSuit.pin => const Color(0xFF3498DB),
    TileSuit.sou => const Color(0xFF2ECC71),
    TileSuit.wind => const Color(0xFFF39C12),
    TileSuit.dragon => const Color(0xFF9B59B6),
  };
}
