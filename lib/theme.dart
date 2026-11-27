import 'package:flutter/material.dart';

class AppColors {
  static const navy = Color(0xFF06224A);
  static const deep = Color(0xFF0B3B7A);
  static const blue = Color(0xFF185FA5);
  static const blue2 = Color(0xFF378ADD);
  static const blueLight = Color(0xFFE6F1FB);
  static const aqua = Color(0xFFE2F3FF);
  static const aqua2 = Color(0xFFCBE8FF);
  static const foam = Color(0xFFF4FBFF);
  static const bg = Color(0xFFF2F6FC);
  static const text = Color(0xFF14213D);
  static const muted = Color(0xFF5D7A90);
  static const red = Color(0xFFD7324F);
  static const redSoft = Color(0xFFFCEBEB);
  static const green = Color(0xFF0F6E56);
  static const greenSoft = Color(0xFFE1F5EE);
  static const amberSoft = Color(0xFFFAEEDA);
}

ThemeData appTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: AppColors.blue, surface: AppColors.foam);
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: Colors.transparent,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: AppColors.navy,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.foam,
      indicatorColor: AppColors.aqua2,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.aqua,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
    ),
  );
}
