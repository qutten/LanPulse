import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../l10n.dart';
import '../models/ping_result.dart';

/// 协议错误（携带面向用户、随系统语言切换的提示）
class ProtocolException implements Exception {
  const ProtocolException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// TCP 控制连接客户端：hello/auth/ping/start/complete/bye
///
/// 协议约定：所有消息为 UTF-8 单行 JSON，以 `\n` 结尾。
/// 内部维护按行缓冲的消息队列，避免读取超时丢失已到达的数据。
class ProtocolClient {
  Socket? _socket;
  final List<int> _buf = [];
  final List<Map<String, dynamic>> _queue = [];
  Completer<void>? _signal;
  bool _closed = false;

  String? _serverName;
  int _serverVersion = 1;
  int _maxConcurrency = 8;

  /// 服务端名称（welcome 返回）
  String get serverName => _serverName ?? '';

  /// 服务端协议版本
  int get serverVersion => _serverVersion;

  /// 服务端允许的最大并发数
  int get maxConcurrency => _maxConcurrency;

  /// 连接并完成握手：hello → (auth-required → auth) → welcome
  Future<void> connect(
    String host,
    int port, {
    String password = '',
    String name = '内网测速',
  }) async {
    try {
      _socket = await Socket.connect(host, port,
          timeout: const Duration(seconds: 10));
    } on SocketException {
      throw ProtocolException(L10n.t.connectFail);
    }
    _socket!.setOption(SocketOption.tcpNoDelay, true);
    _socket!.listen(_onData, onError: (_) {}, onDone: _onClose);
    _closed = false;

    await _send({
      'type': 'hello',
      'app': 'lan-speedtest',
      'version': 1,
      'name': name,
    });
    var msg = await _waitMessage(const Duration(seconds: 10));
    if (msg == null) {
      throw ProtocolException(L10n.t.serverNoResponse);
    }
    if (msg['type'] == 'auth-required') {
      // 服务端要求口令：无论是否为空都要发送 auth
      await _send({'type': 'auth', 'password': password});
      msg = await _waitMessage(const Duration(seconds: 10));
    }
    if (msg == null) {
      throw ProtocolException(L10n.t.serverNoResponse);
    }
    if (msg['type'] == 'auth-failed') {
      throw ProtocolException(L10n.t.wrongPassword);
    }
    if (msg['type'] == 'error') {
      throw ProtocolException(mapErrorCode(msg));
    }
    if (msg['type'] != 'welcome') {
      throw ProtocolException(L10n.t.handshakeFail('${msg['type']}'));
    }
    _serverVersion = (msg['version'] as num?)?.toInt() ?? 1;
    if (_serverVersion != 1) {
      throw ProtocolException(L10n.t.versionIncompatible(_serverVersion));
    }
    _serverName = (msg['name'] as String?) ?? '';
    _maxConcurrency = (msg['maxConcurrency'] as num?)?.toInt() ?? 8;
  }

  /// Ping 测试：逐条发送、等到 pong 再发下一条（参考 test_client.py）
  ///
  /// 默认 20 条、间隔 30ms；单条超时 1 秒计为丢包。
  Future<PingResult> ping({
    int count = 20,
    double intervalMs = 30,
    bool Function()? isCancelled,
  }) async {
    final rtts = <double>[];
    var received = 0;
    final timeoutMs = (intervalMs * 4 + 300).clamp(1000.0, 5000.0);
    final timeout = Duration(milliseconds: timeoutMs.round());
    var sent = 0;

    for (var i = 0; i < count; i++) {
      if (isCancelled?.call() ?? false) break;
      if (_closed) break;
      final ts = DateTime.now().millisecondsSinceEpoch;
      await _send({'type': 'ping', 'seq': i, 'ts': ts});
      sent++;
      final sentAt = DateTime.now();
      final deadline = sentAt.add(timeout);
      while (DateTime.now().isBefore(deadline)) {
        if (_closed) break;
        final msg = await _waitMessage(const Duration(milliseconds: 300));
        if (msg == null) break;
        if (msg['type'] == 'pong' && (msg['ts'] as num?)?.toInt() == ts) {
          final rtt =
              DateTime.now().difference(sentAt).inMicroseconds / 1000.0;
          rtts.add(rtt);
          received++;
          break;
        }
        // 其他消息（如 error）忽略，继续等待本条 pong
      }
      await Future<void>.delayed(Duration(milliseconds: intervalMs.round()));
    }

    final lossPct = sent > 0 ? (sent - received) / sent * 100 : 0.0;
    double? minRtt;
    double? maxRtt;
    double? avgRtt;
    double? jitter;
    if (rtts.isNotEmpty) {
      minRtt = rtts.reduce((a, b) => a < b ? a : b);
      maxRtt = rtts.reduce((a, b) => a > b ? a : b);
      avgRtt = rtts.reduce((a, b) => a + b) / rtts.length;
      if (rtts.length > 1) {
        var sum = 0.0;
        for (var i = 1; i < rtts.length; i++) {
          sum += (rtts[i] - rtts[i - 1]).abs();
        }
        jitter = sum / (rtts.length - 1);
      }
    }
    return PingResult(
      sent: sent,
      received: received,
      lossPct: lossPct,
      rttMin: minRtt,
      rttAvg: avgRtt,
      rttMax: maxRtt,
      jitterMs: jitter,
    );
  }

  /// 发送 start 并等待 started
  Future<void> startTest(
    String test,
    int duration,
    int concurrency,
    int blockSize,
    String token,
  ) async {
    await _send({
      'type': 'start',
      'test': test,
      'duration': duration,
      'concurrency': concurrency,
      'blockSize': blockSize,
      'token': token,
    });
    final msg = await _waitMessage(const Duration(seconds: 10));
    if (msg == null) {
      throw ProtocolException(L10n.t.testStartFail);
    }
    if (msg['type'] == 'error') {
      throw ProtocolException(mapErrorCode(msg));
    }
    if (msg['type'] != 'started') {
      throw ProtocolException(L10n.t.testStartUnknownMsg('${msg['type']}'));
    }
  }

  /// 上报测速结果并等待 complete-ack
  Future<void> complete(
    String test,
    String token,
    int bytes,
    int durationMs,
    double speedMbps,
  ) async {
    await _send({
      'type': 'complete',
      'test': test,
      'token': token,
      'bytes': bytes,
      'durationMs': durationMs,
      'speedMbps': speedMbps,
    });
    final msg = await _waitMessage(const Duration(seconds: 10));
    if (msg == null) {
      throw ProtocolException(L10n.t.reportFail);
    }
    if (msg['type'] == 'error') {
      throw ProtocolException(mapErrorCode(msg));
    }
    if (msg['type'] != 'complete-ack') {
      throw ProtocolException(L10n.t.reportUnknownMsg('${msg['type']}'));
    }
  }

  /// 发送 bye 并关闭连接
  Future<void> close() async {
    if (_closed) return;
    try {
      await _send({'type': 'bye'});
    } catch (_) {
      // 服务端可能已关闭连接，忽略
    }
    try {
      _socket?.destroy();
    } catch (_) {}
    _socket = null;
    _closed = true;
    _signal?.complete();
    _signal = null;
  }

  /// 服务端 error 报文 code → 本地化提示（随系统语言切换）
  static String mapErrorCode(Map<String, dynamic> msg) {
    switch (msg['code']) {
      case 'bad-message':
        return L10n.t.msgBadFormat;
      case 'unknown-type':
        return L10n.t.msgUnknownType;
      case 'bad-test':
        return L10n.t.msgBadTest;
      case 'too-many-clients':
        return L10n.t.msgTooManyClients;
      case 'auth-failed':
        return L10n.t.msgAuthFailed;
      default:
        return L10n.t.msgUnknownError;
    }
  }

  void _onData(Uint8List chunk) {
    _buf.addAll(chunk);
    while (true) {
      final idx = _buf.indexOf(0x0a);
      if (idx < 0) break;
      final lineBytes = _buf.sublist(0, idx);
      _buf.removeRange(0, idx + 1);
      if (lineBytes.isEmpty ||
          lineBytes.every((b) => b == 0x20 || b == 0x09)) {
        continue;
      }
      try {
        final obj = jsonDecode(utf8.decode(lineBytes, allowMalformed: true));
        if (obj is Map<String, dynamic>) {
          _queue.add(obj);
          _signal?.complete();
          _signal = null;
        }
      } catch (_) {
        // 忽略无法解析的行
      }
    }
  }

  void _onClose() {
    _closed = true;
    _signal?.complete();
    _signal = null;
  }

  /// 从队列取一条消息；超时或连接关闭时返回 null
  Future<Map<String, dynamic>?> _waitMessage(Duration timeout) async {
    while (_queue.isEmpty) {
      if (_closed) return null;
      final completer = Completer<void>();
      _signal = completer;
      try {
        await completer.future.timeout(timeout);
      } on TimeoutException {
        _signal = null;
        return null;
      }
    }
    return _queue.removeAt(0);
  }

  Future<void> _send(Map<String, dynamic> obj) async {
    final socket = _socket;
    if (socket == null || _closed) {
      throw ProtocolException(L10n.t.connClosed);
    }
    try {
      socket.add(utf8.encode('${jsonEncode(obj)}\n'));
      await socket.flush();
    } on SocketException {
      throw ProtocolException(L10n.t.connClosed);
    } on StateError {
      throw ProtocolException(L10n.t.connClosed);
    }
  }
}
