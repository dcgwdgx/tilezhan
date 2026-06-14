/// 霓虹金前景 + 翡翠绿背景 进度条 (Neon Gold foreground + Jade Green background progress bar).
///
/// Wraps [LinearProgressIndicator] with rounded corners and the project's
/// canonical progress colors: [AppColors.neonGold] for the filled track,
/// [AppColors.jadeHover] for the unfilled background.
///
/// Used throughout TileZhan to display dungeon progress, collection
/// completion, achievement tracking, and any 0%-100% metric.
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// A stylised progress bar with neon-gold fill and jade-green background.
///
/// Renders as a rounded linear track. The default height is 4 logical pixels
/// and the default colours come from the app palette, but both can be
/// overridden.
class TzProgressBar extends StatelessWidget {
  /// Current progress, expressed as a fraction in the range 0.0 – 1.0.
  final double value; // 0.0-1.0

  /// Optional override for the filled-track colour.
  ///
  /// When `null` (the default), [AppColors.neonGold] is used.
  final Color? color;

  /// Height of the bar in logical pixels (default 4).
  final double height;

  /// Creates a [TzProgressBar].
  ///
  /// [value] must be between 0.0 and 1.0 inclusive. [height] defaults to 4.
  /// If [color] is omitted the standard neon-gold palette colour is applied.
  const TzProgressBar({
    super.key, required this.value,
    this.color, this.height = 4,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: LinearProgressIndicator(
        value: value,
        backgroundColor: AppColors.jadeHover,
        color: color ?? AppColors.neonGold,
        minHeight: height,
      ),
    );
  }
}
