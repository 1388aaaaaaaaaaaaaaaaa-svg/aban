import 'package:flutter/material.dart';

import '../../api.dart';
import '../../format.dart';
import '../../state.dart';
import '../../theme.dart';
import '../../widgets.dart';
import 'common.dart';

/// Support messages from managers and residents, with replies.
class SupportTab extends StatefulWidget {
  const SupportTab({super.key});

  @override
  State<SupportTab> createState() => _SupportTabState();
}

class _SupportTabState extends State<SupportTab> {
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
      final rows = (await rpc('admin_support_list', {'p_admin_key': appState.adminKey}) as List)
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
    if (_rows.isEmpty) return const EmptyState(text: 'پیامی نیست');
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: _rows.map((r) => _SupportCard(row: r, onSent: _load)).toList(),
      ),
    );
  }
}

class _SupportCard extends StatefulWidget {
  final Map<String, dynamic> row;
  final Future<void> Function() onSent;
  const _SupportCard({required this.row, required this.onSent});

  @override
  State<_SupportCard> createState() => _SupportCardState();
}

class _SupportCardState extends State<_SupportCard> {
  final _reply = TextEditingController();

  @override
  void initState() {
    super.initState();
    _reply.text = (widget.row['reply'] ?? '').toString();
  }

  @override
  void dispose() {
    _reply.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.row;
    final who = r['sender'] == 'resident' ? 'ساکن واحد ${r['unit_label'] ?? ''}' : 'مدیر ساختمان';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${r['building_name'] ?? ''} · ${r['building_code'] ?? ''}',
                style: const TextStyle(fontWeight: FontWeight.w700)),
            Text('$who · ${fmtDateTime(r['created_at']?.toString())}',
                style: const TextStyle(fontSize: 12, color: AppColors.muted)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.blueLight, borderRadius: BorderRadius.circular(12)),
              child: Text((r['body'] ?? '').toString()),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _reply,
              minLines: 1,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'پاسخ شما', border: OutlineInputBorder(), isDense: true),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton(
                onPressed: () async {
                  final text = _reply.text.trim();
                  if (text.isEmpty) return;
                  final ok = await runApi(context, () async {
                    await rpc('admin_support_reply', {
                      'p_admin_key': appState.adminKey,
                      'p_msg': r['msg_id'],
                      'p_reply': text,
                    });
                  }, done: 'پاسخ ثبت شد');
                  if (ok) await widget.onSent();
                },
                child: Text(r['reply'] == null ? 'ارسال پاسخ' : 'ویرایش پاسخ'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
