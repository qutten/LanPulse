import 'package:shared_preferences/shared_preferences.dart';

/// 应用设置（shared_preferences 持久化）
class AppSettings {
  const AppSettings({
    this.defaultDurationSec = 10,
    this.defaultConcurrency = 4,
    this.defaultTestUpload = true,
    this.defaultTestPing = true,
    this.discoveryPort = 8900,
  });

  /// 默认测速时长（秒）
  final int defaultDurationSec;

  /// 默认并发数
  final int defaultConcurrency;

  /// 默认是否测上传
  final bool defaultTestUpload;

  /// 默认是否测 Ping
  final bool defaultTestPing;

  /// UDP 发现端口
  final int discoveryPort;

  AppSettings copyWith({
    int? defaultDurationSec,
    int? defaultConcurrency,
    bool? defaultTestUpload,
    bool? defaultTestPing,
    int? discoveryPort,
  }) =>
      AppSettings(
        defaultDurationSec: defaultDurationSec ?? this.defaultDurationSec,
        defaultConcurrency: defaultConcurrency ?? this.defaultConcurrency,
        defaultTestUpload: defaultTestUpload ?? this.defaultTestUpload,
        defaultTestPing: defaultTestPing ?? this.defaultTestPing,
        discoveryPort: discoveryPort ?? this.discoveryPort,
      );
}

/// 设置读写服务
class SettingsService {
  static const _kDuration = 'default_duration_sec';
  static const _kConcurrency = 'default_concurrency';
  static const _kUpload = 'default_test_upload';
  static const _kPing = 'default_test_ping';
  static const _kDiscoveryPort = 'discovery_port';

  Future<AppSettings> load() async {
    final p = await SharedPreferences.getInstance();
    return AppSettings(
      defaultDurationSec: p.getInt(_kDuration) ?? 10,
      defaultConcurrency: p.getInt(_kConcurrency) ?? 4,
      defaultTestUpload: p.getBool(_kUpload) ?? true,
      defaultTestPing: p.getBool(_kPing) ?? true,
      discoveryPort: p.getInt(_kDiscoveryPort) ?? 8900,
    );
  }

  Future<void> save(AppSettings settings) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kDuration, settings.defaultDurationSec);
    await p.setInt(_kConcurrency, settings.defaultConcurrency);
    await p.setBool(_kUpload, settings.defaultTestUpload);
    await p.setBool(_kPing, settings.defaultTestPing);
    await p.setInt(_kDiscoveryPort, settings.discoveryPort);
  }
}
