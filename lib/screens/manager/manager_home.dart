import 'package:flutter/material.dart';

import '../../state.dart';
import '../../theme.dart';
import '../../widgets.dart';
import '../login_screen.dart';
import 'bills_tab.dart';
import 'messages_tab.dart';
import 'period_tab.dart';
import 'units_tab.dart';

/// Manager panel: bottom navigation.
class ManagerHome extends StatefulWidget {
  const ManagerHome({super.key});

  @override
  State<ManagerHome> createState() => _ManagerHomeState();
}

class _ManagerHomeState extends State<ManagerHome> {
  int _index = 0;

  void _logout() {
    appState.clear();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const UnitsTab(),
      const PeriodTab(),
      const BillsTab(),
      const MessagesTab(),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(appState.managerBuildingName ?? 'مدیر ساختمان'),
        actions: [
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout, color: AppColors.red), tooltip: 'خروج'),
        ],
      ),
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'واحدها'),
          NavigationDestination(icon: Icon(Icons.water_drop_outlined), selectedIcon: Icon(Icons.water_drop), label: 'قبض جدید'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'صورت‌حساب'),
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline), selectedIcon: Icon(Icons.chat_bubble), label: 'پیام‌ها'),
        ],
      ),
    );
  }
}
