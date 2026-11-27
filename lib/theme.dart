import 'package:flutter/material.dart';

/// Palette: deep water ink, tide blue, mist surfaces and a signal amber for limits.
/// Names are kept from the earlier theme so every screen picks up the new colors.
class AppColors {
  static const ink = Color(0xFF0E2A3F);
  static const navy = ink;
  static const text = ink;
  static const deep = Color(0xFF16405A);
  static const blue = Color(0xFF1C6E8C);
  static const blue2 = Color(0xFF4A9BB5);
  static const blueLight = Color(0xFFDCEBEA);
  static const aqua = Color(0xFFE3EFEE);
  static const aqua2 = Color(0xFFBFD6D4);
  static const foam = Color(0xFFF6FAF9);
  static const bg = Color(0xFFEDF3F2);
  static const muted = Color(0xFF5C7A86);
  static const red = Color(0xFFB2452F);
  static const redSoft = Color(0xFFF6E3DE);
  static const green = Color(0xFF1F7A5A);
  static const greenSoft = Color(0xFFDDF0E8);
  static const signal = Color(0xFFE0A03A);
  static const amberSoft = Color(0xFFFBF0DA);
}

ThemeData appTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.blue,
    primary: AppColors.blue,
    surface: AppColors.foam,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.bg,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bg,
      foregroundColor: AppColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(color: AppColors.ink, fontSize: 18, fontWeight: FontWeight.w800),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.foam,
      indicatorColor: AppColors.blueLight,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 12,
          fontWeight: states.contains(WidgetState.selected) ? FontWeight.w800 : FontWeight.w500,
          color: AppColors.ink,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.foam,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.aqua2)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.aqua2)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.blue, width: 1.5)),
    ),
  );
}
