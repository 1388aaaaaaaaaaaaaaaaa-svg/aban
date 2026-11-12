import 'package:flutter/material.dart';

import '../../api.dart';
import '../../format.dart';
import '../../state.dart';
import '../../widgets.dart';
import 'common.dart';

/// All activity of all buildings (who did what and where).
class ActivityTab extends StatefulWidget {
  const ActivityTab({super.key});

  @override
  State<ActivityTab> createState() => _ActivityTabState();
}

class _ActivityTabState extends State<ActivityTab> {
  List<Map<String, dynamic>> _rows = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final rows = (await rpc('admin_activity_list', {'p_admin_key': appState.adminKey, 'p_limit': 300}) as List)
          .cast<Map<String, dynamic>>();
      setState(() {
        _rows = rows;
        _error = null;
      });
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
    if (_rows.isEmpty) return const EmptyState(text: 'فعالیتی ثبت نشده است');
    final who = {'manager': 'مدیر', 'resident': 'ساکن'};
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: _rows.map((r) {
          final actor = who[r['actor']] ?? (r['actor'] ?? '').toString();
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: AppCard(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${r['building_name'] ?? ''} — ${r['action']} ($actor)',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  if ((r['details'] ?? '').toString().isNotEmpty) Text(r['details'].toString(), style: const TextStyle(fontSize: 13)),
                  infoLine(fmtDateTime(r['created_at']?.toString())),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
