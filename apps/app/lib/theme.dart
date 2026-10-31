import 'package:flutter/material.dart';

/// Sharp orange palette — punchy coral orange primary with sunny tangerine
/// accent over a soft peach wash, plus playful candy accents for tabs/cards.
const kPrimary = Color(0xFFFF7A3D); // sharp coral orange
const kPrimaryDark = Color(0xFFE8601C); // deep burnt orange
const kAccent = Color(0xFFFFB347); // sunny tangerine
const kAccentDark = Color(0xFFCC7A00);
const kSurface = Color(0xFFFFFFFF);
const kBackground = Color(0xFFFFF6F0); // soft peach wash
const kCard = Color(0xFFFFFFFF);
const kTextPrimary = Color(0xFF2E1A0E); // espresso ink
const kTextSecondary = Color(0xFF8A7568); // warm taupe
const kBorder = Color(0xFFF2E4D9); // warm sand
const kSuccess = Color(0xFF34D399);
const kWarning = Color(0xFFFBBF24);
const kError = Color(0xFFF87171);
const kPink = Color(0xFFEC4899);
const kPurple = Color(0xFFA78BFA);
const kBlue = Color(0xFF60A5FA);
const kOrange = Color(0xFFFF7A3D);

/// Per-tab accent colours used across nav, cards, and chips.
const kTabColors = <Color>[
  kPrimary, // Dashboard
  kBlue, // Courses
  kPink, // Calendar
  kAccent, // Chat
  kSuccess, // Integrity
];

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
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
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
    fillColor: kSurface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    hintStyle: const TextStyle(color: kTextSecondary),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: kBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: kBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: kPrimary, width: 1.8),
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: kPrimary,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
    ),
  ),
  snackBarTheme: SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    backgroundColor: kPrimary,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    contentTextStyle: const TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.w700,
    ),
  ),
  dividerTheme: const DividerThemeData(color: kBorder, space: 1),
);

/// Signature hero gradient — sharp orange into deep burnt orange.
const candyGradient = LinearGradient(
  colors: [kPrimary, kPrimaryDark],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

/// Gradient helpers for hero cards, chips and buttons.
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

/// Soft pastel tint for subtle background chips (per accent colour).
Color tintOf(Color color, [double opacity = 0.12]) =>
    color.withValues(alpha: opacity);

/// Darkens [color] toward black by [amount] (0..1) — handy for gradient ends.
Color shadeOf(Color color, [double amount = 0.18]) =>
    Color.lerp(color, Colors.black, amount)!;
