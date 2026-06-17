/// AppTheme 全局暗色主题配置。
///
/// 赛博国风色彩系统：翡翠绿底 + 霓虹金 + 琉璃红 + 暗夜紫，
/// 统一 TextTheme / 卡片 / 按钮 / 进度条等组件样式。
///
/// 本文件定义了 TileZhan 应用的唯一暗色主题 [AppTheme]。
/// 所有视觉样式集中在此配置，包括：
/// - 全局配色方案 ([ColorScheme])：翡翠绿底、琉璃红主色、霓虹金辅色
/// - 字体系统：统一使用 Poppins 字族
/// - 各组件级样式覆写：AppBar、卡片、按钮、底部导航、进度指示器
/// 调用方应通过 Riverpod provider 或 `Theme.of(context)` 获取主题，
/// 不应持久化持有 getter 返回值的引用（防止主题切换时不同步）。

import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// AppTheme — global visual theme for the TileZhan app.
///
/// Provides a cohesive [ThemeData] built from [AppColors] and [AppTypography],
/// covering ColorScheme, typography, and component-level overrides for
/// AppBar, cards, buttons, bottom nav, and progress indicators.
/// The dark cyber-brush-and-ink aesthetic (赛博国风) is the single supported
/// brightness; all surfaces use the jade-deep palette with vermillion and
/// neon-gold accents.
///
/// ## 设计意图
/// 赛博国风 (Cyber-Brush-and-Ink) 将传统中国色彩与现代暗色 UI 融合：
/// - **翡翠绿底** 营造沉稳、深邃的沉浸感
/// - **琉璃红** 作为主色，吸睛且具有东方韵味
/// - **霓虹金** 作为辅色，提供高对比度的视觉引导
/// - **玉白** 作为文本色，温和不刺眼
///
/// ## 使用方式
/// ```dart
/// // 方式一：通过 Theme.of 获取（推荐）
/// final theme = Theme.of(context);
/// final primaryColor = theme.colorScheme.primary;
///
/// // 方式二：直接引用静态 getter（仅初始化或非 Widget 场景）
/// final themeData = AppTheme.dark;
/// ```
///
/// ## 注意事项
/// - 目前仅支持暗色模式 (Brightness.dark)，暂不提供亮色变体
/// - 所有颜色值来自 [AppColors]，避免在此硬编码
/// - 修改任何组件样式后，需全局检查受影响页面
class AppTheme {
  /// The single [ThemeData] instance used app-wide.
  ///
  /// Always dark brightness. Colors are drawn from [AppColors];
  /// [AppTypography] is applied via the global [fontFamily] and per-widget
  /// [textStyle] overrides. Callers should access this through Riverpod
  /// or `Theme.of(context)` — not by holding a reference to the getter result.
  ///
  /// ## 子配置详解
  ///
  /// ### [colorScheme] — 全局语义色
  /// 定义了 primary/secondary/surface/error 及其对应的 on-* 文本色，
  /// Material 3 组件会自动匹配这些语义色到对应场景。
  ///
  /// ### [appBarTheme] — 顶部导航栏
  /// 深色底、无阴影、白色前景文字，与原型暗色 Header 保持一致。
  /// `scrolledUnderElevation` 设为 0，避免滚动时出现阴影分离感。
  ///
  /// ### [cardTheme] — 卡片容器
  /// 圆角 16px、无阴影，采用翡翠卡片底色，作为内容块的标准容器。
  ///
  /// ### [elevatedButtonTheme] — 实心按钮
  /// 琉璃红填充、圆角 30px 胶囊形、16px 加粗文字，用于主要操作 (Primary CTA)。
  ///
  /// ### [textButtonTheme] — 文字按钮
  /// 仅设置前景色为低亮玉白，适用于次要操作或链接式按钮。
  ///
  /// ### [bottomNavigationBarTheme] — 底部导航栏
  /// 深绿底色 (#0D3D26)、选中项霓虹金高亮、未选中项为柔和玉白，
  /// 类型为 fixed 以适配 4-5 个 tab 的等宽布局。
  ///
  /// ### [progressIndicatorTheme] — 进度指示器
  /// 霓虹金活动轨、翡翠绿悬停态底色作为非活动轨，
  /// 用于加载动画和进度条。
  static ThemeData get dark {
    return ThemeData(
      // ── 全局基础 ──────────────────────────────────────────
      brightness: Brightness.dark,                              // 固定暗色模式
      scaffoldBackgroundColor: AppColors.jadeDeep,              // 翡翠深绿底，营造沉浸感

      // ── 语义配色方案 ──────────────────────────────────────
      // 将 AppColors 的语义色映射到 Material 3 ColorScheme 槽位
      colorScheme: const ColorScheme.dark(
        primary:     AppColors.vermillion,       // 主色：琉璃红 — 用于 FAB、开关、选中态
        secondary:   AppColors.neonGold,         // 辅色：霓虹金 — 用于强调、徽章
        surface:     AppColors.jadeCard,         // 表面色：翡翠卡片色 — 用于卡片、对话框
        error:       AppColors.vermillion,       // 错误色：复用琉璃红 — 用于错误提示、校验失败
        onPrimary:   Colors.white,               // 主色上的文字：纯白
        onSecondary: AppColors.jadeDeep,         // 辅色上的文字：翡翠深绿 — 保证霓虹金上的可读性
        onSurface:   AppColors.jadeWhite,        // 表面上的文字：玉白
      ),

      // ── 全局字体 ──────────────────────────────────────────
      fontFamily: 'Poppins',                                    // 统一使用 Poppins 字族，确保跨平台一致性

      // ── AppBar 顶部导航栏 ─────────────────────────────────
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.jadeDeep,                    // 与脚手架底色一致
        elevation: 0,                                           // 无阴影，扁平化
        scrolledUnderElevation: 0,                              // 滚动后无阴影分离
        foregroundColor: AppColors.jadeWhite,                   // 返回箭头等图标色
        titleTextStyle: TextStyle(
          fontSize:   18,                                       // 标题字号
          fontWeight: FontWeight.w700,                          // 粗体
          color:      AppColors.jadeWhite,                      // 玉白文字
        ),
      ),

      // ── Card 卡片容器 ─────────────────────────────────────
      cardTheme: CardThemeData(
        color: AppColors.jadeCard,                              // 翡翠卡片底色
        elevation: 0,                                           // 无阴影，靠颜色区分层级
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),  // 大圆角 16px
        ),
      ),

      // ── ElevatedButton 实心主按钮 ─────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.vermillion,                // 琉璃红填充
          foregroundColor: Colors.white,                        // 纯白文字
          elevation: 0,                                         // 无阴影
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),            // 完全圆角 → 胶囊形
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 28,                                     // 左右内边距：28px
            vertical: 16,                                       // 上下内边距：16px
          ),
          textStyle: const TextStyle(
            fontSize:   16,                                     // 按钮文字大小
            fontWeight: FontWeight.w700,                        // 加粗
          ),
        ),
      ),

      // ── TextButton 文字按钮 ───────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.jadeWhiteDim,              // 低亮玉白，区分于主按钮
        ),
      ),

      // ── BottomNavigationBar 底部导航栏 ────────────────────
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF0D3D26),                     // 深绿底色，略浅于脚手架
        selectedItemColor: AppColors.neonGold,                  // 选中项：霓虹金高亮
        unselectedItemColor: AppColors.jadeWhiteMuted,          // 未选中项：柔和玉白
        type: BottomNavigationBarType.fixed,                    // 固定等宽布局，适配多 tab
      ),

      // ── ProgressIndicator 进度指示器 ──────────────────────
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.neonGold,                              // 活动轨：霓虹金
        linearTrackColor: AppColors.jadeHover,                  // 非活动轨：翡翠悬停色
      ),
    );
  }
}
