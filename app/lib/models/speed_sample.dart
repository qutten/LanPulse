/// 实时曲线采样点：时刻（秒）+ 瞬时速率（Mbps）
class SpeedSample {
  const SpeedSample(this.t, this.mbps);

  /// 距测速开始的秒数
  final double t;

  /// 瞬时速率（Mbps）
  final double mbps;

  Map<String, dynamic> toJson() => {'t': t, 'mbps': mbps};

  factory SpeedSample.fromJson(Map<String, dynamic> json) => SpeedSample(
        (json['t'] as num?)?.toDouble() ?? 0,
        (json['mbps'] as num?)?.toDouble() ?? 0,
      );
}
