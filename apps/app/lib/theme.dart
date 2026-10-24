import 'package:flutter/material.dart';

/// Sharp orange theme with white-on-orange icon accents.
const kPrimary = Color(0xFFFF6A00);   // sharp orange
const kPrimaryDark = Color(0xFFE65C00);
const kAccent = Color(0xFFFF8A3D);    // bright tangerine
const kAccentDark = Color(0xFFCC5500);
const kSurface = Color(0xFFFFFFFF);
const kBackground = Color(0xFFFFF7F2); // warm off-white wash
const kCard = Color(0xFFFFFFFF);
const kTextPrimary = Color(0xFF2B1608);
const kTextSecondary = Color(0xFF7A6A60);
const kBorder = Color(0xFFF0E3DA);
const kSuccess = Color(0xFF34D399);
const kWarning = Color(0xFFFBBF24);
const kError = Color(0xFFF87171);
const kPink = Color(0xFFEC4899);
const kOrange = Color(0xFFFF6A00);

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

LinearGradient linearGradient(Color start, Color end) => LinearGradient(
      colors: [start, end],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
