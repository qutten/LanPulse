/// Ping 测试统计结果（延迟/抖动/丢包）
class PingResult {
  const PingResult({
    required this.sent,
    required this.received,
    required this.lossPct,
    this.rttMin,
    this.rttAvg,
    this.rttMax,
    this.jitterMs,
  });

  /// 发送条数
  final int sent;

  /// 收到 pong 条数
  final int received;

  /// 丢包率（%）
  final double lossPct;

  /// 最小 RTT（ms）
  final double? rttMin;

  /// 平均 RTT（ms）
  final double? rttAvg;

  /// 最大 RTT（ms）
  final double? rttMax;

  /// 抖动（ms）：相邻 RTT 差的绝对值平均
  final double? jitterMs;

  /// 是否收到过有效 pong
  bool get hasRtt => rttAvg != null;
}
