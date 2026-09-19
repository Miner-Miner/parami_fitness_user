import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const navy = Color(0xFF102331);
  static const navyLight = Color(0xFF1D3A4B);
  static const mint = Color(0xFF1AB98B);
  static const mintDark = Color(0xFF0B8B68);
  static const lime = Color(0xFFD9F16C);
  static const canvas = Color(0xFFF4F7F6);
  static const ink = Color(0xFF18313E);
  static const muted = Color(0xFF647681);
  static const line = Color(0xFFDCE6E3);
  static const warning = Color(0xFFF0A530);
  static const danger = Color(0xFFD95959);
  static const logoCanvas = Color(0xFF2B2B2B);
}

ThemeData gymTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.mint,
    primary: AppColors.mint,
    secondary: AppColors.lime,
    surface: Colors.white,
    brightness: Brightness.light,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.canvas,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.canvas,
      foregroundColor: AppColors.ink,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: AppColors.ink,
        fontWeight: FontWeight.w800,
        fontSize: 21,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.mint, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.danger),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.mint,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.navy,
      contentTextStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: AppColors.mint.withValues(alpha: .15),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        return TextStyle(
          color: states.contains(WidgetState.selected)
              ? AppColors.mintDark
              : AppColors.muted,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w800
              : FontWeight.w600,
        );
      }),
    ),
  );
}
