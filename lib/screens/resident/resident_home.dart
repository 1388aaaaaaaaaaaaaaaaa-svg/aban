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

/// Resident panel: the debt first, then the current bill with its meter, payment and history.
class ResidentHome extends StatefulWidget {
  const ResidentHome({super.key});

  @override
  State<ResidentHome> createState() => _ResidentHomeState();
}

class _ResidentHomeState extends State<ResidentHome> {
  int _index = 0;
  List<BillRow> _bills = [];
  Map<String, dynamic>? _bank;
  num _consumption = 0;
  num? _limit;
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
      final cur = await rpc('get_unit_bill', _params) as List;
      final det = await rpc('get_tariff_details', _params);
      final d = det is Map ? det['details'] as Map<String, dynamic>? : null;
      setState(() {
        _bills = rows.map((r) => BillRow.fromJson(r as Map<String, dynamic>)).toList();
        _bank = bank is Map<String, dynamic> ? bank : null;
        _consumption = cur.isEmpty ? 0 : ((cur.first as Map)['consumption'] ?? 0) as num;
        _limit = d == null ? null : (d['L'] as num?);
      });
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'اطلاعات دریافت نشد. اینترنت را بررسی کنید.');
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

  Widget _divider() => const Divider(height: 1, thickness: 1, color: AppColors.aqua2);

  Widget _row(String label, String value, {bool strong = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: strong ? 15 : 13,
              fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }

  Widget _hero() {
    final unpaid = _bills.where((b) => !b.isPaid).length;
    final clear = unpaid == 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 6, 4, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(clear ? 'بدهی ندارید' : 'مانده بدهی',
              style: const TextStyle(color: AppColors.muted, fontSize: 14)),
          const SizedBox(height: 4),
          Text(
            fmtMoney(_debt),
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              height: 1.1,
              color: clear ? AppColors.green : AppColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            clear ? 'همه قبض‌ها پرداخت شده است.' : '${fmtNum(unpaid)} قبض پرداخت نشده است.',
            style: const TextStyle(color: AppColors.muted, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _currentBill(BillRow b) {
    final limit = _limit;
    return AppCard(
      radius: 16,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(b.periodTitle, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              ),
              StatusChip(paid: b.isPaid),
            ],
          ),
          if (limit != null && limit > 0) ...[
            const SizedBox(height: 12),
            Center(child: MeterGauge(consumption: _consumption, limit: limit)),
            Center(
              child: Text(
                'حد مجاز این دوره ${fmtNum(limit)} متر مکعب است.',
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ),
            const SizedBox(height: 6),
          ],
          _divider(),
          _row('مبلغ قبض', fmtMoney(b.amountDue)),
          _divider(),
          _row('پرداختی', fmtMoney(b.paidAmount)),
          _divider(),
          _row('مانده', fmtMoney(b.balance), strong: true),
          _divider(),
          _row('مهلت پرداخت', fmtJalali(b.dueDate)),
          if (b.verificationCode != null) ...[
            _divider(),
            _row('کد تأیید', b.verificationCode!),
          ],
        ],
      ),
    );
  }

  Widget _transfer(String cardNumber, int debt) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BankCardView(
          bankName: (_bank?['bank_name'] ?? '').toString(),
          holder: (_bank?['holder_name'] ?? '').toString(),
          cardNumber: cardNumber,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Text(fmtMoney(debt),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.ink)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _copy(cardNumber.replaceAll(RegExp(r'\D'), ''), 'شماره کارت کپی شد'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.ink,
                  side: const BorderSide(color: AppColors.blue2),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('کپی شماره کارت'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                onPressed: () => _copy(debt.toString(), 'مبلغ کپی شد'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('کپی مبلغ'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _history() {
    final older = _bills.skip(1).toList();
    if (older.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 22, bottom: 6),
          child: Text('قبض‌های قبلی', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        ),
        ...older.map((b) => Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(b.periodTitle, style: const TextStyle(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 2),
                            Text('مهلت ${fmtJalali(b.dueDate)}',
                                style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(fmtMoney(b.amountDue), style: const TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text(b.isPaid ? 'پرداخت شده' : 'پرداخت نشده',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: b.isPaid ? AppColors.green : AppColors.red,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ],
                  ),
                ),
                _divider(),
              ],
            )),
      ],
    );
  }

  Widget _billsView() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return EmptyState(text: _error!);
    final current = _bills.isEmpty ? null : _bills.first;
    final cardNumber = (_bank?['card_number'] ?? '').toString();

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _hero(),
          const SizedBox(height: 18),
          if (current == null)
            const EmptyState(text: 'هنوز قبضی برای این واحد منتشر نشده است.')
          else
            _currentBill(current),
          if (_debt > 0 && cardNumber.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.only(top: 22, bottom: 10),
              child: Text('پرداخت با کارت', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            ),
            _transfer(cardNumber, _debt.round()),
          ],
          _history(),
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
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'قبض'),
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline), selectedIcon: Icon(Icons.chat_bubble), label: 'پیام‌ها'),
        ],
      ),
    );
  }
}
