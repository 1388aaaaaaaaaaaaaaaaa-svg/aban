import 'package:flutter/material.dart';

import '../../api.dart';
import '../../format.dart';
import '../../models.dart';
import '../../state.dart';
import '../../theme.dart';
import '../../widgets.dart';
import 'pdf_export.dart';
import 'units_tab.dart';

/// List of issued bills (periods). Tap one to see units, payment and seen status.
class BillsTab extends StatefulWidget {
  const BillsTab({super.key});

  @override
  State<BillsTab> createState() => _BillsTabState();
}

class _BillsTabState extends State<BillsTab> {
  List<Map<String, dynamic>> _periods = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await rpc('list_periods', {'p_token': appState.managerToken}) as List;
      setState(() => _periods = rows.cast<Map<String, dynamic>>());
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return EmptyState(text: _error!);
    if (_periods.isEmpty) return const EmptyState(text: 'هنوز قبضی صادر نشده است');
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: _periods.map((p) {
          final unpaid = (p['unpaid_count'] ?? 0) as num;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppCard(
              child: InkWell(
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PeriodDetailPage(
                        periodId: p['period_id'].toString(),
                        title: p['title'].toString(),
                      ),
                    ),
                  );
                  _load();
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p['title'].toString(), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    const SizedBox(height: 6),
                    Text(
                      '${fmtNum((p['bill_count'] ?? 0) as num)} واحد · پرداخت‌شده ${fmtNum((p['paid_count'] ?? 0) as num)} · '
                      'پرداخت‌نشده ${fmtNum(unpaid)}',
                      style: const TextStyle(color: AppColors.muted, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text('جمع بدهی: ${fmtMoney((p['unpaid_total'] ?? 0) as num)}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class PeriodDetailPage extends StatefulWidget {
  final String periodId;
  final String title;
  const PeriodDetailPage({super.key, required this.periodId, required this.title});

  @override
  State<PeriodDetailPage> createState() => _PeriodDetailPageState();
}

class _PeriodDetailPageState extends State<PeriodDetailPage> {
  List<Map<String, dynamic>> _rows = [];
  Map<String, Map<String, dynamic>> _seen = {};
  bool _loading = true;
  String? _error;
  bool _onlyUnpaid = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final bills = await rpc('list_bills', {
        'p_token': appState.managerToken,
        'p_period': widget.periodId,
      }) as List;
      final seen = await rpc('bill_seen_list', {
        'p_token': appState.managerToken,
        'p_period': widget.periodId,
      }) as List;
      final sortedRows = bills.cast<Map<String, dynamic>>().toList()
        ..sort((a, b) => naturalCompare(a['unit_label'].toString(), b['unit_label'].toString()));
      setState(() {
        _rows = sortedRows;
        _seen = {for (final s in seen) (s as Map<String, dynamic>)['unit_label'].toString(): s};
      });
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool _isPaid(Map<String, dynamic> r) => r['payment_status'] == 'paid';

  List<Map<String, dynamic>> get _shown =>
      _rows.where((r) => _onlyUnpaid ? !_isPaid(r) : _isPaid(r)).toList();

  Future<void> _togglePaid(Map<String, dynamic> r) async {
    final paid = _isPaid(r);
    try {
      await rpc('set_paid', {
        'p_token': appState.managerToken,
        'p_period': widget.periodId,
        'p_label': r['unit_label'],
        'p_amount': paid ? 0 : (r['amount_due'] ?? 0),
      });
      await _load();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _pdf() async {
    final filter = _onlyUnpaid ? 'فقط پرداخت‌نشده' : 'فقط پرداخت‌شده';
    try {
      await printPeriodTable(
        buildingName: appState.managerBuildingName ?? '',
        periodTitle: widget.title,
        filterLabel: filter,
        rows: _shown,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ساخت PDF انجام نشد')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    num unpaidDebt = 0;
    var unpaidCount = 0;
    for (final r in _rows) {
      if (!_isPaid(r)) {
        unpaidCount++;
        unpaidDebt += ((r['amount_due'] ?? 0) as num) - ((r['paid_amount'] ?? 0) as num);
      }
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [IconButton(onPressed: _pdf, icon: const Icon(Icons.picture_as_pdf_outlined), tooltip: 'PDF')],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? EmptyState(text: _error!)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.redSoft,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${fmtNum(unpaidCount)} نفر پرداخت نکرده‌اند',
                                style: const TextStyle(color: AppColors.red, fontWeight: FontWeight.w800, fontSize: 16)),
                            const SizedBox(height: 4),
                            Text('جمع بدهی این دوره: ${fmtMoney(unpaidDebt)} · از ${fmtNum(_rows.length)} واحد',
                                style: const TextStyle(fontSize: 13)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(value: true, label: Text('پرداخت نشده')),
                          ButtonSegment(value: false, label: Text('پرداخت شده')),
                        ],
                        selected: {_onlyUnpaid},
                        onSelectionChanged: (s) => setState(() => _onlyUnpaid = s.first),
                      ),
                      const SizedBox(height: 12),
                      if (_shown.isEmpty) const EmptyState(text: 'موردی نیست'),
                      ..._shown.map(_row),
                    ],
                  ),
                ),
    );
  }

  Widget _row(Map<String, dynamic> r) {
    final label = r['unit_label'].toString();
    final paid = _isPaid(r);
    final s = _seen[label];
    final seenAt = s?['first_seen_at']?.toString();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.blueLight,
              foregroundColor: AppColors.blue,
              child: Text(label, style: const TextStyle(fontSize: 12)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${r['resident_name'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text('قبض ${fmtMoney((r['amount_due'] ?? 0) as num)} · پرداختی ${fmtMoney((r['paid_amount'] ?? 0) as num)}',
                      style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                  Text(seenAt == null ? 'ندیده' : 'دیده شده: ${fmtJalali(seenAt)}',
                      style: TextStyle(fontSize: 11, color: seenAt == null ? AppColors.red : AppColors.green)),
                ],
              ),
            ),
            FilledButton.tonal(
              onPressed: () => _togglePaid(r),
              style: FilledButton.styleFrom(
                backgroundColor: paid ? AppColors.greenSoft : AppColors.redSoft,
                foregroundColor: paid ? AppColors.green : AppColors.red,
              ),
              child: Text(paid ? '✓ پرداخت شده' : 'پرداخت نشده', style: const TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}
