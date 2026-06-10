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
    this.onTap,
    this.onDoubleTap,
  });

  @override
  Widget build(BuildContext context) {
    final tileSize = _sizeMap[size]!;
    final isSelected = state == TileState.selected;
    final isDimmed = state == TileState.dimmed;
    final assetPath = 'assets/tiles/${tile.id}.svg';

    return GestureDetector(
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutQuad,
        width: tileSize.width,
        height: tileSize.height,
        transform: Matrix4.translationValues(
          0, isSelected ? -12.0 : 0, 0,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? AppColors.neonGold
                : tile.suitColor.withOpacity(isDimmed ? 0.1 : 0.5),
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: tile.suitColor.withOpacity(0.4),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                  const BoxShadow(
                    color: Colors.black54,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ]
              : [
                  const BoxShadow(
                    color: Colors.black54,
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: Opacity(
            opacity: isDimmed ? 0.4 : 1.0,
            child: SvgPicture.asset(
              assetPath,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
