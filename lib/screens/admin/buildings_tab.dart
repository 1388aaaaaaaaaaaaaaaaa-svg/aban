import 'package:flutter/material.dart';

import '../../api.dart';
import '../../format.dart';
import '../../state.dart';
import '../../theme.dart';
import '../../widgets.dart';
import 'common.dart';

class BuildingsTab extends StatefulWidget {
  const BuildingsTab({super.key});

  @override
  State<BuildingsTab> createState() => _BuildingsTabState();
}

class _BuildingsTabState extends State<BuildingsTab> {
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
      final rows = await rpc('admin_buildings_full', {'p_admin_key': appState.adminKey}) as List;
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
    if (_rows.isEmpty) return const EmptyState(text: 'ساختمانی ثبت نشده است');
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: _rows.map((b) {
          final active = b['is_active'] == true;
          final plan = b['plan']?.toString() ?? 'normal';
          final planText = plan == 'free' ? 'رایگان' : (plan == 'half' ? 'نیم‌بها' : 'عادی');
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppCard(
              padding: const EdgeInsets.all(12),
              child: InkWell(
                onTap: () async {
                  final changed = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(builder: (_) => BuildingDetailPage(building: b)),
                  );
                  if (changed == true) _load();
                },
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(b['name']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w700)),
                          Text('${b['code']} · ${b['city'] ?? ''}',
                              style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                          const SizedBox(height: 4),
                          Text('طرح: $planText · معرفی: ${fmtNum((b['referral_count'] ?? 0) as num)}',
                              style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                    Chip(
                      label: Text(active ? 'فعال' : 'قطع', style: const TextStyle(fontSize: 11)),
                      backgroundColor: active ? AppColors.greenSoft : AppColors.redSoft,
                    ),
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

class BuildingDetailPage extends StatefulWidget {
  final Map<String, dynamic> building;
  const BuildingDetailPage({super.key, required this.building});

  @override
  State<BuildingDetailPage> createState() => _BuildingDetailPageState();
}

class _BuildingDetailPageState extends State<BuildingDetailPage> {
  late Map<String, dynamic> b = Map<String, dynamic>.from(widget.building);
  bool _changed = false;

  String get _code => b['code'].toString();
  String get _key => appState.adminKey ?? '';

  Future<void> _reloadOne() async {
    try {
      final rows = await rpc('admin_buildings_full', {'p_admin_key': _key}) as List;
      final found = rows.cast<Map<String, dynamic>>().where((r) => r['code'] == _code);
      if (found.isNotEmpty && mounted) setState(() => b = found.first);
    } catch (_) {}
  }

  void _open(Widget page) => Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  Future<void> _editManager({required bool newManager}) async {
    final vals = await askFields(context,
        title: newManager ? 'ثبت مدیر جدید' : 'ویرایش مدیر',
        fields: [
          FieldSpec('name', 'نام مدیر', initial: newManager ? '' : (b['manager_name'] ?? '').toString()),
          FieldSpec('phone', 'شماره تلفن', initial: newManager ? '' : (b['manager_phone'] ?? '').toString(), ltr: true),
          if (newManager) const FieldSpec('pass', 'رمز جدید (حداقل ۸ نویسه)', obscure: true),
        ]);
    if (vals == null) return;
    if (newManager && (vals['pass'] ?? '').length < 8) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('رمز باید حداقل ۸ نویسه باشد')));
      return;
    }
    final ok = await runApi(context, () async {
      await rpc('admin_update_manager', {
        'p_admin_key': _key,
        'p_code': _code,
        'p_name': vals['name'],
        'p_phone': vals['phone'],
        'p_password': newManager ? vals['pass'] : null,
      });
    }, done: 'اطلاعات مدیر ذخیره شد');
    if (ok) {
      _changed = true;
      _reloadOne();
    }
  }

  Future<void> _rename() async {
    final vals = await askFields(context, title: 'تغییر نام ساختمان',
        fields: [FieldSpec('name', 'نام جدید', initial: (b['name'] ?? '').toString())]);
    if (vals == null) return;
    final ok = await runApi(context, () async {
      await rpc('admin_rename_building', {'p_admin_key': _key, 'p_code': _code, 'p_name': vals['name']});
    }, done: 'نام ساختمان تغییر کرد');
    if (ok) {
      _changed = true;
      _reloadOne();
    }
  }

  Future<void> _toggleAccess() async {
    final active = b['is_active'] == true;
    if (!await confirm(context, active ? 'دسترسی مدیر این ساختمان قطع شود؟' : 'دسترسی مدیر فعال شود؟')) return;
    final ok = await runApi(context, () async {
      await rpc('admin_set_building_access', {'p_admin_key': _key, 'p_code': _code, 'p_active': !active});
    }, done: 'انجام شد');
    if (ok) {
      _changed = true;
      _reloadOne();
    }
  }

  @override
  Widget build(BuildContext context) {
    final active = b['is_active'] == true;
    final plan = b['plan']?.toString() ?? 'normal';
    final planText = plan == 'free' ? 'رایگان' : (plan == 'half' ? 'نیم‌بها' : 'عادی');
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {}
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(b['name']?.toString() ?? ''),
          leading: BackButton(onPressed: () => Navigator.pop(context, _changed)),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('کد ساختمان: $_code', style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text('مدیر: ${b['manager_name'] ?? '—'} · ${b['manager_phone'] ?? ''}',
                      style: const TextStyle(fontSize: 13)),
                  Text('شهر: ${b['city'] ?? '—'}', style: const TextStyle(fontSize: 13)),
                  Text('دسترسی مدیر: ${active ? 'فعال' : 'قطع'} · طرح: $planText',
                      style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _action(Icons.manage_accounts_outlined, 'ویرایش مدیر', () => _editManager(newManager: false)),
            _action(Icons.person_add_alt_1_outlined, 'ثبت مدیر جدید', () => _editManager(newManager: true)),
            _action(Icons.drive_file_rename_outline, 'عوض کردن اسم ساختمان', _rename),
            _action(Icons.history, 'گزارش فعالیت ساختمان',
                () => _open(BuildingActivityPage(code: _code))),
            _action(Icons.forum_outlined, 'دیدن گروه ساختمان', () => _open(BuildingGroupPage(code: _code))),
            _action(Icons.home_work_outlined, 'واحدهایی که مدیر اضافه کرده',
                () => _open(BuildingUnitsPage(code: _code))),
            _action(Icons.card_giftcard_outlined, 'تعداد معرفی', () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('معرفی'),
                  content: Text(
                    'تعداد معرفی: ${fmtNum((b['referral_count'] ?? 0) as num)}\n'
                    'کد معرف: ${b['ref_code'] ?? '—'}\n'
                    'وضعیت برنامه: $planText',
                  ),
                  actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('بستن'))],
                ),
              );
            }),
            _action(
              active ? Icons.block : Icons.check_circle_outline,
              active ? 'قطع دسترسی مدیر' : 'فعال‌سازی دسترسی مدیر',
              _toggleAccess,
              danger: active,
            ),
          ],
        ),
      ),
    );
  }

  Widget _action(IconData icon, String text, VoidCallback onTap, {bool danger = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        padding: EdgeInsets.zero,
        child: ListTile(
          leading: Icon(icon, color: danger ? AppColors.red : AppColors.blue),
          title: Text(text, style: TextStyle(color: danger ? AppColors.red : AppColors.text, fontWeight: FontWeight.w600)),
          trailing: const Icon(Icons.chevron_left),
          onTap: onTap,
        ),
      ),
    );
  }
}

class BuildingActivityPage extends StatelessWidget {
  final String code;
  const BuildingActivityPage({super.key, required this.code});

  @override
  Widget build(BuildContext context) {
    return _ListPage(
      title: 'گزارش فعالیت',
      load: () async => (await rpc('admin_building_activity', {'p_admin_key': appState.adminKey, 'p_code': code}) as List)
          .cast<Map<String, dynamic>>(),
      render: (r) {
        final who = {'manager': 'مدیر', 'resident': 'ساکن'}[r['actor']] ?? (r['actor'] ?? '').toString();
        return _Line(
          title: '${r['action']} ($who)',
          body: (r['details'] ?? '').toString(),
          time: r['created_at']?.toString(),
        );
      },
    );
  }
}

class BuildingGroupPage extends StatelessWidget {
  final String code;
  const BuildingGroupPage({super.key, required this.code});

  @override
  Widget build(BuildContext context) {
    return _ListPage(
      title: 'گروه ساختمان (فقط خواندنی)',
      load: () async => (await rpc('admin_building_group', {'p_admin_key': appState.adminKey, 'p_code': code}) as List)
          .cast<Map<String, dynamic>>(),
      render: (r) => _Line(
        title: (r['sender_label'] ?? '').toString(),
        body: (r['body'] ?? '').toString(),
        time: r['created_at']?.toString(),
      ),
    );
  }
}

class BuildingUnitsPage extends StatelessWidget {
  final String code;
  const BuildingUnitsPage({super.key, required this.code});

  @override
  Widget build(BuildContext context) {
    return _ListPage(
      title: 'واحدها',
      load: () async => (await rpc('admin_building_units', {'p_admin_key': appState.adminKey, 'p_code': code}) as List)
          .cast<Map<String, dynamic>>(),
      render: (r) => _Line(
        title: 'واحد ${r['label']} — ${r['resident_name'] ?? ''}',
        body: 'تلفن: ${r['phone'] ?? '—'} · کد تأیید: ${r['access_code'] ?? '—'} · ${r['is_active'] == true ? 'فعال' : 'غیرفعال'}',
        time: null,
      ),
    );
  }
}

class _ListPage extends StatefulWidget {
  final String title;
  final Future<List<Map<String, dynamic>>> Function() load;
  final Widget Function(Map<String, dynamic>) render;
  const _ListPage({required this.title, required this.load, required this.render});

  @override
  State<_ListPage> createState() => _ListPageState();
}

class _ListPageState extends State<_ListPage> {
  List<Map<String, dynamic>> _rows = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    try {
      final rows = await widget.load();
      setState(() => _rows = rows);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'بارگذاری انجام نشد');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? EmptyState(text: _error!)
              : _rows.isEmpty
                  ? const EmptyState(text: 'موردی نیست')
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: _rows.map((r) => Padding(padding: const EdgeInsets.only(bottom: 8), child: widget.render(r))).toList(),
                    ),
    );
  }
}

class _Line extends StatelessWidget {
  final String title;
  final String body;
  final String? time;
  const _Line({required this.title, required this.body, this.time});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          if (body.isNotEmpty) Text(body, style: const TextStyle(fontSize: 13)),
          if (time != null && time!.isNotEmpty) infoLine(fmtDateTime(time)),
        ],
      ),
    );
  }
}
