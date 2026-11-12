import 'dart:math';

/// Same formulas as the web app (weighted tiers and largest-remainder split).

num weighted(num x, num limit) {
  return min(x, limit) + 2 * min(max(x - limit, 0), 2 * limit) + 3 * max(x - 3 * limit, 0);
}

List<int> distribute(int total, List<num> weights) {
  if (total < 0) throw Exception('مبلغ باید مثبت باشد');
  final sum = weights.fold<num>(0, (a, b) => a + b);
  if (sum == 0) {
    if (total == 0) return List.filled(weights.length, 0);
    throw Exception('مصرف تعدیل‌شدهٔ کل صفر است؛ تقسیم مبلغ ممکن نیست');
  }
  final raw = weights.map((w) => total * w / sum).toList();
  final out = raw.map((v) => v.floor()).toList();
  final rem = total - out.fold<int>(0, (a, b) => a + b);
  final order = List<int>.generate(weights.length, (i) => i)
    ..sort((a, b) {
      final fa = raw[a] - out[a];
      final fb = raw[b] - out[b];
      final c = fb.compareTo(fa);
      return c != 0 ? c : a.compareTo(b);
    });
  for (var i = 0; i < rem; i++) {
    out[order[i]]++;
  }
  return out;
}

class UnitReading {
  final String label;
  final num prev;
  final num cur;
  final num penalty;
  UnitReading({required this.label, required this.prev, required this.cur, this.penalty = 0});
}

class CalcRow {
  final String label;
  final num prev;
  final num cur;
  final num cons;
  final num adjusted;
  final int abon;
  final int water;
  final num penalty;
  final int amount;

  CalcRow({
    required this.label,
    required this.prev,
    required this.cur,
    required this.cons,
    required this.adjusted,
    required this.abon,
    required this.water,
    required this.penalty,
    required this.amount,
  });

  Map<String, dynamic> toJson() => {
        'label': label,
        'cons': cons,
        'prev': prev,
        'cur': cur,
        'adjusted': adjusted,
        'penalty': penalty,
        'abon': abon,
        'water': water,
        'amount': amount,
      };
}

class CalcResult {
  final String title;
  final num limit;
  final String mode; // split | rate
  final int abon;
  final String abonMode; // total | unit
  final int abonTotal;
  final num? rate;
  final int total; // main bill without penalties
  final String? due;
  final num penaltyTotal;
  final List<CalcRow> rows;

  CalcResult({
    required this.title,
    required this.limit,
    required this.mode,
    required this.abon,
    required this.abonMode,
    required this.abonTotal,
    required this.rate,
    required this.total,
    required this.due,
    required this.penaltyTotal,
    required this.rows,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'L': limit,
        'mode': mode,
        'abon': abon,
        'abonMode': abonMode,
        'abonTotal': abonTotal,
        'rate': rate,
        'total': total,
        'due': due,
        'penaltyTotal': penaltyTotal,
        'data': rows.map((r) => r.toJson()).toList(),
      };
}

CalcResult calculate({
  required String title,
  required num limit,
  required int abon,
  required String abonMode,
  required String mode,
  int? amount,
  num? rate,
  String? due,
  required List<UnitReading> units,
}) {
  if (units.isEmpty) throw Exception('واحدها را ثبت کنید');
  if (title.trim().isEmpty) throw Exception('عنوان دوره را وارد کنید');
  if (!(limit > 0)) throw Exception('حد مجاز باید بیشتر از صفر باشد');

  final n = units.length;
  final cons = <num>[];
  final adj = <num>[];
  for (final u in units) {
    if (u.cur < u.prev) {
      throw Exception('عدد فعلی کنتور واحد ${u.label} از عدد قبلی کمتر است');
    }
    final c = u.cur - u.prev;
    cons.add(c);
    adj.add(weighted(c, limit));
  }

  final abonTotal = abonMode == 'unit' ? abon * n : abon;
  final abs = distribute(abonTotal, List<num>.filled(n, 1));

  List<int> costs;
  int total;
  num? usedRate;
  if (mode == 'split') {
    final t = amount ?? 0;
    if (t < abonTotal) throw Exception('قبض اصلی باید حداقل برابر آبونمان کل باشد');
    total = t;
    costs = distribute(t - abonTotal, adj);
  } else {
    if (rate == null || rate <= 0) throw Exception('نرخ هر متر مکعب را وارد کنید');
    usedRate = rate;
    costs = adj.map((w) => (w * rate).round()).toList();
    total = costs.fold<int>(0, (a, b) => a + b) + abonTotal;
  }

  final rows = <CalcRow>[];
  num penaltyTotal = 0;
  for (var i = 0; i < n; i++) {
    final u = units[i];
    penaltyTotal += u.penalty;
    rows.add(CalcRow(
      label: u.label,
      prev: u.prev,
      cur: u.cur,
      cons: cons[i],
      adjusted: adj[i],
      abon: abs[i],
      water: costs[i],
      penalty: u.penalty,
      amount: costs[i] + abs[i] + u.penalty.toInt(),
    ));
  }

  return CalcResult(
    title: title.trim(),
    limit: limit,
    mode: mode,
    abon: abon,
    abonMode: abonMode,
    abonTotal: abonTotal,
    rate: usedRate,
    total: total,
    due: due,
    penaltyTotal: penaltyTotal,
    rows: rows,
  );
}
