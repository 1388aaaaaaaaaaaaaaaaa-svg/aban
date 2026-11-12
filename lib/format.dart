import 'logic/jalali.dart';

const _fa = '۰۱۲۳۴۵۶۷۸۹';

/// Converts Latin digits to Persian digits.
String toFa(String input) {
  final b = StringBuffer();
  for (final c in input.split('')) {
    final i = '0123456789'.indexOf(c);
    b.write(i >= 0 ? _fa[i] : c);
  }
  return b.toString();
}

/// 12345 -> ۱۲٬۳۴۵
String fmtNum(num n) {
  final s = n.round().abs().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write('٬');
    b.write(s[i]);
  }
  final sign = n < 0 ? '-' : '';
  return sign + toFa(b.toString());
}

String fmtMoney(num n) => '${fmtNum(n)} تومان';

const jMonths = [
  'فروردین', 'اردیبهشت', 'خرداد', 'تیر', 'مرداد', 'شهریور',
  'مهر', 'آبان', 'آذر', 'دی', 'بهمن', 'اسفند',
];

/// Gregorian to Jalali (Persian calendar).
List<int> _toJalali(int gy, int gm, int gd) {
  const gdm = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334];
  final gy2 = gm > 2 ? gy + 1 : gy;
  var days = 355666 + 365 * gy + (gy2 + 3) ~/ 4 - (gy2 + 99) ~/ 100 +
      (gy2 + 399) ~/ 400 + gd + gdm[gm - 1];
  var jy = -1595 + 33 * (days ~/ 12053);
  days %= 12053;
  jy += 4 * (days ~/ 1461);
  days %= 1461;
  if (days > 365) {
    jy += (days - 1) ~/ 365;
    days = (days - 1) % 365;
  }
  int jm, jd;
  if (days < 186) {
    jm = 1 + days ~/ 31;
    jd = 1 + days % 31;
  } else {
    jm = 7 + (days - 186) ~/ 30;
    jd = 1 + (days - 186) % 30;
  }
  return [jy, jm, jd];
}

/// '2026-11-06...' -> '۱۵ آبان ۱۴۰۵'
String fmtJalali(String? iso) {
  if (iso == null || iso.length < 10) return '—';
  final d = DateTime.tryParse(iso.substring(0, 10));
  if (d == null) return '—';
  final j = _toJalali(d.year, d.month, d.day);
  return toFa('${j[2]} ${jMonths[j[1] - 1]} ${j[0]}');
}

/// '2026-11-06T07:01:01+00:00' -> '۱۵ آبان ۱۴۰۵ · ۱۰:۳۰' (local time)
String fmtDateTime(String? iso) {
  if (iso == null || iso.isEmpty) return '';
  final d = DateTime.tryParse(iso)?.toLocal();
  if (d == null) return '';
  final j = toJalali(d.year, d.month, d.day);
  final hh = d.hour.toString().padLeft(2, '0');
  final mm = d.minute.toString().padLeft(2, '0');
  return toFa('${j[2]} ${jMonths[j[1] - 1]} ${j[0]} · $hh:$mm');
}
