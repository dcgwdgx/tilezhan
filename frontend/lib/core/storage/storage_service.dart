import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// StorageService — 基于本地 JSON 文件的 KV 持久化存储服务。
///
/// 纯 Dart 实现，不依赖 SPM / CocoaPods，无原生桥接风险。
/// - 简单值（int / String）统一存储在 `prefs.json` 中。
/// - 复杂 JSON Map 各自存储在独立的 `{key}.json` 文件中。
///
/// 用途：心数、连胜天数、Elo 评分、SRS 条目、应用设置等轻量 KV 数据。
/// 结构化关系数据（如完整的 SRS 进度表）由 [IsarService] 负责。
///
/// 用法：
/// ```dart
/// final storage = await StorageService.init();
/// storage.setInt('hearts', 5);
/// final h = storage.getInt('hearts'); // 5
/// ```
class StorageService {
  /// 应用文档目录的引用，所有 JSON 文件均存储在此目录下。
  /// 在 [init] 完成前不可用。
  late final Directory _dir;

  /// 标记是否已完成初始化。
  /// [init] 调用后将置为 `true`，防止未初始化时的误读写。
  bool _init = false;

  // 私有构造函数，强制通过 [init] 工厂方法获取实例。
  StorageService._();

  /// 异步初始化存储服务，解析并缓存应用文档目录。
  ///
  /// 非 Web 平台通过 path_provider 的 [getApplicationDocumentsDirectory] 获取目录；
  /// Web 平台不设置目录（文件系统不可用）。
  ///
  /// 必须在任何读写操作之前 `await` 此方法。
  ///
  /// 返回已初始化的 [StorageService] 单例。
  static Future<StorageService> init() async {
    final s = StorageService._();
    if (!kIsWeb) {
      // 非 Web 平台：获取持久化文档目录
      s._dir = await getApplicationDocumentsDirectory();
    }
    // 标记初始化完成，后续读写调用方可正常执行
    s._init = true;
    return s;
  }

  /// 根据 [key] 构造对应的 JSON 文件 [File] 对象。
  ///
  /// 文件路径为 `{_dir.path}/{key}.json`。
  File _file(String key) => File('${_dir.path}/$key.json');

  // ── 简单值存取（统一存储在 prefs.json 中）──

  /// 读取存储在 [key] 下的 int 值，不存在时返回 `0`。
  ///
  /// 从 `prefs.json` 中读取，非独立文件。
  int getInt(String key) {
    final all = _readJson('prefs');
    return all[key] as int? ?? 0;
  }

  /// 将 int [value] 持久化到 [key] 下，写入 `prefs.json`。
  ///
  /// 异步写入磁盘，静默忽略 I/O 异常。
  Future<void> setInt(String key, int value) async {
    final all = _readJson('prefs');
    all[key] = value;
    await _writeJson('prefs', all);
  }

  /// 读取存储在 [key] 下的 String 值，不存在时返回 `''`（空字符串）。
  ///
  /// 从 `prefs.json` 中读取，非独立文件。
  String getString(String key) {
    final all = _readJson('prefs');
    return all[key] as String? ?? '';
  }

  /// 将 String [value] 持久化到 [key] 下，写入 `prefs.json`。
  ///
  /// 异步写入磁盘，静默忽略 I/O 异常。
  Future<void> setString(String key, String value) async {
    final all = _readJson('prefs');
    all[key] = value;
    await _writeJson('prefs', all);
  }

  // ── JSON Map 存取（每个 key 对应独立文件 {key}.json）──

  /// 读取存储在 [key] 下的完整 JSON Map，不存在时返回 `{}`（空 Map）。
  ///
  /// 每个 key 对应磁盘上一个独立的 `{key}.json` 文件。
  /// 返回类型为 `Map<String, dynamic>`，支持任意嵌套结构。
  Map<String, dynamic> getJson(String key) {
    return _readJson(key);
  }

  /// 将完整的 JSON Map [value] 写入独立的 `{key}.json` 文件。
  ///
  /// 会完全覆盖该 key 对应的已有文件内容。
  /// 异步写入磁盘，静默忽略 I/O 异常。
  Future<void> setJson(String key, Map<String, dynamic> value) async {
    await _writeJson(key, value);
  }

  // ── 内部方法 ──

  /// 同步读取 `{key}.json` 文件并解析为 [Map]。
  ///
  /// 未初始化、文件不存在或解析失败时均返回 `{}`，保证调用方无需 try/catch。
  /// 使用同步 I/O 是为了简化简单 KV 读取的调用链（无需 await）。
  Map<String, dynamic> _readJson(String key) {
    // 未初始化时直接返回空 Map，防止空指针
    if (!_init) return {};
    try {
      final f = _file(key);
      // 文件不存在时返回空 Map，而非抛异常
      if (!f.existsSync()) return {};
      // 同步读取并解码 JSON
      return jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
    } catch (_) {
      // 解析异常（格式损坏、类型不匹配等）统一静默降级为空 Map
      return {};
    }
  }

  /// 异步将 [value] 编码为 JSON 并写入 `{key}.json` 文件。
  ///
  /// 未初始化时直接返回（不执行任何 I/O）。
  /// 写入失败时静默吞下异常——调用方无需处理 I/O 错误，
  /// 下次读取时会自然退回到默认值。
  Future<void> _writeJson(String key, Map<String, dynamic> value) async {
    // 未初始化时跳过写入，避免空指针
    if (!_init) return;
    try {
      final f = _file(key);
      // 异步写入：将 Map 编码为 JSON 字符串后落盘
      await f.writeAsString(jsonEncode(value));
    } catch (_) {
      // I/O 错误（磁盘满、权限不足等）静默吞下
      // 设计意图：KV 存储不应对调用方暴露 I/O 异常，
      // 失败后下次读取回退到默认值即可
    }
  }

  /// SRS 条目 JSON 存储的 key 常量。
  /// 对应的磁盘文件为 `srs_items.json`。
  static const kSrsItems = 'srs_items';

  /// 心数 / 体力状态 int 存储的 key 常量。
  /// 存储在 `prefs.json` 中的 `hearts` 字段。
  static const kHearts = 'hearts';

  /// 每日连胜计数器的 key 常量。
  /// 存储在 `prefs.json` 中的 `streak` 字段。
  static const kStreak = 'streak';

  /// Elo 评分 int 存储的 key 常量。
  /// 存储在 `prefs.json` 中的 `elo` 字段。
  static const kElo = 'elo';
}
