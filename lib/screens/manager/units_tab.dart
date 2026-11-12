import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../api.dart';
import '../../format.dart';
import '../../input.dart';
import '../../models.dart';
import '../../state.dart';
import '../../theme.dart';
import '../../widgets.dart';
import '../pdf/unit_history_pdf.dart';

/// Units, referral box, add/edit unit and the full history of a unit.
class UnitsTab extends StatefulWidget {
  const UnitsTab({super.key});

  @override
  State<UnitsTab> createState() => _UnitsTabState();
}

class _UnitsTabState extends State<UnitsTab> {
  List<UnitInfo> _units = [];
  bool _loading = true;
  String? _error;
  final _search = TextEditingController();

  Map<String, dynamic>? _referral;
  final _refCode = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    _refCode.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await rpc('list_units', {'p_token': appState.managerToken}) as List;
      final list = rows.map((r) => UnitInfo.fromJson(r as Map<String, dynamic>)).toList();
      list.sort((a, b) => naturalCompare(a.label, b.label));
      final ref = await rpc('referral_info', {'p_token': appState.managerToken}) as List;
      setState(() {
        _units = list;
        _referral = ref.isEmpty ? null : ref.first as Map<String, dynamic>;
      });
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _applyReferral() async {
    try {
      await rpc('use_referral', {'p_token': appState.managerToken, 'p_code': _refCode.text.trim()});
      _refCode.clear();
      _snack('کد معرف ثبت شد');
      await _load();
    } on ApiException catch (e) {
      _snack(e.message);
    }
  }

  void _snack(String t) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));
  }

  Future<void> _call(String phone) => launchUrl(Uri.parse('tel:$phone'));

  Future<void> _sms(UnitInfo u) async {
    final text = '${u.residentName} عزیز، لطفاً قبض آب واحد ${u.label} را پرداخت کنید. aban AS';
    await launchUrl(Uri.parse('sms:${u.phone}?body=${Uri.encodeComponent(text)}'));
  }

  Future<void> _openForm({UnitInfo? unit}) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => UnitForm(unit: unit),
    );
    if (saved == true) await _load();
  }

  Future<void> _openHistory(UnitInfo u) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => UnitHistorySheet(unit: u),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return EmptyState(text: _error!);

    final q = _search.text.trim();
    final shown = q.isEmpty
        ? <UnitInfo>[]
        : _units.where((u) => u.label.contains(q) || u.residentName.contains(q)).take(40).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.blue,
        foregroundColor: Colors.white,
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('ثبت واحد جدید'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
          children: [
            _referralCard(),
            const SizedBox(height: 14),
            TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'جستجوی واحد با شماره یا نام ساکن…',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 10),
            Text('${fmtNum(_units.length)} واحد ثبت شده',
                style: const TextStyle(color: AppColors.muted, fontSize: 13)),
            const SizedBox(height: 8),
            if (q.isEmpty)
              const EmptyState(text: 'برای دیدن واحد، شماره یا نام ساکن را جستجو کنید')
            else if (shown.isEmpty)
              const EmptyState(text: 'واحدی پیدا نشد')
            else
              ...shown.map(_unitCard),
          ],
        ),
      ),
    );
  }

  Widget _referralCard() {
    final r = _referral;
    if (r == null) return const SizedBox.shrink();
    final plan = r['plan']?.toString() ?? 'normal';
    final planText = plan == 'free' ? 'رایگان' : (plan == 'half' ? 'نیم‌بها' : 'عادی');
    final used = r['ref_used'] == true;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('کد معرف و هدیه', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text('کد معرف شما: ${r['ref_code']}', style: const TextStyle(fontSize: 13)),
          Text('تعداد معرفی: ${fmtNum((r['referral_count'] ?? 0) as num)} · وضعیت برنامه: $planText',
              style: const TextStyle(fontSize: 13, color: AppColors.muted)),
          if (!used) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _refCode,
                    textDirection: TextDirection.ltr,
                    decoration: const InputDecoration(hintText: 'REF-XXXXXX', isDense: true),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(onPressed: _applyReferral, child: const Text('ثبت')),
              ],
            ),
            const Text('فقط یک بار می‌توانید کد معرف وارد کنید.',
                style: TextStyle(fontSize: 11, color: AppColors.muted)),
          ],
        ],
      ),
    );
  }

  Widget _unitCard(UnitInfo u) {
    final hasPhone = u.phone != null && u.phone!.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        padding: const EdgeInsets.all(12),
        child: InkWell(
          onTap: () => _openHistory(u),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.blueLight,
                foregroundColor: AppColors.blue,
                child: Text(u.label),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('واحد ${u.label}', style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text(u.residentName.isEmpty ? 'بدون نام' : u.residentName,
                        style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                  ],
                ),
              ),
              if (hasPhone)
                IconButton(
                  onPressed: () => _call(u.phone!),
                  icon: const Icon(Icons.call, color: AppColors.green),
                  tooltip: 'تماس',
                ),
              if (hasPhone)
                IconButton(
                  onPressed: () => _sms(u),
                  icon: const Icon(Icons.sms_outlined, color: AppColors.blue),
                  tooltip: 'پیامک',
                ),
              IconButton(
                onPressed: () => _openForm(unit: u),
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'ویرایش',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 1, 2, ..., 10 (not 1, 10, 2)
int naturalCompare(String a, String b) {
  final na = int.tryParse(RegExp(r'\d+').stringMatch(enDigits(a)) ?? '') ?? 0;
  final nb = int.tryParse(RegExp(r'\d+').stringMatch(enDigits(b)) ?? '') ?? 0;
  return na != nb ? na.compareTo(nb) : a.compareTo(b);
}

class UnitForm extends StatefulWidget {
  final UnitInfo? unit;
  const UnitForm({super.key, this.unit});

  @override
  State<UnitForm> createState() => _UnitFormState();
}

class _UnitFormState extends State<UnitForm> {
  late final _label = TextEditingController(text: widget.unit?.label ?? '');
  late final _name = TextEditingController(text: widget.unit?.residentName ?? '');
  late final _phone = TextEditingController(text: widget.unit?.phone ?? '');
  late final _code = TextEditingController(text: widget.unit?.accessCode ?? '');
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_label, _name, _phone, _code]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_label.text.trim().isEmpty) return setState(() => _error = 'شماره واحد لازم است');
    if (_code.text.trim().isEmpty) return setState(() => _error = 'کد تأیید واحد لازم است');
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await rpc('upsert_unit', {
        'p_token': appState.managerToken,
        'p_label': enDigits(_label.text),
        'p_resident': _name.text.trim(),
        'p_area': 0,
        'p_persons': 1,
        'p_access_code': _code.text.trim(),
        'p_phone': _phone.text.trim().isEmpty ? null : enDigits(_phone.text),
      });
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.unit != null;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(editing ? 'ویرایش واحد ${widget.unit!.label}' : 'ثبت واحد جدید',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          _f(_label, 'شماره یا نام واحد', enabled: !editing),
          _f(_name, 'نام ساکن'),
          _f(_phone, 'شماره تلفن', ltr: true),
          _f(_code, 'کد تأیید واحد (الزامی — ساکن با این کد وارد می‌شود)', ltr: true),
          if (_error != null) Text(_error!, style: const TextStyle(color: AppColors.red)),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _busy ? null : _save,
            style: FilledButton.styleFrom(backgroundColor: AppColors.blue, padding: const EdgeInsets.all(14)),
            child: Text(_busy ? 'در حال ذخیره…' : 'ذخیره'),
          ),
        ],
      ),
    );
  }

  Widget _f(TextEditingController c, String label, {bool ltr = false, bool enabled = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: c,
        enabled: enabled,
        textDirection: ltr ? TextDirection.ltr : null,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      ),
    );
  }
}

/// Full history of one unit across all issued periods, with the total debt.
class UnitHistorySheet extends StatefulWidget {
  final UnitInfo unit;
  const UnitHistorySheet({super.key, required this.unit});

  @override
  State<UnitHistorySheet> createState() => _UnitHistorySheetState();
}

class _UnitHistorySheetState extends State<UnitHistorySheet> {
  List<Map<String, dynamic>> _rows = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final periods = await rpc('list_periods', {'p_token': appState.managerToken}) as List;
      final out = <Map<String, dynamic>>[];
      for (final p in periods) {
        final pm = p as Map<String, dynamic>;
        final bills = await rpc('list_bills', {
          'p_token': appState.managerToken,
          'p_period': pm['period_id'],
        }) as List;
        for (final b in bills) {
          final bm = b as Map<String, dynamic>;
          if (bm['unit_label'] == widget.unit.label) {
            out.add({
              'title': pm['title'],
              'published_at': pm['published_at'],
              'amount_due': bm['amount_due'],
              'paid_amount': bm['paid_amount'],
              'payment_status': bm['payment_status'],
            });
          }
        }
      }
      setState(() => _rows = out);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    num debt = 0;
    for (final r in _rows) {
      if (r['payment_status'] != 'paid') {
        debt += ((r['amount_due'] ?? 0) as num) - ((r['paid_amount'] ?? 0) as num);
      }
    }
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.85,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('واحد ${widget.unit.label} — ${widget.unit.residentName}',
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                ),
                IconButton(
                  onPressed: () => printUnitHistoryPdf(
                    buildingName: appState.managerBuildingName ?? '',
                    unitLabel: widget.unit.label,
                    residentName: widget.unit.residentName,
                    rows: _rows,
                  ),
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  tooltip: 'PDF سابقه',
                ),
              ],
            ),
            const SizedBox(height: 12),
            AppCard(
              child: Row(
                children: [
                  const Text('مجموع بدهی', style: TextStyle(color: AppColors.muted)),
                  const Spacer(),
                  Text(fmtMoney(debt), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? EmptyState(text: _error!)
                      : _rows.isEmpty
                          ? const EmptyState(text: 'قبضی برای این واحد نیست')
                          : ListView(
                              children: _rows
                                  .map((r) => Padding(
                                        padding: const EdgeInsets.only(bottom: 8),
                                        child: AppCard(
                                          padding: const EdgeInsets.all(12),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(r['title'].toString(),
                                                        style: const TextStyle(fontWeight: FontWeight.w700)),
                                                    Text(
                                                        '${fmtMoney((r['amount_due'] ?? 0) as num)} · پرداختی ${fmtMoney((r['paid_amount'] ?? 0) as num)}',
                                                        style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                                                  ],
                                                ),
                                              ),
                                              StatusChip(paid: r['payment_status'] == 'paid'),
                                            ],
                                          ),
                                        ),
                                      ))
                                  .toList(),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

