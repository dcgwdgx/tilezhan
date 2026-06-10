import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

enum TzButtonStyle { primary, gold, ghost }

class TzButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final TzButtonStyle style;
  final double? width;
  final IconData? icon;

  const TzButton({
    super.key, required this.label, this.onPressed,
    this.style = TzButtonStyle.primary, this.width, this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (style) {
      TzButtonStyle.primary => (AppColors.vermillion, Colors.white),
      TzButtonStyle.gold => (AppColors.neonGold, Colors.black),
      TzButtonStyle.ghost => (Colors.transparent, AppColors.jadeWhiteDim),
    };

    return SizedBox(
      width: width ?? double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
            side: style == TzButtonStyle.ghost
                ? const BorderSide(color: AppColors.jadeHover)
                : BorderSide.none,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
            Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}
