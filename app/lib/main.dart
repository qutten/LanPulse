import 'package:flutter/material.dart';

import 'l10n.dart';
import 'l10n/app_localizations.dart';
import 'pages/home_page.dart';

void main() {
  runApp(const LanPulseApp());
}

/// LanPulse 脉冲测速 App 入口：Material 3，支持浅色/深色跟随系统
class LanPulseApp extends StatelessWidget {
  const LanPulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (ctx) => AppLocalizations.of(ctx).appTitle,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      // 中文/英文按系统语言匹配；其他语言统一回退到中文（zh 兜底）
      localeResolutionCallback: (locale, supportedLocales) {
        if (locale == null) return null;
        for (final supported in supportedLocales) {
          if (supported.languageCode == locale.languageCode) {
            return supported;
          }
        }
        return const Locale('zh');
      },
      builder: (context, child) {
        // 刷新服务层（无 BuildContext）使用的当前语言文案
        L10n.set(AppLocalizations.of(context));
        return child!;
      },
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      themeMode: ThemeMode.system,
      home: const HomePage(),
    );
  }
}
