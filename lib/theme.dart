import 'package:flutter/material.dart';

class AppColors {
  static const navy = Color(0xFF06224A);
  static const blue = Color(0xFF185FA5);
  static const blue2 = Color(0xFF378ADD);
  static const blueLight = Color(0xFFE6F1FB);
  static const bg = Color(0xFFF2F6FC);
  static const text = Color(0xFF14213D);
  static const muted = Color(0xFF6B7C93);
  static const red = Color(0xFFD7324F);
  static const redSoft = Color(0xFFFCEBEB);
  static const green = Color(0xFF0F6E56);
  static const greenSoft = Color(0xFFE1F5EE);
  static const amberSoft = Color(0xFFFAEEDA);
}

ThemeData appTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.blue, surface: Colors.white),
    scaffoldBackgroundColor: AppColors.bg,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bg,
      foregroundColor: AppColors.text,
      elevation: 0,
      centerTitle: false,
    ),
  );
}
