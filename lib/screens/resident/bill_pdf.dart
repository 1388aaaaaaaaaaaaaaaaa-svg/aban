import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../api.dart';
import '../../format.dart';
import '../../state.dart';
import '../pdf/pdf_common.dart';

const _blue = PdfColor.fromInt(0xFF185FA5);
const _blueDeep = PdfColor.fromInt(0xFF0C447C);
const _blueSoft = PdfColor.fromInt(0xFFE6F1FB);
const _blueMid = PdfColor.fromInt(0xFF378ADD);
const _greenSoft = PdfColor.fromInt(0xFFE1F5EE);
const _greenDeep = PdfColor.fromInt(0xFF04342C);
const _muted = PdfColor.fromInt(0xFF5D7A90);
const _white = PdfColors.white;

pw.Widget _cell(String label, String value, {PdfColor bg = _blueSoft, PdfColor fg = _blueDeep, PdfColor labelColor = _blue}) {
  return pw.Expanded(
    child: pw.Container(
      margin: const pw.EdgeInsets.all(3),
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: pw.BoxDecoration(color: bg, borderRadius: pw.BorderRadius.circular(10)),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 8.5, color: labelColor)),
          pw.SizedBox(height: 3),
          pw.Text(value, style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold, color: fg)),
        ],
      ),
    ),
  );
}

pw.Widget _row(String label, String value, {bool last = false, bool bold = false}) {
  return pw.Container(
    padding: const pw.EdgeInsets.symmetric(vertical: 7, horizontal: 12),
    decoration: pw.BoxDecoration(
      border: last ? null : pw.Border(bottom: pw.BorderSide(color: _blueSoft, width: 1)),
    ),
    child: pw.Row(textDirection: pw.TextDirection.rtl, 
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 10, color: _muted)),
        pw.Text(value, style: pw.TextStyle(fontSize: 10, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
      ],
    ),
  );
}

/// Prints the current bill of the resident's unit on one A4 page, in the web design.
Future<void> printResidentBill() async {
  final p = {
    'p_building': appState.residentBuilding,
    'p_unit': appState.residentUnit,
    'p_check': appState.residentCheck,
  };
  final cur = await rpc('get_unit_bill', p) as List;
  if (cur.isEmpty) throw ApiException('قبض منتشرشده‌ای وجود ندارد');
  final b = cur.first as Map<String, dynamic>;

  final hist = (await rpc('get_unit_history', p) as List).cast<Map<String, dynamic>>();
  final det = await rpc('get_tariff_details', p);
  final d = det is Map ? det['details'] as Map<String, dynamic>? : null;
  final bank = await rpc('get_building_bank_info', p) as Map<String, dynamic>?;

  final amount = (b['amount_due'] ?? 0) as num;
  final paid = (b['paid_amount'] ?? 0) as num;
  final balance = (b['balance'] ?? 0) as num;
  final isPaid = b['payment_status'] == 'paid';

  num prevDebt = 0;
  for (final h in hist) {
    if (h['period_title'] != b['period_title'] && h['payment_status'] != 'paid') {
      prevDebt += (h['balance'] ?? 0) as num;
    }
  }
  final totalDebt = prevDebt + (isPaid ? 0 : balance);

  num? water, abon, penalty;
  if (d != null) {
    water = (d['water'] ?? 0) as num;
    abon = (d['abon'] ?? 0) as num;
    penalty = amount - water - abon;
  }

  final cardRaw = (bank?['card_number'] ?? '').toString().replaceAll(RegExp(r'\D'), '');
  final cardText = cardRaw.isEmpty
      ? '•••• •••• •••• ••••'
      : RegExp(r'.{1,4}').allMatches(cardRaw).map((m) => m.group(0)).join(' ');

  final blockBorder = pw.Border.all(color: _blueSoft, width: 1);

  await printA4Page([
    // header band
    pw.Container(
      padding: const pw.EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: pw.BoxDecoration(color: _blue, borderRadius: pw.BorderRadius.circular(18)),
      child: pw.Column(
        children: [
          pw.Text('صورتحساب مصرف آب · ${b['period_title'] ?? ''}',
              style: const pw.TextStyle(color: _white, fontSize: 11)),
        ],
      ),
    ),
    pw.SizedBox(height: 10),
    // building card
    pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: pw.BoxDecoration(
        color: _white,
        border: pw.Border.all(color: _blueSoft, width: 1),
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Column(
        children: [
          pw.Text('ساختمان', style: const pw.TextStyle(fontSize: 9, color: _blue)),
          pw.SizedBox(height: 3),
          pw.Text((b['building_name'] ?? '').toString(),
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: _blueDeep)),
        ],
      ),
    ),
    pw.SizedBox(height: 10),
    // sentence-style lines, right to left
    pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: pw.BoxDecoration(color: _blueSoft, borderRadius: pw.BorderRadius.circular(12)),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Text('واحد ${b['unit_label'] ?? ''}',
              textAlign: pw.TextAlign.right,
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: _blueDeep)),
          pw.SizedBox(height: 4),
          pw.Text('ساکن: ${b['resident_name'] ?? '—'}',
              textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 11, color: _blueDeep)),
          pw.SizedBox(height: 4),
          pw.Text('مصرف: ${fmtNum((b['consumption'] ?? 0) as num)} متر مکعب',
              textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 11, color: _blueDeep)),
          pw.SizedBox(height: 4),
          pw.Text('مبلغ قابل پرداخت: ${fmtMoney(amount)}',
              textAlign: pw.TextAlign.right,
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: _blueDeep)),
          pw.SizedBox(height: 4),
          pw.Text('مهلت پرداخت: ${fmtJalali(b['due_date']?.toString())}',
              textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 11, color: _blueDeep)),
        ],
      ),
    ),
    pw.SizedBox(height: 10),
    // info grid
    pw.Row(textDirection: pw.TextDirection.rtl, children: [
      _cell('نام ساکن', (b['resident_name'] ?? '—').toString()),
      _cell('شماره واحد', (b['unit_label'] ?? '').toString()),
      _cell('دوره صورتحساب', (b['period_title'] ?? '').toString()),
    ]),
    pw.Row(textDirection: pw.TextDirection.rtl, children: [
      _cell('تاریخ صدور', b['published_at'] == null ? '—' : fmtJalali(b['published_at'].toString())),
      _cell('مهلت پرداخت', fmtJalali(b['due_date']?.toString())),
      _cell('کد تأیید قبض', (b['verification_code'] ?? '—').toString()),
    ]),
    pw.SizedBox(height: 6),
    // readings
    pw.Row(textDirection: pw.TextDirection.rtl, children: [
      _cell('قرائت قبلی', fmtNum((b['prev_reading'] ?? 0) as num)),
      _cell('قرائت فعلی', fmtNum((b['cur_reading'] ?? 0) as num)),
      _cell('مصرف', '${fmtNum((b['consumption'] ?? 0) as num)} م³', bg: _blue, fg: _white, labelColor: _blueSoft),
      _cell('حد مجاز', d == null ? '—' : '${fmtNum((d['L'] ?? 0) as num)} م³'),
      _cell('نرخ هر م³', b['price_per_m3'] == null ? '—' : fmtMoney(b['price_per_m3'] as num)),
    ]),
    pw.SizedBox(height: 10),
    // breakdown
    pw.Text('تفکیک مبلغ این دوره', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: _blueDeep)),
    pw.SizedBox(height: 4),
    pw.Container(
      decoration: pw.BoxDecoration(border: blockBorder, borderRadius: pw.BorderRadius.circular(10)),
      child: pw.Column(children: [
        _row('هزینهٔ مصرف آب', water == null ? '—' : fmtMoney(water)),
        _row('آبونمان', abon == null ? '—' : fmtMoney(abon)),
        _row('جریمه دیرکرد', penalty == null ? '—' : fmtMoney(penalty)),
        _row('مبلغ این دوره', fmtMoney(amount), last: true, bold: true),
      ]),
    ),
    pw.SizedBox(height: 10),
    // debt boxes
    pw.Row(textDirection: pw.TextDirection.rtl, children: [
      _cell('بدهی دوره‌های قبل', fmtMoney(prevDebt), bg: _greenSoft, fg: _greenDeep, labelColor: const PdfColor.fromInt(0xFF0F6E56)),
      _cell('مبلغ این دوره', fmtMoney(amount)),
      _cell('مجموع بدهی', fmtMoney(totalDebt), bg: _blueDeep, fg: _white, labelColor: _blueSoft),
    ]),
    pw.SizedBox(height: 10),
    // bank card and text
    pw.Row(textDirection: pw.TextDirection.rtl, crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
      pw.Container(
        width: 250,
        height: 150,
        padding: const pw.EdgeInsets.all(16),
        decoration: pw.BoxDecoration(color: _blueMid, borderRadius: pw.BorderRadius.circular(14)),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text((bank?['bank_name'] ?? 'بانک').toString(),
                style: pw.TextStyle(color: _white, fontSize: 11, fontWeight: pw.FontWeight.bold)),
            pw.Text(cardText, style: pw.TextStyle(color: _white, fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.Text((bank?['holder_name'] ?? '—').toString(),
                style: const pw.TextStyle(color: _blueSoft, fontSize: 9)),
          ],
        ),
      ),
      pw.SizedBox(width: 12),
      pw.Expanded(
        child: pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(border: blockBorder, borderRadius: pw.BorderRadius.circular(12)),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('پرداخت به کارت', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: _blueDeep)),
              pw.SizedBox(height: 6),
              pw.Text('شماره کارت بالا را برای واریز استفاده کنید و کد تأیید قبض را در توضیحات واریز بنویسید.',
                  style: const pw.TextStyle(fontSize: 9, color: _blueDeep)),
            ],
          ),
        ),
      ),
    ]),
    pw.SizedBox(height: 14),
    // footer band
    pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      decoration: pw.BoxDecoration(color: _blue, borderRadius: pw.BorderRadius.circular(12)),
      child: pw.Row(textDirection: pw.TextDirection.rtl, 
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('کد پیگیری: ${b['verification_code'] ?? '—'}', style: const pw.TextStyle(color: _white, fontSize: 9)),
          pw.Text('ساخته‌شده توسط برنامهٔ aban AS', style: const pw.TextStyle(color: _white, fontSize: 9)),
        ],
      ),
    ),
  ]);
}
