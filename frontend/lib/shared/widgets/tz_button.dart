/// 琉璃红/霓虹金/ghost 三样式通用按钮组件。
///
/// 提供赛博国风配色体系下的三种按钮变体：
/// - [TzButtonStyle.primary] — 琉璃红填充，白字，适合主 CTA
/// - [TzButtonStyle.gold]   — 霓虹金填充，黑字，适合高亮操作
/// - [TzButtonStyle.ghost]  — 透明底 + 翡翠绿描边，玉白字，适合次级操作
///
/// Universal button widget with three cyber-Chinese-style variants:
/// vermillion-filled, neon-gold-filled, and ghost (transparent with jade border).
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// 按钮样式枚举，控制 [TzButton] 的填充和描边外观。
/// Button style variants that determine fill color and border treatment.
enum TzButtonStyle {
  /// 琉璃红填充 / Vermillion fill
  primary,

  /// 霓虹金填充 / Neon gold fill
  gold,

  /// 透明底 + 翡翠绿描边 / Transparent with jade-green border
  ghost,
}

/// 赛博国风通用按钮，支持琉璃红/霓虹金/ghost 三种样式。
///
/// Cyber-Chinese-style universal button with vermillion, gold, and ghost variants.
///
/// 固定圆角胶囊形状 (radius 30)，垂直内边距 16，可附带前置图标。
/// 未指定 [width] 时默认撑满父容器宽度。
class TzButton extends StatelessWidget {
  /// 按钮文本 / Button label text.
  final String label;

  /// 点击回调，为 null 时按钮禁用 / Tap callback; button is disabled when null.
  final VoidCallback? onPressed;

  /// 按钮样式变体，默认 [TzButtonStyle.primary] / Style variant, defaults to primary.
  final TzButtonStyle style;

  /// 按钮宽度，默认撑满父容器 / Width override; fills parent when null.
  final double? width;

  /// 前置图标，为 null 时不显示 / Leading icon; hidden when null.
  final IconData? icon;

  /// 创建 [TzButton] 实例，[label] 为必填项。
  /// Constructs a [TzButton] with the given [label] (required).
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
