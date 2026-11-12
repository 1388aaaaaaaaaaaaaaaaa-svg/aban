import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../format.dart';
import 'pdf_common.dart';

/// Prints the history of one unit across all periods, with the total debt.
Future<void> printUnitHistoryPdf({
  required String buildingName,
  required String unitLabel,
  required String residentName,
  required List<Map<String, dynamic>> rows,
}) async {
  num debt = 0;
  final data = <List<String>>[];
  for (final r in rows) {
    final amount = (r['amount_due'] ?? 0) as num;
    final paid = (r['paid_amount'] ?? 0) as num;
    if (r['payment_status'] != 'paid') debt += amount - paid;
    data.add([
      (r['title'] ?? '').toString(),
      fmtNum(amount),
      fmtNum(paid),
      fmtNum(amount - paid),
      r['payment_status'] == 'paid' ? 'پرداخت شده' : 'پرداخت نشده',
    ]);
  }
  final unpaid = rows.where((r) => r['payment_status'] != 'paid').length;

  await printA4Page([
    pdfHeader('سابقهٔ حساب واحد', 'واحد $unitLabel — $residentName', buildingName),
    pw.SizedBox(height: 10),
    pw.Row(children: [
      pdfBox('تعداد قبض‌ها', fmtNum(rows.length)),
      pdfBox('پرداخت نشده', fmtNum(unpaid)),
      pdfBox('مجموع بدهی', fmtMoney(debt), dark: true),
    ]),
    pw.SizedBox(height: 12),
    pw.Table.fromTextArray(
      headers: ['دوره', 'مبلغ قبض', 'پرداختی', 'مانده', 'وضعیت'],
      data: data,
      headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 9),
      headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF14213D)),
      cellStyle: const pw.TextStyle(fontSize: 9),
      cellAlignment: pw.Alignment.center,
      cellPadding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 4),
    ),
    pdfFooter(),
  ]);
}
