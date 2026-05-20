import 'package:flutter/material.dart';

ThemeData buildTheme() {
  const bg = Color(0xFF0B1220);
  const surface = Color(0xFF111A2E);
  const accent = Color(0xFF22C55E);

  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF3B82F6),
    brightness: Brightness.dark,
  ).copyWith(
    surface: surface,
    primary: const Color(0xFF60A5FA),
    secondary: accent,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: bg,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF18233D),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    ),
    chipTheme: const ChipThemeData(
      selectedColor: Color(0xFF1D4ED8),
      backgroundColor: Color(0xFF1E293B),
      labelStyle: TextStyle(color: Colors.white),
      side: BorderSide.none,
    ),
  );
}
