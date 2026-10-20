import 'package:flutter/material.dart';

/// Lively, vibrant theme with gradient accents and playful shadows.
const kPrimary = Color(0xFF7C3AED);   // vivid violet
const kPrimaryDark = Color(0xFF5B21B6);
const kAccent = Color(0xFF22D3EE);    // bright cyan
const kAccentDark = Color(0xFF0891B2);
const kSurface = Color(0xFFFFFFFF);
const kBackground = Color(0xFFF0F9FF); // light cyan-blue wash
const kCard = Color(0xFFFFFFFF);
const kTextPrimary = Color(0xFF1E1B4B);
const kTextSecondary = Color(0xFF6B7280);
const kBorder = Color(0xFFE5E7EB);
const kSuccess = Color(0xFF34D399);
const kWarning = Color(0xFFFBBF24);
const kError = Color(0xFFF87171);
const kPink = Color(0xFFEC4899);
const kOrange = Color(0xFFF97316);

final appTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: kPrimary,
    brightness: Brightness.light,
  ),
  scaffoldBackgroundColor: kBackground,
  cardTheme: CardThemeData(
    elevation: 0,
    color: kCard,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
  ),
  appBarTheme: const AppBarTheme(
    centerTitle: false,
    elevation: 0,
    scrolledUnderElevation: 0,
    backgroundColor: Colors.transparent,
    foregroundColor: kTextPrimary,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: kCard,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: kBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: kBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: kPrimary),
    ),
  ),
  dividerTheme: const DividerThemeData(color: kBorder, space: 1),
);

/// Gradient helper for cards and buttons.
LinearGradient livelyGradient(Color start, Color end) => LinearGradient(
      colors: [start, end],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
