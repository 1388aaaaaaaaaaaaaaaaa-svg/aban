/// Gregorian -> Jalali (Persian calendar).
List<int> toJalali(int gy, int gm, int gd) {
  const gdm = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334];
  final gy2 = gm > 2 ? gy + 1 : gy;
  var days = 355666 + 365 * gy + (gy2 + 3) ~/ 4 - (gy2 + 99) ~/ 100 + (gy2 + 399) ~/ 400 + gd + gdm[gm - 1];
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

/// Jalali date -> 'YYYY-MM-DD' (Gregorian), found by walking day by day.
String? isoFromJalali(int jy, int jm, int jd) {
  if (jm < 1 || jm > 12 || jd < 1 || jd > 31) return null;
  final target = jy * 10000 + jm * 100 + jd;
  var d = DateTime.utc(jy + 621, 3, 19);
  for (var k = 0; k < 800; k++) {
    final j = toJalali(d.year, d.month, d.day);
    final v = j[0] * 10000 + j[1] * 100 + j[2];
    if (v == target) {
      return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    }
    d = d.add(Duration(days: v < target ? 1 : -1));
  }
  return null;
}
