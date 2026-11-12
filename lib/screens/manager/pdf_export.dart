import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../format.dart';

const _fontUrl =
    'https://raw.githubusercontent.com/rastikerdar/vazirmatn/master/fonts/ttf/Vazirmatn-Regular.ttf';

/// Downloads a Persian font. Without it the PDF still works, but Persian text may not show.
Future<pw.Font> _loadFont() async {
  try {
    final res = await http.get(Uri.parse(_fontUrl)).timeout(const Duration(seconds: 15));
    if (res.statusCode == 200) {
      return pw.Font.ttf(ByteData.view(Uint8List.fromList(res.bodyBytes).buffer));
    }
  } catch (_) {}
  return pw.Font.helvetica();
}

/// One A4 page: header, totals and the table. The content is scaled down to fit one page.
Future<void> printPeriodTable({
  required String buildingName,
  required String periodTitle,
  required String filterLabel,
  required List<Map<String, dynamic>> rows,
}) async {
  final font = await _loadFont();
  final doc = pw.Document(theme: pw.ThemeData.withFont(base: font, bold: font));

  num total = 0, paid = 0;
  for (final r in rows) {
    total += (r['amount_due'] ?? 0) as num;
    paid += (r['paid_amount'] ?? 0) as num;
  }

  final data = <List<String>>[];
  for (var i = 0; i < rows.length; i++) {
    final r = rows[i];
    final isPaid = r['payment_status'] == 'paid';
    data.add([
      toFa('${i + 1}'),
      toFa(r['unit_label'].toString()),
      (r['resident_name'] ?? '—').toString(),
      fmtNum((r['amount_due'] ?? 0) as num),
      fmtNum((r['paid_amount'] ?? 0) as num),
      isPaid ? 'پرداخت شده' : 'پرداخت نشده',
    ]);
  }

  final content = pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
    mainAxisSize: pw.MainAxisSize.min,
    children: [
      pw.Container(
        padding: const pw.EdgeInsets.all(14),
        decoration: pw.BoxDecoration(
          color: const PdfColor.fromInt(0xFF185FA5),
          borderRadius: pw.BorderRadius.circular(10),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('گزارش قبض‌های آب',
                style: const pw.TextStyle(color: PdfColors.white, fontSize: 11)),
            pw.SizedBox(height: 4),
            pw.Text(buildingName,
                style: pw.TextStyle(color: PdfColors.white, fontSize: 20, fontWeight: pw.FontWeight.bold)),
            pw.Text('$periodTitle · $filterLabel',
                style: const pw.TextStyle(color: PdfColors.white, fontSize: 11)),
          ],
        ),
      ),
      pw.SizedBox(height: 12),
      pw.Row(
        children: [
          _box('تعداد واحد', toFa('${rows.length}')),
          _box('جمع قبض‌ها', fmtMoney(total)),
          _box('جمع پرداختی', fmtMoney(paid)),
          _box('باقی‌مانده', fmtMoney(total - paid)),
        ],
      ),
      pw.SizedBox(height: 12),
      pw.Table.fromTextArray(
        headers: ['#', 'واحد', 'نام ساکن', 'مبلغ قبض', 'پرداختی', 'وضعیت'],
        data: data,
        headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10),
        headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF14213D)),
        cellStyle: const pw.TextStyle(fontSize: 9),
        cellAlignment: pw.Alignment.center,
        oddRowDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFF8FAFD)),
        cellPadding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 4),
      ),
      pw.SizedBox(height: 16),
      pw.Center(
        child: pw.Text('تهیه شده توسط برنامهٔ aban AS',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
      ),
    ],
  );

  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      textDirection: pw.TextDirection.rtl,
      build: (ctx) => pw.FittedBox(fit: pw.BoxFit.scaleDown, child: pw.SizedBox(width: 530, child: content)),
    ),
  );

  await Printing.layoutPdf(onLayout: (_) async => doc.save());
}

pw.Widget _box(String label, String value) {
  return pw.Expanded(
    child: pw.Container(
      margin: const pw.EdgeInsets.all(3),
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFE6F1FB),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
          pw.SizedBox(height: 3),
          pw.Text(value, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    ),
  );
}
