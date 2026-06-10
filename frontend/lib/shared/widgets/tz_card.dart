import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class TzCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool goldBorder;
  final double borderRadius;

  const TzCard({
    super.key, required this.child,
    this.padding = const EdgeInsets.all(16),
    this.goldBorder = false,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.jadeCard,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: goldBorder ? AppColors.neonGold.withOpacity(0.15) : AppColors.jadeHover,
        ),
      ),
      child: child,
    );
  }
}
