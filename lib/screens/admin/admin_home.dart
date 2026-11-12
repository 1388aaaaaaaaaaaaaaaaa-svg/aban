import 'package:flutter/material.dart';

import '../../api.dart';
import '../../state.dart';
import '../../theme.dart';
import '../login_screen.dart';
import 'activity_tab.dart';
import 'buildings_tab.dart';
import 'notifications_tab.dart';
import 'register_tab.dart';
import 'support_tab.dart';

/// Admin panel: bottom navigation with every section.
class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  int _index = 0;
  int _unread = 0;

  void _logout() {
    appState.clear();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  Future<void> _refreshUnread() async {
    try {
      final rows = await rpc('admin_notifications', {'p_admin_key': appState.adminKey}) as List;
      final n = rows.where((r) => (r as Map)['is_read'] != true).length;
      if (mounted) setState(() => _unread = n);
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    _refreshUnread();
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const BuildingsTab(),
      NotificationsTab(onUnreadChanged: _refreshUnread),
      const SupportTab(),
      const RegisterTab(),
      const ActivityTab(),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('پنل ادمین'),
        actions: [
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout, color: AppColors.red), tooltip: 'خروج'),
        ],
      ),
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          const NavigationDestination(icon: Icon(Icons.apartment_outlined), selectedIcon: Icon(Icons.apartment), label: 'ساختمان‌ها'),
          NavigationDestination(
            icon: Badge(isLabelVisible: _unread > 0, label: Text('$_unread'), child: const Icon(Icons.notifications_outlined)),
            selectedIcon: const Icon(Icons.notifications),
            label: 'اعلان‌ها',
          ),
          const NavigationDestination(icon: Icon(Icons.support_agent_outlined), selectedIcon: Icon(Icons.support_agent), label: 'پشتیبانی'),
          const NavigationDestination(icon: Icon(Icons.add_business_outlined), selectedIcon: Icon(Icons.add_business), label: 'ثبت ساختمان'),
          const NavigationDestination(icon: Icon(Icons.history), selectedIcon: Icon(Icons.history), label: 'گزارش'),
        ],
      ),
    );
  }
}
