/// AppColors 色板常量
///
/// 赛博国风色彩系统：琉璃红/翡翠绿/霓虹金/暗夜紫，含主色、悬停态及辅助色。
/// 牌花色支持万/筒/索/风/龙五类。
///
/// Cyber-Chinese-style color palette: vermillion, jade, neon gold, demon purple
/// with base, hover, and auxiliary variants. Tile suit colors for Man/Pin/Sou/Wind/Dragon.
import 'package:flutter/material.dart';

/// 赛博国风全局色板 — 所有颜色常量集中管理，通过 [AppColors] 静态成员访问。
/// Centralized color palette for the cyber-Chinese-style theme.
class AppColors {
  /// 翡翠绿 — 深底色 / Jade green — deep background
  static const jadeDeep = Color(0xFF0A2F1D);
  /// 翡翠绿 — 卡片底色 / Jade green — card surface
  static const jadeCard = Color(0xFF0D3D26);
  /// 翡翠绿 — 悬停态 / Jade green — hover state
  static const jadeHover = Color(0xFF124D31);

  /// 琉璃红 — 主色 / Vermillion red — primary
  static const vermillion = Color(0xFFFF3B30);
  /// 琉璃红 — 悬停态 / Vermillion red — hover
  static const vermillionHover = Color(0xFFFF6B6B);
  /// 霓虹金 — 主色 / Neon gold — primary
  static const neonGold = Color(0xFFFFD700);
  /// 霓虹金 — 悬停态 / Neon gold — hover
  static const neonGoldHover = Color(0xFFFFE44D);
  /// 霓虹金 — 低亮态 / Neon gold — dimmed
  static const neonGoldDim = Color(0xFFFFC107);

  /// 玉白 — 主色 / Jade white — primary
  static const jadeWhite = Color(0xFFF5F0E8);
  /// 玉白 — 低亮态 / Jade white — dimmed
  static const jadeWhiteDim = Color(0xFFD5CFC6);
  /// 玉白 — 柔和态 / Jade white — muted
  static const jadeWhiteMuted = Color(0xFF8A847C);

  /// 青瓷蓝 — 主色 / Celadon blue — primary
  static const celadonBlue = Color(0xFF4A90D9);
  /// 青瓷蓝 — 浅色 / Celadon blue — light
  static const celadonLight = Color(0xFF6DB3F2);
  /// 暗夜紫 — 主色 / Demon purple — primary
  static const demonPurple = Color(0xFF9B59B6);

  /// 牌花色 — 万子 (红) / Suit — Man (red)
  static const suitMan = Color(0xFFE74C3C);
  /// 牌花色 — 筒子 (蓝) / Suit — Pin (blue)
  static const suitPin = Color(0xFF3498DB);
  /// 牌花色 — 索子 (绿) / Suit — Sou (green)
  static const suitSou = Color(0xFF2ECC71);
  /// 牌花色 — 风牌 (橙) / Suit — Wind (orange)
  static const suitWind = Color(0xFFF39C12);
  /// 牌花色 — 龙牌 (紫) / Suit — Dragon (purple)
  static const suitDragon = Color(0xFF9B59B6);
}
