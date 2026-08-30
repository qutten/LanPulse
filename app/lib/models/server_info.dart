/// 服务端信息：自动发现（UDP announce）或手动输入获得
class ServerInfo {
  const ServerInfo({
    required this.name,
    required this.ip,
    required this.port,
    required this.version,
    required this.discoveryTime,
  });

  /// 服务端名称（电脑名）
  final String name;

  /// 服务端 IP
  final String ip;

  /// 服务端 TCP 端口
  final int port;

  /// 协议版本
  final int version;

  /// 发现/刷新时间（列表展示与过期清理用）
  final DateTime discoveryTime;

  /// 解析 UDP announce 报文
  factory ServerInfo.fromAnnounce(Map<String, dynamic> json) => ServerInfo(
        name: (json['name'] as String?) ?? '未知服务端',
        ip: (json['ip'] as String?) ?? '',
        port: (json['port'] as num?)?.toInt() ?? 8899,
        version: (json['version'] as num?)?.toInt() ?? 1,
        discoveryTime: DateTime.now(),
      );

  /// 手动连接（自动发现失败时的兜底方案）
  factory ServerInfo.manual(String ip, int port) => ServerInfo(
        name: '手动连接',
        ip: ip,
        port: port,
        version: 1,
        discoveryTime: DateTime.now(),
      );

  /// 去重键：IP + 端口
  String get key => '$ip:$port';
}
