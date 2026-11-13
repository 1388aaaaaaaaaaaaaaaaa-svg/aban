import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

const _fontUrl =
    'https://raw.githubusercontent.com/rastikerdar/vazirmatn/master/fonts/ttf/Vazirmatn-Regular.ttf';

Future<pw.Font> _loadFont() async {
  try {
    final res = await http.get(Uri.parse(_fontUrl)).timeout(const Duration(seconds: 15));
    if (res.statusCode == 200) {
      return pw.Font.ttf(ByteData.view(Uint8List.fromList(res.bodyBytes).buffer));
    }
  } catch (_) {}
  return pw.Font.helvetica();
}

/// Prints one A4 page. The content is scaled down so it always fits on one page.
Future<void> printA4Page(List<pw.Widget> children) async {
  final font = await _loadFont();
  final doc = pw.Document(theme: pw.ThemeData.withFont(base: font, bold: font));
  final column = pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
    mainAxisSize: pw.MainAxisSize.min,
    children: children,
  );
  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      textDirection: pw.TextDirection.rtl,
      build: (ctx) => pw.FittedBox(
        fit: pw.BoxFit.scaleDown,
        child: pw.SizedBox(width: 530, child: column),
      ),
    ),
  );
  await Printing.layoutPdf(onLayout: (_) async => doc.save());
}

pw.Widget pdfHeader(String kicker, String title, String subtitle) {
  return pw.Container(
    padding: const pw.EdgeInsets.all(14),
    decoration: pw.BoxDecoration(
      color: const PdfColor.fromInt(0xFF185FA5),
      borderRadius: pw.BorderRadius.circular(10),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(kicker, style: const pw.TextStyle(color: PdfColors.white, fontSize: 10)),
        pw.SizedBox(height: 4),
        pw.Text(title, style: pw.TextStyle(color: PdfColors.white, fontSize: 18, fontWeight: pw.FontWeight.bold)),
        pw.Text(subtitle, style: const pw.TextStyle(color: PdfColors.white, fontSize: 10)),
      ],
    ),
  );
}

/// A small summary box. Use inside a pw.Row.
pw.Widget pdfBox(String label, String value, {bool dark = false}) {
  return pw.Expanded(
    child: pw.Container(
      margin: const pw.EdgeInsets.all(3),
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: dark ? const PdfColor.fromInt(0xFF0C447C) : const PdfColor.fromInt(0xFFE6F1FB),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label,
              style: pw.TextStyle(fontSize: 9, color: dark ? PdfColors.white : PdfColors.grey700)),
          pw.SizedBox(height: 3),
          pw.Text(value,
              style: pw.TextStyle(
                  fontSize: 10, fontWeight: pw.FontWeight.bold, color: dark ? PdfColors.white : PdfColors.black)),
        ],
      ),
    ),
  );
}

pw.Widget pdfLine(String label, String value) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 2),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
        pw.Text(value, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
      ],
    ),
  );
}

pw.Widget pdfFooter() {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(top: 14),
    child: pw.Center(
      child: pw.Text('تهیه شده توسط برنامهٔ aban AS',
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
    ),
  );
}

/// A row whose first child is placed on the right (right-to-left reading order).
pw.Widget rtlRow(List<pw.Widget> children) {
  return pw.Row(children: children.reversed.toList());
}
