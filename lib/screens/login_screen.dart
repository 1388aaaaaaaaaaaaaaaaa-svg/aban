import 'package:flutter/material.dart';

import '../api.dart';
import '../state.dart';
import '../theme.dart';
import 'admin/admin_home.dart';
import 'manager/manager_home.dart';
import 'resident/resident_home.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String _role = 'manager';
  bool _busy = false;
  bool _hidePass = true;
  String? _error;

  final _building = TextEditingController();
  final _password = TextEditingController();
  final _unit = TextEditingController();
  final _check = TextEditingController();
  final _adminKey = TextEditingController();

  @override
  void dispose() {
    for (final c in [_building, _password, _unit, _check, _adminKey]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (_role == 'manager') {
        final rows = await rpc('manager_login', {
          'p_building': _building.text.trim(),
          'p_password': _password.text,
        }) as List;
        final r = rows.first as Map<String, dynamic>;
        appState.managerToken = r['token'].toString();
        appState.managerBuildingName = r['building_name'].toString();
        _go(const ManagerHome());
      } else if (_role == 'resident') {
        final params = {
          'p_building': _building.text.trim(),
          'p_unit': _unit.text.trim(),
          'p_check': _check.text.trim().isEmpty ? null : _check.text.trim(),
        };
        await rpc('get_unit_history', params);
        appState.residentBuilding = params['p_building'] as String;
        appState.residentUnit = params['p_unit'] as String;
        appState.residentCheck = params['p_check'] as String?;
        _go(const ResidentHome());
      } else {
        await rpc('admin_login', {'p_admin_key': _adminKey.text});
        appState.adminKey = _adminKey.text;
        _go(const AdminHome());
      }
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'ورود انجام نشد؛ دوباره تلاش کنید');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _go(Widget page) {
    _password.clear();
    _adminKey.clear();
    _check.clear();
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0B3B7A), AppColors.navy],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: size.height * 0.04),
                Image.asset('assets/logo.png', width: 96, height: 96),
                const SizedBox(height: 10),
                const Text('aban AS',
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                const Text('صدور قبض آب، سریع و آسان',
                    style: TextStyle(color: Color(0xFFBFD9FF), fontSize: 13)),
                const SizedBox(height: 26),
                Container(
                  width: double.infinity,
                  constraints: BoxConstraints(minHeight: size.height * 0.62),
                  padding: const EdgeInsets.fromLTRB(22, 24, 22, 28),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('ورود به حساب', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      const Text('نقش خود را انتخاب کنید', style: TextStyle(color: AppColors.muted, fontSize: 13)),
                      const SizedBox(height: 16),
                      _roleSwitch(),
                      const SizedBox(height: 22),
                      if (_role == 'manager') ...[
                        _field(_building, 'نام یا کد ساختمان', Icons.apartment_outlined),
                        _field(_password, 'رمز مدیر', Icons.lock_outline, obscure: true),
                      ],
                      if (_role == 'resident') ...[
                        _field(_building, 'نام یا کد ساختمان', Icons.apartment_outlined),
                        _field(_unit, 'شماره واحد', Icons.home_outlined),
                        _field(_check, 'کد تأیید واحد', Icons.vpn_key_outlined, obscure: true),
                      ],
                      if (_role == 'admin')
                        _field(_adminKey, 'کلید ثبت ساختمان', Icons.admin_panel_settings_outlined, obscure: true),
                      if (_error != null) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                              color: AppColors.redSoft, borderRadius: BorderRadius.circular(12)),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: AppColors.red, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                  child: Text(_error!,
                                      style: const TextStyle(color: AppColors.red, fontSize: 13))),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      SizedBox(
                        height: 52,
                        child: FilledButton(
                          onPressed: _busy ? null : _submit,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.blue,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: _busy
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                              : const Text('ورود', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _roleSwitch() {
    const roles = [
      ('manager', 'مدیر', Icons.business_center_outlined),
      ('resident', 'ساکن', Icons.home_outlined),
      ('admin', 'ادمین', Icons.shield_outlined),
    ];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: roles.map((r) {
          final selected = _role == r.$1;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() {
                _role = r.$1;
                _error = null;
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? AppColors.blue : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: selected
                      ? const [BoxShadow(color: Color(0x33185FA5), blurRadius: 8, offset: Offset(0, 3))]
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(r.$3, size: 20, color: selected ? Colors.white : AppColors.muted),
                    const SizedBox(height: 4),
                    Text(r.$2,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: selected ? Colors.white : AppColors.muted)),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _field(TextEditingController c, String label, IconData icon, {bool obscure = false}) {
    final isPass = obscure;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: c,
        obscureText: isPass && _hidePass,
        onSubmitted: (_) => _submit(),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppColors.blue2),
          suffixIcon: isPass
              ? IconButton(
                  icon: Icon(_hidePass ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _hidePass = !_hidePass),
                )
              : null,
          filled: true,
          fillColor: AppColors.bg,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.blue2, width: 1.5),
          ),
        ),
      ),
    );
  }
}
