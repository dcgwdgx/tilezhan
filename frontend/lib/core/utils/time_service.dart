/// ╔══════════════════════════════════════════════════════════════╗
/// ║  TimeService — 全局时间服务（单例静态工具类）                    ║
/// ║                                                              ║
/// ║  职责：                                                       ║
/// ║  1. 提供统一的时间获取入口 [now]，外部不应直接使用              ║
/// ║     DateTime.now()，而应全部通过本服务获取"正确"的时间。        ║
/// ║  2. NTP 时间同步——防止玩家通过修改设备本地时间来作弊           ║
/// ║    （典型场景：体力恢复倒计时、每日签到刷新、限时活动）。        ║
/// ║  3. 格式转换 & 计时器 & 日期比较（预留扩展）。                  ║
/// ║                                                              ║
/// ║  设计要点：                                                    ║
/// ║  - 静态类：无需实例化，全局一个偏移量即可覆盖所有调用者。        ║
/// ║  - 偏移量缓存：服务端时间与本地时间的差值仅计算一次，             ║
/// ║    后续所有 [now] 调用直接复用该差值，不用每次请求 NTP。          ║
/// ║  - 优雅降级：NTP 同步失败时不抛异常，沿用上次缓存的偏移量;       ║
/// ║    首次同步失败则回退到本地时间，保证 App 不因网络问题崩溃。     ║
/// ║                                                              ║
/// ║  设计文档：lib/core/utils/time_service.dart                    ║
/// ╚══════════════════════════════════════════════════════════════╝

/// NTP 时间同步服务。
///
/// 提供统一的时间获取入口 [now]，该 getter 返回经过 NTP 偏移校正后的时间。
/// 调用者应通过 [now] 获取当前时间，而不是直接使用 [DateTime.now]，
/// 以确保游戏内所有时间判断均基于服务器时间，杜绝客户端时间作弊。
///
/// 使用方式：
/// ```dart
/// // App 启动时执行一次同步
/// await TimeService.sync();
///
/// // 后续所有需要当前时间的场景统一使用
/// final currentTime = TimeService.now();
/// ```
///
/// 注意：本类是纯静态工具类，无需也**不应该**创建实例。
class TimeService {
  // NTP 服务器时间与本地时间之间的差值。
  // - 正数：服务器时间比本地时间快（本地时钟偏慢）。
  // - 负数：服务器时间比本地时间慢（本地时钟偏快）。
  // - null：尚未调用 [sync] 或同步失败，此时 [now] 退回本地时间。
  //
  // 使用 [Duration] 类型而非直接存服务器时间戳，是为了避免长时间
  // 运行后本地时钟漂移累积误差——每次调用 [now] 时重新读取本地时钟
  // 并叠加偏移量，误差仅来自两次 NTP 同步之间本地时钟的漂移量。
  static Duration? _ntpOffset;

  /// 获取当前经过 NTP 偏移校正后的时间。
  ///
  /// 如果尚未调用 [sync] 或同步失败，则退回使用本地时间
  /// （即偏移量为 [Duration.zero]），确保 App 在任何情况下都能正常运行。
  ///
  /// 返回：校正后的 [DateTime]，用于游戏内所有时间相关的判断。
  static DateTime now() {
    // _ntpOffset 为 null 时走 Duration.zero 分支，等价于 DateTime.now()
    return DateTime.now().add(_ntpOffset ?? Duration.zero);
  }

  /// 同步内部时钟偏移量：向 NTP 服务器请求当前时间，计算并缓存偏移量。
  ///
  /// 应在 App 初始化阶段（如 main.dart 的 setup 流程中）调用一次。
  /// 同步成功后，后续所有 [now] 调用将自动应用该偏移量。
  ///
  /// 容错策略：
  /// - 网络正常：用服务器时间减去本地时间，更新 [_ntpOffset]。
  /// - 网络异常：静默捕获异常，保留上一次成功同步的偏移量（若有）;
  ///   首次启动且无缓存时，[_ntpOffset] 保持 null，[now] 退回本地时间。
  static Future<void> sync() async {
    try {
      // 从 NTP 服务器获取当前标准时间
      final ntpNow = await _fetchNtpTime();
      // 计算偏移量：服务器时间 - 本地时间
      _ntpOffset = ntpNow.difference(DateTime.now());
    } catch (_) {
      // NTP 同步失败——
      // 不抛异常，不更新 _ntpOffset（保留上一次有效值或保持 null），
      // 让 now() 的退路逻辑（Duration.zero）兜底。
    }
  }

  // 向 NTP 服务器请求当前标准时间。
  //
  // 当前为占位实现——直接返回本地 UTC 时间。
  // 正式上线前需替换为真实的 NTP 请求逻辑：
  //   1. 使用 ntp 包：NTP.getNtpOffset(lookUpAddress: 'time.google.com')
  //   2. 或使用 NTP 协议库：dart:io RawDatagramSocket 自行发送 NTP 请求
  //   3. 建议增加超时限制（如 3 秒），防止网络不佳时长时间阻塞启动流程
  //
  // 返回：从 NTP 服务器获取的标准 UTC 时间。
  static Future<DateTime> _fetchNtpTime() async {
    // TODO: 生产环境替换为真实 NTP 请求 ——
    // 引入 ntp 包后，使用以下代码替换当前实现：
    // ```
    // final offset = await NTP.getNtpOffset(
    //   lookUpAddress: 'time.google.com',
    //   timeout: const Duration(seconds: 3),
    // );
    // return DateTime.now().add(offset);
    // ```
    //
    // 当前占位实现在开发和测试阶段不影响功能，但无法提供反作弊保护。
    return DateTime.now().toUtc();
  }
}
