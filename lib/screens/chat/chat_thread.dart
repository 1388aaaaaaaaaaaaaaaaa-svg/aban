import 'dart:async';

import 'package:flutter/material.dart';

import '../../api.dart';
import '../../format.dart';
import '../../theme.dart';

class ChatMessage {
  final bool mine;
  final String senderLabel;
  final String body;
  final String createdAt;
  ChatMessage({required this.mine, required this.senderLabel, required this.body, required this.createdAt});
}

/// A conversation: bubbles + composer. Reloads every 12 seconds.
class ChatThread extends StatefulWidget {
  final Future<List<ChatMessage>> Function() load;
  final Future<void> Function(String text) send;
  final String emptyText;
  final Widget? header;

  const ChatThread({
    super.key,
    required this.load,
    required this.send,
    required this.emptyText,
    this.header,
  });

  @override
  State<ChatThread> createState() => _ChatThreadState();
}

class _ChatThreadState extends State<ChatThread> {
  List<ChatMessage> _items = [];
  bool _loading = true;
  bool _sending = false;
  String? _error;
  final _text = TextEditingController();
  final _scroll = ScrollController();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _reload();
    _timer = Timer.periodic(const Duration(seconds: 12), (_) => _reload(silent: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _text.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _reload({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    try {
      final items = await widget.load();
      if (!mounted) return;
      setState(() {
        _items = items;
        _error = null;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'بارگذاری انجام نشد');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    final t = _text.text.trim();
    if (t.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await widget.send(t);
      _text.clear();
      await _reload(silent: true);
    } on ApiException catch (e) {
      _snack(e.message);
    } catch (_) {
      _snack('ارسال انجام نشد');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _snack(String t) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.header != null) widget.header!,
        Expanded(
          child: _loading && _items.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : _error != null && _items.isEmpty
                  ? Center(child: Text(_error!, style: const TextStyle(color: AppColors.muted)))
                  : _items.isEmpty
                      ? Center(child: Text(widget.emptyText, style: const TextStyle(color: AppColors.muted)))
                      : RefreshIndicator(
                          onRefresh: () => _reload(silent: true),
                          child: ListView.builder(
                            controller: _scroll,
                            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                            itemCount: _items.length,
                            itemBuilder: (_, i) => _bubble(_items[i], i),
                          ),
                        ),
        ),
        SafeArea(
          top: false,
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _text,
                    minLines: 1,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'پیام بنویسید…',
                      filled: true,
                      fillColor: AppColors.bg,
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _sending ? null : _send,
                  icon: _sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.send),
                  style: IconButton.styleFrom(backgroundColor: AppColors.blue),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _bubble(ChatMessage m, int i) {
    final showLabel = !m.mine && (i == 0 || _items[i - 1].senderLabel != m.senderLabel || _items[i - 1].mine);
    return Align(
      alignment: m.mine ? Alignment.centerLeft : Alignment.centerRight,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        child: Column(
          crossAxisAlignment: m.mine ? CrossAxisAlignment.start : CrossAxisAlignment.end,
          children: [
            if (showLabel)
              Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 2, right: 4, left: 4),
                child: Text(m.senderLabel,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.blue)),
              ),
            Container(
              margin: const EdgeInsets.symmetric(vertical: 2),
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
              decoration: BoxDecoration(
                color: m.mine ? AppColors.blue : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 6, offset: Offset(0, 2))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(m.body,
                      style: TextStyle(color: m.mine ? Colors.white : AppColors.text, fontSize: 14, height: 1.5)),
                  const SizedBox(height: 2),
                  Text(fmtDateTime(m.createdAt),
                      style: TextStyle(
                          fontSize: 10, color: m.mine ? Colors.white70 : AppColors.muted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
