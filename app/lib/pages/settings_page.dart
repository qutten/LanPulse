import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/settings_service.dart';

/// 设置页：默认测速参数 + UDP 发现端口（shared_preferences 持久化）
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final SettingsService _service = SettingsService();
  final TextEditingController _portCtrl = TextEditingController();
  AppSettings _settings = const AppSettings();
  bool _loaded = false;

  static const _durations = [5, 10, 30, 60];
  static const _concurrencies = [1, 2, 4, 8];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await _service.load();
    if (!mounted) return;
    setState(() {
      _settings = s;
      _portCtrl.text = s.discoveryPort.toString();
      _loaded = true;
    });
  }

  void _save(AppSettings s) {
    setState(() => _settings = s);
    _service.save(s);
  }

  void _onPortChanged(String text) {
    final port = int.tryParse(text.trim());
    if (port == null || port < 1 || port > 65535) return;
    _save(_settings.copyWith(discoveryPort: port));
  }

  @override
  void dispose() {
    _portCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  l10n.defaultParams,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Text(l10n.defaultDurationSec),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final d in _durations)
                      ChoiceChip(
                        label: Text('$d'),
                        selected: _settings.defaultDurationSec == d,
                        onSelected: (_) =>
                            _save(_settings.copyWith(defaultDurationSec: d)),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(l10n.defaultConcurrency),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final c in _concurrencies)
                      ChoiceChip(
                        label: Text('$c'),
                        selected: _settings.defaultConcurrency == c,
                        onSelected: (_) =>
                            _save(_settings.copyWith(defaultConcurrency: c)),
                      ),
                  ],
                ),
                SwitchListTile(
                  title: Text(l10n.defaultTestUpload),
                  value: _settings.defaultTestUpload,
                  onChanged: (v) =>
                      _save(_settings.copyWith(defaultTestUpload: v)),
                ),
                SwitchListTile(
                  title: Text(l10n.defaultTestPing),
                  value: _settings.defaultTestPing,
                  onChanged: (v) =>
                      _save(_settings.copyWith(defaultTestPing: v)),
                ),
                const Divider(height: 24),
                Text(
                  l10n.discoverySettings,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.discoveryPort),
                  subtitle: Text(l10n.discoveryPortHint),
                  trailing: SizedBox(
                    width: 110,
                    child: TextField(
                      controller: _portCtrl,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.right,
                      onChanged: _onPortChanged,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: '8900',
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
