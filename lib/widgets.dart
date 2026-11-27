import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'format.dart';
import 'theme.dart';

/// Flat sheet: a mist surface with one hairline. No shadow, no gradient wash.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.foam,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.aqua2),
      ),
      child: child,
    );
  }
}

class StatusChip extends StatelessWidget {
  final bool paid;
  const StatusChip({super.key, required this.paid});

  @override
  Widget build(BuildContext context) {
    final color = paid ? AppColors.green : AppColors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: paid ? AppColors.greenSoft : AppColors.redSoft,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        paid ? 'پرداخت شده' : 'پرداخت نشده',
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final String text;
  const EmptyState({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Text(
          text,
          style: const TextStyle(color: AppColors.muted, fontSize: 14, height: 1.7),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

/// Shown for sections that are built in the next phases.
class ComingSoon extends StatelessWidget {
  final String title;
  const ComingSoon({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: const EmptyState(text: 'این بخش در مرحلهٔ بعد اضافه می‌شود'),
    );
  }
}

/// Bank card: ink surface, amber chip, number on the left as in a real card.
class BankCardView extends StatelessWidget {
  final String bankName;
  final String holder;
  final String cardNumber;
  const BankCardView({super.key, required this.bankName, required this.holder, required this.cardNumber});

  String get _grouped {
    final d = cardNumber.replaceAll(RegExp(r'\D'), '');
    if (d.isEmpty) return '•••• •••• •••• ••••';
    return RegExp(r'.{1,4}').allMatches(d).map((m) => m.group(0)).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(bankName.isEmpty ? 'بانک' : bankName,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
              const Spacer(),
              Container(
                width: 34,
                height: 24,
                decoration: BoxDecoration(color: AppColors.signal, borderRadius: BorderRadius.circular(5)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Text(_grouped,
                style: const TextStyle(color: Colors.white, fontSize: 19, letterSpacing: 2, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 14),
          Text(holder.isEmpty ? '—' : holder, style: const TextStyle(color: AppColors.aqua2, fontSize: 13)),
        ],
      ),
    );
  }
}

/// Tabs as an underline: the active tab has a tide bar under it.
class PillTabs extends StatelessWidget {
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;
  const PillTabs({super.key, required this.labels, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.aqua2)),
      ),
      child: Row(
        children: List.generate(labels.length, (i) {
          final on = i == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: on ? AppColors.blue : Colors.transparent, width: 2.5),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  labels[i],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: on ? FontWeight.w800 : FontWeight.w500,
                    color: on ? AppColors.ink : AppColors.muted,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// Signature element: a meter arc with the tariff tiers (1x, 2x, 3x of the limit) and a needle.
class MeterGauge extends StatelessWidget {
  final num consumption;
  final num limit;
  const MeterGauge({super.key, required this.consumption, required this.limit});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      height: 140,
      child: CustomPaint(
        painter: _GaugePainter(value: consumption.toDouble(), limit: limit.toDouble()),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  fmtNum(consumption),
                  style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: AppColors.ink),
                ),
                const Text('متر مکعب', style: TextStyle(fontSize: 12, color: AppColors.muted)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double value;
  final double limit;
  const _GaugePainter({required this.value, required this.limit});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height - 6);
    final radius = size.width / 2 - 12;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const stroke = 12.0;
    final maxV = limit <= 0 ? 1.0 : limit * 3;

    double frac(double v) => (v / maxV).clamp(0.0, 1.0).toDouble();

    void arc(double from, double to, Color color) {
      final p = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke;
      canvas.drawArc(rect, 3.14159 + from * 3.14159, (to - from) * 3.14159, false, p);
    }

    final l1 = frac(limit);
    final l2 = frac(limit * 2);
    arc(0, l1, AppColors.blue);
    arc(l1, l2, AppColors.signal);
    arc(l2, 1, AppColors.red.withValues(alpha: 0.55));

    final a = 3.14159 + frac(value) * 3.14159;
    final tip = center + Offset(math.cos(a), math.sin(a)) * (radius - 6);
    canvas.drawLine(
      center,
      tip,
      Paint()
        ..color = AppColors.ink
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(center, 6, Paint()..color = AppColors.ink);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) => old.value != value || old.limit != limit;
}
