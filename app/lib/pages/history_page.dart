import 'package:flutter/material.dart';

import '../db/history_dao.dart';
import '../l10n/app_localizations.dart';
import '../models/speed_result.dart';

/// 历史记录页：列表 / 详情 / 删除 / 清空
class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final HistoryDao _dao = HistoryDao();
  List<SpeedResult> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await _dao.getAll();
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  Future<void> _delete(SpeedResult r) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteRecord),
        content: Text(l10n.deleteConfirm(_fmtTime(r.timeMs))),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _dao.delete(r.id);
    await _load();
  }

  Future<void> _clearAll() async {
    if (_items.isEmpty) return;
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.clearAllTitle),
        content: Text(l10n.clearConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.clearAll),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _dao.clear();
    await _load();
  }

  void _openDetail(SpeedResult r) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => _HistoryDetailPage(result: r)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.historyTitle),
        actions: [
          TextButton(
            onPressed: _items.isEmpty ? null : _clearAll,
            child: Text(l10n.clearAll),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? Center(child: Text(l10n.emptyHistory))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final r = _items[index];
                    return Card(
                      child: ListTile(
                        title: Text(
                            l10n.serverTitle(r.serverName, r.serverIp)),
                        subtitle: Text(
                          '${_fmtTime(r.timeMs)}\n'
                          '${l10n.historyItem(r.downloadMbps.toStringAsFixed(2), r.uploadMbps.toStringAsFixed(2))}',
                        ),
                        trailing: IconButton(
                          tooltip: l10n.delete,
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _delete(r),
                        ),
                        onTap: () => _openDetail(r),
                      ),
                    );
                  },
                ),
    );
  }

  static String _fmtTime(int ms) {
    final t = DateTime.fromMillisecondsSinceEpoch(ms);
    String two(int v) => v.toString().padLeft(2, '0');
    return '${t.year}-${two(t.month)}-${two(t.day)} '
        '${two(t.hour)}:${two(t.minute)}:${two(t.second)}';
  }
}

/// 历史记录详情页（全部指标 + 参数）
class _HistoryDetailPage extends StatelessWidget {
  const _HistoryDetailPage({required this.result});

  final SpeedResult result;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final r = result;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.detail)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _detailRow(l10n.time, _fmtTime(r.timeMs)),
          _detailRow(l10n.server,
              l10n.serverDetail(r.serverName, r.serverIp, r.serverPort)),
          _detailRow(l10n.duration, l10n.durationValue(r.durationSec)),
          _detailRow(l10n.concurrency, '${r.concurrency}'),
          _detailRow(l10n.testUpload, r.testUpload ? l10n.yes : l10n.no),
          _detailRow(l10n.testPing, r.testPing ? l10n.yes : l10n.no),
          const Divider(height: 24),
          _detailRow(l10n.downloadSpeed, '${r.downloadMbps.toStringAsFixed(2)} Mbps'),
          if (r.testUpload)
            _detailRow(l10n.uploadSpeed, '${r.uploadMbps.toStringAsFixed(2)} Mbps'),
          if (r.testPing && r.pingAvg != null) ...[
            _detailRow(
              l10n.latencyDetail,
              '${_fmt2(r.pingMin)} / ${_fmt2(r.pingAvg)} / ${_fmt2(r.pingMax)} ms',
            ),
            _detailRow(l10n.jitter, '${_fmt2(r.jitterMs)} ms'),
            _detailRow(l10n.lossRate, '${_fmt2(r.lossPct)}%'),
          ],
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );

  static String _fmt2(double? v) => v?.toStringAsFixed(2) ?? '—';

  static String _fmtTime(int ms) {
    final t = DateTime.fromMillisecondsSinceEpoch(ms);
    String two(int v) => v.toString().padLeft(2, '0');
    return '${t.year}-${two(t.month)}-${two(t.day)} '
        '${two(t.hour)}:${two(t.minute)}:${two(t.second)}';
  }
}
