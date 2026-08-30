import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/server_info.dart';
import '../services/discovery_service.dart';
import '../services/settings_service.dart';
import 'history_page.dart';
import 'settings_page.dart';
import 'speed_test_page.dart';

/// 手动连接对话框的输入
class _ManualInput {
  const _ManualInput({
    required this.ip,
    required this.port,
    required this.password,
  });

  final String ip;
  final int port;
  final String password;
}

/// 首页：服务端发现列表 + 手动连接入口
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final SettingsService _settingsService = SettingsService();
  DiscoveryService? _discovery;
  StreamSubscription<List<ServerInfo>>? _sub;
  List<ServerInfo> _servers = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final settings = await _settingsService.load();
    if (!mounted) return;
    _discovery = DiscoveryService(discoveryPort: settings.discoveryPort);
    await _startDiscovery();
  }

  Future<void> _startDiscovery() async {
    final discovery = _discovery;
    if (discovery == null) return;
    try {
      await discovery.start();
      if (!mounted) return;
      _sub?.cancel();
      _sub = discovery.servers.listen((list) {
        if (mounted) {
          setState(() {
            _servers = list;
            _error = null;
          });
        }
      });
    } on DiscoveryException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  /// 设置页返回后按最新的发现端口重启发现
  Future<void> _openSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsPage()),
    );
    if (!mounted) return;
    _discovery?.stop();
    final settings = await _settingsService.load();
    if (!mounted) return;
    _discovery = DiscoveryService(discoveryPort: settings.discoveryPort);
    await _startDiscovery();
  }

  Future<void> _refresh() async {
    await _discovery?.probe();
  }

  void _openHistory() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const HistoryPage()),
    );
  }

  Future<void> _showManualConnect() async {
    final ipCtrl = TextEditingController();
    final portCtrl = TextEditingController(text: '8899');
    final pwdCtrl = TextEditingController();
    final input = await showDialog<_ManualInput>(
      context: context,
      builder: (ctx) {
        final l10n = AppLocalizations.of(ctx);
        return AlertDialog(
          title: Text(l10n.manualConnect),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ipCtrl,
                decoration: InputDecoration(
                  labelText: l10n.serverIp,
                  hintText: l10n.serverIpHint,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: portCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l10n.serverPort,
                  hintText: l10n.serverPortHint,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: pwdCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: l10n.passwordOptional,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () {
                final ip = ipCtrl.text.trim();
                final port = int.tryParse(portCtrl.text.trim()) ?? 0;
                if (ip.isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text(l10n.enterIp)),
                  );
                  return;
                }
                if (port < 1 || port > 65535) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text(l10n.invalidPort)),
                  );
                  return;
                }
                Navigator.of(ctx).pop(
                  _ManualInput(ip: ip, port: port, password: pwdCtrl.text),
                );
              },
              child: Text(l10n.connect),
            ),
          ],
        );
      },
    );
    if (input == null || !mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SpeedTestPage(
          server: ServerInfo.manual(input.ip, input.port),
          password: input.password,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    _discovery?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          IconButton(
            tooltip: l10n.historyTitle,
            icon: const Icon(Icons.history),
            onPressed: _openHistory,
          ),
          IconButton(
            tooltip: l10n.settingsTitle,
            icon: const Icon(Icons.settings),
            onPressed: _openSettings,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: l10n.manualConnectFab,
        onPressed: _showManualConnect,
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 120),
          Center(
            child: Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      );
    }
    if (_servers.isEmpty) {
      final l10n = AppLocalizations.of(context);
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 100),
          const Icon(Icons.wifi_off, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Center(child: Text(l10n.notFoundServer)),
          const SizedBox(height: 8),
          Center(
            child: Text(
              l10n.pullToRefresh,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ],
      );
    }
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: _servers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final s = _servers[index];
        final l10n = AppLocalizations.of(context);
        return Card(
          child: ListTile(
            leading: const Icon(Icons.computer, size: 36),
            title: Text(s.name),
            subtitle: Text(
              '${s.ip}:${s.port}\n${l10n.discoveredAt(_fmtTime(s.discoveryTime))}',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SpeedTestPage(server: s),
                ),
              );
            },
          ),
        );
      },
    );
  }

  static String _fmtTime(DateTime t) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${t.year}-${two(t.month)}-${two(t.day)} '
        '${two(t.hour)}:${two(t.minute)}:${two(t.second)}';
  }
}
