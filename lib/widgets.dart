import 'package:flutter/material.dart';

import 'theme.dart';

/// White rounded card used across the app.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const AppCard({super.key, required this.child, this.padding = const EdgeInsets.all(16)});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.blueLight),
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 14, offset: Offset(0, 6))],
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: paid ? AppColors.greenSoft : AppColors.redSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        paid ? 'پرداخت شده' : 'پرداخت نشده',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: paid ? AppColors.green : AppColors.red,
        ),
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
        padding: const EdgeInsets.all(24),
        child: Text(text, style: const TextStyle(color: AppColors.muted), textAlign: TextAlign.center),
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

/// Bank card design (same idea as the approved card): blue gradient, chip, number, holder.
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF1F6FD1), Color(0xFF0B3B7A)]),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 14, offset: Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(bankName.isEmpty ? 'بانک' : bankName,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
              const Spacer(),
              Container(
                width: 38,
                height: 28,
                decoration: BoxDecoration(color: const Color(0xFFB5D4F4), borderRadius: BorderRadius.circular(6)),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Text(_grouped,
                style: const TextStyle(color: Colors.white, fontSize: 20, letterSpacing: 2, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 16),
          Text(holder.isEmpty ? '—' : holder,
              style: const TextStyle(color: Color(0xFFD6E8FF), fontSize: 13)),
        ],
      ),
    );
  }
}

/// Minimal pill-style tabs used across the app.
class PillTabs extends StatelessWidget {
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;
  const PillTabs({super.key, required this.labels, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x0F000000), blurRadius: 8, offset: Offset(0, 3))],
      ),
      child: Row(
        children: List.generate(labels.length, (i) {
          final on = i == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: on ? AppColors.blue : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  labels[i],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: on ? Colors.white : AppColors.muted,
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
