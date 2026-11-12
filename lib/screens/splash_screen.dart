import 'dart:async';

import 'package:flutter/material.dart';

import '../theme.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _spin =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat();

  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const LoginScreen(),
          transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    });
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0B3B7A), AppColors.navy],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/logo.png', width: 170, height: 170),
            const SizedBox(height: 14),
            const Text('صدور قبض آب، سریع و آسان',
                style: TextStyle(color: Color(0xFFBFD9FF), fontSize: 14)),
            const SizedBox(height: 44),
            RotationTransition(
              turns: _spin,
              child: const SizedBox(
                width: 46,
                height: 46,
                child: CircularProgressIndicator(strokeWidth: 3, color: Color(0xFF6EC8FF)),
              ),
            ),
            const SizedBox(height: 16),
            const Text('در حال بارگذاری…', style: TextStyle(color: Color(0xFFBFD9FF), fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
