import 'package:pdf/widgets.dart' as pw;

import '../../api.dart';
import '../../format.dart';
import '../../state.dart';
import '../pdf/pdf_common.dart';
import 'package:pdf/pdf.dart';

/// Prints the current bill of the resident's unit on one A4 page.
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
      ? '—'
      : RegExp(r'.{1,4}').allMatches(cardRaw).map((m) => m.group(0)).join(' ');

  await printA4Page([
    pdfHeader(
      'صورتحساب مصرف آب',
      (b['building_name'] ?? '').toString(),
      '${b['period_title'] ?? ''} · واحد ${b['unit_label'] ?? ''}',
    ),
    pw.SizedBox(height: 10),
    pw.Row(children: [
      pdfBox('مبلغ قبض', fmtMoney(amount)),
      pdfBox('پرداختی', fmtMoney(paid)),
      pdfBox('مانده', fmtMoney(balance)),
      pdfBox('مهلت پرداخت', fmtJalali(b['due_date']?.toString())),
    ]),
    pw.SizedBox(height: 10),
    pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400), borderRadius: pw.BorderRadius.circular(8)),
      child: pw.Column(children: [
        pdfLine('نام ساکن', (b['resident_name'] ?? '—').toString()),
        pdfLine('کد تأیید قبض', (b['verification_code'] ?? '—').toString()),
        pdfLine('قرائت قبلی', fmtNum((b['prev_reading'] ?? 0) as num)),
        pdfLine('قرائت فعلی', fmtNum((b['cur_reading'] ?? 0) as num)),
        pdfLine('مصرف این دوره', '${fmtNum((b['consumption'] ?? 0) as num)} متر مکعب'),
        pdfLine('حد مجاز', d == null ? '—' : '${fmtNum((d['L'] ?? 0) as num)} متر مکعب'),
        pdfLine('نرخ هر متر مکعب', b['price_per_m3'] == null ? '—' : fmtMoney(b['price_per_m3'] as num)),
      ]),
    ),
    pw.SizedBox(height: 10),
    pw.Text('تفکیک مبلغ این دوره', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
    pw.SizedBox(height: 4),
    pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400), borderRadius: pw.BorderRadius.circular(8)),
      child: pw.Column(children: [
        pdfLine('هزینهٔ مصرف آب', water == null ? '—' : fmtMoney(water)),
        pdfLine('آبونمان', abon == null ? '—' : fmtMoney(abon)),
        pdfLine('جریمه', penalty == null ? '—' : fmtMoney(penalty)),
        pdfLine('مبلغ این دوره', fmtMoney(amount)),
      ]),
    ),
    pw.SizedBox(height: 10),
    pw.Row(children: [
      pdfBox('بدهی دوره‌های قبل', fmtMoney(prevDebt)),
      pdfBox('این دوره', fmtMoney(amount)),
      pdfBox('مجموع بدهی', fmtMoney(totalDebt), dark: true),
    ]),
    pw.SizedBox(height: 10),
    pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400), borderRadius: pw.BorderRadius.circular(8)),
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text('پرداخت به کارت', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 4),
        pw.Text('صاحب کارت: ${bank?['holder_name'] ?? '—'}', style: const pw.TextStyle(fontSize: 10)),
        pw.Text('بانک: ${bank?['bank_name'] ?? '—'}', style: const pw.TextStyle(fontSize: 10)),
        pw.Text('شماره کارت: $cardText', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
      ]),
    ),
    pdfFooter(),
  ]);
}
