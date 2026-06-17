/// IAP 内购服务 — 封装 in_app_purchase 插件的核心逻辑。
///
/// 初始化 StoreKit 连接、查询商品、执行购买/恢复、
/// 通过 [IapState] 暴拉响应式状态流供 UI 消费。

import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';

/// 内购商品 ID 常量集合 — 必须与 App Store Connect 后台配置完全一致。
///
/// 集中管理所有 IAP SKU，避免散落字符串。新增商品时只需在此处添加，
/// 查询/购买流程会自动覆盖。所有 ID 使用反向域名约定（reverse-domain）。
class TzProducts {
  // 私有构造函数，防止实例化 — 此类仅作为命名空间使用。
  TzProducts._();

  /// 月度订阅 — 按月自动续费的高级会员。
  static const String monthly = 'com.tilezhan.app.premium.monthly';
  /// 年度订阅 — 按年自动续费的高级会员，单价低于月订阅。
  static const String yearly = 'com.tilezhan.app.premium.yearly';
  /// 永久买断 — 一次性购买，终身有效，无需续费。
  static const String lifetime = 'com.tilezhan.app.premium.lifetime';

  /// 所有已注册的商品 ID 集合，供 [InAppPurchase.queryProductDetails] 批量查询使用。
  static const Set<String> all = {monthly, yearly, lifetime};
}

/// IAP 响应式状态数据类 — 不可变（immutable），通过 [copyWith] 派生新实例。
///
/// 承载当前 IAP 连接状态、可用商品列表、用户已购权益及错误信息。
/// 通过 [IapService.stateStream] 向外广播，供 UI 层通过 Riverpod
/// 或 StreamBuilder 消费。
class IapState {
  /// 当前 IAP 连接状态：加载中 / 就绪 / 购买中 / 恢复中 / 错误 / 不可用。
  final IapStatus status;
  /// App Store 返回的商品详情列表，包含价格、货币、标题等本地化信息。
  final List<ProductDetails> products;
  /// 用户当前持有的权益 ID 集合（已购买或已恢复的商品 ID）。
  final Set<String> activeEntitlements;
  /// 最近一次错误的描述信息，无错误时为 null。
  final String? error;

  const IapState({
    this.status = IapStatus.loading,
    this.products = const [],
    this.activeEntitlements = const {},
    this.error,
  });

  /// 用户是否拥有高级会员权益 — 只要持有任意一个有效权益即为 true。
  bool get isPremium => activeEntitlements.isNotEmpty;
  /// App Store 是否已返回可购买商品列表。
  bool get hasProducts => products.isNotEmpty;

  /// 通过商品 ID 快速查找对应的 [ProductDetails]。
  ///
  /// 未找到时返回 null，不会抛出异常，适合 UI 安全取值。
  ProductDetails? operator [](String id) {
    try {
      return products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  /// 创建当前状态的拷贝，仅替换指定字段。
  ///
  /// [clearError] 为 true 时强制将 [error] 置为 null，
  /// 用于 UI 消费完错误提示后清除。
  IapState copyWith({
    IapStatus? status,
    List<ProductDetails>? products,
    Set<String>? activeEntitlements,
    String? error,
    bool clearError = false,
  }) {
    return IapState(
      status: status ?? this.status,
      products: products ?? this.products,
      activeEntitlements: activeEntitlements ?? this.activeEntitlements,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// IAP 连接生命周期状态枚举。
///
/// UI 依此决定展示 Loading 动画、商品列表、购买进度、错误提示或"不可用"页面。
enum IapStatus {
  /// 正在初始化 IAP 连接，尚未就绪。
  loading,
  /// 商品列表已加载完成，可以正常购买。
  ready,
  /// 用户正在进行购买操作。
  purchasing,
  /// 正在从 App Store 恢复已有购买记录。
  restoring,
  /// 发生错误，详见 [IapState.error]。
  error,
  /// 设备不支持 IAP（如家长控制已开启、未登录 Apple ID 等）。
  unavailable,
}

/// IAP 内购服务核心 — 对 [InAppPurchase] 插件的薄封装，提供 Riverpod 友好的响应式流。
///
/// # 架构角色
/// 位于 `core/iap` 层，是整个应用的唯一 IAP 入口。所有与购买相关的逻辑
/// （初始化、查询商品、购买、恢复、凭证更新监听）全部集中在此，上层 UI
/// 只通过 [stateStream] 和公开方法消费。
///
/// # 使用方式
/// ```dart
/// final service = IapService();
/// await service.init();
/// service.stateStream.listen((s) { ... });
/// await service.purchase(TzProducts.monthly);
/// ```
///
/// # 线程安全
/// [InAppPurchase] 的内部回调已在平台主线程执行，本类不做额外线程处理。
/// [purchase] 和 [restore] 的并发调用由 UI 层的购买按钮防重复点击保证，
/// 本类不做排队。
class IapService {
  // App Store 插件实例 — 使用单例 `InAppPurchase.instance`。
  final InAppPurchase _iap = InAppPurchase.instance;

  // 广播流控制器，支持多个监听者同时订阅（Riverpod provider + UI 层）。
  final _stateCtrl = StreamController<IapState>.broadcast();
  // 内部持有最新状态快照，用于 [state] 同步取值。
  IapState _state = const IapState();

  /// 响应式状态流 — 每次状态变更都会推送一个新的 [IapState]。
  Stream<IapState> get stateStream => _stateCtrl.stream;
  /// 当前状态同步快照 — 不需要监听变化时直接取用。
  IapState get state => _state;

  /// 初始化 IAP 连接：检测设备是否支持 IAP，若支持则开启购买凭证监听
  /// 并拉取商品列表。
  ///
  /// 应在应用启动早期调用（如 main() 或首个页面 initState）。
  /// 不支持 IAP 的设备会收到 [IapStatus.unavailable]。
  Future<void> init() async {
    final available = await _iap.isAvailable();
    if (!available) {
      _emit(_state.copyWith(status: IapStatus.unavailable));
      return;
    }
    // 订阅 App Store 购买凭证流 — 处理购买完成、恢复、取消等通知。
    _iap.purchaseStream.listen(_onPurchaseUpdate);
    await _fetchProducts();
  }

  // 向 App Store 查询 [TzProducts.all] 中已配置的商品详情。
  // 未配置的 SKU 仅打印警告，不阻塞就绪状态 — 这在开发期很常见。
  Future<void> _fetchProducts() async {
    try {
      final response = await _iap.queryProductDetails(TzProducts.all);
      if (response.notFoundIDs.isNotEmpty) {
        // 部分 SKU 未在 App Store Connect 配置 — 非致命错误。
        print('⚠ SKUs not found: ${response.notFoundIDs}');
      }
      _emit(_state.copyWith(
        status: IapStatus.ready,
        products: response.productDetails,
      ));
    } catch (e) {
      _emit(_state.copyWith(status: IapStatus.error, error: e.toString()));
    }
  }

  /// 发起购买指定商品 [productId]。
  ///
  /// 调用前需确保 [state] 处于 [IapStatus.ready]，且 [productId] 存在于
  /// [IapState.products] 列表中。购买结果通过 [stateStream] 异步推送：
  /// - 成功 → [IapStatus.ready] + [IapState.activeEntitlements] 更新
  /// - 失败/取消 → [IapStatus.ready] 或 [IapStatus.error]
  ///
  /// 会抛出 [StateError] 当 productId 不在已加载的商品列表中。
  /// 会 rethrow 底层购买异常，调用方应自行 catch。
  Future<void> purchase(String productId) async {
    final details = _state.products.firstWhere(
      (p) => p.id == productId,
      orElse: () => throw StateError('Product not found: $productId'),
    );
    print('🔵 Purchase: $productId (${details.title}, ${details.price})');
    _emit(_state.copyWith(status: IapStatus.purchasing));
    try {
      // buyNonConsumable 同时处理非消耗型商品和自动续费订阅
      await _iap.buyNonConsumable(purchaseParam: PurchaseParam(productDetails: details));
      print('✅ Purchase completed: $productId');
    } catch (e) {
      print('❌ Purchase error: $e');
      _emit(_state.copyWith(status: IapStatus.error, error: e.toString()));
      rethrow;
    }
  }

  /// 恢复用户已购买的商品 / 订阅记录。
  ///
  /// 适用于用户换机或卸载重装后恢复权益的场景。
  /// 恢复结果通过 [stateStream] 异步推送，与 [purchase] 的流程一致。
  Future<void> restore() async {
    _emit(_state.copyWith(status: IapStatus.restoring));
    try {
      await _iap.restorePurchases();
    } catch (e) {
      _emit(_state.copyWith(status: IapStatus.error, error: e.toString()));
    }
  }

  // 处理 App Store 推送的购买凭证更新流。
  //
  // 根据不同的 [PurchaseStatus] 分别处理：
  // - purchased/restored → 记录权益，完成凭证，恢复就绪状态
  // - pending → 等待（如"Ask to Buy"家长审批场景）
  // - error → 推送错误状态
  // - canceled → 直接恢复就绪状态
  void _onPurchaseUpdate(List<PurchaseDetails> purchases) {
    for (final p in purchases) {
      switch (p.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          // 将新获得的商品 ID 合并进活跃权益集合
          final entitlements = {..._state.activeEntitlements, p.productID};
          // 通知 App Store 凭证已处理完毕
          _iap.completePurchase(p);
          _emit(_state.copyWith(
            status: IapStatus.ready,
            activeEntitlements: entitlements,
          ));
        case PurchaseStatus.pending:
          // "Ask to Buy" 等场景 — 等待家长/监护人审批，不做状态变更。
          break;
        case PurchaseStatus.error:
          _emit(_state.copyWith(status: IapStatus.error, error: p.error?.message));
        case PurchaseStatus.canceled:
          // 用户主动取消 — 回到就绪状态，不清空已持有的权益。
          _emit(_state.copyWith(status: IapStatus.ready));
      }
    }
  }

  // 内部状态更新函数 — 同时更新同步快照和广播流。
  // 所有状态变更都经过此函数，保证 [_state] 与 [_stateCtrl] 始终一致。
  void _emit(IapState s) {
    _state = s;
    _stateCtrl.add(s);
  }

  /// 释放 IAP 资源 — 关闭状态广播流控制器。
  ///
  /// 应在 Service 生命周期结束时调用（如 Provider dispose）。
  /// 调用后 [stateStream] 不再推送任何事件。
  void dispose() => _stateCtrl.close();
}
