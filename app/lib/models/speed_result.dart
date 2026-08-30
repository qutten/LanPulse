import 'dart:convert';

import 'speed_sample.dart';

/// 一次完整测速的结果（含曲线采样点），同时作为历史记录的一行
class SpeedResult {
  const SpeedResult({
    this.id = 0,
    required this.timeMs,
    required this.serverName,
    required this.serverIp,
    required this.serverPort,
    required this.durationSec,
    required this.concurrency,
    required this.testUpload,
    required this.testPing,
    required this.downloadMbps,
    required this.uploadMbps,
    this.pingMin,
    this.pingAvg,
    this.pingMax,
    this.jitterMs,
    this.lossPct,
    this.downloadSamples = const [],
    this.uploadSamples = const [],
  });

  /// 数据库主键（0 表示尚未保存）
  final int id;

  /// 测速完成时间（毫秒时间戳）
  final int timeMs;

  final String serverName;
  final String serverIp;
  final int serverPort;
  final int durationSec;
  final int concurrency;
  final bool testUpload;
  final bool testPing;

  /// 下载/上传速率（Mbps）
  final double downloadMbps;
  final double uploadMbps;

  /// 延迟（ms），未测 Ping 或全部丢包时为 null
  final double? pingMin;
  final double? pingAvg;
  final double? pingMax;

  /// 抖动（ms）
  final double? jitterMs;

  /// 丢包率（%）
  final double? lossPct;

  /// 曲线采样点
  final List<SpeedSample> downloadSamples;
  final List<SpeedSample> uploadSamples;

  /// 转数据库行
  Map<String, Object?> toMap() => {
        if (id > 0) 'id': id,
        'time': timeMs,
        'serverName': serverName,
        'serverIp': serverIp,
        'serverPort': serverPort,
        'durationSec': durationSec,
        'concurrency': concurrency,
        'testUpload': testUpload ? 1 : 0,
        'testPing': testPing ? 1 : 0,
        'downloadMbps': downloadMbps,
        'uploadMbps': uploadMbps,
        'pingMin': pingMin,
        'pingAvg': pingAvg,
        'pingMax': pingMax,
        'jitterMs': jitterMs,
        'lossPct': lossPct,
        'samplesJson': jsonEncode({
          'download': downloadSamples.map((s) => s.toJson()).toList(),
          'upload': uploadSamples.map((s) => s.toJson()).toList(),
        }),
      };

  /// 从数据库行解析
  factory SpeedResult.fromMap(Map<String, Object?> map) {
    Map<String, dynamic> samples = const {};
    try {
      final raw = map['samplesJson'] as String?;
      if (raw != null && raw.isNotEmpty) {
        samples = jsonDecode(raw) as Map<String, dynamic>;
      }
    } catch (_) {
      samples = const {};
    }
    List<SpeedSample> parseList(String key) {
      final rawList = samples[key];
      if (rawList is List) {
        return rawList
            .whereType<Map>()
            .map((e) => SpeedSample.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
      return const [];
    }

    return SpeedResult(
      id: (map['id'] as num?)?.toInt() ?? 0,
      timeMs: (map['time'] as num?)?.toInt() ?? 0,
      serverName: (map['serverName'] as String?) ?? '',
      serverIp: (map['serverIp'] as String?) ?? '',
      serverPort: (map['serverPort'] as num?)?.toInt() ?? 0,
      durationSec: (map['durationSec'] as num?)?.toInt() ?? 0,
      concurrency: (map['concurrency'] as num?)?.toInt() ?? 0,
      testUpload: (map['testUpload'] as num?)?.toInt() == 1,
      testPing: (map['testPing'] as num?)?.toInt() == 1,
      downloadMbps: (map['downloadMbps'] as num?)?.toDouble() ?? 0,
      uploadMbps: (map['uploadMbps'] as num?)?.toDouble() ?? 0,
      pingMin: (map['pingMin'] as num?)?.toDouble(),
      pingAvg: (map['pingAvg'] as num?)?.toDouble(),
      pingMax: (map['pingMax'] as num?)?.toDouble(),
      jitterMs: (map['jitterMs'] as num?)?.toDouble(),
      lossPct: (map['lossPct'] as num?)?.toDouble(),
      downloadSamples: parseList('download'),
      uploadSamples: parseList('upload'),
    );
  }
}
