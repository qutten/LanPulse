import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../l10n.dart';
import '../models/server_info.dart';

/// UDP 自动发现异常（携带面向用户的中文提示）
class DiscoveryException implements Exception {
  const DiscoveryException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// 服务端自动发现（UDP 广播/监听）
///
/// - 绑定发现端口（REUSEADDR），开启 broadcast
/// - 进入页面时发送 probe 到 255.255.255.255:发现端口
/// - 持续监听 announce（服务端每 3 秒广播一次，并对 probe 单播回复），
///   按 IP+端口 去重刷新列表，通过 Stream 暴露给 UI
class DiscoveryService {
  DiscoveryService({int discoveryPort = 8900})
      : _discoveryPort = discoveryPort;

  final int _discoveryPort;
  RawDatagramSocket? _socket;
  final Map<String, ServerInfo> _servers = {};
  final _controller = StreamController<List<ServerInfo>>.broadcast();
  Timer? _cleanupTimer;
  bool _started = false;

  /// 服务端列表变化流（每次去重/刷新/清理后发出）
  Stream<List<ServerInfo>> get servers => _controller.stream;

  /// 当前服务端列表（按名称排序）
  List<ServerInfo> get currentServers {
    final list = _servers.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  /// 启动发现：绑定 UDP 端口并发送一次 probe
  Future<void> start() async {
    if (_started) return;
    try {
      _socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        _discoveryPort,
        reuseAddress: true,
      );
    } on SocketException {
      throw DiscoveryException(L10n.t.discoveryBindFail(_discoveryPort));
    }
    _socket!.broadcastEnabled = true;
    _socket!.listen(_onEvent, onError: (_) {});
    _cleanupTimer =
        Timer.periodic(const Duration(seconds: 5), (_) => _removeStale());
    _started = true;
    await probe();
  }

  /// 发送一次探测报文（进入页面 / 下拉刷新时调用）
  Future<void> probe() async {
    final sock = _socket;
    if (sock == null) return;
    try {
      final data = utf8.encode(
        jsonEncode({'type': 'lanpulse-probe', 'version': 1}),
      );
      sock.send(data, InternetAddress('255.255.255.255'), _discoveryPort);
    } on SocketException {
      // 广播发送失败（如无网络权限）时静默忽略，等待周期性广播到达
    }
  }

  void _onEvent(RawSocketEvent event) {
    if (event != RawSocketEvent.read) return;
    final Datagram? dg = _socket?.receive();
    if (dg == null) return;
    try {
      final obj = jsonDecode(utf8.decode(dg.data, allowMalformed: true));
      if (obj is Map<String, dynamic> &&
          obj['type'] == 'lanpulse-announce') {
        final info = ServerInfo.fromAnnounce(obj);
        if (info.version != 1) return; // 版本不兼容不收录
        _servers[info.key] = info; // 按 IP+端口 去重刷新
        _controller.add(currentServers);
      }
    } catch (_) {
      // 忽略无法解析的报文
    }
  }

  /// 清理超过 15 秒未再广播的服务端（服务端广播间隔为 3 秒）
  void _removeStale() {
    final now = DateTime.now();
    final before = _servers.length;
    _servers.removeWhere(
        (_, info) => now.difference(info.discoveryTime).inSeconds > 15);
    if (_servers.length != before) {
      _controller.add(currentServers);
    }
  }

  /// 停止发现并释放端口
  void stop() {
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
    _socket?.close();
    _socket = null;
    _started = false;
    _servers.clear();
  }

  /// 释放资源（页面销毁时调用）
  void dispose() {
    stop();
    _controller.close();
  }
}
