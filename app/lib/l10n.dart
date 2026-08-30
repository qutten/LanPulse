import 'package:flutter/widgets.dart';

import 'l10n/app_localizations.dart';

/// 无 BuildContext 环境（服务层）访问当前语言文案的入口。
///
/// 由 main.dart 的 MaterialApp.builder 在每个 build 时刷新 `_current`，
/// 因此抛出的错误/状态消息会随系统语言切换。兜底为中文（zh）。
class L10n {
  static AppLocalizations? _current;

  static AppLocalizations get t =>
      _current ?? lookupAppLocalizations(const Locale('zh'));

  static void set(AppLocalizations v) => _current = v;
}
