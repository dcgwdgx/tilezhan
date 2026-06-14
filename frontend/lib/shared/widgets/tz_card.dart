import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// 翡翠绿底统一卡片组件，支持可配金边与圆角。
///
/// 采用 [AppColors.jadeCard] 作为统一底色，通过 [goldBorder] 开关控制
/// 是否展示 15% 透明度霓虹金描边，[borderRadius] 控制四角圆角半径。
///
/// 作为项目中统一的卡片容器，保证视觉一致性。
class TzCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool goldBorder;
  final double borderRadius;

  /// 创建一张翡翠绿底卡片。
  ///
  /// [child] 为卡片内容组件，必传。
  /// [padding] 内边距，默认 16px 四周。
  /// [goldBorder] 是否显示金色边框，默认 `false`（仅 hover 色描边）。
  /// [borderRadius] 圆角半径，默认 16px。
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
