import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const night = Color(0xFF07111F);
  static const navy = Color(0xFF10233F);
  static const slate = Color(0xFF213757);
  static const mist = Color(0xFFEAF2FF);
  static const ice = Color(0xFFB4C9F3);
  static const gold = Color(0xFFF4C66D);
  static const coral = Color(0xFFFF8A65);
  static const emerald = Color(0xFF5ED3A2);
  static const panel = Color(0xFF112743);
  static const panelSoft = Color(0xFF17355B);
}

ThemeData buildAppTheme() {
  final textTheme = GoogleFonts.manropeTextTheme().copyWith(
    displayLarge: GoogleFonts.cinzel(
      fontSize: 42,
      fontWeight: FontWeight.w700,
      color: AppColors.mist,
    ),
    displayMedium: GoogleFonts.cinzel(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      color: AppColors.mist,
    ),
    headlineMedium: GoogleFonts.manrope(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      color: AppColors.mist,
    ),
    titleLarge: GoogleFonts.manrope(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: AppColors.mist,
    ),
    bodyLarge: GoogleFonts.manrope(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: AppColors.mist,
    ),
    bodyMedium: GoogleFonts.manrope(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: AppColors.ice,
    ),
  );

  final scheme = ColorScheme.fromSeed(
    brightness: Brightness.dark,
    seedColor: AppColors.gold,
    primary: AppColors.gold,
    secondary: AppColors.emerald,
    surface: AppColors.panel,
    error: AppColors.coral,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.night,
    textTheme: textTheme,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.06),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: const BorderSide(color: AppColors.gold),
      ),
      hintStyle: textTheme.bodyMedium,
    ),
    cardTheme: CardThemeData(
      color: AppColors.panel,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: AppColors.night,
        backgroundColor: AppColors.gold,
        textStyle: GoogleFonts.manrope(fontWeight: FontWeight.w800),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.white.withValues(alpha: 0.08),
      selectedColor: AppColors.gold,
      labelStyle: textTheme.bodyMedium!,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}
