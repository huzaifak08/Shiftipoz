import 'package:flutter/material.dart';

class ShiftipozTheme {
  // Primary Colors
  static const Color midnightBlue = Color(0xFF0B132B);
  static const Color deepSpace = Color(0xFF1C2541);
  static const Color liquidChrome = Color(0xFFC0C0C0);
  static const Color ivoryCream = Color(0xFFF8F9FA);
  static const Color royalBlue = Color(0xFF3A506B);

  // --- LIGHT THEME (The Modern Library) ---
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: royalBlue,
      primary: royalBlue,
      onPrimary: Colors.white,
      secondary: midnightBlue,
      surface: Colors.white,
      outline: Colors.grey[300],
    ),
    scaffoldBackgroundColor: ivoryCream,
    fontFamily: 'Plus Jakarta Sans', // Modern, premium sans-serif
    // Card Style (For Book Listings)
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
    ),

    // Bottom Sheet (For ISBN Scanner/Unit Picker)
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.white,
      elevation: 10,
      showDragHandle: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
    ),

    // Date Picker Light
    datePickerTheme: DatePickerThemeData(
      backgroundColor: ivoryCream,
      headerBackgroundColor: royalBlue,
      headerForegroundColor: Colors.white,
      dayShape: WidgetStateProperty.all(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );

  // --- DARK THEME (The Signature Shiftipoz) ---
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: liquidChrome,
      brightness: Brightness.dark,
      primary: liquidChrome, // Silver accent
      onPrimary: midnightBlue,
      secondary: const Color(0xFF5BC0BE), // Oxygen Cyan for action buttons
      surface: deepSpace,
      onSurface: Colors.white,
      outline: Colors.white.withValues(alpha: 0.1),
    ),
    scaffoldBackgroundColor: midnightBlue,
    fontFamily: 'Plus Jakarta Sans',

    // Card Style (Glassmorphism Lite)
    cardTheme: CardThemeData(
      color: Colors.white.withValues(alpha: 0.04),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
      ),
    ),

    // Bottom Sheet (Deep UI)
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: deepSpace,
      showDragHandle: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
    ),

    // Time Picker Dark (Chrome Accents)
    timePickerTheme: TimePickerThemeData(
      backgroundColor: deepSpace,
      dialHandColor: liquidChrome,
      hourMinuteColor: midnightBlue,
      hourMinuteTextColor: liquidChrome,
      dayPeriodColor: midnightBlue,
      dayPeriodTextColor: liquidChrome,
    ),
  );
}
