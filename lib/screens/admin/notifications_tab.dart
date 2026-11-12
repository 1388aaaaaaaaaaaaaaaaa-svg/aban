import 'package:flutter/material.dart';

import '../../api.dart';
import '../../format.dart';
import '../../state.dart';
import '../../theme.dart';
import '../../widgets.dart';
import 'common.dart';

/// Milestones (5 and 10 referrals) and other admin notifications.
class NotificationsTab extends StatefulWidget {
  final VoidCallback? onUnreadChanged;
  const NotificationsTab({super.key, this.onUnreadChanged});

  @override
  State<NotificationsTab> createState() => _NotificationsTabState();
}

class _NotificationsTabState extends State<NotificationsTab> {
  List<Map<String, dynamic>> _rows = [];
  Set<dynamic> _unreadIds = {};
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
      final rows = (await rpc('admin_notifications', {'p_admin_key': appState.adminKey}) as List)
          .cast<Map<String, dynamic>>();
      final unread = rows.where((r) => r['is_read'] != true).map((r) => r['notif_id']).toSet();
      await rpc('admin_notifications_read', {'p_admin_key': appState.adminKey});
      setState(() {
        _rows = rows;
        _unreadIds = unread;
        _error = null;
      });
      widget.onUnreadChanged?.call();
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
    if (_rows.isEmpty) return const EmptyState(text: 'اعلانی نیست');
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: _rows.map((r) {
          final isNew = _unreadIds.contains(r['notif_id']);
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppCard(
              child: Row(
                children: [
                  Icon(Icons.emoji_events_outlined, color: isNew ? AppColors.green : AppColors.muted),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text((r['building_name'] ?? '').toString(), style: const TextStyle(fontWeight: FontWeight.w700)),
                        Text((r['body'] ?? '').toString(), style: const TextStyle(fontSize: 13)),
                        infoLine(fmtDateTime(r['created_at']?.toString())),
                      ],
                    ),
                  ),
                  if (isNew) const Icon(Icons.fiber_manual_record, size: 12, color: AppColors.green),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
