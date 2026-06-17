/// AppColors 全局色板常量 — 赛博国风色彩系统
///
/// 本文件集中定义整个应用的色彩常量，所有界面组件通过 [AppColors] 的静态成员引用颜色，
/// 禁止在业务代码中硬编码 Color(0xFF...)。修改色板时只需改此文件，全局生效。
///
/// ## 色彩体系概览
/// - **翡翠绿系**：深底色、卡片底色、悬停态三层递进，构成暗色背景基调。
/// - **琉璃红系**：主强调色 + 悬停态，用于关键操作按钮、危险提示、高亮标记。
/// - **霓虹金系**：主强调色 + 悬停态 + 低亮态，用于高亮文字、图标、得分/等级展示。
/// - **玉白系**：主文字色 + 低亮态(次要文字) + 柔和态(禁用/占位文字)。
/// - **青瓷蓝系**：辅助强调色，用于链接、信息提示、次要交互元素。
/// - **暗夜紫系**：辅助强调色，用于特殊状态、龙牌标识。
/// - **牌花色系**：万(红)/筒(蓝)/索(绿)/风(橙)/龙(紫)，用于牌面花色渲染及牌型统计图表。
///
/// ## 使用约定
/// - 背景色一律从翡翠绿系选取：最深色用于页面/导航栏底色，卡片色用于卡片/面板，
///   悬停色用于列表项 hover/选中态。
/// - 前景强调色从琉璃红或霓虹金选取，同一界面内避免两者混用以免视觉冲突。
/// - 文字层级：主文字用 `jadeWhite`，次要说明用 `jadeWhiteDim`，
///   禁用/占位符用 `jadeWhiteMuted`。
/// - 牌花色仅供牌面渲染及牌型相关 UI 使用，不应用于通用界面组件。
///
/// Cyber-Chinese-style centralized color palette. All UI components reference
/// colors via [AppColors] static members; never hardcode Color(0xFF...) in
/// business code. Edit here to update globally.
library;

import 'package:flutter/material.dart';

/// 赛博国风全局色板 — 所有颜色常量的静态持有类
///
/// 本类仅包含静态常量成员，不提供实例化。每个字段代表色彩系统中的一个语义色阶，
/// 命名规则为 `色系名 + 可选状态后缀`（如 `vermillionHover` 表示琉璃红的悬停态）。
///
/// ## 状态后缀约定
/// - 无后缀：该色系的基准色/主色。
/// - `Hover`：鼠标悬停或按下时的反馈色，比基准色更亮/更柔和。
/// - `Dim`：降低亮度的变体，用于非激活态但仍需保持色系辨识度的场景。
/// - `Muted`：大幅降低饱和度的变体，用于禁用态或极次要信息。
/// - `Light`：浅色变体，用于浅色背景上的该色系元素。
/// - `Deep`：最深色变体，用于最深层的背景。
/// - `Card`：卡片/面板底色变体，比 `Deep` 略亮以形成层次。
///
/// Centralized color palette for the cyber-Chinese-style theme.
/// All members are static const; this class is never instantiated.
class AppColors {
  // =========================================================================
  // 翡翠绿系 — 暗色背景基调
  // Jade green family: dark background foundation
  // =========================================================================

  /// 翡翠绿-深底色，用于页面/导航栏/侧边栏等最底层背景。
  /// Jade green — deepest background for pages, nav bars, sidebars.
  static const jadeDeep = Color(0xFF0A2F1D);

  /// 翡翠绿-卡片底色，用于卡片、面板、对话框等浮层背景。
  /// 比 [jadeDeep] 略亮，在深底色上形成清晰的层次分隔。
  /// Jade green — card/panel surface, slightly lighter than [jadeDeep]
  /// to create clear layering on dark backgrounds.
  static const jadeCard = Color(0xFF0D3D26);

  /// 翡翠绿-悬停态，用于列表项 hover、选中态、高亮行背景。
  /// 比 [jadeCard] 更亮，提供即时交互反馈。
  /// Jade green — hover/selected state for list items and rows.
  /// Brighter than [jadeCard] for immediate interaction feedback.
  static const jadeHover = Color(0xFF124D31);

  // =========================================================================
  // 琉璃红系 — 主强调色 (暖色，高视觉权重)
  // Vermillion red family: primary accent (warm, high visual weight)
  // =========================================================================

  /// 琉璃红-基准色，用于主按钮、重要操作入口、危险/错误状态图标。
  /// 该颜色视觉权重极高，一个界面内建议不超过 2-3 处使用。
  /// Vermillion red — primary buttons, critical actions, error/danger icons.
  /// Very high visual weight; limit to 2-3 occurrences per screen.
  static const vermillion = Color(0xFFFF3B30);

  /// 琉璃红-悬停态，用于主按钮的 hover/pressed 反馈。
  /// 比 [vermillion] 更亮更柔和，按压时避免刺眼。
  /// Vermillion red — hover/pressed state. Brighter and softer than
  /// [vermillion] to avoid visual harshness on press.
  static const vermillionHover = Color(0xFFFF6B6B);

  // =========================================================================
  // 霓虹金系 — 高亮强调色 (暖色，适合文字/图标高亮)
  // Neon gold family: highlight accent (warm, ideal for text/icon highlighting)
  // =========================================================================

  /// 霓虹金-基准色，用于高亮文字、关键数据、得分/等级徽章、金色图标。
  /// 适合在暗色背景上营造"发光"效果。
  /// Neon gold — highlighted text, key metrics, score/badge, gold icons.
  /// Designed to create a "glow" effect on dark backgrounds.
  static const neonGold = Color(0xFFFFD700);

  /// 霓虹金-悬停态，用于可点击金色元素的 hover 反馈。
  /// 比 [neonGold] 更亮。
  /// Neon gold — hover state for clickable gold elements.
  /// Brighter than [neonGold].
  static const neonGoldHover = Color(0xFFFFE44D);

  /// 霓虹金-低亮态，用于非激活态的金色元素（如未解锁的成就徽章）。
  /// 比 [neonGold] 略暗，保持色系辨识度但降低视觉权重。
  /// Neon gold — dimmed variant for inactive gold elements
  /// (e.g. locked achievement badges). Slightly darker than [neonGold].
  static const neonGoldDim = Color(0xFFFFC107);

  // =========================================================================
  // 玉白系 — 文字层级
  // Jade white family: text hierarchy
  // =========================================================================

  /// 玉白-基准色，用于正文、标题、重要标签等主要文字内容。
  /// 在翡翠绿深色背景上提供高对比度阅读体验。
  /// Jade white — body text, headings, primary labels.
  /// High contrast against jade-green dark backgrounds.
  static const jadeWhite = Color(0xFFF5F0E8);

  /// 玉白-低亮态，用于次要说明文字、副标题、辅助信息。
  /// 比 [jadeWhite] 暗一级，形成主次文字视觉层级。
  /// Jade white — dimmed, for secondary text, subtitles, auxiliary info.
  /// One level darker than [jadeWhite] for visual hierarchy.
  static const jadeWhiteDim = Color(0xFFD5CFC6);

  /// 玉白-柔和态，用于禁用文字、占位符(placeholder)、极次要标注。
  /// 大幅降低对比度，明确传达"不可交互/低优先级"语义。
  /// Jade white — muted, for disabled text, placeholders, low-priority labels.
  /// Significantly reduced contrast to convey non-interactive/low-priority state.
  static const jadeWhiteMuted = Color(0xFF8A847C);

  // =========================================================================
  // 青瓷蓝系 — 辅助强调色 (冷色，适合信息/链接)
  // Celadon blue family: secondary accent (cool, ideal for info/links)
  // =========================================================================

  /// 青瓷蓝-基准色，用于链接、信息提示图标、次要交互按钮。
  /// 作为琉璃红的冷色补充，适合"信息型"（非"行动型"）强调场景。
  /// Celadon blue — links, info icons, secondary buttons.
  /// Cool-toned complement to vermillion, for informational emphasis
  /// rather than action-oriented emphasis.
  static const celadonBlue = Color(0xFF4A90D9);

  /// 青瓷蓝-浅色，用于浅色背景上的蓝色元素或 hover 态。
  /// 比 [celadonBlue] 更亮，在深色背景上也能保持辨识度。
  /// Celadon blue — light variant, for blue elements on light surfaces
  /// or hover states. Brighter than [celadonBlue].
  static const celadonLight = Color(0xFF6DB3F2);

  // =========================================================================
  // 暗夜紫系 — 辅助强调色 (冷色，适合特殊状态/龙牌)
  // Demon purple family: secondary accent (cool, for special states/dragons)
  // =========================================================================

  /// 暗夜紫-基准色，用于特殊状态标记、龙牌花色、魔法/稀有元素。
  /// 视觉权重介于琉璃红和青瓷蓝之间，适合需要"突出但不紧急"的场景。
  /// Demon purple — special states, dragon suit, magic/rare elements.
  /// Visual weight between vermillion and celadon blue; suitable for
  /// "prominent but not urgent" scenarios.
  static const demonPurple = Color(0xFF9B59B6);

  // =========================================================================
  // 牌花色系 — 麻将牌面花色渲染
  // Tile suit colors: for mahjong tile face rendering
  // =========================================================================

  /// 牌花色-万子(红)，用于万子牌面字符及万子相关统计图表。
  /// 选用偏暖红色以区分于琉璃红（更偏橙红）。
  /// Suit — Man (Characters), used for Man tile faces and Man-related charts.
  /// Warmer red distinct from vermillion (which leans orange-red).
  static const suitMan = Color(0xFFE74C3C);

  /// 牌花色-筒子(蓝)，用于筒子牌面图案及筒子相关统计图表。
  /// Suit — Pin (Dots), used for Pin tile faces and Pin-related charts.
  static const suitPin = Color(0xFF3498DB);

  /// 牌花色-索子(绿)，用于索子牌面图案及索子相关统计图表。
  /// Suit — Sou (Bamboo), used for Sou tile faces and Sou-related charts.
  static const suitSou = Color(0xFF2ECC71);

  /// 牌花色-风牌(橙)，用于风牌(东南西北)牌面及风牌相关统计。
  /// Suit — Wind (honor tiles: E/S/W/N), used for Wind tile faces and charts.
  static const suitWind = Color(0xFFF39C12);

  /// 牌花色-龙牌(紫)，用于龙牌(中发白/箭牌)牌面及龙牌相关统计。
  /// 与 [demonPurple] 值相同，但语义独立——龙牌花色未来可能需要独立调整。
  /// Suit — Dragon (honor tiles: dragons/arrows).
  /// Same value as [demonPurple] but semantically independent —
  /// dragon suit color may need independent adjustment in the future.
  static const suitDragon = Color(0xFF9B59B6);
}
