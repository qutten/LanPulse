// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '脉冲测速';

  @override
  String get notFoundServer => '未发现服务端，请确认电脑端已运行 run.bat';

  @override
  String get pullToRefresh => '下拉刷新重新探测';

  @override
  String discoveredAt(Object time) {
    return '发现时间 $time';
  }

  @override
  String get manualConnect => '手动连接服务端';

  @override
  String get manualConnectFab => '手动连接';

  @override
  String get serverIp => '服务端 IP';

  @override
  String get serverIpHint => '例如 192.168.1.5';

  @override
  String get serverPort => '服务端端口';

  @override
  String get serverPortHint => '默认 8899';

  @override
  String get passwordOptional => '访问口令（可选）';

  @override
  String get cancel => '取消';

  @override
  String get enterIp => '请输入服务端 IP';

  @override
  String get invalidPort => '端口无效（1-65535）';

  @override
  String get connect => '连接';

  @override
  String get historyTitle => '历史记录';

  @override
  String get settingsTitle => '设置';

  @override
  String get speedTestTitle => '测速';

  @override
  String get testParams => '测速参数';

  @override
  String get durationSec => '测速时长（秒）';

  @override
  String get concurrency => '并发连接数';

  @override
  String get testUpload => '测试上传';

  @override
  String get testUploadHint => '在下载测速后执行上传测速';

  @override
  String get testPing => '测试Ping';

  @override
  String get testPingHint => '测量延迟、抖动与丢包率';

  @override
  String get startTest => '开始测速';

  @override
  String get stop => '停止';

  @override
  String realTimeSpeed(Object speed) {
    return '实时速度：$speed Mbps';
  }

  @override
  String get chartTitle => '实时速度曲线';

  @override
  String get download => '下载';

  @override
  String get upload => '上传';

  @override
  String get collectingData => '正在收集数据…';

  @override
  String get noData => '暂无数据，测速开始后显示实时曲线';

  @override
  String get resultTitle => '测速结果';

  @override
  String get latency => '延迟（最小/平均/最大）';

  @override
  String get latencyDetail => '延迟 最小/平均/最大';

  @override
  String get jitter => '抖动';

  @override
  String get lossRate => '丢包率';

  @override
  String get resultSaved => '结果已保存到历史记录';

  @override
  String get deleteRecord => '删除记录';

  @override
  String deleteConfirm(Object time) {
    return '确定删除 $time 的这条测速记录吗？';
  }

  @override
  String get delete => '删除';

  @override
  String get clearAllTitle => '清空历史记录';

  @override
  String get clearConfirm => '将删除全部测速记录，确定吗？';

  @override
  String get clearAll => '清空';

  @override
  String get emptyHistory => '暂无历史记录';

  @override
  String get detail => '测速详情';

  @override
  String get time => '时间';

  @override
  String get server => '服务端';

  @override
  String get duration => '测速时长';

  @override
  String get yes => '是';

  @override
  String get no => '否';

  @override
  String get downloadSpeed => '下载速度';

  @override
  String get uploadSpeed => '上传速度';

  @override
  String historyItem(Object download, Object upload) {
    return '下载 $download Mbps　上传 $upload Mbps';
  }

  @override
  String serverTitle(Object ip, Object name) {
    return '$name（$ip）';
  }

  @override
  String serverDetail(Object ip, Object name, Object port) {
    return '$name（$ip:$port）';
  }

  @override
  String durationValue(Object sec) {
    return '$sec 秒';
  }

  @override
  String get defaultParams => '默认测速参数';

  @override
  String get defaultDurationSec => '默认测速时长（秒）';

  @override
  String get defaultConcurrency => '默认并发连接数';

  @override
  String get defaultTestUpload => '默认测试上传';

  @override
  String get defaultTestPing => '默认测试Ping';

  @override
  String get discoverySettings => '发现设置';

  @override
  String get discoveryPort => 'UDP 发现端口';

  @override
  String get discoveryPortHint => '自动发现广播/监听端口，默认 8900（TCP 端口 + 1）';

  @override
  String get connectFail => '无法连接服务端，请检查 IP 与端口';

  @override
  String get serverNoResponse => '服务端无响应';

  @override
  String get wrongPassword => '口令错误';

  @override
  String handshakeFail(Object type) {
    return '握手失败：收到未知消息 $type';
  }

  @override
  String versionIncompatible(Object version) {
    return '服务端版本不兼容（服务端版本 $version，客户端需要 1）';
  }

  @override
  String get msgBadFormat => '消息格式错误';

  @override
  String get msgUnknownType => '未知消息类型';

  @override
  String get msgBadTest => '测速类型错误';

  @override
  String get msgTooManyClients => '服务端客户端数量已达上限';

  @override
  String get msgAuthFailed => '口令错误';

  @override
  String get msgUnknownError => '未知错误';

  @override
  String get testStartFail => '测速开始失败：服务端无响应';

  @override
  String testStartUnknownMsg(Object type) {
    return '测速开始失败：收到未知消息 $type';
  }

  @override
  String get reportFail => '上报测速结果失败：服务端无响应';

  @override
  String reportUnknownMsg(Object type) {
    return '上报测速结果失败：收到未知消息 $type';
  }

  @override
  String get connClosed => '连接已断开';

  @override
  String get connecting => '正在连接服务端…';

  @override
  String concurrencyExceed(Object concurrency, Object max) {
    return '并发数 $concurrency 超过服务端上限 $max';
  }

  @override
  String get testingPing => '正在测 Ping…';

  @override
  String get testingDownload => '正在测下载…';

  @override
  String get testingUpload => '正在测上传…';

  @override
  String unknownError(Object error) {
    return '发生未知错误：$error';
  }

  @override
  String get completed => '完成';

  @override
  String get stopping => '正在停止…';

  @override
  String get manuallyStopped => '测速已手动停止';

  @override
  String get dataConnFailed => '无法建立数据连接，请检查服务端与网络';

  @override
  String discoveryBindFail(Object port) {
    return '无法绑定 UDP 发现端口 $port（可能被占用）';
  }
}
