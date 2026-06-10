import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import '../../core/constants/app_colors.dart';
import '../models/tile_model.dart';

enum TileSize { sm, md, lg }
enum TileState { normal, selected, floating, discarded, dimmed }

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
