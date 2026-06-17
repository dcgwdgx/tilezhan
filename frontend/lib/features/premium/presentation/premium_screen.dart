/// 会员订阅页面：展示四档定价方案（免费 / 月付 / 年付 / 终身买断）。
///
/// 页面结构包括：
/// - 顶部的方案卡片（含角标高亮、功能列表、实时 IAP 价格）；
/// - 底部的 CTA 按钮（"继续" / "请选择方案" / "购买中..."）；
/// - "恢复购买"链接（调用 IapService.restore）；
/// - 错误重试卡片（当 IAP 初始化失败时显示）；
/// - 首开 48 小时终身折扣横幅（仅对新用户展示，已付费用户不显示）。
///
/// 状态管理：
/// - [IapState] 通过 Riverpod 的 [iapStateProvider] 读取，包含产品列表、购买状态、错误信息；
/// - 当前选中的方案 ID 存储在本地 state [_selectedId] 中；
/// - 购买流程通过 [IapService] 发起，结果以 SnackBar 反馈。
///
/// 导航：
/// - 返回按钮调用 [GoRouter.pop]，关闭当前页面；
/// - 选择"免费方案"时直接 pop 返回，不触发 IAP 流程。
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/hearts/heart_provider.dart';
import '../../../core/iap/iap_provider.dart';
import '../../../core/iap/iap_service.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/tz_button.dart';
import '../../../shared/widgets/tz_card.dart';

/// 会员定价页面顶层 Widget，绑定 Riverpod 的 [ConsumerStatefulWidget]。
///
/// 该页面展示四档方案：免费、月付、年付、终身买断。
/// 从 [IapState] 读取 IAP 产品详情（通过 Riverpod），渲染可选方案卡片，
/// 并在底部提供 CTA 按钮触发 [IapService] 的购买流程。
/// 同时渲染"恢复购买"链接和各方案的功能列表。
class PremiumScreen extends ConsumerStatefulWidget {
  const PremiumScreen({super.key});

  /// 创建与当前 Widget 绑定的 State 对象。
  ///
  /// 返回 [_PremiumScreenState] 实例，该 State 持有本地选中方案 ID，
  /// 并负责监听 IAP 状态变化、渲染方案卡片、处理购买与恢复逻辑。
  @override
  ConsumerState<PremiumScreen> createState() => _PremiumScreenState();
}

/// [PremiumScreen] 的 State 类，生命周期与 Widget 绑定。
///
/// 职责：
/// - 维护当前选中的方案 ID [_selectedId]；
/// - 通过 [ref.watch] 订阅 [iapStateProvider] 的状态变化并自动重绘；
/// - 构建 Loading / Error / Content 三种 UI 形态（使用 [AsyncValue.when]）；
/// - 提供购买、恢复、方案切换等方法。
class _PremiumScreenState extends ConsumerState<PremiumScreen> {
  /// 当前用户选中的方案 ID（如 'free', 'monthly', 'yearly', 'lifetime'）。
  ///
  /// 为 `null` 时表示用户尚未选择任何方案，此时 CTA 按钮显示"请选择方案"且不可点击。
  String? _selectedId;

  /// 构建页面的根 Widget 树。
  ///
  /// 渲染步骤：
  /// 1. 从 [AppLocalizations] 获取本地化字符串；
  /// 2. 通过 [ref.watch] 订阅 [iapStateProvider] 获取异步 IAP 状态；
  /// 3. 使用 [AsyncValue.when] 匹配三种状态：
  ///    - `data`：IAP 初始化成功，渲染完整内容区；
  ///    - `loading`：显示居中的加载指示器；
  ///    - `error`：构造一个带 error 信息的伪 [IapState] 传给内容区渲染错误界面。
  ///
  /// 整体布局为 [Scaffold]（深色翡翠背景 + 返回按钮 AppBar）+ [SafeArea] 包裹。
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final iapAsync = ref.watch(iapStateProvider);

    return Scaffold(
      backgroundColor: AppColors.jadeDeep,
      appBar: AppBar(
        backgroundColor: AppColors.jadeDeep,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.jadeWhiteDim),
          // 返回按钮：调用 GoRouter 的 pop 关闭当前页面
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: iapAsync.when(
          data: (state) => _buildContent(state),
          loading: () => _buildLoading(),
          // 出错时构造伪 state 传入 _buildContent，让用户看到错误提示和重试按钮
          error: (e, _) => _buildContent(IapState(
            status: IapStatus.error,
            error: e.toString(),
          )),
        ),
      ),
    );
  }

  /// 构建加载中界面：居中显示 NeonGold 旋转指示器 + "Connecting..." 文案。
  ///
  /// 在 [IapState] 尚未就绪时显示，让用户感知到正在连接 App Store 获取价格信息。
  Widget _buildLoading() {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const CircularProgressIndicator(color: AppColors.neonGold),
        const SizedBox(height: 16),
        Text(l10n.premiumConnecting,
          style: TextStyle(fontSize: 14, color: AppColors.jadeWhiteDim)),
      ]),
    );
  }

  /// 构建页面主体内容区（正常展示或错误展示）。
  ///
  /// 接收 [IapState] 参数，根据其内部状态决定渲染内容：
  /// - 当 [state.error] 非空时，渲染错误卡片（含重试按钮）；
  /// - 当 [state.hasProducts] 为 true 时，渲染方案卡片列表；
  /// - 底部始终渲染 CTA 按钮、"恢复购买"链接、以及页脚说明。
  ///
  /// 额外条件：
  /// - 首开 48 小时 Lifetime 促销横幅：仅当 [heartServiceProvider] 返回 active 且用户
  ///   未付费时展示（通过 [isLifetimePromoActive(false)] 判断非付费用户）；
  /// - CTA 按钮文字根据状态切换："购买中..." / "继续" / "请选择方案"；
  /// - 购买中或未选择方案时 CTA 按钮不可点击。
  ///
  /// [state] 当前 IAP 状态，包含产品列表、支付状态、错误信息等。
  Widget _buildContent(IapState state) {
    final l10n = AppLocalizations.of(context)!;
    final error = state.error;
    final isPurchasing = state.status == IapStatus.purchasing;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        // 顶部图标：💎 宝石 emoji，视觉锚点
        const Text('💎', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 8),
        // 页面标题："Premium" / "高级会员"
        Text(l10n.premiumTitle,
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900,
            color: AppColors.neonGold, letterSpacing: 1)),
        const SizedBox(height: 16),
        // 首开 48h Lifetime 促销横幅（仅对新用户展示，已付费用户不显示）
        if (ref.read(heartServiceProvider).isLifetimePromoActive(false))
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.neonGold.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.neonGold.withOpacity(0.2)),
            ),
            // 🚀 火箭 emoji + 促销文案
            child: Row(children: [
              const Text('🚀', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(child: Text(l10n.premiumLaunchBanner,
                style: TextStyle(fontSize: 12, color: AppColors.neonGold))),
            ]),
          ),
        // 错误卡片：当 IAP 初始化失败时展示
        if (error != null)
          _buildError(error)
        // 方案卡片列表：当产品列表已加载时展开渲染
        else if (state.hasProducts)
          ..._buildPlanCards(state, isPurchasing),

        const SizedBox(height: 20),

        // 底部 CTA 按钮：三种状态文字切换
        // - 购买中："Purchasing..."（不可点击）
        // - 已选方案："Continue"（可点击，触发 _purchase）
        // - 未选方案："Select a plan"（不可点击）
        TzButton(
          label: isPurchasing
            ? l10n.premiumPurchasing
            : (_selectedId != null ? l10n.premiumContinue : l10n.premiumSelectPlan),
          style: TzButtonStyle.gold,
          onPressed: _selectedId != null && !isPurchasing
            ? () => _purchase(_selectedId!)
            : null,
        ),
        const SizedBox(height: 12),
        // "恢复购买"文本按钮（底部链接样式）
        _buildRestoreButton(),
        const SizedBox(height: 8),
        // 页脚说明："所有方案均包含..." 等法律/说明文本
        _buildAllPlansFooter(),
        const SizedBox(height: 40),
      ]),
    );
  }

  /// 构建四档方案卡片列表（Free / Monthly / Annual / Lifetime）。
  ///
  /// 数据来源：
  /// - [state.products] 中的 [ProductDetails] 按 ID 映射，用于获取实时价格；
  /// - 硬编码的功能列表和文案（通过 l10n 国际化）。
  ///
  /// 交互：
  /// - 每张卡片是一个 [GestureDetector]，点击后通过 [setState] 更新 [_selectedId]；
  /// - 当 [disabled] 为 true（购买进行中）时，所有卡片的点击事件被禁用；
  /// - 选中的卡片有 NeonGold 边框 + 浅金背景高亮，免费方案卡片有半透明叠加区分。
  ///
  /// 每张卡片的内部结构：
  /// - 第一行：方案标题 + 角标（如"最受欢迎"/"最佳价值"/"一次付费"）；
  /// - 第二行：价格（大字）+ 单位后缀；
  /// - 第三部分：功能列表（check 图标 + 功能文字）。
  ///
  /// [state] 当前 IAP 状态，用于读取产品价格。
  /// [disabled] 是否禁用所有卡片交互（购买进行中时为 true）。
  /// 返回方案卡片 Widget 列表，通过 `...` 展开嵌入父级 [Column]。
  List<Widget> _buildPlanCards(IapState state, bool disabled) {
    final l10n = AppLocalizations.of(context)!;
    // 将产品列表转为 Map<id, ProductDetails>，便于按 ID 快速查找价格
    final products = Map<String, ProductDetails>.fromEntries(
      state.products.map((p) => MapEntry(p.id, p)),
    );

    // 四档方案定义：构造函数 [_Plan] 统一建模
    final plans = [
      _Plan(
        id: 'free',
        title: l10n.premiumFree,
        price: '\$0',
        subtitle: '10/day',
        badge: null, // 免费方案无角标
        features: const ['10 puzzles/day', 'Mistakes free forever', 'Daily challenge'],
        isFree: true,
      ),
      _Plan(
        id: TzProducts.monthly,
        title: l10n.premiumMonthly,
        // 优先取 IAP 实时价格，获取失败则回退到固定默认价格
        price: products[TzProducts.monthly]?.price ?? '\$4.99',
        subtitle: '/month',
        badge: l10n.premiumPopular, // "Most Popular" 角标
        features: const ['Unlimited puzzles', 'SRS mistake tracking', 'Full stats & analytics', 'All difficulties'],
      ),
      _Plan(
        id: TzProducts.yearly,
        title: l10n.premiumAnnual,
        price: products[TzProducts.yearly]?.price ?? '\$29.99',
        subtitle: '/year',
        badge: l10n.premiumBestValue, // "Best Value" 角标
        features: const ['Everything in Monthly', 'ELO deep analysis', 'Exclusive skins', 'Priority support'],
      ),
      _Plan(
        id: TzProducts.lifetime,
        title: l10n.premiumLifetime,
        price: products[TzProducts.lifetime]?.price ?? '\$49.99',
        subtitle: 'one time',
        badge: l10n.premiumPayOnce, // "Pay Once" 角标
        features: const ['Everything forever', 'All future features', 'Founder badge', 'No subscriptions'],
      ),
    ];

    // 遍历四档方案，为每个方案生成一张可点击的卡片
    return plans.map((plan) {
      final isSelected = _selectedId == plan.id;
      final isFree = plan.isFree;

      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: GestureDetector(
          // disable 为 true 时禁止点击（购买进行中）
          onTap: disabled ? null : () => setState(() => _selectedId = plan.id),
          child: AnimatedContainer(
            // 200ms 动画过渡：背景色、边框宽度、边框颜色平滑切换
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              // 背景色三层逻辑：选中→NeonGold浅色；免费→半透明；默认→标准卡片色
              color: isSelected
                ? AppColors.neonGold.withOpacity(0.12)
                : isFree
                  ? AppColors.jadeCard.withOpacity(0.6)
                  : AppColors.jadeCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                // 边框：选中→NeonGold 2px；未选中→jadeHover 1px
                color: isSelected
                  ? AppColors.neonGold
                  : isFree ? AppColors.jadeHover : AppColors.jadeHover,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // ======== 第一行：方案标题 + 角标 ========
              Row(children: [
                // 方案标题（如"月付会员"），选中时高亮为 NeonGold
                Expanded(child: Text(plan.title, style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: isSelected ? AppColors.neonGold : AppColors.jadeWhite,
                  letterSpacing: 1,
                ))),
                // 角标（如"最受欢迎"）：仅在 badge 非空时渲染
                if (plan.badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      // 终身方案角标用浅金半透明，其他方案角标用实心 NeonGold
                      color: plan.id == TzProducts.lifetime
                        ? AppColors.neonGold.withOpacity(0.2)
                        : AppColors.neonGold,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(plan.badge!, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800,
                        // 终身方案角标文字为金色，其他角标文字为黑色
                        color: plan.id == TzProducts.lifetime
                          ? AppColors.neonGold : Colors.black,
                    )),
                  ),
              ]),
              const SizedBox(height: 6),
              // ======== 第二行：价格 + 单位后缀 ========
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                // 价格大字（如 "$4.99"）
                Text(plan.price, style: const TextStyle(
                  fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.jadeWhite)),
                // 单位后缀（如 "/month", "/year", "one time"）
                if (plan.subtitle.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4, left: 4),
                    child: Text(plan.subtitle, style: const TextStyle(
                      fontSize: 12, color: AppColors.jadeWhiteDim)),
                  ),
              ]),
              const SizedBox(height: 10),
              // ======== 第三部分：功能列表 ========
              ...plan.features.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(children: [
                  // NeonGold ✓ 勾选图标
                  const Icon(Icons.check, size: 14, color: AppColors.neonGold),
                  const SizedBox(width: 8),
                  // 功能描述文字
                  Expanded(child: Text(f, style: const TextStyle(
                    fontSize: 12, color: AppColors.jadeWhiteDim, height: 1.4))),
                ]),
              )),
            ]),
          ),
        ),
      );
    }).toList();
  }

  /// 构建错误展示卡片：错误图标 + 错误信息 + "RETRY" 重试按钮。
  ///
  /// 当 IAP 初始化失败或网络异常时显示此卡片。
  /// 重试按钮调用 [IapService.init] 重新初始化 IAP 连接。
  ///
  /// [message] 错误描述字符串，来自 [IapState.error]。
  Widget _buildError(String message) {
    return TzCard(padding: const EdgeInsets.all(16), child: Column(children: [
      // 红色错误图标
      const Icon(Icons.error_outline, color: Colors.redAccent, size: 32),
      const SizedBox(height: 8),
      // 错误信息文本（居中、小字、低亮度）
      Text(message, textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 13, color: AppColors.jadeWhiteDim)),
      const SizedBox(height: 12),
      // RETRY 按钮：Ghost 样式，点击后重新调用 IapService.init()
      TzButton(label: 'RETRY', style: TzButtonStyle.ghost,
        onPressed: () => ref.read(iapServiceProvider).init()),
    ]));
  }

  /// 构建"Restore Purchases"文本按钮。
  ///
  /// 样式为带下划线的文字链接（jadeWhiteMuted 色）。
  /// 点击后调用 [IapService.restore] 恢复用户之前已购买的非消耗型 IAP 商品。
  /// 恢复成功与否由 [IapService] 内部处理（通常通过 SnackBar 反馈）。
  Widget _buildRestoreButton() {
    final l10n = AppLocalizations.of(context)!;
    return TextButton(
      onPressed: () => ref.read(iapServiceProvider).restore(),
      child: Text(l10n.premiumRestore,
        style: TextStyle(fontSize: 12, color: AppColors.jadeWhiteMuted,
          decoration: TextDecoration.underline)),
    );
  }

  /// 构建页脚说明区域：显示"所有方案均包含..."等法律/政策说明文本。
  ///
  /// 位于"恢复购买"按钮下方，半透明卡片容器内居中展示两行小字文本。
  /// 第一行为标题（如"All plans include:"），第二行为详细说明。
  Widget _buildAllPlansFooter() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppColors.jadeCard.withOpacity(0.5),
      ),
      child: Column(children: [
        // 页脚标题
        Text(l10n.premiumAllPlansHeader,
          style: const TextStyle(fontSize: 11, color: AppColors.jadeWhiteMuted)),
        const SizedBox(height: 6),
        // 页脚详细说明文本
        Text(l10n.premiumAllPlansFooter,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: AppColors.jadeWhiteDim)),
      ]),
    );
  }

  /// 执行购买流程。
  ///
  /// 分支逻辑：
  /// - 如果 [id] 为 `'free'`，直接调用 [context.pop] 返回上一页（免费方案无需 IAP）；
  /// - 否则显示"Connecting to App Store..." SnackBar，
  ///   然后调用 [IapService.purchase(id)] 发起 IAP 购买；
  /// - 购买成功：在 `mounted` 检查后显示绿色"Purchase successful!" SnackBar；
  /// - 购买失败：在 `mounted` 检查后显示红色"Purchase failed:" SnackBar（持续 4 秒）。
  ///
  /// 注意事项：
  /// - 所有 UI 更新前都检查 [mounted]，防止 Widget 已销毁时调用 setState/ScaffoldMessenger；
  /// - 购买结果通过 SnackBar 即时反馈，不阻塞 UI。
  ///
  /// [id] 要购买的方案 ID，对应 [TzProducts] 中的常量（monthly/yearly/lifetime）或 'free'。
  void _purchase(String id) {
    // 免费方案：直接返回上一页，不触发 IAP
    if (id == 'free') {
      context.pop();
      return;
    }
    // 显示购买中 SnackBar，告知用户正在连接 App Store
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Connecting to App Store...'),
        duration: Duration(seconds: 2)));

    // 调用 IapService 发起购买
    ref.read(iapServiceProvider).purchase(id).then((_) {
      // 成功回调：仅在 Widget 仍挂载时显示成功提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Purchase successful! 🎉'),
            backgroundColor: Colors.green));
      }
    }).catchError((e) {
      // 失败回调：仅在 Widget 仍挂载时显示错误提示（持续 4 秒便于用户阅读）
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Purchase failed: $e'),
            backgroundColor: Colors.red, duration: const Duration(seconds: 4)));
      }
    });
  }
}

/// UI 展示用的定价方案数据模型。
///
/// 仅用于 [PremiumScreen] 内部的方案卡片渲染，不参与 IAP 逻辑。
/// 每个实例对应一档方案（Free / Monthly / Annual / Lifetime），
/// 包含展示所需的全部信息：ID、标题、价格、副标题、角标、功能列表、是否免费。
///
/// 字段说明：
/// - [id]：方案唯一标识（'free', TzProducts.monthly, TzProducts.yearly, TzProducts.lifetime）；
/// - [title]：方案名称（已国际化）；
/// - [price]：价格字符串（IAP 实时价格或默认回退价）；
/// - [subtitle]：价格后缀（如 '/month', '/year', 'one time'）；
/// - [badge]：角标文字（如"Most Popular", "Best Value", "Pay Once"），null 表示无角标；
/// - [features]：功能列表字符串数组；
/// - [isFree]：是否为免费方案（影响卡片背景色和点击行为）。
class _Plan {
  /// 方案唯一标识符。
  /// 对应 'free' 或 [TzProducts] 中的 monthly / yearly / lifetime 常量。
  final String id;

  /// 方案显示名称，已通过 [AppLocalizations] 国际化。
  final String title;

  /// 价格展示字符串。
  /// 优先使用 [ProductDetails.price]（IAP 实时价格），获取失败时回退到硬编码默认值。
  final String price;

  /// 价格后缀，如 '/month', '/year', 'one time'。
  /// 免费方案则为空字符串。
  final String subtitle;

  /// 角标文字，如"Most Popular"、"Best Value"、"Pay Once"。
  /// 免费方案无角标（null）。
  final String? badge;

  /// 方案包含的功能列表，每项功能前渲染 ✓ 图标。
  final List<String> features;

  /// 是否为免费方案。
  /// 为 true 时卡片背景半透明，点击直接返回而非触发 IAP 流程。
  final bool isFree;

  /// 构造一档定价方案。
  ///
  /// [id] 和 [title] 和 [price] 为必填参数。
  /// [subtitle] 默认为空字符串；[badge] 默认为 null；
  /// [features] 默认为空列表；[isFree] 默认为 false。
  const _Plan({
    required this.id,
    required this.title,
    required this.price,
    this.subtitle = '',
    this.badge,
    this.features = const [],
    this.isFree = false,
  });
}
