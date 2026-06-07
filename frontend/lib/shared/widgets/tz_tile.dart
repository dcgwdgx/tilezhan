import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../models/tile_model.dart';

enum TileSize { sm, md, lg }
enum TileState { normal, selected, floating, discarded, dimmed }

class TzTile extends StatelessWidget {
  final TileModel tile;
  final TileSize size;
  final TileState state;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;

  static const _sizeMap = {
    TileSize.sm: Size(36, 52),
    TileSize.md: Size(52, 74),
    TileSize.lg: Size(64, 90),
  };

  static const _fontSizeMap = {
    TileSize.sm: 16.0,
    TileSize.md: 22.0,
    TileSize.lg: 28.0,
  };

  const TzTile({
    super.key,
    required this.tile,
    this.size = TileSize.md,
    this.state = TileState.normal,
    this.onTap,
    this.onDoubleTap,
  });

  @override
  Widget build(BuildContext context) {
    final tileSize = _sizeMap[size]!;
    final fontSize = _fontSizeMap[size]!;

    return GestureDetector(
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutQuad,
        width: tileSize.width,
        height: tileSize.height,
        transform: Matrix4.translationValues(
          0, state == TileState.selected ? -12.0 : 0, 0,
        ),
        decoration: BoxDecoration(
          color: state == TileState.dimmed
              ? AppColors.jadeDeep.withOpacity(0.5)
              : AppColors.jadeCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: state == TileState.selected
                ? AppColors.neonGold
                : tile.suitColor.withOpacity(0.3),
            width: state == TileState.selected ? 2.0 : 1.0,
          ),
          boxShadow: state == TileState.selected
              ? [
                  BoxShadow(
                    color: tile.suitColor.withOpacity(0.4),
                    blurRadius: 16, spreadRadius: 2,
                  ),
                  const BoxShadow(
                    color: Colors.black54, blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ]
              : [
                  const BoxShadow(
                    color: Colors.black54, blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(tile.character,
                    style: TextStyle(
                      fontSize: fontSize, fontWeight: FontWeight.w900,
                      color: AppColors.jadeWhite,
                      fontFamily: 'Noto Serif SC',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(tile.seal,
                    style: TextStyle(
                      fontSize: fontSize * 0.45, fontWeight: FontWeight.w700,
                      color: tile.suitColor,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 4, right: 6,
              child: Text(tile.label,
                style: const TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w600,
                  color: AppColors.celadonLight,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
