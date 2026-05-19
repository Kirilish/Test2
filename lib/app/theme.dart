import 'package:flutter/material.dart';

ThemeData buildTheme() => ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF0A84FF),
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF0F172A),
      useMaterial3: true,
    );
