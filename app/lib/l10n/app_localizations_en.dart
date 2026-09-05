// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'LanPulse';

  @override
  String get notFoundServer =>
      'No server found. Please make sure run.bat is running on your computer';

  @override
  String get pullToRefresh => 'Pull down to refresh';

  @override
  String discoveredAt(Object time) {
    return 'Discovered at $time';
  }

  @override
  String get manualConnect => 'Connect to Server Manually';

  @override
  String get manualConnectFab => 'Manual Connect';

  @override
  String get serverIp => 'Server IP';

  @override
  String get serverIpHint => 'e.g. 192.168.1.5';

  @override
  String get serverPort => 'Server Port';

  @override
  String get serverPortHint => 'Default 8899';

  @override
  String get passwordOptional => 'Password (Optional)';

  @override
  String get cancel => 'Cancel';

  @override
  String get enterIp => 'Please enter the server IP';

  @override
  String get invalidPort => 'Invalid port (1-65535)';

  @override
  String get connect => 'Connect';

  @override
  String get historyTitle => 'History';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get speedTestTitle => 'Speed Test';

  @override
  String get testParams => 'Test Parameters';

  @override
  String get durationSec => 'Duration (s)';

  @override
  String get concurrency => 'Concurrency';

  @override
  String get testUpload => 'Test Upload';

  @override
  String get testUploadHint => 'Run the upload test after the download test';

  @override
  String get testPing => 'Test Ping';

  @override
  String get testPingHint => 'Measure latency, jitter and packet loss';

  @override
  String get startTest => 'Start Test';

  @override
  String get stop => 'Stop';

  @override
  String realTimeSpeed(Object speed) {
    return 'Real-time speed: $speed Mbps';
  }

  @override
  String get chartTitle => 'Real-time Speed Chart';

  @override
  String get download => 'Download';

  @override
  String get upload => 'Upload';

  @override
  String get collectingData => 'Collecting data…';

  @override
  String get noData =>
      'No data yet. The chart will appear once the test starts';

  @override
  String get resultTitle => 'Test Result';

  @override
  String get latency => 'Latency (min/avg/max)';

  @override
  String get latencyDetail => 'Latency Min/Avg/Max';

  @override
  String get jitter => 'Jitter';

  @override
  String get lossRate => 'Packet Loss';

  @override
  String get resultSaved => 'Result saved to history';

  @override
  String get deleteRecord => 'Delete Record';

  @override
  String deleteConfirm(Object time) {
    return 'Delete this record from $time?';
  }

  @override
  String get delete => 'Delete';

  @override
  String get clearAllTitle => 'Clear History';

  @override
  String get clearConfirm => 'Delete all history records?';

  @override
  String get clearAll => 'Clear All';

  @override
  String get emptyHistory => 'No history yet';

  @override
  String get detail => 'Test Details';

  @override
  String get time => 'Time';

  @override
  String get server => 'Server';

  @override
  String get duration => 'Duration';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get downloadSpeed => 'Download Speed';

  @override
  String get uploadSpeed => 'Upload Speed';

  @override
  String historyItem(Object download, Object upload) {
    return 'Download $download Mbps  Upload $upload Mbps';
  }

  @override
  String serverTitle(Object ip, Object name) {
    return '$name ($ip)';
  }

  @override
  String serverDetail(Object ip, Object name, Object port) {
    return '$name ($ip:$port)';
  }

  @override
  String durationValue(Object sec) {
    return '$sec s';
  }

  @override
  String get defaultParams => 'Default Test Parameters';

  @override
  String get defaultDurationSec => 'Default Duration (s)';

  @override
  String get defaultConcurrency => 'Default Concurrency';

  @override
  String get defaultTestUpload => 'Test Upload by Default';

  @override
  String get defaultTestPing => 'Test Ping by Default';

  @override
  String get discoverySettings => 'Discovery Settings';

  @override
  String get discoveryPort => 'UDP Discovery Port';

  @override
  String get discoveryPortHint =>
      'Broadcast/listen port for auto-discovery, default 8900 (TCP port + 1)';

  @override
  String get connectFail =>
      'Cannot connect to the server. Check the IP and port';

  @override
  String get serverNoResponse => 'Server did not respond';

  @override
  String get wrongPassword => 'Wrong password';

  @override
  String handshakeFail(Object type) {
    return 'Handshake failed: unknown message $type';
  }

  @override
  String versionIncompatible(Object version) {
    return 'Incompatible server version ($version, client requires 1)';
  }

  @override
  String get msgBadFormat => 'Bad message format';

  @override
  String get msgUnknownType => 'Unknown message type';

  @override
  String get msgBadTest => 'Bad test type';

  @override
  String get msgTooManyClients => 'Server client limit reached';

  @override
  String get msgAuthFailed => 'Wrong password';

  @override
  String get msgUnknownError => 'Unknown error';

  @override
  String get testStartFail => 'Failed to start test: server did not respond';

  @override
  String testStartUnknownMsg(Object type) {
    return 'Failed to start test: unknown message $type';
  }

  @override
  String get reportFail =>
      'Failed to report test result: server did not respond';

  @override
  String reportUnknownMsg(Object type) {
    return 'Failed to report test result: unknown message $type';
  }

  @override
  String get connClosed => 'Connection closed';

  @override
  String get connecting => 'Connecting to server…';

  @override
  String concurrencyExceed(Object concurrency, Object max) {
    return 'Concurrency $concurrency exceeds the server limit $max';
  }

  @override
  String get testingPing => 'Testing Ping…';

  @override
  String get testingDownload => 'Testing download…';

  @override
  String get testingUpload => 'Testing upload…';

  @override
  String unknownError(Object error) {
    return 'Unknown error: $error';
  }

  @override
  String get completed => 'Completed';

  @override
  String get stopping => 'Stopping…';

  @override
  String get manuallyStopped => 'Test stopped manually';

  @override
  String get dataConnFailed =>
      'Cannot establish data connections. Check the server and network';

  @override
  String discoveryBindFail(Object port) {
    return 'Cannot bind UDP discovery port $port (maybe in use)';
  }
}
