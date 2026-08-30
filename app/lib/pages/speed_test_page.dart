import 'dart:async';
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../db/history_dao.dart';
import '../l10n/app_localizations.dart';
import '../models/server_info.dart';
import '../models/speed_result.dart';
import '../models/test_params.dart';
import '../services/settings_service.dart';
import '../services/speed_test_engine.dart';

/// 测速页：参数选择 + 一键测速 + 实时曲线 + 结果展示
class SpeedTestPage extends StatefulWidget {
  const SpeedTestPage({super.key, required this.server, this.password = ''});

  final ServerInfo server;
  final String password;

  @override
  State<SpeedTestPage> createState() => _SpeedTestPageState();
}

class _SpeedTestPageState extends State<SpeedTestPage> {
  final SettingsService _settingsService = SettingsService();
  late final SpeedTestEngine _engine;
  StreamSubscription<EngineState>? _sub;
  EngineState _state = const EngineState();
  bool _loaded = false;

  late int _durationSec;
  late int _concurrency;
  late bool _testUpload;
  late bool _testPing;

  static const _durations = [5, 10, 30, 60];
  static const _concurrencies = [1, 2, 4, 8];

  @override
  void initState() {
    super.initState();
    _engine = SpeedTestEngine(historyDao: HistoryDao());
    _sub = _engine.states.listen((s) {
      if (mounted) setState(() => _state = s);
    });
    _loadDefaults();
  }

  Future<void> _loadDefaults() async {
    final s = await _settingsService.load();
    if (!mounted) return;
    setState(() {
      _durationSec = s.defaultDurationSec;
      _concurrency = s.defaultConcurrency;
      _testUpload = s.defaultTestUpload;
      _testPing = s.defaultTestPing;
      _loaded = true;
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _engine.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    final params = TestParams(
      durationSec: _durationSec,
      concurrency: _concurrency,
      testUpload: _testUpload,
      testPing: _testPing,
      blockSize: kDefaultBlockSize,
      host: widget.server.ip,
      port: widget.server.port,
    );
    await _engine.start(params, widget.server, password: widget.password);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.speedTestTitle)),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildServerHeader(),
                const SizedBox(height: 12),
                _buildParamsCard(),
                const SizedBox(height: 16),
                _buildActionButton(),
                const SizedBox(height: 16),
                _buildStatusArea(),
                const SizedBox(height: 16),
                _buildChartSection(),
                if (_state.phase == TestPhase.done && _state.result != null) ...[
                  const SizedBox(height: 16),
                  _buildResultCard(_state.result!),
                ],
              ],
            ),
    );
  }

  Widget _buildServerHeader() {
    final server = widget.server;
    return Card(
      child: ListTile(
        leading: const Icon(Icons.dns, size: 32),
        title: Text(
          server.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('${server.ip}:${server.port}'),
      ),
    );
  }

  Widget _buildParamsCard() {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.testParams, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Text(l10n.durationSec),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: [
                for (final d in _durations)
                  ChoiceChip(
                    label: Text('$d'),
                    selected: _durationSec == d,
                    onSelected: (_) => setState(() => _durationSec = d),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(l10n.concurrency),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: [
                for (final c in _concurrencies)
                  ChoiceChip(
                    label: Text('$c'),
                    selected: _concurrency == c,
                    onSelected: (_) => setState(() => _concurrency = c),
                  ),
              ],
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.testUpload),
              subtitle: Text(l10n.testUploadHint),
              value: _testUpload,
              onChanged: (v) => setState(() => _testUpload = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.testPing),
              subtitle: Text(l10n.testPingHint),
              value: _testPing,
              onChanged: (v) => setState(() => _testPing = v),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    final l10n = AppLocalizations.of(context);
    if (_state.isRunning) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          onPressed: _engine.stop,
          icon: const Icon(Icons.stop),
          label: Text(l10n.stop),
        ),
      );
    }
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: _start,
        icon: const Icon(Icons.speed),
        label: Text(l10n.startTest),
      ),
    );
  }

  Widget _buildStatusArea() {
    final children = <Widget>[];
    if (_state.statusText.isNotEmpty) {
      children.add(
        Row(
          children: [
            if (_state.isRunning)
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            Text(
              _state.statusText,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      );
    }
    if (_state.isRunning) {
      children.add(const SizedBox(height: 4));
      children.add(
        Text(
          AppLocalizations.of(context).realTimeSpeed(
              _state.currentSpeedMbps.toStringAsFixed(2)),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }
    if (_state.phase == TestPhase.error && _state.errorMessage != null) {
      final scheme = Theme.of(context).colorScheme;
      children.add(const SizedBox(height: 8));
      children.add(
        Card(
          color: scheme.errorContainer,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              _state.errorMessage!,
              style: TextStyle(color: scheme.onErrorContainer),
            ),
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  Widget _buildChartSection() {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  l10n.chartTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                _legendDot(Colors.blue),
                const SizedBox(width: 4),
                Text(l10n.download),
                const SizedBox(width: 12),
                _legendDot(Colors.orange),
                const SizedBox(width: 4),
                Text(l10n.upload),
              ],
            ),
            const SizedBox(height: 12),
            _buildChart(),
          ],
        ),
      ),
    );
  }

  Widget _legendDot(Color color) => Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );

  /// 实时曲线：横轴秒、纵轴 Mbps；数据不足 2 点显示占位文本
  Widget _buildChart() {
    final l10n = AppLocalizations.of(context);
    final dl = _state.downloadSamples;
    final ul = _state.uploadSamples;
    if (dl.length + ul.length < 2) {
      return SizedBox(
        height: 220,
        child: Center(
          child: Text(
            _state.isRunning ? l10n.collectingData : l10n.noData,
            style: const TextStyle(color: Colors.grey),
          ),
        ),
      );
    }
    final dlSpots = dl.map((s) => FlSpot(s.t, s.mbps)).toList();
    final ulSpots = ul.map((s) => FlSpot(s.t, s.mbps)).toList();
    var yMax = 10.0;
    var xMax = 1.0;
    for (final s in dl) {
      if (s.mbps > yMax) yMax = s.mbps;
      if (s.t > xMax) xMax = s.t;
    }
    for (final s in ul) {
      if (s.mbps > yMax) yMax = s.mbps;
      if (s.t > xMax) xMax = s.t;
    }
    yMax *= 1.15;
    xMax += 1;
    // 使用整数刻度并让顶部对齐到整刻度，避免纵轴数字重叠
    final yInterval = _niceInterval(yMax);
    yMax = (yMax / yInterval).ceil() * yInterval;

    return SizedBox(
      height: 220,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: xMax,
          minY: 0,
          maxY: yMax,
          gridData: const FlGridData(show: true, drawVerticalLine: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 44,
                interval: yInterval,
                getTitlesWidget: (value, meta) {
                  // 隐藏顶部最大刻度，防止与图表边缘重叠
                  if (value == meta.max) return const SizedBox.shrink();
                  final label = yInterval >= 1
                      ? value.toInt().toString()
                      : value.toStringAsFixed(1);
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Text(
                      label,
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                interval: 1,
                getTitlesWidget: (value, meta) => Text(
                  '${value.toInt()}s',
                  style: const TextStyle(fontSize: 10),
                ),
              ),
            ),
          ),
          lineBarsData: [
            if (dlSpots.isNotEmpty)
              LineChartBarData(
                spots: dlSpots,
                color: Colors.blue,
                barWidth: 2,
                isCurved: false,
                dotData: const FlDotData(show: false),
              ),
            if (ulSpots.isNotEmpty)
              LineChartBarData(
                spots: ulSpots,
                color: Colors.orange,
                barWidth: 2,
                isCurved: false,
                dotData: const FlDotData(show: false),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(SpeedResult r) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.resultTitle, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _metricRow(l10n.download, '${r.downloadMbps.toStringAsFixed(2)} Mbps'),
            if (r.testUpload)
              _metricRow(l10n.upload, '${r.uploadMbps.toStringAsFixed(2)} Mbps'),
            if (r.testPing && r.pingAvg != null) ...[
              _metricRow(
                l10n.latency,
                '${_fmt2(r.pingMin)} / ${_fmt2(r.pingAvg)} / ${_fmt2(r.pingMax)} ms',
              ),
              _metricRow(l10n.jitter, '${_fmt2(r.jitterMs)} ms'),
              _metricRow(l10n.lossRate, '${_fmt2(r.lossPct)}%'),
            ],
            const SizedBox(height: 8),
            Center(
              child: Text(
                l10n.resultSaved,
                style: TextStyle(
                  color: scheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );

  static String _fmt2(double? v) => v?.toStringAsFixed(2) ?? '—';

  /// 计算"美观"的纵轴刻度间隔（1/2/5 × 10ⁿ，约 5 个刻度，如 200/350 类型场景 → 50）
  static double _niceInterval(double maxY, {int target = 5}) {
    if (maxY <= 0) return 1;
    final rough = maxY / target;
    final exp = (math.log(rough) / math.ln10).floor();
    final mag = math.pow(10, exp).toDouble();
    final f = rough / mag;
    if (f < 1.5) return mag;
    if (f < 3) return 2 * mag;
    if (f < 7) return 5 * mag;
    return 10 * mag;
  }
}
