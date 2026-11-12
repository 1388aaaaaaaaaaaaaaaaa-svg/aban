/// Persian/Arabic digits -> Latin, and removes thousands separators.
String enDigits(String s) {
  const fa = '۰۱۲۳۴۵۶۷۸۹';
  const ar = '٠١٢٣٤٥٦٧٨٩';
  final b = StringBuffer();
  for (final c in s.split('')) {
    final i = fa.indexOf(c);
    final j = ar.indexOf(c);
    if (i >= 0) {
      b.write(i);
    } else if (j >= 0) {
      b.write(j);
    } else if (c == '٬' || c == ',') {
      continue;
    } else {
      b.write(c);
    }
  }
  return b.toString().trim();
}

/// Returns null when the text is not a number.
num? parseNum(String s) {
  final t = enDigits(s);
  if (t.isEmpty) return null;
  return num.tryParse(t);
}

int? parseInt(String s) {
  final n = parseNum(s);
  if (n == null || n != n.roundToDouble()) return null;
  return n.toInt();
}
