/// DioClient HTTP 客户端。
///
/// 封装 [Dio] 实例，统一管理：
/// - 请求/响应拦截器（认证 token 注入、统一错误处理）
/// - 连接超时、接收超时、发送超时配置
/// - 自动重试策略（指数退避）
/// - 请求/响应日志记录
///
/// 典型用法：
/// ```dart
/// final client = DioClient(baseUrl: 'https://api.example.com');
/// final response = await client.get('/users');
/// ```
///
/// 当前状态：API 尚未部署，此文件为占位桩代码。
// Todo: implement DioClient class with interceptors, timeout, retry, and logging
// Dio client stub — API not deployed yet

import 'package:dio/dio.dart';

/// HTTP 网络请求客户端，基于 [Dio] 封装的单例式网络层。
///
/// 职责：
/// 1. 管理全局 [Dio] 实例及其配置（baseUrl、超时、拦截器等）。
/// 2. 在所有请求的 header 中自动注入 Bearer token（来自认证模块）。
/// 3. 拦截响应，统一处理业务级错误码与 HTTP 状态码。
/// 4. 对符合条件的失败请求执行自动重试（指数退避 + 抖动）。
/// 5. 输出结构化请求/响应日志，便于调试与线上排障。
///
/// 本类不作为单例使用 —— 调用方应通过依赖注入获取同一个实例。
class DioClient {
  // ---------------------------------------------------------------------------
  // 私有字段
  // ---------------------------------------------------------------------------

  /// 内部持有的 [Dio] 实例，所有 HTTP 请求均通过此实例发出。
  final Dio _dio;

  /// API 基础地址，例如 `https://api.tilezhan.com`。
  /// 所有相对路径的请求都会拼接此 baseUrl。
  final String _baseUrl;

  /// 默认连接超时时间（毫秒），用于建立 TCP 连接阶段。
  static const int _defaultConnectTimeoutMs = 10000;

  /// 默认接收超时时间（毫秒），用于等待响应体传输完成。
  static const int _defaultReceiveTimeoutMs = 15000;

  /// 默认发送超时时间（毫秒），用于发送请求体数据。
  static const int _defaultSendTimeoutMs = 10000;

  /// 最大自动重试次数，超过此次数后直接抛出异常。
  static const int _maxRetries = 3;

  /// 重试的基础间隔（毫秒），实际延迟 = base * 2^attempt + 随机抖动。
  static const int _retryBaseDelayMs = 500;

  // ---------------------------------------------------------------------------
  // 构造函数
  // ---------------------------------------------------------------------------

  /// 创建 [DioClient] 实例并初始化内部 [Dio] 对象。
  ///
  /// [baseUrl] 必传，所有相对路径的请求都会以它为前缀。
  /// [connectTimeout]、[receiveTimeout]、[sendTimeout] 可选，默认分别
  /// 为 10s、15s、10s。
  /// [interceptors] 可选，调用方可在内置拦截器之外追加自定义拦截器。
  /// [authTokenProvider] 可选，返回当前有效的认证 token；传入后会在每个请求
  /// 的 Authorization 头中注入 Bearer token。
  DioClient({
    required String baseUrl,
    int? connectTimeout,
    int? receiveTimeout,
    int? sendTimeout,
    List<Interceptor>? interceptors,
    Future<String> Function()? authTokenProvider,
  }) : _baseUrl = baseUrl,
       _dio = Dio(BaseOptions(
         baseUrl: baseUrl,
         connectTimeout: Duration(
           milliseconds: connectTimeout ?? _defaultConnectTimeoutMs,
         ),
         receiveTimeout: Duration(
           milliseconds: receiveTimeout ?? _defaultReceiveTimeoutMs,
         ),
         sendTimeout: Duration(
           milliseconds: sendTimeout ?? _defaultSendTimeoutMs,
         ),
         // 默认 Content-Type 为 application/json
         contentType: Headers.jsonContentType,
         // 默认响应类型为 JSON
         responseType: ResponseType.json,
       )) {
    // 注册内置拦截器：token 注入 → 日志记录 → 错误处理与重试
    _dio.interceptors.addAll([
      _AuthInterceptor(authTokenProvider),
      _LoggingInterceptor(),
      _RetryInterceptor(maxRetries: _maxRetries, baseDelayMs: _retryBaseDelayMs),
      // 将调用方传入的自定义拦截器追加到最后
      if (interceptors != null) ...interceptors,
    ]);
  }

  // ---------------------------------------------------------------------------
  // 公开 getter
  // ---------------------------------------------------------------------------

  /// 暴露底层 [Dio] 实例，供需要直接使用 Dio 参数（如 [CancelToken]、
  /// [ProgressCallback]）的高级场景使用。
  Dio get dio => _dio;

  /// 返回当前配置的 API 基础地址。
  String get baseUrl => _baseUrl;

  // ---------------------------------------------------------------------------
  // 公开 HTTP 方法
  // ---------------------------------------------------------------------------

  /// 发送 HTTP GET 请求。
  ///
  /// [path] 为相对路径（拼接 baseUrl），[queryParameters] 为 URL 查询参数。
  /// [cancelToken] 可传入以支持请求取消。
  /// 返回一个 [Response]，其 [Response.data] 为已解码的 JSON 体。
  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    Options? options,
  }) {
    return _dio.get(
      path,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
      options: options,
    );
  }

  /// 发送 HTTP POST 请求。
  ///
  /// [data] 为请求体，通常为 [Map] 或 [List]，会被自动序列化为 JSON。
  /// [queryParameters] 为 URL 查询参数。
  Future<Response<dynamic>> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    Options? options,
  }) {
    return _dio.post(
      path,
      data: data,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
      options: options,
    );
  }

  /// 发送 HTTP PUT 请求（完整替换资源）。
  Future<Response<dynamic>> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    Options? options,
  }) {
    return _dio.put(
      path,
      data: data,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
      options: options,
    );
  }

  /// 发送 HTTP PATCH 请求（部分更新资源）。
  Future<Response<dynamic>> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    Options? options,
  }) {
    return _dio.patch(
      path,
      data: data,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
      options: options,
    );
  }

  /// 发送 HTTP DELETE 请求。
  Future<Response<dynamic>> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    Options? options,
  }) {
    return _dio.delete(
      path,
      data: data,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
      options: options,
    );
  }

  /// 发送 HTTP HEAD 请求，仅获取响应头（无响应体）。
  Future<Response<dynamic>> head(
    String path, {
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    Options? options,
  }) {
    return _dio.head(
      path,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
      options: options,
    );
  }

  /// 发送原始 HTTP 请求，适用于需要自定义 method 字符串的场景。
  ///
  /// [method] 为 HTTP 动词字符串（如 `'TRACE'`、`'CONNECT'`）。
  Future<Response<dynamic>> request(
    String path, {
    required String method,
    dynamic data,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    Options? options,
  }) {
    return _dio.request(
      path,
      data: data,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
      options: (options ?? Options()).copyWith(method: method),
    );
  }

  /// 上传文件（multipart/form-data）。
  ///
  /// [filePath] 为本地文件绝对路径，[uploadFieldName] 为后端接收的字段名。
  /// [onSendProgress] 可传入以监听上传进度。
  Future<Response<dynamic>> uploadFile(
    String path, {
    required String filePath,
    String uploadFieldName = 'file',
    Map<String, dynamic>? extraFields,
    ProgressCallback? onSendProgress,
    CancelToken? cancelToken,
  }) async {
    // 构建 multipart 表单数据
    final formData = FormData.fromMap({
      uploadFieldName: await MultipartFile.fromFile(filePath),
      if (extraFields != null) ...extraFields,
    });
    return _dio.post(
      path,
      data: formData,
      onSendProgress: onSendProgress,
      cancelToken: cancelToken,
    );
  }

  /// 下载文件到本地路径。
  ///
  /// [savePath] 为本地保存路径，[onReceiveProgress] 可传入以监听下载进度。
  Future<Response<dynamic>> downloadFile(
    String urlPath, {
    required String savePath,
    Map<String, dynamic>? queryParameters,
    ProgressCallback? onReceiveProgress,
    CancelToken? cancelToken,
  }) {
    return _dio.download(
      urlPath,
      savePath,
      queryParameters: queryParameters,
      onReceiveProgress: onReceiveProgress,
      cancelToken: cancelToken,
    );
  }

  // ---------------------------------------------------------------------------
  // 生命周期
  // ---------------------------------------------------------------------------

  /// 关闭底层 [Dio] 实例，释放持有的连接资源。
  ///
  /// 在应用退出或不再需要此客户端时调用。调用后此实例不应再使用。
  void close() {
    _dio.close();
  }
}

// =============================================================================
// 内置拦截器
// =============================================================================

/// **认证拦截器**：在每个请求的 header 中自动注入 Bearer token。
///
/// 通过 [tokenProvider] 回调从外部获取最新 token，支持 token 动态刷新。
/// 若 [tokenProvider] 为 null 或返回 null，则跳过 token 注入。
class _AuthInterceptor extends Interceptor {
  /// 外部传入的 token 获取回调，每次请求前调用以获取最新 token。
  final Future<String> Function()? _tokenProvider;

  /// 创建认证拦截器。
  ///
  /// [_tokenProvider] 可选；为 null 时本拦截器不执行任何操作。
  _AuthInterceptor(this._tokenProvider);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // 仅在 tokenProvider 存在时才尝试注入 token
    if (_tokenProvider != null) {
      final token = await _tokenProvider!();
      // 注入 Authorization 头：Bearer <token>
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}

/// **日志拦截器**：将每次请求和响应的关键信息输出到控制台。
///
/// 请求阶段记录：method、URL、headers、query 参数、请求体大小。
/// 响应阶段记录：状态码、响应体大小、耗时。
/// 错误阶段记录：异常类型、错误消息、堆栈。
class _LoggingInterceptor extends Interceptor {
  /// 记录请求开始时间戳（毫秒），用于计算请求耗时。
  final Map<String, int> _startTimes = {};

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // 使用 options 的唯一标识作为 key 记录开始时间
    _startTimes[options.hashCode.toString()] = DateTime.now().millisecondsSinceEpoch;

    // 结构化日志：请求信息
    // ignore: avoid_print
    print('[DioClient] --> ${options.method} ${options.baseUrl}${options.path}');
    // ignore: avoid_print
    print('[DioClient]     query: ${options.queryParameters}');
    // ignore: avoid_print
    print('[DioClient]     headers: ${options.headers}');

    handler.next(options);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    // 计算请求耗时
    final startTime = _startTimes.remove(response.requestOptions.hashCode.toString());
    final durationMs = startTime != null
        ? DateTime.now().millisecondsSinceEpoch - startTime
        : -1;

    // 结构化日志：响应信息
    // ignore: avoid_print
    print(
      '[DioClient] <-- ${response.statusCode} '
      '${response.requestOptions.method} '
      '${response.requestOptions.path} '
      '(${durationMs}ms)',
    );

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // 清理已记录的开始时间，防止内存泄漏
    _startTimes.remove(err.requestOptions.hashCode.toString());

    // 结构化日志：错误信息
    // ignore: avoid_print
    print('[DioClient] <-- ERROR ${err.type}: ${err.message}');
    // ignore: avoid_print
    print('[DioClient]     path: ${err.requestOptions.path}');

    handler.next(err);
  }
}

/// **重试拦截器**：对符合条件的网络故障执行自动重试。
///
/// 重试条件：
/// - 仅重试 [DioExceptionType.connectionTimeout] 和
///   [DioExceptionType.receiveTimeout] 类型的错误。
/// - HTTP 5xx 服务端错误（`response.statusCode >= 500`）。
/// - 不重试 [DioExceptionType.cancel]（用户主动取消）。
///
/// 重试策略：指数退避 + 随机抖动，避免惊群效应。
class _RetryInterceptor extends Interceptor {
  /// 最大重试次数。
  final int _maxRetries;

  /// 基础重试延迟（毫秒），实际延迟 = base * 2^attempt + 随机抖动。
  final int _baseDelayMs;

  /// 记录每个请求已重试的次数，key 为请求的唯一标识。
  final Map<String, int> _retryCounts = {};

  _RetryInterceptor({int maxRetries = 3, int baseDelayMs = 500})
      : _maxRetries = maxRetries,
        _baseDelayMs = baseDelayMs;

  /// 判断给定 [DioException] 是否应该触发重试。
  ///
  /// 返回 `true` 的条件：
  /// - 连接超时或接收超时。
  /// - 服务端返回 5xx 状态码。
  bool _shouldRetry(DioException error) {
    // 检查超时类型
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return true;
    }

    // 检查 5xx 服务端错误
    final statusCode = error.response?.statusCode;
    if (statusCode != null && statusCode >= 500) {
      return true;
    }

    return false;
  }

  /// 计算第 [attempt] 次重试的等待延迟（毫秒）。
  ///
  /// 公式：baseDelay * 2^(attempt-1) + random(0, 500)
  /// 随重试次数增加，延迟呈指数增长，同时加入随机抖动。
  int _calculateDelay(int attempt) {
    // 指数退避：基础延迟 * 2^(attempt - 1)
    final exponentialDelay = _baseDelayMs * (1 << (attempt - 1));
    // 随机抖动：0 ~ 500ms，避免多个并发请求同时重试
    final jitter = (DateTime.now().microsecondsSinceEpoch % 500);
    return exponentialDelay + jitter;
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // 获取当前请求的重试计数 key
    final key = err.requestOptions.hashCode.toString();
    final currentRetries = _retryCounts[key] ?? 0;

    // 判断是否应该重试
    if (_shouldRetry(err) && currentRetries < _maxRetries) {
      // 递增重试计数
      _retryCounts[key] = currentRetries + 1;
      final attempt = currentRetries + 1;

      // 计算并等待退避延迟
      final delayMs = _calculateDelay(attempt);
      // ignore: avoid_print
      print(
        '[DioClient] 重试第 $attempt/$_maxRetries 次，'
        '等待 ${delayMs}ms: ${err.requestOptions.path}',
      );
      await Future.delayed(Duration(milliseconds: delayMs));

      // 重新发起请求，传入相同的 cancelToken 以保持取消能力
      try {
        final response = await _dioInstanceForRetry(err);
        _retryCounts.remove(key); // 成功后清理计数
        handler.resolve(response);
      } catch (e) {
        // 重试仍失败，继续传递错误
        handler.next(err);
      }
    } else {
      // 不需要重试或已达最大次数，清理计数后传递错误
      _retryCounts.remove(key);
      handler.next(err);
    }
  }

  /// 使用原始 [DioException] 中的请求配置重新发送请求。
  ///
  /// 注意：此处需要持有外部 [DioClient] 的 [_dio] 引用才能实际重试。
  /// 当前为桩代码，实际实现需要通过构造函数注入 Dio 实例。
  Future<Response<dynamic>> _dioInstanceForRetry(DioException err) async {
    // 桩：需要通过构造函数持有 DioClient._dio 引用来实现
    // 此处仅保留接口占位
    throw UnimplementedError('重试机制待 Dio 实例注入后实现');
  }
}
