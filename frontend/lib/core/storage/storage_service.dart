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

  /// Per-key serialization keeps concurrent callers from sharing one staging
  /// file while allowing unrelated JSON keys to continue writing in parallel.
  final Map<String, Future<void>> _writeQueues = {};

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

  File _backupFile(String key) => File('${_dir.path}/$key.json.bak');

  File _temporaryFile(String key) => File('${_dir.path}/$key.json.tmp');

  // ── 简单值存取（统一存储在 prefs.json 中）──

  /// 读取存储在 [key] 下的 int 值，不存在时返回 `0`。
  ///
  /// 从 `prefs.json` 中读取，非独立文件。
  int getInt(String key) {
    final all = _readJson('prefs');
    return all[key] as int? ?? 0;
  }

  /// 读取存储在 [key] 下的 int 值，不存在或类型不匹配时返回 `null`。
  ///
  /// 与 [getInt] 不同，此方法可以区分“尚未保存”和显式保存的 `0`。
  /// 现有调用方继续使用 [getInt] 时，其缺省为 `0` 的语义保持不变。
  int? getIntOrNull(String key) {
    final all = _readJson('prefs');
    final value = all[key];
    return value is int ? value : null;
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
      final target = _file(key);
      final primary = _tryReadJsonFile(
        target,
        key: key,
        role: 'target',
      );
      if (primary != null) return primary;

      // A valid .bak is a previously committed target. A .tmp is only staged
      // data and is deliberately never considered readable/committed.
      final backup = _tryReadJsonFile(
        _backupFile(key),
        key: key,
        role: 'backup',
      );
      if (backup != null) {
        debugPrint('StorageService recovered backup ($key)');
        return backup;
      }
      return {};
    } catch (e) {
      debugPrint('StorageService read error ($key): $e');
      return {};
    }
  }

  /// 异步将 [value] 编码为 JSON 并写入 `{key}.json` 文件。
  ///
  /// 未初始化时直接返回（不执行任何 I/O）。
  /// 写入失败时静默吞下异常——调用方无需处理 I/O 错误，
  /// 下次读取时会自然退回到默认值。
  Future<void> _writeJson(String key, Map<String, dynamic> value) {
    // 未初始化时跳过写入，避免空指针
    if (!_init) return Future<void>.value();

    late final String encoded;
    try {
      // Capture the same call-time snapshot as the old direct write did.
      encoded = jsonEncode(value);
    } catch (e) {
      debugPrint('StorageService write error ($key): $e');
      return Future<void>.value();
    }

    final previous = _writeQueues[key] ?? Future<void>.value();
    late final Future<void> queued;
    queued = previous.then((_) async {
      try {
        await _commitJson(key, encoded);
      } catch (e) {
        // Preserve the existing best-effort public API. Higher-level stores
        // that need a strict contract perform write-after-read verification.
        debugPrint('StorageService write error ($key): $e');
      }
    }).whenComplete(() {
      if (identical(_writeQueues[key], queued)) {
        _writeQueues.remove(key);
      }
    });
    _writeQueues[key] = queued;
    return queued;
  }

  Future<void> _commitJson(String key, String encoded) async {
    final target = _file(key);
    final backup = _backupFile(key);
    final temporary = _temporaryFile(key);

    try {
      // Staging in the same directory keeps the final rename on one volume.
      // flush:true forces bytes through the file-system boundary before the
      // previously committed target is moved aside.
      await temporary.writeAsString(encoded, flush: true);
      if (await temporary.readAsString() != encoded) {
        throw StateError('JSON staging verification failed');
      }

      if (await target.exists()) {
        final current = _tryReadJsonFile(
          target,
          key: key,
          role: 'target',
          reportErrors: false,
        );
        if (current != null) {
          // File.rename replaces an existing file on supported Dart platforms.
          // If the process stops after this step, reads recover from .bak.
          await target.rename(backup.path);
        }
      }

      // A same-directory rename is the commit point. It replaces a corrupt
      // target but never promotes a stale .tmp during reads.
      await temporary.rename(target.path);
    } finally {
      // Normal failures should not leave staged data around. A real process
      // interruption may leave .tmp, which reads intentionally ignore.
      try {
        if (await temporary.exists()) await temporary.delete();
      } catch (_) {
        // Best-effort cleanup; target/backup remain authoritative.
      }
    }
  }

  Map<String, dynamic>? _tryReadJsonFile(
    File file, {
    required String key,
    required String role,
    bool reportErrors = true,
  }) {
    if (!file.existsSync()) return null;
    try {
      final decoded = jsonDecode(file.readAsStringSync());
      if (decoded is! Map) {
        throw const FormatException('Expected a JSON object');
      }
      return Map<String, dynamic>.from(decoded);
    } catch (e) {
      if (reportErrors) {
        debugPrint('StorageService $role read error ($key): $e');
      }
      return null;
    }
  }

  /// SRS 条目 JSON 存储的 key 常量。
  /// 对应的磁盘文件为 `srs_items.json`。
  static const kSrsItems = 'srs_items';

  /// 何切技能熟练度 JSON 存储的 key 常量。
  /// 对应的磁盘文件为 `nanikiru_skill_mastery_v1.json`。
  static const kNanikiruSkillMasteryV1 = 'nanikiru_skill_mastery_v1';

  /// 当日训练计划与连续学习记录的 JSON 存储 key。
  /// 对应的磁盘文件为 `daily_training_plan_v1.json`。
  static const kDailyTrainingPlanV1 = 'daily_training_plan_v1';

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
