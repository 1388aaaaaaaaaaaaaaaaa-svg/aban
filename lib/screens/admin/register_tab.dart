import 'package:flutter/material.dart';

import '../../api.dart';
import '../../state.dart';
import '../../theme.dart';
import 'common.dart';

/// Register a new building with its manager and bank account.
class RegisterTab extends StatefulWidget {
  const RegisterTab({super.key});

  @override
  State<RegisterTab> createState() => _RegisterTabState();
}

class _RegisterTabState extends State<RegisterTab> {
  final _name = TextEditingController();
  final _city = TextEditingController();
  final _mName = TextEditingController();
  final _mPhone = TextEditingController();
  final _pass = TextEditingController();
  final _holder = TextEditingController();
  final _card = TextEditingController();
  final _bank = TextEditingController();
  bool _busy = false;
  String? _result;

  @override
  void dispose() {
    for (final c in [_name, _city, _mName, _mPhone, _pass, _holder, _card, _bank]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (_name.text.trim().length < 3) return _msg('نام ساختمان حداقل ۳ حرف باشد');
    if (_pass.text.length < 8) return _msg('رمز مدیر حداقل ۸ نویسه باشد');
    setState(() {
      _busy = true;
      _result = null;
    });
    final ok = await runApi(context, () async {
      final rows = await rpc('create_building_with_bank', {
        'p_admin_key': appState.adminKey,
        'p_name': _name.text.trim(),
        'p_password': _pass.text,
        'p_city': _city.text.trim(),
        'p_manager_name': _mName.text.trim(),
        'p_manager_phone': _mPhone.text.trim(),
        'p_holder': _holder.text.trim(),
        'p_card': _card.text.trim(),
        'p_bank': _bank.text.trim(),
      }) as List;
      final r = rows.first as Map<String, dynamic>;
      _result = 'ساختمان ثبت شد. کد ساختمان: ${r['code']}';
    }, done: null);
    if (mounted) {
      setState(() => _busy = false);
      if (ok && _result != null) {
        for (final c in [_name, _city, _mName, _mPhone, _pass, _holder, _card, _bank]) {
          c.clear();
        }
        setState(() {});
      }
    }
  }

  void _msg(String t) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('ثبت ساختمان جدید', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        _f(_name, 'نام ساختمان'),
        _f(_city, 'شهر'),
        _f(_mName, 'نام مدیر'),
        _f(_mPhone, 'شماره تلفن مدیر', ltr: true),
        _f(_pass, 'رمز مدیر (حداقل ۸ نویسه)', obscure: true),
        const Divider(height: 28),
        const Text('اطلاعات حساب بانکی', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        _f(_holder, 'نام صاحب کارت'),
        _f(_card, 'شماره کارت (۱۶ رقم)', ltr: true),
        _f(_bank, 'نام بانک'),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: _busy ? null : _submit,
          style: FilledButton.styleFrom(backgroundColor: AppColors.blue, padding: const EdgeInsets.all(14)),
          child: Text(_busy ? 'در حال ثبت…' : 'ثبت ساختمان'),
        ),
        if (_result != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(_result!, style: const TextStyle(color: AppColors.green, fontWeight: FontWeight.w700)),
          ),
      ],
    );
  }

  Widget _f(TextEditingController c, String label, {bool ltr = false, bool obscure = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: c,
        obscureText: obscure,
        textDirection: ltr ? TextDirection.ltr : null,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), isDense: true),
      ),
    );
  }
}
