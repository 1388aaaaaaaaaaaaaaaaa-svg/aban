import 'package:flutter/material.dart';

import '../../api.dart';
import '../../format.dart';
import '../../state.dart';
import '../../theme.dart';
import '../../widgets.dart';
import '../chat/chat_thread.dart';

/// Manager messages: group, direct inbox (per unit) and support.
class MessagesTab extends StatefulWidget {
  const MessagesTab({super.key});

  @override
  State<MessagesTab> createState() => _MessagesTabState();
}

class _MessagesTabState extends State<MessagesTab> {
  int _view = 0; // 0 group, 1 inbox, 2 support

  @override
  Widget build(BuildContext context) {
    final token = appState.managerToken;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
          child: PillTabs(labels: const ['گروه', 'به ساکنین', 'پشتیبانی'], selected: _view, onChanged: (i) => setState(() => _view = i),),
        ),
        Expanded(
          child: IndexedStack(
            index: _view,
            children: [
              _GroupView(token: token),
              const _InboxView(),
              _SupportView(token: token),
            ],
          ),
        ),
      ],
    );
  }
}

class _GroupView extends StatefulWidget {
  final String? token;
  const _GroupView({required this.token});

  @override
  State<_GroupView> createState() => _GroupViewState();
}

class _GroupViewState extends State<_GroupView> {
  String _name = 'گروه ساختمان';
  String _desc = '';

  @override
  void initState() {
    super.initState();
    _loadInfo();
  }

  Future<void> _loadInfo() async {
    try {
      final rows = await rpc('group_info_manager', {'p_token': widget.token}) as List;
      if (rows.isNotEmpty && mounted) {
        final r = rows.first as Map<String, dynamic>;
        setState(() {
          _name = (r['group_name'] ?? _name).toString();
          _desc = (r['group_description'] ?? '').toString();
        });
      }
    } catch (_) {}
  }

  Future<void> _editInfo() async {
    final name = TextEditingController(text: _name);
    final desc = TextEditingController(text: _desc);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('پروفایل گروه'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: 'نام گروه')),
            const SizedBox(height: 10),
            TextField(controller: desc, decoration: const InputDecoration(labelText: 'توضیح')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('ذخیره')),
        ],
      ),
    );
    if (ok == true && name.text.trim().length >= 2) {
      try {
        await rpc('group_update_manager', {
          'p_token': widget.token,
          'p_name': name.text.trim(),
          'p_description': desc.text.trim(),
        });
        await _loadInfo();
      } on ApiException catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
    name.dispose();
    desc.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChatThread(
      emptyText: 'هنوز پیامی در گروه نیست',
      header: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
        child: AppCard(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.blue,
                foregroundColor: Colors.white,
                child: Text(_name.isEmpty ? '؟' : _name.substring(0, 1)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_name, style: const TextStyle(fontWeight: FontWeight.w800)),
                    if (_desc.isNotEmpty)
                      Text(_desc, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                  ],
                ),
              ),
              IconButton(onPressed: _editInfo, icon: const Icon(Icons.edit_outlined), tooltip: 'ویرایش گروه'),
            ],
          ),
        ),
      ),
      load: () async {
        final rows = await rpc('group_list_manager', {'p_token': widget.token}) as List;
        return rows.map((r) {
          final m = r as Map<String, dynamic>;
          return ChatMessage(
            mine: m['sender'] == 'manager',
            senderLabel: (m['sender_label'] ?? '').toString(),
            body: (m['body'] ?? '').toString(),
            createdAt: (m['created_at'] ?? '').toString(),
          );
        }).toList();
      },
      send: (t) async {
        await rpc('group_send_manager', {'p_token': widget.token, 'p_body': t});
      },
    );
  }
}

class _InboxView extends StatefulWidget {
  const _InboxView();

  @override
  State<_InboxView> createState() => _InboxViewState();
}

class _InboxViewState extends State<_InboxView> {
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
      final rows = await rpc('direct_inbox_manager', {'p_token': appState.managerToken}) as List;
      setState(() {
        _rows = rows.cast<Map<String, dynamic>>();
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
    if (_rows.isEmpty) return const EmptyState(text: 'ساکنی ثبت نشده است');
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: _rows.map((r) {
          final newMsg = r['last_sender'] == 'resident';
          final label = (r['unit_label'] ?? '').toString();
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppCard(
              padding: const EdgeInsets.all(12),
              child: InkWell(
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DirectChatPage(unitId: r['unit_id'].toString(), unitLabel: label, residentName: (r['resident_name'] ?? '').toString()),
                    ),
                  );
                  _load();
                },
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.blueLight,
                      foregroundColor: AppColors.blue,
                      child: Text(label),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('واحد $label — ${r['resident_name'] ?? ''}',
                              style: const TextStyle(fontWeight: FontWeight.w700)),
                          Text((r['last_body'] ?? 'بدون پیام').toString(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                        ],
                      ),
                    ),
                    if (newMsg) const Icon(Icons.fiber_manual_record, size: 12, color: AppColors.green),
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

class DirectChatPage extends StatelessWidget {
  final String unitId;
  final String unitLabel;
  final String residentName;
  const DirectChatPage({super.key, required this.unitId, required this.unitLabel, required this.residentName});

  @override
  Widget build(BuildContext context) {
    final token = appState.managerToken;
    return Scaffold(
      appBar: AppBar(title: Text('واحد $unitLabel — $residentName')),
      body: ChatThread(
        emptyText: 'هنوز پیامی نیست',
        load: () async {
          final rows = await rpc('direct_list_manager', {'p_token': token, 'p_unit': unitId}) as List;
          return rows.map((r) {
            final m = r as Map<String, dynamic>;
            return ChatMessage(
              mine: m['sender'] == 'manager',
              senderLabel: (m['sender_label'] ?? '').toString(),
              body: (m['body'] ?? '').toString(),
              createdAt: (m['created_at'] ?? '').toString(),
            );
          }).toList();
        },
        send: (t) async {
          await rpc('direct_send_manager', {'p_token': token, 'p_unit': unitId, 'p_body': t});
        },
      ),
    );
  }
}

class _SupportView extends StatelessWidget {
  final String? token;
  const _SupportView({required this.token});

  @override
  Widget build(BuildContext context) {
    return ChatThread(
      emptyText: 'پیامی برای پشتیبانی نفرستاده‌اید',
      load: () async {
        final rows = await rpc('support_manager_list', {'p_token': token}) as List;
        final out = <ChatMessage>[];
        for (final r in rows.reversed) {
          final m = r as Map<String, dynamic>;
          out.add(ChatMessage(mine: true, senderLabel: 'شما', body: (m['body'] ?? '').toString(), createdAt: (m['created_at'] ?? '').toString()));
          if (m['reply'] != null) {
            out.add(ChatMessage(mine: false, senderLabel: 'پشتیبانی aban AS', body: m['reply'].toString(), createdAt: (m['replied_at'] ?? '').toString()));
          }
        }
        return out;
      },
      send: (t) async {
        await rpc('support_send_manager', {'p_token': token, 'p_body': t});
      },
    );
  }
}
