import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import '../db/history_dao.dart';
import '../l10n.dart';
import '../models/ping_result.dart';
import '../models/server_info.dart';
import '../models/speed_sample.dart';
import '../models/speed_result.dart';
import '../models/test_params.dart';
import 'protocol_client.dart';

/// 测速阶段状态
enum TestPhase { idle, connecting, ping, download, upload, done, error }

/// 引擎状态快照（通过 Stream 推送给 UI）
class EngineState {
  const EngineState({
    this.phase = TestPhase.idle,
    this.downloadSamples = const [],
    this.uploadSamples = const [],
    this.currentSpeedMbps = 0,
    this.pingResult,
    this.result,
    this.errorMessage,
    this.statusText = '',
  });

  final TestPhase phase;

  /// 下载/上传曲线采样点（实时追加）
  final List<SpeedSample> downloadSamples;
  final List<SpeedSample> uploadSamples;

  /// 当前实时速率（Mbps）
  final double currentSpeedMbps;

  final PingResult? pingResult;
  final SpeedResult? result;
  final String? errorMessage;
  final String statusText;

  bool get isRunning =>
      phase == TestPhase.connecting ||
      phase == TestPhase.ping ||
      phase == TestPhase.download ||
      phase == TestPhase.upload;

  EngineState copyWith({
    TestPhase? phase,
    List<SpeedSample>? downloadSamples,
    List<SpeedSample>? uploadSamples,
    double? currentSpeedMbps,
    PingResult? pingResult,
    SpeedResult? result,
    String? errorMessage,
    String? statusText,
  }) =>
      EngineState(
        phase: phase ?? this.phase,
        downloadSamples: downloadSamples ?? this.downloadSamples,
        uploadSamples: uploadSamples ?? this.uploadSamples,
        currentSpeedMbps: currentSpeedMbps ?? this.currentSpeedMbps,
        pingResult: pingResult ?? this.pingResult,
        result: result ?? this.result,
        errorMessage: errorMessage ?? this.errorMessage,
        statusText: statusText ?? this.statusText,
      );
}

/// 单次数据测速（下载/上传）的统计结果（引擎内部使用）
class DataTestResult {
  const DataTestResult({
    required this.test,
    required this.totalBytes,
    required this.durationMs,
    required this.speedMbps,
    required this.samples,
    required this.errorConnections,
  });

  final String test;
  final int totalBytes;
  final int durationMs;
  final double speedMbps;
  final List<SpeedSample> samples;
  final int errorConnections;
}

/// 并发测速核心引擎
///
/// 流程：Ping（可选）→ 下载（必测）→ 上传（可选）→ 计算全部指标 →
/// 自动保存历史（sqflite）→ 更新 UI。
/// 每条数据连接一个 async 任务（Socket.connect），共享字节计数；
/// 采样用 Timer.periodic 每秒读取一次，推送实时曲线。
class SpeedTestEngine {
  SpeedTestEngine({required HistoryDao historyDao}) : _historyDao = historyDao;

  final HistoryDao _historyDao;
  final _controller = StreamController<EngineState>.broadcast();
  final _sockets = <Socket>[];
  final _random = Random();
  EngineState _state = const EngineState();
  bool _running = false;
  bool _stopRequested = false;
  Timer? _sampleTimer;

  /// 状态流
  Stream<EngineState> get states => _controller.stream;

  /// 当前状态
  EngineState get state => _state;

  bool get isRunning => _running;

  /// 开始一次完整测速（失败/停止均通过状态流通知 UI）
  Future<void> start(
    TestParams params,
    ServerInfo server, {
    String password = '',
  }) async {
    if (_running) return;
    _running = true;
    _stopRequested = false;
    _state = EngineState(
      phase: TestPhase.connecting,
      statusText: L10n.t.connecting,
    );
    _emit();

    final ctrl = ProtocolClient();
    try {
      await ctrl.connect(server.ip, server.port, password: password);
      if (params.concurrency > ctrl.maxConcurrency) {
        throw ProtocolException(
            L10n.t.concurrencyExceed(params.concurrency, ctrl.maxConcurrency));
      }

      // Ping（可选）
      PingResult? pingResult;
      if (params.testPing) {
        _setPhase(TestPhase.ping, L10n.t.testingPing);
        pingResult = await ctrl.ping(isCancelled: () => _stopRequested);
        _state = _state.copyWith(pingResult: pingResult);
        _emit();
        if (_stopRequested) return _finishAborted();
      }

      // 下载（必测）
      _setPhase(TestPhase.download, L10n.t.testingDownload);
      final download = await _runDataTest(ctrl, 'download', params, server);
      if (_stopRequested) return _finishAborted();
      _state = _state.copyWith(downloadSamples: download.samples);
      _emit();

      // 上传（可选，默认开）
      DataTestResult? upload;
      if (params.testUpload) {
        _setPhase(TestPhase.upload, L10n.t.testingUpload);
        upload = await _runDataTest(ctrl, 'upload', params, server);
        if (_stopRequested) return _finishAborted();
        _state = _state.copyWith(uploadSamples: upload.samples);
        _emit();
      }

      final result = SpeedResult(
        timeMs: DateTime.now().millisecondsSinceEpoch,
        serverName: ctrl.serverName.isEmpty ? server.name : ctrl.serverName,
        serverIp: server.ip,
        serverPort: server.port,
        durationSec: params.durationSec,
        concurrency: params.concurrency,
        testUpload: params.testUpload,
        testPing: params.testPing,
        downloadMbps: download.speedMbps,
        uploadMbps: upload?.speedMbps ?? 0,
        pingMin: pingResult?.rttMin,
        pingAvg: pingResult?.rttAvg,
        pingMax: pingResult?.rttMax,
        jitterMs: pingResult?.jitterMs,
        lossPct: pingResult?.lossPct,
        downloadSamples: download.samples,
        uploadSamples: upload?.samples ?? const [],
      );

      await _historyDao.insert(result);
      _setPhase(TestPhase.done, L10n.t.completed, result: result);
    } on ProtocolException catch (e) {
      _setPhase(TestPhase.error, '', errorMessage: e.message);
    } catch (e) {
      _setPhase(TestPhase.error, '', errorMessage: L10n.t.unknownError('$e'));
    } finally {
      _sampleTimer?.cancel();
      _sampleTimer = null;
      for (final s in _sockets) {
        try {
          s.destroy();
        } catch (_) {}
      }
      _sockets.clear();
      await ctrl.close();
      _running = false;
    }
  }

  /// 用户手动停止：取消所有 socket 与定时器
  void stop() {
    if (!_running) return;
    _stopRequested = true;
    _sampleTimer?.cancel();
    _sampleTimer = null;
    for (final s in _sockets) {
      try {
        s.destroy();
      } catch (_) {}
    }
    _sockets.clear();
    _state = _state.copyWith(statusText: L10n.t.stopping);
    _emit();
  }

  /// 释放资源（页面销毁时调用）
  void dispose() {
    stop();
    _controller.close();
  }

  void _finishAborted() {
    _setPhase(TestPhase.error, '', errorMessage: L10n.t.manuallyStopped);
  }

  void _setPhase(TestPhase phase, String statusText,
      {String? errorMessage, SpeedResult? result}) {
    _state = EngineState(
      phase: phase,
      downloadSamples: _state.downloadSamples,
      uploadSamples: _state.uploadSamples,
      currentSpeedMbps: 0,
      pingResult: _state.pingResult,
      result: result,
      errorMessage: errorMessage,
      statusText: statusText,
    );
    _emit();
  }

  /// 一次下载/上传数据测速
  Future<DataTestResult> _runDataTest(
    ProtocolClient ctrl,
    String test,
    TestParams params,
    ServerInfo server,
  ) async {
    final token = _randomToken();
    // 收到 started 后再建立 K 条数据连接
    await ctrl.startTest(
        test, params.durationSec, params.concurrency, params.blockSize, token);

    _sockets.clear();
    final stopwatch = Stopwatch()..start();
    var totalBytes = 0;
    DateTime? firstTime;
    var errorConnections = 0;
    var workerStop = false;
    final samples = <SpeedSample>[];

    Future<void> worker() async {
      Socket? s;
      try {
        s = await Socket.connect(server.ip, server.port,
            timeout: const Duration(seconds: 10));
        s.setOption(SocketOption.tcpNoDelay, true);
        _sockets.add(s);
        // 数据连接头部
        s.add(utf8.encode('{"type":"data","test":"$test","token":"$token"}\n'));
        await s.flush();
        if (test == 'download') {
          // 下载：持续接收原始字节并计数
          await for (final chunk in s) {
            if (workerStop) break;
            firstTime ??= DateTime.now(); // 从首字节到达计时
            totalBytes += chunk.length;
          }
        } else {
          // 上传：持续发送原始字节（零块）并计数
          final block = List<int>.filled(params.blockSize, 0);
          while (!workerStop) {
            s.add(block);
            await s.flush();
            firstTime ??= DateTime.now(); // 从首字节发送计时
            totalBytes += params.blockSize;
          }
        }
      } catch (_) {
        if (!workerStop) errorConnections += 1;
      } finally {
        _sockets.remove(s);
        try {
          s?.close();
        } catch (_) {}
      }
    }

    final workers = <Future<void>>[];
    for (var i = 0; i < params.concurrency; i++) {
      workers.add(worker());
    }

    // 每秒 1 个采样点（该秒内各连接字节增量 × 8 / 1e6 → Mbps）
    var prevBytes = 0;
    _sampleTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final elapsedSec = stopwatch.elapsedMilliseconds / 1000.0;
      final deltaBytes = totalBytes - prevBytes;
      prevBytes = totalBytes;
      final mbps = deltaBytes * 8 / 1e6;
      samples.add(SpeedSample(elapsedSec, mbps));
      _state = _state.copyWith(
        currentSpeedMbps: mbps,
        downloadSamples: test == 'download' ? List.of(samples) : null,
        uploadSamples: test == 'upload' ? List.of(samples) : null,
      );
      _emit();
    });

    // 持续 duration 秒后关闭全部数据连接
    while (!_stopRequested &&
        stopwatch.elapsedMilliseconds < params.durationSec * 1000) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    workerStop = true;
    _sampleTimer?.cancel();
    _sampleTimer = null;

    final sockets = List<Socket>.of(_sockets);
    for (final s in sockets) {
      try {
        s.destroy();
      } catch (_) {}
    }
    // 等待所有 worker 结束（最多再等 3 秒，避免个别连接卡死）
    await Future.wait(workers).timeout(
      const Duration(seconds: 3),
      onTimeout: () => <void>[],
    );

    // 速率 = 总字节 × 8 / 实际耗时 / 1e6（Mbps）
    final elapsedMs = firstTime == null
        ? stopwatch.elapsedMilliseconds.toDouble()
        : DateTime.now().difference(firstTime!).inMicroseconds / 1000.0;
    final elapsedSec = elapsedMs / 1000.0;
    final speed = elapsedSec > 0 ? totalBytes * 8 / elapsedSec / 1e6 : 0.0;
    final dataResult = DataTestResult(
      test: test,
      totalBytes: totalBytes,
      durationMs: elapsedMs.round(),
      speedMbps: speed,
      samples: samples,
      errorConnections: errorConnections,
    );

    if (!_stopRequested) {
      if (errorConnections == params.concurrency && totalBytes == 0) {
        throw ProtocolException(L10n.t.dataConnFailed);
      }
      await ctrl.complete(
          test, token, totalBytes, elapsedMs.round(), speed);
    }
    return dataResult;
  }

  String _randomToken() {
    const chars = '0123456789abcdef';
    return List.generate(12, (_) => chars[_random.nextInt(chars.length)]).join();
  }

  void _emit() {
    if (!_controller.isClosed) _controller.add(_state);
  }
}
