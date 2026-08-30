/// 默认数据块大小（字节），与协议保持一致
const int kDefaultBlockSize = 65536;

/// 一次测速的完整参数（含服务端地址）
class TestParams {
  const TestParams({
    required this.durationSec,
    required this.concurrency,
    required this.testUpload,
    required this.testPing,
    required this.blockSize,
    required this.host,
    required this.port,
  });

  /// 每项测速时长（秒）
  final int durationSec;

  /// 并发数据连接数
  final int concurrency;

  /// 是否测试上传
  final bool testUpload;

  /// 是否测试 Ping（延迟/抖动/丢包）
  final bool testPing;

  /// 数据块大小（字节）
  final int blockSize;

  /// 服务端地址（IP）
  final String host;

  /// 服务端端口
  final int port;
}
