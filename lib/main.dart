import 'package:flutter/material.dart';

import 'screens/splash_screen.dart';
import 'theme.dart';

void main() => runApp(const AbanApp());

class AbanApp extends StatelessWidget {
  const AbanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'aban AS',
      debugShowCheckedModeBanner: false,
      theme: appTheme(),
      builder: (context, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child!),
      home: const SplashScreen(),
    );
  }
}
