/// 麻雀牌瓦片组件
///
/// 基于 [Material] + [InkWell] 实现带涟漪反馈的可靠点击，
/// 支持选中上浮、暗纹、新牌提示、助记文字等牌桌视觉状态。
///
/// 详见设计文档 [TileZhan 牌桌交互](docs/tilezhan-tile-interaction.md)。
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import '../../core/constants/app_colors.dart';
import '../models/tile_model.dart';

/// 牌面尺寸档位。
///
/// * [sm] — 小号 (39×54)
/// * [md] — 中号 (52×74)，默认尺寸
/// * [lg] — 大号 (64×90)
enum TileSize { sm, md, lg }

/// 牌面视觉状态。
///
/// * [normal] — 默认闲牌
/// * [selected] — 选中上浮 + 金框 + 发光阴影
/// * [floating] — 浮牌（预留）
/// * [discarded] — 已出牌（预留）
/// * [dimmed] — 暗纹/弱化
enum TileState { normal, selected, floating, discarded, dimmed }

/// 麻雀牌瓦片。
///
/// 单张牌的可视化组件，用 [Material] + [InkWell] 包裹 SVG 牌面，
/// 保证涟漪触摸反馈在任何场景下都能可靠触发。
///
/// 典型用法：
/// ```dart
/// TzTile(
///   tile: myTileModel,
///   state: TileState.selected,
///   onTap: () => print('tapped'),
/// )
/// ```
class TzTile extends StatelessWidget {
  final TileModel tile;
  final TileSize size;
  final TileState state;
  final bool showMnemonic;
  final double mnemonicOpacity;
  final bool isNewDraw;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;

  static const _sizeMap = {
    TileSize.sm: Size(39, 54),
    TileSize.md: Size(52, 74),
    TileSize.lg: Size(64, 90),
  };

  /// 创建一张麻雀牌瓦片。
  ///
  /// [tile] 为必须传入的牌数据模型，包含 id、花色颜色、助记标签等。
  ///
  /// [size] 控制牌面尺寸，默认 [TileSize.md]。
  /// [state] 控制视觉状态（选中上浮、暗纹等），默认 [TileState.normal]。
  /// [showMnemonic] 与 [mnemonicOpacity] 联合控制助记文字的显隐与透明度。
  /// [isNewDraw] 为 `true` 时绘制金色新牌提示边框。
  /// [onTap] / [onDoubleTap] 分别绑定单击与双击回调。
  const TzTile({
    super.key,
    required this.tile,
    this.size = TileSize.md,
    this.state = TileState.normal,
    this.showMnemonic = false,
    this.mnemonicOpacity = 1.0,
    this.isNewDraw = false,
    this.onTap,
    this.onDoubleTap,
  });

  @override
  Widget build(BuildContext context) {
    final tileSize = _sizeMap[size]!;
    final isSelected = state == TileState.selected;
    final isDimmed = state == TileState.dimmed;
    final assetPath = 'assets/tiles/${tile.id}.svg';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOutQuad,
      width: tileSize.width,
      height: tileSize.height,
      transform: Matrix4.translationValues(0, isSelected ? -12.0 : 0, 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: isNewDraw
            ? Border.all(color: AppColors.neonGold.withOpacity(0.6), width: 1.5)
            : Border.all(
                color: isSelected ? AppColors.neonGold : tile.suitColor.withOpacity(isDimmed ? 0.1 : 0.5),
                width: isSelected ? 2.0 : 1.0,
              ),
        boxShadow: isSelected
            ? [BoxShadow(color: tile.suitColor.withOpacity(0.4), blurRadius: 16, spreadRadius: 2),
               const BoxShadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 4))]
            : [const BoxShadow(color: Colors.black54, blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onDoubleTap: onDoubleTap,
          borderRadius: BorderRadius.circular(7),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Opacity(
                  opacity: isDimmed ? 0.4 : 1.0,
                  child: SvgPicture.asset(assetPath, fit: BoxFit.contain),
                ),
                if (showMnemonic && mnemonicOpacity > 0)
                  Positioned(
                    top: 2, right: 4,
                    child: Opacity(
                      opacity: mnemonicOpacity,
                      child: Text(tile.label, style: const TextStyle(
                        fontSize: 8, fontWeight: FontWeight.w600, color: AppColors.celadonLight,
                      )),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
