import 'dart:math';

import 'package:excel/excel.dart' as xl;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../api.dart';
import '../../format.dart';
import '../../input.dart';
import '../../logic/calc.dart';
import '../../logic/jalali.dart';
import '../../models.dart';
import '../../state.dart';
import '../../theme.dart';
import '../../widgets.dart';
import 'units_tab.dart';

/// New bill: readings, optional Excel import, preview, publish.
class PeriodTab extends StatefulWidget {
  const PeriodTab({super.key});

  @override
  State<PeriodTab> createState() => _PeriodTabState();
}

class _UnitField {
  final UnitInfo unit;
  final bool prevVisible; // true only when the unit has no previous bill
  final prev = TextEditingController();
  final cur = TextEditingController();
  final penalty = TextEditingController();
  _UnitField(this.unit, this.prevVisible);
  void dispose() {
    prev.dispose();
    cur.dispose();
    penalty.dispose();
  }
}

class _PeriodTabState extends State<PeriodTab> {
  bool _loading = true;
  String? _error;
  List<_UnitField> _fields = [];
  Map<String, num> _lastCur = {};

  final _title = TextEditingController();
  final _limit = TextEditingController();
  final _dueDay = TextEditingController();
  final _dueYear = TextEditingController();
  int _dueMonth = 1;
  String _mode = 'split';
  final _amount = TextEditingController();
  final _rate = TextEditingController();
  final _abon = TextEditingController(text: '0');
  String _abonMode = 'total';

  CalcResult? _preview;
  bool _busy = false;
  String? _formError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final f in _fields) {
      f.dispose();
    }
    for (final c in [_title, _limit, _dueDay, _dueYear, _amount, _rate, _abon]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final units = (await rpc('list_units', {'p_token': appState.managerToken}) as List)
          .map((r) => UnitInfo.fromJson(r as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => naturalCompare(a.label, b.label));
      final last = await rpc('last_readings', {'p_token': appState.managerToken}) as List;
      final map = <String, num>{};
      for (final r in last) {
        final m = r as Map<String, dynamic>;
        map[m['unit_label'].toString()] = (m['cur_reading'] ?? 0) as num;
      }
      for (final f in _fields) {
        f.dispose();
      }
      setState(() {
        _lastCur = map;
        _fields = units.map((u) => _UnitField(u, !map.containsKey(u.label))).toList();
      });
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ---------- Excel ----------
  Future<void> _importExcel() async {
    final pick = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['xlsx'], withData: true);
    if (pick == null || pick.files.single.bytes == null) return;
    try {
      final book = xl.Excel.decodeBytes(pick.files.single.bytes!);
      final sheet = book.tables[book.tables.keys.first]!;
      final rows = sheet.rows;
      int header = -1, uc = -1, mc = -1, pc = -1;
      for (var r = 0; r < rows.length && header < 0; r++) {
        final cells = rows[r].map(_cellText).toList();
        final u = cells.indexWhere((c) => c.contains('واحد'));
        if (u < 0) continue;
        header = r;
        uc = u;
        mc = cells.indexWhere((c) => RegExp(r'کنتور|فعلی|قرائت').hasMatch(c));
        pc = cells.indexWhere((c) => c.contains('قبلی'));
      }
      if (header < 0 || mc < 0) throw ApiException('ستون «واحد» یا عدد کنتور در فایل پیدا نشد');
      var ok = 0;
      final missing = <String>[];
      for (var r = header + 1; r < rows.length; r++) {
        final label = _normLabel(_cellAt(rows[r], uc));
        if (label.isEmpty) continue;
        final f = _fields.where((x) => _normLabel(x.unit.label) == label).toList();
        if (f.isEmpty) {
          missing.add(label);
          continue;
        }
        final cur = parseNum(_cellAt(rows[r], mc));
        if (cur == null) continue;
        f.first.cur.text = enDigits(cur.toString());
        if (pc >= 0 && f.first.prevVisible) {
          final pv = parseNum(_cellAt(rows[r], pc));
          if (pv != null) f.first.prev.text = enDigits(pv.toString());
        }
        ok++;
      }
      _snack('کنتور $ok واحد خوانده شد${missing.isEmpty ? '' : ' · واحد پیدا نشد: ${missing.join('، ')}'}');
      setState(() => _preview = null);
    } on ApiException catch (e) {
      _snack(e.message);
    } catch (_) {
      _snack('فایل اکسل خوانده نشد؛ فایل xlsx را بررسی کنید');
    }
  }

  String _cellAt(List<dynamic> row, int idx) => (idx < 0 || idx >= row.length) ? '' : _cellText(row[idx]);

  String _cellText(dynamic d) {
    if (d == null) return '';
    final v = d is xl.Data ? d.value : d;
    return v?.toString() ?? '';
  }

  String _normLabel(String s) => enDigits(s).replaceAll('واحد', '').replaceAll(' ', '').trim();

  // ---------- preview / publish ----------
  CalcResult _calculate() {
    final due = _dueDate();
    final units = <UnitReading>[];
    for (final f in _fields) {
      final cur = parseNum(f.cur.text);
      if (cur == null) throw Exception('عدد فعلی کنتور واحد ${f.unit.label} را وارد کنید');
      final num prev;
      if (_lastCur.containsKey(f.unit.label)) {
        prev = _lastCur[f.unit.label]!;
      } else {
        final p = parseNum(f.prev.text);
        if (p == null) throw Exception('عدد قبلی کنتور واحد ${f.unit.label} را وارد کنید (اولین قبض)');
        prev = p;
      }
      final pen = parseNum(f.penalty.text) ?? 0;
      units.add(UnitReading(label: f.unit.label, prev: prev, cur: cur, penalty: pen));
    }
    final limit = parseNum(_limit.text);
    if (limit == null) throw Exception('حد مجاز این دوره را وارد کنید');
    final abon = parseInt(_abon.text) ?? 0;
    return calculate(
      title: _title.text,
      limit: limit,
      abon: abon,
      abonMode: _abonMode,
      mode: _mode,
      amount: parseInt(_amount.text),
      rate: parseNum(_rate.text),
      due: due,
      units: units,
    );
  }

  String? _dueDate() {
    final d = parseInt(_dueDay.text);
    final y = parseInt(_dueYear.text);
    if (d == null && y == null) return null;
    if (d == null || y == null) throw Exception('مهلت پرداخت را کامل وارد کنید (روز و سال)');
    final iso = isoFromJalali(y, _dueMonth, d);
    if (iso == null) throw Exception('تاریخ مهلت معتبر نیست');
    return iso;
  }

  void _doPreview() {
    try {
      final r = _calculate();
      setState(() {
        _preview = r;
        _formError = null;
      });
    } catch (e) {
      setState(() {
        _preview = null;
        _formError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _publish() async {
    final r = _preview;
    if (r == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: const Text('این صورت‌حساب‌ها منتشر شوند؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('منتشر کن')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      final token = appState.managerToken;
      final pid = (await rpc('save_period', {
        'p_token': token,
        'p_title': r.title,
        'p_main_bill': r.total + r.penaltyTotal,
        'p_main_prev': 0,
        'p_main_cur': r.rows.fold<num>(0, (s, x) => s + x.adjusted),
        'p_method': 'consumption',
        'p_due_date': r.due,
      })).toString();
      await rpc('save_readings', {
        'p_token': token,
        'p_period': pid,
        'p_rows': r.rows.map((x) => {'label': x.label, 'prev': x.prev, 'cur': x.cur}).toList(),
      });
      await rpc('publish_bills', {
        'p_token': token,
        'p_period': pid,
        'p_rows': r.rows
            .map((x) => {
                  'label': x.label,
                  'cons': x.cons,
                  'share': 0,
                  'amount': x.amount,
                  'vc': _code8(),
                })
            .toList(),
        'p_period_code': null,
      });
      await rpc('save_tariff_details', {'p_token': token, 'p_period': pid, 'p_details': r.toJson()});
      _snack('قبض‌ها منتشر شدند');
      _clearAll();
      await _load();
    } on ApiException catch (e) {
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _code8() {
    final rnd = Random.secure();
    const chars = '0123456789abcdef';
    return List.generate(8, (_) => chars[rnd.nextInt(16)]).join();
  }

  void _clearAll() {
    for (final c in [_title, _limit, _dueDay, _dueYear, _amount, _rate]) {
      c.clear();
    }
    for (final f in _fields) {
      f.cur.clear();
      f.prev.clear();
      f.penalty.clear();
    }
    setState(() => _preview = null);
  }

  void _snack(String t) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return EmptyState(text: _error!);
    if (_fields.isEmpty) return const EmptyState(text: 'ابتدا واحدها را ثبت کنید');

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
      children: [
        const Text('صدور قبض', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.text)),
        const SizedBox(height: 2),
        Text('${fmtNum(_fields.length)} واحد · دوره را وارد کنید و کنتورها را بنویسید',
            style: const TextStyle(color: AppColors.muted, fontSize: 13)),
        const SizedBox(height: 16),
        _section('اطلاعات دوره', [
          _tf(_title, 'عنوان دوره', hint: 'مثلاً آبان ۱۴۰۵'),
          _tf(_limit, 'حد مجاز مصرف (متر مکعب)', number: true),
          Row(
            children: [
              Expanded(child: _tf(_dueDay, 'روز', number: true)),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: DropdownButtonFormField<int>(
                    value: _dueMonth,
                    decoration: _deco('ماه'),
                    items: List.generate(12, (i) => DropdownMenuItem(value: i + 1, child: Text(jMonths[i]))),
                    onChanged: (v) => setState(() => _dueMonth = v ?? 1),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(child: _tf(_dueYear, 'سال', number: true)),
            ],
          ),
        ]),
        _section('محاسبه', [
          PillTabs(
            labels: const ['تقسیم مبلغ کل', 'نرخ هر متر مکعب'],
            selected: _mode == 'split' ? 0 : 1,
            onChanged: (i) => setState(() => _mode = i == 0 ? 'split' : 'rate'),
          ),
          const SizedBox(height: 12),
          if (_mode == 'split')
            _tf(_amount, 'مبلغ کل قبض اصلی (تومان)', number: true)
          else
            _tf(_rate, 'نرخ هر متر مکعب (تومان)', number: true),
          _tf(_abon, 'آبونمان (تومان)', number: true),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: DropdownButtonFormField<String>(
              value: _abonMode,
              decoration: _deco('نوع آبونمان'),
              items: const [
                DropdownMenuItem(value: 'total', child: Text('کل ساختمان، تقسیم مساوی')),
                DropdownMenuItem(value: 'unit', child: Text('ثابت برای هر واحد')),
              ],
              onChanged: (v) => setState(() => _abonMode = v ?? 'total'),
            ),
          ),
        ]),
        _section('کنتورها', [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: AppColors.blueLight, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.table_chart_outlined, color: AppColors.blue),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('کنتورها را از فایل اکسل وارد کنید',
                    style: TextStyle(fontSize: 13, color: AppColors.muted)),
              ),
              TextButton(onPressed: _importExcel, child: const Text('اکسل')),
            ],
          ),
          const SizedBox(height: 8),
          ..._fields.map(_unitRow),
        ]),
        if (_formError != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 8),
            child: Text(_formError!, style: const TextStyle(color: AppColors.red, fontSize: 13)),
          ),
        const SizedBox(height: 4),
        SizedBox(
          height: 50,
          child: OutlinedButton(
            onPressed: _busy ? null : _doPreview,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.blue,
              side: const BorderSide(color: AppColors.blue2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('محاسبه و پیش‌نمایش', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ),
        if (_preview != null) ...[
          const SizedBox(height: 14),
          _previewCard(_preview!),
          const SizedBox(height: 12),
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: _busy ? null : _publish,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.green,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(_busy ? 'در حال انتشار…' : 'انتشار قبض‌ها',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ),
        ],
      ],
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Color(0x0F000000), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.text)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _unitRow(_UnitField f) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 15,
                backgroundColor: Colors.white,
                foregroundColor: AppColors.blue,
                child: Text(f.unit.label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(f.unit.residentName.isEmpty ? 'بدون نام' : f.unit.residentName,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (f.prevVisible) ...[
                Expanded(child: _tf(f.prev, 'عدد قبلی', number: true)),
                const SizedBox(width: 8),
              ],
              Expanded(child: _tf(f.cur, 'عدد فعلی', number: true)),
              const SizedBox(width: 8),
              Expanded(child: _tf(f.penalty, 'جریمه', number: true)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _previewCard(CalcResult r) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.blueLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(r.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          Text('حد مجاز: ${fmtNum(r.limit)} متر مکعب', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
          const SizedBox(height: 10),
          ...r.rows.map((x) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Text('واحد ${x.label}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    Text('مصرف ${fmtNum(x.cons)}', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                    const Spacer(),
                    Text(fmtMoney(x.amount), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  ],
                ),
              )),
          const Divider(height: 22),
          Row(
            children: [
              const Text('جمع قبض‌ها', style: TextStyle(fontWeight: FontWeight.w700)),
              const Spacer(),
              Text(fmtMoney(r.total + r.penaltyTotal),
                  style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.blue, fontSize: 16)),
            ],
          ),
        ],
      ),
    );
  }

  InputDecoration _deco(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.blueLight)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.blueLight)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.blue2, width: 1.5)),
    );
  }

  Widget _tf(TextEditingController c, String label, {String? hint, bool number = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        keyboardType: number ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
        decoration: _deco(label, hint: hint),
      ),
    );
  }
}
