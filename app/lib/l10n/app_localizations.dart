import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh')
  ];

  /// No description provided for @appTitle.
  ///
  /// In zh, this message translates to:
  /// **'内网测速'**
  String get appTitle;

  /// No description provided for @notFoundServer.
  ///
  /// In zh, this message translates to:
  /// **'未发现服务端，请确认电脑端已运行 run.bat'**
  String get notFoundServer;

  /// No description provided for @pullToRefresh.
  ///
  /// In zh, this message translates to:
  /// **'下拉刷新重新探测'**
  String get pullToRefresh;

  /// No description provided for @discoveredAt.
  ///
  /// In zh, this message translates to:
  /// **'发现时间 {time}'**
  String discoveredAt(Object time);

  /// No description provided for @manualConnect.
  ///
  /// In zh, this message translates to:
  /// **'手动连接服务端'**
  String get manualConnect;

  /// No description provided for @manualConnectFab.
  ///
  /// In zh, this message translates to:
  /// **'手动连接'**
  String get manualConnectFab;

  /// No description provided for @serverIp.
  ///
  /// In zh, this message translates to:
  /// **'服务端 IP'**
  String get serverIp;

  /// No description provided for @serverIpHint.
  ///
  /// In zh, this message translates to:
  /// **'例如 192.168.1.5'**
  String get serverIpHint;

  /// No description provided for @serverPort.
  ///
  /// In zh, this message translates to:
  /// **'服务端端口'**
  String get serverPort;

  /// No description provided for @serverPortHint.
  ///
  /// In zh, this message translates to:
  /// **'默认 8899'**
  String get serverPortHint;

  /// No description provided for @passwordOptional.
  ///
  /// In zh, this message translates to:
  /// **'访问口令（可选）'**
  String get passwordOptional;

  /// No description provided for @cancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get cancel;

  /// No description provided for @enterIp.
  ///
  /// In zh, this message translates to:
  /// **'请输入服务端 IP'**
  String get enterIp;

  /// No description provided for @invalidPort.
  ///
  /// In zh, this message translates to:
  /// **'端口无效（1-65535）'**
  String get invalidPort;

  /// No description provided for @connect.
  ///
  /// In zh, this message translates to:
  /// **'连接'**
  String get connect;

  /// No description provided for @historyTitle.
  ///
  /// In zh, this message translates to:
  /// **'历史记录'**
  String get historyTitle;

  /// No description provided for @settingsTitle.
  ///
  /// In zh, this message translates to:
  /// **'设置'**
  String get settingsTitle;

  /// No description provided for @speedTestTitle.
  ///
  /// In zh, this message translates to:
  /// **'测速'**
  String get speedTestTitle;

  /// No description provided for @testParams.
  ///
  /// In zh, this message translates to:
  /// **'测速参数'**
  String get testParams;

  /// No description provided for @durationSec.
  ///
  /// In zh, this message translates to:
  /// **'测速时长（秒）'**
  String get durationSec;

  /// No description provided for @concurrency.
  ///
  /// In zh, this message translates to:
  /// **'并发连接数'**
  String get concurrency;

  /// No description provided for @testUpload.
  ///
  /// In zh, this message translates to:
  /// **'测试上传'**
  String get testUpload;

  /// No description provided for @testUploadHint.
  ///
  /// In zh, this message translates to:
  /// **'在下载测速后执行上传测速'**
  String get testUploadHint;

  /// No description provided for @testPing.
  ///
  /// In zh, this message translates to:
  /// **'测试Ping'**
  String get testPing;

  /// No description provided for @testPingHint.
  ///
  /// In zh, this message translates to:
  /// **'测量延迟、抖动与丢包率'**
  String get testPingHint;

  /// No description provided for @startTest.
  ///
  /// In zh, this message translates to:
  /// **'开始测速'**
  String get startTest;

  /// No description provided for @stop.
  ///
  /// In zh, this message translates to:
  /// **'停止'**
  String get stop;

  /// No description provided for @realTimeSpeed.
  ///
  /// In zh, this message translates to:
  /// **'实时速度：{speed} Mbps'**
  String realTimeSpeed(Object speed);

  /// No description provided for @chartTitle.
  ///
  /// In zh, this message translates to:
  /// **'实时速度曲线'**
  String get chartTitle;

  /// No description provided for @download.
  ///
  /// In zh, this message translates to:
  /// **'下载'**
  String get download;

  /// No description provided for @upload.
  ///
  /// In zh, this message translates to:
  /// **'上传'**
  String get upload;

  /// No description provided for @collectingData.
  ///
  /// In zh, this message translates to:
  /// **'正在收集数据…'**
  String get collectingData;

  /// No description provided for @noData.
  ///
  /// In zh, this message translates to:
  /// **'暂无数据，测速开始后显示实时曲线'**
  String get noData;

  /// No description provided for @resultTitle.
  ///
  /// In zh, this message translates to:
  /// **'测速结果'**
  String get resultTitle;

  /// No description provided for @latency.
  ///
  /// In zh, this message translates to:
  /// **'延迟（最小/平均/最大）'**
  String get latency;

  /// No description provided for @latencyDetail.
  ///
  /// In zh, this message translates to:
  /// **'延迟 最小/平均/最大'**
  String get latencyDetail;

  /// No description provided for @jitter.
  ///
  /// In zh, this message translates to:
  /// **'抖动'**
  String get jitter;

  /// No description provided for @lossRate.
  ///
  /// In zh, this message translates to:
  /// **'丢包率'**
  String get lossRate;

  /// No description provided for @resultSaved.
  ///
  /// In zh, this message translates to:
  /// **'结果已保存到历史记录'**
  String get resultSaved;

  /// No description provided for @deleteRecord.
  ///
  /// In zh, this message translates to:
  /// **'删除记录'**
  String get deleteRecord;

  /// No description provided for @deleteConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确定删除 {time} 的这条测速记录吗？'**
  String deleteConfirm(Object time);

  /// No description provided for @delete.
  ///
  /// In zh, this message translates to:
  /// **'删除'**
  String get delete;

  /// No description provided for @clearAllTitle.
  ///
  /// In zh, this message translates to:
  /// **'清空历史记录'**
  String get clearAllTitle;

  /// No description provided for @clearConfirm.
  ///
  /// In zh, this message translates to:
  /// **'将删除全部测速记录，确定吗？'**
  String get clearConfirm;

  /// No description provided for @clearAll.
  ///
  /// In zh, this message translates to:
  /// **'清空'**
  String get clearAll;

  /// No description provided for @emptyHistory.
  ///
  /// In zh, this message translates to:
  /// **'暂无历史记录'**
  String get emptyHistory;

  /// No description provided for @detail.
  ///
  /// In zh, this message translates to:
  /// **'测速详情'**
  String get detail;

  /// No description provided for @time.
  ///
  /// In zh, this message translates to:
  /// **'时间'**
  String get time;

  /// No description provided for @server.
  ///
  /// In zh, this message translates to:
  /// **'服务端'**
  String get server;

  /// No description provided for @duration.
  ///
  /// In zh, this message translates to:
  /// **'测速时长'**
  String get duration;

  /// No description provided for @yes.
  ///
  /// In zh, this message translates to:
  /// **'是'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In zh, this message translates to:
  /// **'否'**
  String get no;

  /// No description provided for @downloadSpeed.
  ///
  /// In zh, this message translates to:
  /// **'下载速度'**
  String get downloadSpeed;

  /// No description provided for @uploadSpeed.
  ///
  /// In zh, this message translates to:
  /// **'上传速度'**
  String get uploadSpeed;

  /// No description provided for @historyItem.
  ///
  /// In zh, this message translates to:
  /// **'下载 {download} Mbps　上传 {upload} Mbps'**
  String historyItem(Object download, Object upload);

  /// No description provided for @serverTitle.
  ///
  /// In zh, this message translates to:
  /// **'{name}（{ip}）'**
  String serverTitle(Object ip, Object name);

  /// No description provided for @serverDetail.
  ///
  /// In zh, this message translates to:
  /// **'{name}（{ip}:{port}）'**
  String serverDetail(Object ip, Object name, Object port);

  /// No description provided for @durationValue.
  ///
  /// In zh, this message translates to:
  /// **'{sec} 秒'**
  String durationValue(Object sec);

  /// No description provided for @defaultParams.
  ///
  /// In zh, this message translates to:
  /// **'默认测速参数'**
  String get defaultParams;

  /// No description provided for @defaultDurationSec.
  ///
  /// In zh, this message translates to:
  /// **'默认测速时长（秒）'**
  String get defaultDurationSec;

  /// No description provided for @defaultConcurrency.
  ///
  /// In zh, this message translates to:
  /// **'默认并发连接数'**
  String get defaultConcurrency;

  /// No description provided for @defaultTestUpload.
  ///
  /// In zh, this message translates to:
  /// **'默认测试上传'**
  String get defaultTestUpload;

  /// No description provided for @defaultTestPing.
  ///
  /// In zh, this message translates to:
  /// **'默认测试Ping'**
  String get defaultTestPing;

  /// No description provided for @discoverySettings.
  ///
  /// In zh, this message translates to:
  /// **'发现设置'**
  String get discoverySettings;

  /// No description provided for @discoveryPort.
  ///
  /// In zh, this message translates to:
  /// **'UDP 发现端口'**
  String get discoveryPort;

  /// No description provided for @discoveryPortHint.
  ///
  /// In zh, this message translates to:
  /// **'自动发现广播/监听端口，默认 8900（TCP 端口 + 1）'**
  String get discoveryPortHint;

  /// No description provided for @connectFail.
  ///
  /// In zh, this message translates to:
  /// **'无法连接服务端，请检查 IP 与端口'**
  String get connectFail;

  /// No description provided for @serverNoResponse.
  ///
  /// In zh, this message translates to:
  /// **'服务端无响应'**
  String get serverNoResponse;

  /// No description provided for @wrongPassword.
  ///
  /// In zh, this message translates to:
  /// **'口令错误'**
  String get wrongPassword;

  /// No description provided for @handshakeFail.
  ///
  /// In zh, this message translates to:
  /// **'握手失败：收到未知消息 {type}'**
  String handshakeFail(Object type);

  /// No description provided for @versionIncompatible.
  ///
  /// In zh, this message translates to:
  /// **'服务端版本不兼容（服务端版本 {version}，客户端需要 1）'**
  String versionIncompatible(Object version);

  /// No description provided for @msgBadFormat.
  ///
  /// In zh, this message translates to:
  /// **'消息格式错误'**
  String get msgBadFormat;

  /// No description provided for @msgUnknownType.
  ///
  /// In zh, this message translates to:
  /// **'未知消息类型'**
  String get msgUnknownType;

  /// No description provided for @msgBadTest.
  ///
  /// In zh, this message translates to:
  /// **'测速类型错误'**
  String get msgBadTest;

  /// No description provided for @msgTooManyClients.
  ///
  /// In zh, this message translates to:
  /// **'服务端客户端数量已达上限'**
  String get msgTooManyClients;

  /// No description provided for @msgAuthFailed.
  ///
  /// In zh, this message translates to:
  /// **'口令错误'**
  String get msgAuthFailed;

  /// No description provided for @msgUnknownError.
  ///
  /// In zh, this message translates to:
  /// **'未知错误'**
  String get msgUnknownError;

  /// No description provided for @testStartFail.
  ///
  /// In zh, this message translates to:
  /// **'测速开始失败：服务端无响应'**
  String get testStartFail;

  /// No description provided for @testStartUnknownMsg.
  ///
  /// In zh, this message translates to:
  /// **'测速开始失败：收到未知消息 {type}'**
  String testStartUnknownMsg(Object type);

  /// No description provided for @reportFail.
  ///
  /// In zh, this message translates to:
  /// **'上报测速结果失败：服务端无响应'**
  String get reportFail;

  /// No description provided for @reportUnknownMsg.
  ///
  /// In zh, this message translates to:
  /// **'上报测速结果失败：收到未知消息 {type}'**
  String reportUnknownMsg(Object type);

  /// No description provided for @connClosed.
  ///
  /// In zh, this message translates to:
  /// **'连接已断开'**
  String get connClosed;

  /// No description provided for @connecting.
  ///
  /// In zh, this message translates to:
  /// **'正在连接服务端…'**
  String get connecting;

  /// No description provided for @concurrencyExceed.
  ///
  /// In zh, this message translates to:
  /// **'并发数 {concurrency} 超过服务端上限 {max}'**
  String concurrencyExceed(Object concurrency, Object max);

  /// No description provided for @testingPing.
  ///
  /// In zh, this message translates to:
  /// **'正在测 Ping…'**
  String get testingPing;

  /// No description provided for @testingDownload.
  ///
  /// In zh, this message translates to:
  /// **'正在测下载…'**
  String get testingDownload;

  /// No description provided for @testingUpload.
  ///
  /// In zh, this message translates to:
  /// **'正在测上传…'**
  String get testingUpload;

  /// No description provided for @unknownError.
  ///
  /// In zh, this message translates to:
  /// **'发生未知错误：{error}'**
  String unknownError(Object error);

  /// No description provided for @completed.
  ///
  /// In zh, this message translates to:
  /// **'完成'**
  String get completed;

  /// No description provided for @stopping.
  ///
  /// In zh, this message translates to:
  /// **'正在停止…'**
  String get stopping;

  /// No description provided for @manuallyStopped.
  ///
  /// In zh, this message translates to:
  /// **'测速已手动停止'**
  String get manuallyStopped;

  /// No description provided for @dataConnFailed.
  ///
  /// In zh, this message translates to:
  /// **'无法建立数据连接，请检查服务端与网络'**
  String get dataConnFailed;

  /// No description provided for @discoveryBindFail.
  ///
  /// In zh, this message translates to:
  /// **'无法绑定 UDP 发现端口 {port}（可能被占用）'**
  String discoveryBindFail(Object port);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
