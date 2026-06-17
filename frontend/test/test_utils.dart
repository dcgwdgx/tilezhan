import 'package:tilezhan/shared/models/tile_model.dart';

/// 共享测试工具函数 — 避免各测试文件重复定义 TileModel 工厂方法
/// 提供统一的 makeTile 工厂，保证所有测试使用一致的牌模型默认值

/// 快速创建 TileModel 实例的测试工厂函数
/// [id] 牌的标识符，如 'm1'
/// [suit] 牌的花色（万/筒/索/风/箭）
/// [label] 可选的显示标签，为空时使用 id
TileModel makeTile(String id, TileSuit suit, [String label = '']) {
  return TileModel(
    id: id,
    suit: suit,
    character: id,
    seal: '',
    value: 1,
    label: label.isEmpty ? id : label,
    mnemonic: const MnemonicData(
      emoji: '🀄',
      name: '',
      slogan: '',
      desc: '',
      chinese: '',
      anchor: '',
    ),
    confusedWith: const [],
  );
}
