import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../api.dart';
import '../../format.dart';
import '../../models.dart';
import '../../state.dart';
import '../../theme.dart';
import '../../widgets.dart';
import '../login_screen.dart';
import 'bill_pdf.dart';
import 'resident_messages_tab.dart';

/// Resident panel: current bill, card-to-card payment, past bills and messages.
class ResidentHome extends StatefulWidget {
  const ResidentHome({super.key});

  @override
  State<ResidentHome> createState() => _ResidentHomeState();
}

class _ResidentHomeState extends State<ResidentHome> {
  int _index = 0;
  List<BillRow> _bills = [];
  Map<String, dynamic>? _bank;
  bool _loading = true;
  String? _error;

  Map<String, dynamic> get _params => {
        'p_building': appState.residentBuilding,
        'p_unit': appState.residentUnit,
        'p_check': appState.residentCheck,
      };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await rpc('get_unit_history', _params) as List;
      final bank = await rpc('get_building_bank_info', _params);
      setState(() {
        _bills = rows.map((r) => BillRow.fromJson(r as Map<String, dynamic>)).toList();
        _bank = bank is Map<String, dynamic> ? bank : null;
      });
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'اطلاعات دریافت نشد؛ اینترنت را بررسی کنید');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String t) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));
  }

  Future<void> _pdf() async {
    try {
      await printResidentBill();
    } on ApiException catch (e) {
      _snack(e.message);
    } catch (_) {
      _snack('ساخت PDF انجام نشد');
    }
  }

  void _logout() {
    appState.clear();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  num get _debt => _bills.where((b) => !b.isPaid).fold<num>(0, (s, b) => s + b.balance);

  Future<void> _copy(String text, String done) async {
    await Clipboard.setData(ClipboardData(text: text));
    _snack(done);
  }

  Widget _billsView() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return EmptyState(text: _error!);
    final unpaidCount = _bills.where((b) => !b.isPaid).length;
    final current = _bills.isEmpty ? null : _bills.first;
    final cardNumber = (_bank?['card_number'] ?? '').toString();
    final debtNumber = _debt.round();

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.blue2, AppColors.deep]),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('مجموع بدهی', style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 6),
                Text(fmtMoney(_debt),
                    style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(
                  unpaidCount == 0 ? 'همه قبض‌ها پرداخت شده است' : '${fmtNum(unpaidCount)} قبض پرداخت نشده',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (current == null)
            const EmptyState(text: 'هنوز قبضی برای این واحد منتشر نشده است')
          else ...[
            const Text('قبض این دوره', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 8),
            _billCard(current, highlight: true),
          ],
          const SizedBox(height: 18),
          if (_debt > 0 && cardNumber.isNotEmpty) ...[
            const Text('پرداخت کارت به کارت', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 8),
            _transferCard(cardNumber, debtNumber),
            const SizedBox(height: 18),
          ],
          if (_bank != null && cardNumber.isNotEmpty) ...[
            const Text('کارت مدیر', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 8),
            BankCardView(
              bankName: (_bank!['bank_name'] ?? '').toString(),
              holder: (_bank!['holder_name'] ?? '').toString(),
              cardNumber: cardNumber,
            ),
            const SizedBox(height: 18),
          ],
          if (_bills.length > 1) ...[
            const Text('قبض‌های قبلی', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 8),
            ..._bills.skip(1).map((b) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _billCard(b),
                )),
          ],
        ],
      ),
    );
  }

  Widget _transferCard(String cardNumber, int debt) {
    final grouped = RegExp(r'.{1,4}')
        .allMatches(cardNumber.replaceAll(RegExp(r'\D'), ''))
        .map((m) => m.group(0))
        .join(' ');
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('کارت مقصد (کارت مدیر)', style: TextStyle(fontSize: 12, color: AppColors.muted)),
          const SizedBox(height: 4),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Text(grouped,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 1.5, color: AppColors.deep)),
          ),
          const SizedBox(height: 12),
          const Text('مبلغ پرداخت (کل بدهی)', style: TextStyle(fontSize: 12, color: AppColors.muted)),
          const SizedBox(height: 4),
          Text(fmtMoney(debt), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.blue)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _copy(cardNumber.replaceAll(RegExp(r'\D'), ''), 'شماره کارت کپی شد'),
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('کپی کارت'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _copy(debt.toString(), 'مبلغ کپی شد'),
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('کپی مبلغ'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _billCard(BillRow b, {bool highlight = false}) {
    final color = b.isPaid ? AppColors.green : AppColors.red;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Color(0x0F000000), blurRadius: 10, offset: Offset(0, 4))],
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(width: 5, color: color),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(b.periodTitle,
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: highlight ? 17 : 15)),
                        ),
                        StatusChip(paid: b.isPaid),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _mini('مبلغ قبض', fmtMoney(b.amountDue)),
                        _mini('مانده', fmtMoney(b.balance)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _line('پرداختی', fmtMoney(b.paidAmount)),
                    _line('مهلت پرداخت', fmtJalali(b.dueDate)),
                    if (b.verificationCode != null) _line('کد تأیید', b.verificationCode!),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mini(String label, String value) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(left: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(color: AppColors.blueLight, borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.blue)),
          ],
        ),
      ),
    );
  }

  Widget _line(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('واحد ${appState.residentUnit ?? ''}'),
        actions: [
          IconButton(onPressed: _pdf, icon: const Icon(Icons.picture_as_pdf_outlined), tooltip: 'PDF قبض'),
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout, color: AppColors.red), tooltip: 'خروج'),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: [
          _billsView(),
          const ResidentMessagesTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'قبض من'),
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline), selectedIcon: Icon(Icons.chat_bubble), label: 'پیام‌ها'),
        ],
      ),
    );
  }
}
