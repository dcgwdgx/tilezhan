import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class TzProgressBar extends StatelessWidget {
  final double value; // 0.0-1.0
  final Color? color;
  final double height;

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
