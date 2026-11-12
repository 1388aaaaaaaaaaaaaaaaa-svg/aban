import 'package:flutter/material.dart';

import '../../api.dart';
import '../../input.dart';
import '../../state.dart';
import '../../theme.dart';
import '../chat/chat_thread.dart';

/// Resident messages: group, direct message to the manager, and support.
class ResidentMessagesTab extends StatefulWidget {
  const ResidentMessagesTab({super.key});

  @override
  State<ResidentMessagesTab> createState() => _ResidentMessagesTabState();
}

class _ResidentMessagesTabState extends State<ResidentMessagesTab> {
  int _view = 0; // 0 group, 1 manager, 2 support

  Map<String, dynamic> get _params => {
        'p_building': appState.residentBuilding,
        'p_unit': appState.residentUnit,
        'p_check': appState.residentCheck,
      };

  /// True when a group message was sent by this unit.
  bool _isMine(Map<String, dynamic> m) {
    final label = enDigits((m['sender_label'] ?? '').toString());
    final unit = enDigits(appState.residentUnit ?? '');
    return m['sender'] == 'resident' && label.endsWith(' $unit');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
          child: SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text('گروه ساختمان')),
              ButtonSegment(value: 1, label: Text('مدیر')),
              ButtonSegment(value: 2, label: Text('پشتیبانی')),
            ],
            selected: {_view},
            onSelectionChanged: (s) => setState(() => _view = s.first),
          ),
        ),
        Expanded(
          child: IndexedStack(
            index: _view,
            children: [
              ChatThread(
                emptyText: 'هنوز پیامی در گروه نیست',
                load: () async {
                  final rows = await rpc('group_list_resident', _params) as List;
                  return rows.map((r) {
                    final m = r as Map<String, dynamic>;
                    return ChatMessage(
                      mine: _isMine(m),
                      senderLabel: (m['sender_label'] ?? '').toString(),
                      body: (m['body'] ?? '').toString(),
                      createdAt: (m['created_at'] ?? '').toString(),
                    );
                  }).toList();
                },
                send: (t) async {
                  await rpc('group_send_resident', {..._params, 'p_body': t});
                },
              ),
              ChatThread(
                emptyText: 'پیامی به مدیر نفرستاده‌اید',
                load: () async {
                  final rows = await rpc('direct_list_resident', _params) as List;
                  return rows.map((r) {
                    final m = r as Map<String, dynamic>;
                    return ChatMessage(
                      mine: m['sender'] == 'resident',
                      senderLabel: 'مدیر ساختمان',
                      body: (m['body'] ?? '').toString(),
                      createdAt: (m['created_at'] ?? '').toString(),
                    );
                  }).toList();
                },
                send: (t) async {
                  await rpc('direct_send_resident', {..._params, 'p_body': t});
                },
              ),
              ChatThread(
                emptyText: 'پیامی برای پشتیبانی نفرستاده‌اید',
                load: () async {
                  final rows = await rpc('support_resident_list', _params) as List;
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
                  await rpc('support_send_resident', {..._params, 'p_body': t});
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
