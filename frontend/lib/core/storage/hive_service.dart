/// HiveService — 基于 [Hive](https://docs.hivedb.dev/) 的 NoSQL 本地持久化服务。
///
/// ## 职责
/// - 统一管理 Hive Box 的生命周期（初始化 / 开关）。
/// - 提供两个语义独立的 Box，隔离"可丢弃缓存"与"持久化配置"：
///   - `cache`：题库缓存、临时计算结果、网络响应缓存等，可随时整箱清空。
///   - `settings`：用户偏好、应用配置、登录态等，需要长期保留的键值对。
/// - 暴露简洁的类型安全读写 API，隐藏底层 Hive 调用细节。
///
/// ## 架构约束
/// - **单例模式**：全应用仅允许一个 [HiveService] 实例，通过 [HiveService.instance] 访问。
/// - **初始化顺序**：必须在 `WidgetsFlutterBinding.ensureInitialized()` 之后、`runApp()` 之前调用
///   [HiveService.init]；未初始化即访问 [instance] 会抛出 [StateError]。
/// - **线程模型**：Hive 的读写操作本身是同步的（内存映射），但 `put` / `clear` 等写入会
///   异步刷盘，因此写方法返回 [Future]。
///
/// ## 使用示例
/// ```dart
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   await HiveService.init();
///   runApp(MyApp());
/// }
///
/// // 任意位置读写
/// final hive = HiveService.instance;
/// hive.set('theme', 'dark');
/// hive.cache('questions_v1', questionList);
/// final theme = hive.get<String>('theme');
/// ```
import 'package:hive_flutter/hive_flutter.dart';

/// 基于 Hive 的本地持久化服务，管理 `cache` 与 `settings` 两个 Box。
///
/// ## 设计意图
/// 将应用数据分为两类存储桶，避免缓存污染配置、也避免清缓存时误删用户设置。
/// 为什么不直接用 SharedPreferences？
/// - Hive 支持复杂对象（无需 JSON 序列化往返），适合缓存结构化题库数据。
/// - Hive 的 Box 概念天然支持分桶隔离，比 SharedPreferences 的扁平 key-space 更清晰。
/// - Hive 读写性能优于 SharedPreferences（内存映射 + 懒加载）。
///
/// ## 生命周期
/// 1. 应用启动 → [HiveService.init] 初始化引擎并打开两个 Box。
/// 2. 运行期间 → 通过 [get]/[set] 读写 settings，通过 [getCached]/[cache] 读写 cache。
/// 3. 用户登出 / 清缓存 → [clearCache] 一键清空 cacheBox，settingsBox 不受影响。
/// 4. 应用退出 → Flutter 引擎销毁时 Hive 自动关闭 Box。
///
/// ## 注意事项
/// - Box 名称 `'cache'` 和 `'settings'` 是硬编码常量，如需更名请全局搜索替换。
/// - Hive 数据文件默认存储在应用文档目录，不要在外部手动删除。
class HiveService {
  // 单例持有者 — 在 [HiveService.init] 完成前为 null。
  // 使用 `static HiveService?` 而非 late 是为了能在 [instance] getter 中
  // 给出明确的错误信息，而非隐式的 LateInitializationError。
  static HiveService? _instance;

  /// 全局单例访问器。
  ///
  /// 首次访问前必须调用 [HiveService.init] 完成初始化，否则抛出 [StateError]。
  /// 设计为 getter 而非普通方法，让调用侧保持简洁：`HiveService.instance.xxx()`。
  ///
  /// 抛出:
  /// - [StateError] 当 [HiveService.init] 尚未调用或初始化失败时。
  static HiveService get instance =>
      _instance ?? (throw StateError('HiveService not initialized'));

  /// 初始化 Hive 引擎并打开 `cache` 与 `settings` 两个 Box。
  ///
  /// 应在 `main()` 函数中、`WidgetsFlutterBinding.ensureInitialized()` 之后调用。
  /// 此方法为异步操作，需 `await` 以确保 Box 就绪后再启动 UI。
  ///
  /// ## 初始化步骤
  /// 1. [Hive.initFlutter] — 初始化 Hive 的 Flutter 绑定，注册 TypeAdapter 等。
  /// 2. [Hive.openBox] — 打开指定名称的 Box，若文件不存在则自动创建。
  /// 3. 将自身赋给 [_instance] — 标记服务已就绪，后续 [instance] 访问不再报错。
  ///
  /// ## 调用时机约束
  /// 必须在 `runApp()` 之前完成，因为 UI 可能在 `initState` 中直接读取
  /// settings（如主题偏好），若 Box 未打开会导致运行时异常。
  static Future<void> init() async {
    // 步骤1: 初始化 Hive 的 Flutter 平台适配层。
    // 这一步会设置正确的存储路径（Android/iOS/Web/Desktop 各不相同）。
    await Hive.initFlutter();

    // 步骤2: 打开 cache Box — 用于临时/可丢弃数据。
    // 若磁盘上已有同名 Box 文件则直接加载，否则创建空 Box。
    await Hive.openBox('cache');

    // 步骤3: 打开 settings Box — 用于持久化配置。
    await Hive.openBox('settings');

    // 步骤4: 创建单例实例，标记服务就绪。
    // 放在两个 openBox 完成之后，确保 instance 可用时 Box 已全部打开。
    _instance = HiveService();
  }

  /// 缓存 Box (`cache`)，用于存储题库数据、临时计算结果、网络缓存等可丢弃内容。
  ///
  /// ## 语义约定
  /// - 此 Box 中的所有数据都视为"可丢弃"：用户可以随时通过 [clearCache] 清空，
  ///   UI 代码不应假设此 Box 中的数据永远存在。
  /// - 典型用途：缓存最近一次刷题记录、预加载的关卡数据、图片内存缓存索引等。
  ///
  /// ## 性能特性
  /// - Hive Box 的 `get` 操作是同步 O(1) 的（懒加载 + 内存映射），可放心在
  ///   `build()` 方法中直接调用而无需 FutureBuilder。
  Box get cacheBox => Hive.box('cache');

  /// 设置 Box (`settings`)，用于存储用户偏好、应用配置等需持久化的键值对。
  ///
  /// ## 语义约定
  /// - 此 Box 中的数据视为"持久化"：除非用户主动修改，否则在应用重启、缓存清理
  ///   后依然保留。**不要在 [clearCache] 时误清 settings**。
  /// - 典型存储：主题模式、语言偏好、音量设置、是否首次启动、登录 token 等。
  Box get settingsBox => Hive.box('settings');

  /// 从 [settingsBox] 读取指定 [key] 的值（类型安全）。
  ///
  /// ## 参数
  /// - [key]：存储键名，建议使用有意义的常量而非字符串字面量。
  /// - [defaultValue]：键不存在时的默认返回值，默认为 `null`。
  /// - 类型参数 `T`：期望的返回值类型，Hive 会在读取时自动进行类型适配。
  ///
  /// ## 返回值
  /// 返回 `T?` 类型（可空），调用方应处理 null 场景。
  ///
  /// ## 使用示例
  /// ```dart
  /// final theme = hive.get<String>('theme', defaultValue: 'light');
  /// final volume = hive.get<double>('volume', defaultValue: 0.8);
  /// ```
  T? get<T>(String key, {T? defaultValue}) =>
      settingsBox.get(key, defaultValue: defaultValue);

  /// 向 [settingsBox] 写入键值对（异步持久化）。
  ///
  /// ## 参数
  /// - [key]：存储键名，若已存在则覆盖旧值。
  /// - [value]：任意可持久化的值（基础类型、List、Map 均可，Hive 自动序列化）。
  ///
  /// ## 返回值
  /// 返回 [Future<void>]，在数据刷写到磁盘后完成。大多数场景无需 await，
  /// 因为 Hive 的内存映射保证了后续读取立即可见新值。
  Future<void> set(String key, dynamic value) =>
      settingsBox.put(key, value);

  /// 从 [cacheBox] 读取指定 [key] 的原始缓存数据（无类型约束）。
  ///
  /// ## 与 [get] 的区别
  /// - [getCached] 读取自 cacheBox（可丢弃），[get] 读取自 settingsBox（持久化）。
  /// - [getCached] 返回 `dynamic` 无泛型约束，调用方需自行做类型转换。
  /// - 设计意图：缓存数据格式多变（可能是 Map、List<Map>、原始 JSON），
  ///   不适合用强类型约束；而 settings 的数据类型相对固定，用泛型更安全。
  dynamic getCached(String key) => cacheBox.get(key);

  /// 向 [cacheBox] 写入缓存数据（异步持久化）。
  ///
  /// ## 参数
  /// - [key]：缓存键名。
  /// - [value]：任意可序列化的值。
  ///
  /// ## 注意事项
  /// 缓存数据应视为可丢弃的，不要在此存储任何需要持久化的用户数据。
  /// 应用应定期或在特定时机（如登出）调用 [clearCache] 清理过期缓存。
  Future<void> cache(String key, dynamic value) => cacheBox.put(key, value);

  /// 清空 [cacheBox] 中的所有缓存条目（异步操作）。
  ///
  /// ## 调用时机
  /// - 用户登出时清理会话相关缓存。
  /// - 检测到数据格式版本升级时丢弃旧版缓存。
  /// - 用户手动触发"清理缓存"功能。
  ///
  /// ## 注意事项
  /// - 此方法**仅清空 cacheBox**，settingsBox 不受影响。
  /// - [Box.clear] 会删除底层文件中的所有记录，操作不可逆。
  /// - 对于大量数据（>10000 条），此操作可能耗时数十毫秒，
  ///   建议在后台或过渡动画期间执行。
  Future<void> clearCache() => cacheBox.clear();
}
